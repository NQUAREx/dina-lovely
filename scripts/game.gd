extends Node2D
## All coordinates are world pixels. Artwork is a shared nearest-filtered atlas.
const TILE := 48.0
const SPEED := 150.0
const SAVE_PATH := "user://garden_save_v1.json"
const TITLES := ["Таинственный лабиринт", "Испытание храбрости", "Домашний сад", "Последний подарок"]
const REQUIRED := ["dawn", "flower", "star"]
const CREAM := Color("f5e3cf")
const PINK := Color("e5a6bd")
const INK := Color("45394f")
var atlas: Texture2D = preload("res://assets/atlas.png")
var ground: Texture2D = preload("res://assets/ground.png")
var glow: Texture2D = preload("res://assets/glow.png")
var body_font: Font = preload("res://assets/body.ttf")
var title_font: Font = preload("res://assets/title.ttf")
var sprites: Dictionary
var content: Dictionary
var save_data: Dictionary
var level := 0
var grid: Array[String] = []
var objects: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var player := Vector2.ZERO
var camera := Vector2.ZERO
var direction := 2
var moving := false
var time := 0.0
var health := 8
var invincible := 0.0
var attack_cd := 0.0
var attack_flash := 0.0
var aim := Vector2.RIGHT
var wave := 0
var wave_timer := 2.0
var combat_done := false
var garden_can := false
var water := 0
var watered: Array = []
var bloom_times: Dictionary = {}
var puzzle: Array[String] = []
var chest_open := false
var playing := false
var paused := true
var touch_mode := false
var touch_buttons: Dictionary = {}
var joy_id := -1
var joy_origin := Vector2.ZERO
var joy_vector := Vector2.ZERO
var attack_held := false
var ui: CanvasLayer
var root: Control
var hud: Control
var modal: Control
var rotate_overlay: Control
var objective: Label
var status: Label
var hint: Label
var action_button: Button
var attack_button: Button
var toast: Label
var toast_time := 0.0
var nearest := -1
var audio_pool: Array[AudioStreamPlayer] = []
var audio_cursor := 0
var step_clock := 0.0
var shake := 0.0
var shake_offset := Vector2.ZERO
var ambience_clock := 3.0
var sound: AudioStreamPlayer
var sound_on := true
var fps_average := 60.0
var low_fx := false
var save_error := false
var browser_paused := false
var browser_poll := 0.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprites = JSON.parse_string(FileAccess.get_file_as_string("res://assets/atlas.json"))
	content = JSON.parse_string(FileAccess.get_file_as_string("res://content/letters.json"))
	load_save()
	setup_audio()
	setup_ui()
	build_level(2)
	camera = Vector2(13.5,9.5)*TILE
	touch_mode = true
	show_menu()
	get_viewport().size_changed.connect(layout_ui)
	layout_ui()

func default_save() -> Dictionary:
	return {"version":1,"level":0,"completed_levels":[],"letters":[],"secrets":[],"finished":false,"garden_can":false,"water":0,"watered":[],"sound":true,"started":false}

func load_save() -> void:
	save_data = default_save()
	if FileAccess.file_exists(SAVE_PATH):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
		if parsed is Dictionary and parsed.get("version", 0) == 1:
			for key in save_data:
				if parsed.has(key) and typeof(parsed[key]) == typeof(save_data[key]):
					save_data[key] = parsed[key]
			# JSON numbers decode as floats.
			save_data.level = clampi(int(parsed.get("level", 0)), 0, 3)
			save_data.water = clampi(int(parsed.get("water", 0)), 0, 3)
	sound_on = save_data.sound

func persist() -> void:
	save_data.erase("music")
	save_data.sound = sound_on
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.flush()
	else:
		save_error = true
		if is_instance_valid(toast): notify("Хранилище недоступно. Не закрывай вкладку до финала.")

func setup_audio() -> void:
	for i in range(10):
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -12
		add_child(voice)
		audio_pool.append(voice)

func sfx(name: String = "chime") -> void:
	if not sound_on: return
	var voice := audio_pool[audio_cursor % audio_pool.size()]
	audio_cursor += 1
	voice.stream = load("res://assets/" + name + ".wav")
	voice.pitch_scale = randf_range(.94,1.06)
	voice.play()

func haptic(duration: int = 18) -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.gardenHaptic && window.gardenHaptic(" + str(duration) + ")")

func panel_style(color: Color, border: Color = Color("a07890"), radius: int = 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func label(text: String, size: int, color: Color = CREAM, fancy: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", title_font if fancy else body_font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func button(text: String, callback: Callable, width: float = 250) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(minf(width, 420), 60)
	b.add_theme_font_override("font", body_font)
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_color_override("font_color", CREAM)
	b.add_theme_stylebox_override("normal", panel_style(Color("51445f")))
	b.add_theme_stylebox_override("hover", panel_style(Color("70536e"), PINK))
	b.add_theme_stylebox_override("pressed", panel_style(Color("97677d"), CREAM))
	b.pressed.connect(callback)
	return b

func setup_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(root)
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)
	var top := Panel.new()
	top.position = Vector2(16, 70)
	top.size = Vector2(508, 100)
	top.add_theme_stylebox_override("panel", panel_style(Color(0.12,0.14,0.22,0.92)))
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(top)
	objective = label("", 18)
	objective.position = Vector2(32, 84)
	objective.size = Vector2(390, 46)
	hud.add_child(objective)
	status = label("", 14, Color("c1bdce"))
	status.position = Vector2(32, 132)
	status.size = Vector2(470, 34)
	hud.add_child(status)
	var menu_button := button("Ⅱ", show_menu, 68)
	menu_button.name = "MenuButton"
	hud.add_child(menu_button)
	hint = label("", 15)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.add_child(hint)
	action_button = button("Читать", interact, 155)
	hud.add_child(action_button)
	attack_button = button("✦  Атака", func(): attack(), 120)
	attack_button.button_down.connect(func(): attack_held = true)
	attack_button.button_up.connect(func(): attack_held = false)
	hud.add_child(attack_button)
	toast = label("", 17, Color("ffe6b3"))
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(toast)
	rotate_overlay = Control.new()
	rotate_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(rotate_overlay)
	var bg := ColorRect.new()
	bg.color = Color("242538")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rotate_overlay.add_child(bg)
	var tip := label("↻\nВерни телефон вертикально\n\nСад раскрывается в портретном режиме.", 24, CREAM, true)
	tip.name = "OrientationMessage"
	tip.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	tip.position = Vector2(-220,-125)
	tip.size = Vector2(440,250)
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotate_overlay.add_child(tip)
	rotate_overlay.z_index = 100

func layout_ui() -> void:
	var size := get_viewport_rect().size
	if not is_instance_valid(hud): return
	hud.get_node("MenuButton").position = Vector2(444, 80)
	action_button.position = Vector2(337, 824)
	action_button.custom_minimum_size = Vector2(180,76)
	attack_button.position = Vector2(365, 720)
	attack_button.custom_minimum_size = Vector2(150,82)
	hint.position = Vector2(36, 914)
	hint.size = Vector2(468, 32)
	toast.position = Vector2(32, 180)
	toast.size = Vector2(476, 76)
	rotate_overlay.visible = false
	var orientation_text: Label = rotate_overlay.get_node("OrientationMessage")
	orientation_text.position = Vector2(-240,-180)
	orientation_text.size = Vector2(480,360)

func clear_modal() -> void:
	if is_instance_valid(modal):
		root.remove_child(modal)
		modal.queue_free()
	modal = null
	paused = false
	if playing and is_instance_valid(hud): hud.show()
	joy_id = -1
	joy_vector = Vector2.ZERO
	attack_held = false

func modal_box(width: float = 610, height: float = 430, paper: bool = false) -> VBoxContainer:
	clear_modal()
	paused = true
	modal = Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(modal)
	var shade := ColorRect.new()
	shade.color = Color(0.07,0.08,0.14,0.78)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(500, minf(height, 740))
	panel.add_theme_stylebox_override("panel", panel_style(CREAM if paper else Color("292c42"), Color("c899a4"), 16))
	center.add_child(panel)
	var margin := MarginContainer.new()
	for key in ["margin_left","margin_right","margin_top","margin_bottom"]: margin.add_theme_constant_override(key, 22)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	margin.add_child(box)
	panel.modulate.a = 0
	create_tween().tween_property(panel, "modulate:a", 1.0, 0.25)
	return box

func show_menu() -> void:
	var box := modal_box(590, 0)
	box.add_child(label("A LITTLE JOURNEY FOR YOU", 12, PINK))
	box.add_child(label(content.game_title, 35, CREAM, true))
	box.add_child(label("Четыре маленьких шага. Одно большое чувство.", 15, Color("c1bdce")))
	if playing: box.add_child(button("Вернуться в сад" if health>0 else "Повторить комнату", func():
		if health<=0: build_level(1)
		clear_modal()))
	elif save_data.started: box.add_child(button("Продолжить", resume_game))
	box.add_child(button("Новая игра", confirm_new if save_data.started else new_game))
	box.add_child(button("Собранные письма · " + str(save_data.letters.size()) + "/7", show_journal))
	box.add_child(button("Настройки звука", show_settings))
	if save_data.finished: box.add_child(button("Посмотреть открытку", show_card))
	box.add_child(label("10–15 минут для тебя  ·  Наушники добавят уюта", 12, Color("b5adc4")))
	hud.visible = playing

func confirm_new() -> void:
	var box := modal_box(540, 260)
	box.add_child(label("Начать сначала?", 28, CREAM, true))
	box.add_child(label("Собранные письма и текущий прогресс будут сброшены.", 17))
	box.add_child(button("Начать новую историю", new_game))
	box.add_child(button("Назад", show_menu))

func new_game() -> void:
	save_data = default_save()
	save_data.started = true
	playing = true
	build_level(0)
	persist()
	show_intro()

func resume_game() -> void:
	playing = true
	build_level(int(save_data.level))
	clear_modal()
	hud.show()

func show_intro() -> void:
	var box := modal_box(650, 410)
	box.add_child(label("Глава " + str(level + 1) + " / 4", 13, PINK))
	box.add_child(label(TITLES[level], 30, CREAM, true))
	var texts := ["Этот сад хранит три письма. Найди их среди живых изгородей — и арка откроет дорогу дальше. Золотые искорки укажут, где можно что-то прочитать.\n\nНе спеши. Здесь есть и два маленьких секрета.","Немного смелости — и дорога снова открыта. Три волны сонных хранителей хотят поиграть.\n\nПодойди ближе и используй атаку. Розовый круг предупреждает об ударе: отойди! После каждой волны здоровье восстановится.","Когда о саде заботятся, он отвечает цветами. Найди лейку, набери воду у колодца и полей шесть ростков.\n\nЛейки хватит на три цветка. Возвращайся к колодцу, когда вода закончится.","Самый важный подарок уже рядом. Три знака на камнях хранят порядок нашего маленького дня.\n\nНажми их в порядке из писем. Журнал всегда доступен через меню."]
	box.add_child(label(texts[level], 18))
	box.add_child(label("Слева — джойстик. Справа — действие и атака.\nГероиня сама выбирает ближайшую цель.", 18, Color("c1bdce")))
	box.add_child(button("Пойдём", func(): clear_modal(); hud.show()))

func show_settings() -> void:
	var box := modal_box(550, 350)
	box.add_child(label("Звуки нашего сада", 28, CREAM, true))
	box.add_child(button("Эффекты: " + ("вкл" if sound_on else "выкл"), func(): sound_on = not sound_on; persist(); show_settings()))
	box.add_child(label("Прогресс хранится в этом браузере. Очистка данных сайта удалит сохранение. В приватном режиме оно может не сохраниться.", 14, Color("c1bdce")))
	box.add_child(button("Назад", show_menu))

func show_journal() -> void:
	var box := modal_box(670, 460)
	box.add_child(label("Письма, которые остаются", 29, CREAM, true))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 285
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for letter in content.letters:
		if letter.id in save_data.letters:
			var id: String = letter.id
			list.add_child(button(letter.title, func(): show_letter(id, true)))
	if save_data.letters.is_empty(): list.add_child(label("Пока здесь тихо. Первое письмо ждёт тебя в саду.", 18))
	box.add_child(button("Назад", show_menu))

func show_letter(id: String, journal: bool = false) -> void:
	var letter: Dictionary = {}
	for item in content.letters:
		if item.id == id: letter = item
	if letter.is_empty(): return
	var box := modal_box(690, 440, true)
	box.add_child(label("ДЛЯ ТЕБЯ · С ЛЮБОВЬЮ", 12, Color("a26c7e")))
	box.add_child(label(letter.title, 27, INK, true))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 225
	box.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)
	var text := label(letter.text, 20, INK)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(text)
	if not str(letter.get("image", "")).is_empty() and ResourceLoader.exists(letter.image):
		var pic := TextureRect.new()
		pic.texture = load(letter.image)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.custom_minimum_size = Vector2(300,180)
		column.add_child(pic)
	box.add_child(label("бережно сохранено в твоём журнале", 12, Color("a26c7e")))
	box.add_child(button("Вернуться к письмам" if journal else "Сохранить в сердце", show_journal if journal else clear_modal))

func collect(id: String) -> void:
	if id not in save_data.letters:
		save_data.letters.append(id)
		if id.begins_with("secret"):
			save_data.secrets.append(id)
		burst(player, 22, PINK)
		persist()
		sfx()
	sfx("paper")
	show_letter(id)

func show_card() -> void:
	var box := modal_box(900, 490, true)
	box.add_child(label("НАШЕ МАЛЕНЬКОЕ НАВСЕГДА", 12, Color("a26c7e")))
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 420
	row.add_child(left)
	var picture := TextureRect.new()
	picture.texture = load(content.photo) if ResourceLoader.exists(content.photo) else preload("res://assets/keepsake.png")
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	picture.custom_minimum_size = Vector2(420, 190)
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	left.add_child(picture)
	left.add_child(label(content.photo_caption, 13, Color("a26c7e"), true))
	left.add_child(label("♡  " + content.signature, 21, INK, true))
	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 420
	row.add_child(right)
	right.add_child(label(content.recipient + ",", 19, Color("a26c7e"), true))
	right.add_child(label(content.card_title, 28, INK, true))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(420, 210)
	right.add_child(scroll)
	var text := label(content.card_text, 17, INK)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(text)
	box.add_child(button("♡  Оставить это мгновение в сердце", show_menu))
	sfx()

func put_object(kind: String, cell: Vector2i, id: String = "", solid: bool = false) -> void:
	objects.append({"kind":kind,"pos":Vector2(cell)*TILE+Vector2.ONE*TILE/2,"id":id,"solid":solid})

func set_cell(x: int, y: int, value: String) -> void:
	grid[y] = grid[y].substr(0,x) + value + grid[y].substr(x+1)

func build_level(index: int) -> void:
	level = index
	grid.clear()
	objects.clear()
	enemies.clear()
	particles.clear()
	bloom_times.clear()
	health = 8
	invincible = 1.0
	wave = 0
	wave_timer = 2.5
	combat_done = "courage" in save_data.letters
	garden_can = save_data.garden_can
	water = int(save_data.water)
	watered = save_data.watered.duplicate()
	chest_open = save_data.finished
	puzzle.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1287 + level
	if level == 0:
		# Perfect maze: every corridor is connected; letters occupy distinct far branches.
		for y in range(23): grid.append("#".repeat(31))
		var stack: Array[Vector2i] = [Vector2i(1,1)]
		set_cell(1,1,".")
		while not stack.is_empty():
			var p: Vector2i = stack.back()
			var candidates: Array[Vector2i] = []
			for d in [Vector2i(2,0),Vector2i(-2,0),Vector2i(0,2),Vector2i(0,-2)]:
				var q: Vector2i = p+d
				if q.x>0 and q.y>0 and q.x<30 and q.y<22 and grid[q.y][q.x]=="#": candidates.append(q)
			if candidates.is_empty(): stack.pop_back()
			else:
				var q := candidates[rng.randi_range(0,candidates.size()-1)]
				set_cell((p.x+q.x)/2,(p.y+q.y)/2,".")
				set_cell(q.x,q.y,".")
				stack.append(q)
		# A few loops reduce backtracking while preserving the labyrinth.
		for p in [Vector2i(8,5),Vector2i(16,11),Vector2i(22,17),Vector2i(10,19)]: set_cell(p.x,p.y,".")
		put_object("note",Vector2i(13,3),"dawn")
		put_object("note",Vector2i(27,11),"flower")
		put_object("note",Vector2i(5,19),"star")
		put_object("note",Vector2i(29,1),"secret_moon")
		put_object("note",Vector2i(17,21),"secret_bench")
		put_object("arch",Vector2i(29,21),"exit")
		player = Vector2(1.5,1.5)*TILE
	else:
		for y in range(19):
			grid.append("#".repeat(27) if y==0 or y==18 else "#"+".".repeat(25)+"#")
		player = Vector2(13.5,15.5)*TILE
		if level == 1:
			for p in [Vector2i(5,5),Vector2i(21,5),Vector2i(5,13),Vector2i(21,13)]:
				put_object("stone",p,"",true)
				put_object("lamp",p+Vector2i(0,-1))
			put_object("chest",Vector2i(13,7),"courage")
			put_object("arch",Vector2i(13,2),"exit")
		elif level == 2:
			put_object("can",Vector2i(5,14),"can")
			put_object("well",Vector2i(13,8),"well",true)
			var cells := [Vector2i(6,5),Vector2i(20,5),Vector2i(7,10),Vector2i(19,10),Vector2i(9,14),Vector2i(17,14)]
			for i in range(cells.size()): put_object("sprout",cells[i],str(i))
			put_object("note",Vector2i(13,5),"garden")
			put_object("arch",Vector2i(13,2),"exit")
			for p in [Vector2i(3,4),Vector2i(23,4),Vector2i(3,12),Vector2i(23,12)]: put_object("tree",p,"",true)
		else:
			put_object("chest",Vector2i(13,6),"final")
			put_object("stone",Vector2i(9,10),"sun",true)
			put_object("stone",Vector2i(13,10),"flower",true)
			put_object("stone",Vector2i(17,10),"star",true)
			for x in [7,19]:
				for y in [5,8,11,14]: put_object("candle",Vector2i(x,y))
	if level>0:
		for x in range(2,25,2):
			for y in [2,16]:
				if abs(x-13)>2:
					put_object("blueflowers" if level==1 else "flowers",Vector2i(x,y))
		for y in range(3,17,4):
			for x in [2,24]: put_object("tree",Vector2i(x,y),"",true)
		if level==3:
			put_object("arch",Vector2i(13,3))
			for x in [10,16]: put_object("blueflowers",Vector2i(x,6))
	# Decorative borders and flowers never block a corridor.
	for y in range(1,grid.size()-1):
		for x in range(1,grid[0].length()-1):
			if grid[y][x] == "#":
				if rng.randf()<0.07: put_object("tree",Vector2i(x,y))
			elif rng.randf() < (0.11 if level==0 else 0.035):
				var p := Vector2(x,y)*TILE + Vector2(8,9)
				objects.append({"kind":"flowers" if rng.randf()<0.6 else "blueflowers","pos":p,"id":"","solid":false})
	for y in range(3,grid.size()-1,6):
		for x in [1,grid[0].length()-2]:
			if grid[y][x]==".": put_object("lamp",Vector2i(x,y))
	camera = camera_target()
	nearest = -1
	update_hud()

func camera_target() -> Vector2:
	var half := get_viewport_rect().size/2
	return Vector2(clampf(player.x,half.x-48,grid[0].length()*TILE-half.x+48),clampf(player.y,half.y-220,grid.size()*TILE-half.y+64))

func blocked(pos: Vector2) -> bool:
	for offset in [Vector2(-10,-7),Vector2(10,-7),Vector2(-10,7),Vector2(10,7)]:
		var c := Vector2i((pos+offset)/TILE)
		if c.y<0 or c.x<0 or c.y>=grid.size() or c.x>=grid[0].length() or grid[c.y][c.x]=="#": return true
	for obj in objects:
		if obj.solid and pos.distance_to(obj.pos) < 24: return true
	return false

func move_player(delta: float, input: Vector2) -> void:
	moving = input.length()>0.1
	if not moving: return
	step_clock -= delta
	if step_clock<=0:
		var cell := Vector2i(player/TILE)
		sfx("step_stone" if level in [1,3] or (level==2 and (cell.x==13 or cell.y==15)) else "step_grass")
		step_clock = .31
	var motion := input.limit_length()*SPEED*delta
	var next := player+Vector2(motion.x,0)
	if not blocked(next): player = next
	next = player+Vector2(0,motion.y)
	if not blocked(next): player = next
	if abs(input.x)>abs(input.y): direction = 1 if input.x<0 else 3
	else: direction = 0 if input.y<0 else 2

func _process(delta: float) -> void:
	browser_poll -= delta
	if OS.has_feature("web") and browser_poll<=0:
		browser_paused = bool(JavaScriptBridge.eval("!!window.gardenSuspended"))
		browser_poll = .25
		if browser_paused: joy_id = -1; joy_vector = Vector2.ZERO; attack_held = false
	time += delta
	toast_time -= delta
	toast.visible = toast_time>0
	fps_average = lerpf(fps_average, 1.0/maxf(delta,0.001), 0.01)
	low_fx = false
	shake = maxf(0,shake-delta*13)
	shake_offset = Vector2(sin(time*47),cos(time*53))*shake
	ambience_clock -= delta
	if ambience_clock<=0 and playing and not paused:
		sfx("ambient")
		ambience_clock = randf_range(7,13)
	if not paused and playing and not browser_paused and not rotate_overlay.visible:
		var input := Vector2.ZERO
		if joy_id>=0: input = joy_vector
		move_player(minf(delta,0.04),input)
		camera = camera.lerp(camera_target(),1-exp(-delta*9))
		invincible = maxf(0,invincible-delta)
		attack_cd -= delta
		attack_flash = maxf(0,attack_flash-delta)
		if attack_held: attack()
		if level == 1 and not combat_done: update_combat(minf(delta,0.04))
		for id in bloom_times: bloom_times[id] = minf(1.0,bloom_times[id]+delta/2.8)
		find_nearest()
		update_hud()
	for i in range(particles.size()-1,-1,-1):
		particles[i].life -= delta
		particles[i].pos += particles[i].vel*delta
		particles[i].vel *= 0.98
		if particles[i].life<=0: particles.remove_at(i)
	queue_redraw()

func touch_button_at(node: Node, pos: Vector2) -> Button:
	var children := node.get_children()
	children.reverse()
	for child in children:
		var found := touch_button_at(child, pos)
		if found: return found
	if node is Button and node.is_visible_in_tree() and not node.disabled and node.get_global_rect().has_point(pos):
		return node
	return null

func _input(event: InputEvent) -> void:
	if not event is InputEventScreenTouch: return
	touch_mode = true
	if not event.pressed and event.index==joy_id:
		joy_id = -1
		joy_vector = Vector2.ZERO
	if rotate_overlay.visible: return
	if event.pressed:
		var surface: Node = modal if paused and is_instance_valid(modal) else root
		var target := touch_button_at(surface,event.position)
		if target:
			haptic(12)
			sfx("ui")
			touch_buttons[event.index] = weakref(target)
			if target==attack_button: attack_held = true; attack()
			get_viewport().set_input_as_handled()
	elif touch_buttons.has(event.index):
		var target = touch_buttons[event.index].get_ref()
		touch_buttons.erase(event.index)
		attack_held = false
		if is_instance_valid(target) and target.is_visible_in_tree() and target.get_global_rect().has_point(event.position): target.pressed.emit()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if paused or not playing: return
	if event is InputEventScreenTouch:
		touch_mode = true
		if event.pressed and event.position.x<get_viewport_rect().size.x*0.48 and joy_id<0:
			joy_id = event.index
			joy_origin = event.position
			joy_vector = Vector2.ZERO
		elif not event.pressed and event.index==joy_id:
			joy_id = -1
			joy_vector = Vector2.ZERO
	if event is InputEventScreenDrag and event.index==joy_id:
		joy_vector = ((event.position-joy_origin)/52).limit_length()

func available(obj: Dictionary) -> bool:
	var id: String = obj.id
	if id.is_empty(): return false
	if id == "courage": return combat_done and id not in save_data.letters
	if id == "garden": return watered.size()==6 and id not in save_data.letters and blooms_ready()
	if obj.kind == "note": return id not in save_data.letters
	if id == "can": return not garden_can
	if obj.kind == "sprout": return id not in watered
	return true

func blooms_ready() -> bool:
	for v in bloom_times.values():
		if v<1: return false
	return true

func find_nearest() -> void:
	nearest = -1
	var distance := 79.0
	for i in range(objects.size()):
		if available(objects[i]):
			var d := player.distance_to(objects[i].pos)
			if d<distance:
				distance = d
				nearest = i

func action_text(obj: Dictionary) -> String:
	if obj.id == "exit": return "Дальше"
	if obj.id == "well": return "Набрать воду"
	if obj.id == "can": return "Взять лейку"
	if obj.kind == "sprout": return "Полить"
	if obj.id == "final": return "Открыть"
	if level==3 and obj.kind=="stone": return {"sun":"Солнце","flower":"Цветок","star":"Звезда"}[obj.id]
	return "Читать"

func interact() -> void:
	if paused or nearest<0: return
	var obj := objects[nearest]
	var id: String = obj.id
	if id=="exit":
		if level==0 and not has_maze_letters(): notify("Арка ждёт три письма. Загляни в другие уголки сада.")
		elif level==1 and "courage" not in save_data.letters: notify("Сначала открой сундук с письмом.")
		elif level==2 and "garden" not in save_data.letters: notify("Сначала вырасти сад и прочитай письмо в центре.")
		else: next_level()
	elif id=="can":
		garden_can = true
		save_data.garden_can = true
		persist()
		sfx()
		notify("Лейка найдена! Теперь к колодцу в центре сада.")
	elif id=="well":
		if not garden_can: notify("Лейка ждёт в юго-западном уголке сада.")
		else:
			water = 3
			sfx("fill")
			save_data.water = water
			persist()
			sfx()
			burst(obj.pos,16,Color("a9dce1"))
			notify("Три капельки заботы. Полей ростки вокруг колодца.")
	elif obj.kind=="sprout":
		if not garden_can: notify("Сначала найди лейку в юго-западном уголке.")
		elif water==0: notify("Вода закончилась. Колодец в центре сада.")
		else:
			water -= 1
			sfx("water")
			haptic(25)
			watered.append(id)
			bloom_times[id] = 0.0
			save_data.water = water
			save_data.watered = watered.duplicate()
			persist()
			sfx()
			burst(obj.pos,20,PINK)
			if watered.size()==6: notify("Сад ожил. В центре появилось письмо для тебя.")
	elif id=="final":
		if chest_open: show_card()
		elif puzzle==["sun","flower","star"]: finish_game()
		else: notify("Зажги знаки по порядку: подсказка в собранных письмах.")
	elif level==3 and obj.kind=="stone":
		var order := ["sun","flower","star"]
		if puzzle.size()==3: notify("Все знаки сияют. Твой подарок ждёт в сундуке.")
		elif id==order[puzzle.size()]:
			puzzle.append(id)
			sfx()
			burst(obj.pos,20,Color("ffe1a6"))
			notify("Солнце → Цветок → Звезда. Сундук открыт для тебя!" if puzzle.size()==3 else "Знак зажёгся. Продолжай наш маленький день.")
		else:
			puzzle.clear()
			notify("Попробуем ещё раз: сначала утро, потом цветение, потом ночь.")
	else: collect(id)
	find_nearest()

func has_maze_letters() -> bool:
	for id in REQUIRED:
		if id not in save_data.letters: return false
	return true

func next_level() -> void:
	if level>=3: return
	if level not in save_data.completed_levels: save_data.completed_levels.append(level)
	save_data.level = level+1
	persist()
	clear_modal()
	build_level(level+1)
	show_intro()

func finish_game() -> void:
	chest_open = true
	shake = 14
	haptic(100)
	sfx("chest")
	save_data.finished = true
	if 3 not in save_data.completed_levels: save_data.completed_levels.append(3)
	persist()
	sfx()
	paused = true
	for obj in objects:
		if obj.id=="final": burst(obj.pos,65,PINK)
	var tween := create_tween()
	tween.tween_interval(2.1)
	tween.tween_callback(show_card)

func update_hud() -> void:
	if not is_instance_valid(objective): return
	objective.text = str(level+1) + " / 4   ·   " + TITLES[level]
	match level:
		0:
			var count := 0
			for id in REQUIRED:
				if id in save_data.letters: count+=1
			status.text = "Письма %d / 3   ·   Секреты %d / 2   ·   %s" % [count,save_data.secrets.size(),"Арка открыта" if count==3 else "Ищи золотые искорки"]
		1: status.text = "♥ ".repeat(health) + "   Волна %d / 3   ·   %s" % [mini(wave,3),"Открой сундук" if combat_done else "Удерживай кнопку атаки"]
		2: status.text = "Цветы %d / 6   ·   %s" % [watered.size(),"Вода: "+str(water)+" / 3" if garden_can else "Найди лейку на юго-западе"]
		3: status.text = "Знаки %d / 3   ·   Подсказка в журнале писем" % puzzle.size()
	action_button.visible = nearest>=0 and playing
	if nearest>=0: action_button.text = ""+action_text(objects[nearest])
	attack_button.visible = level==1 and not combat_done and playing
	hint.text = "Коснись слева, чтобы идти" if joy_id<0 else ""

func notify(text: String) -> void:
	toast.text = text
	toast_time = 4.0

func burst(pos: Vector2, count: int, color: Color) -> void:
	for i in range(count*2):
		if particles.size()>=420: break
		particles.append({"pos":pos+Vector2(0,-22),"vel":Vector2(randf_range(-65,65),randf_range(-100,20)),"life":randf_range(.7,1.6),"color":color,"heart":i%4==0})

func spawn_wave() -> void:
	wave += 1
	health = mini(8,health+3)
	wave_timer = 3.0
	var count := 3 + wave*2
	for i in range(count):
		var angle := TAU*i/count
		var pos := Vector2(13.5,9.5)*TILE+Vector2(cos(angle)*390,sin(angle)*235)
		enemies.append({"pos":pos,"hp":2 if wave<3 else 3,"type":i%mini(wave,3),"state":"spawn","timer":1.4+float(i)*0.14,"target":player,"cooldown":randf_range(.4,1.2)})
	notify("Волна %d из 3 · Ты справишься. Я рядом." % wave)

func update_combat(delta: float) -> void:
	if enemies.is_empty():
		wave_timer -= delta
		if wave_timer<=0:
			if wave<3: spawn_wave()
			else:
				combat_done = true
				health = 8
				notify("Ты справилась! В центре ждёт сундук с письмом.")
				sfx()
		return
	for enemy in enemies:
		enemy.timer -= delta
		enemy.cooldown -= delta
		var diff: Vector2 = player-enemy.pos
		if enemy.state=="spawn":
			if enemy.timer<=0: enemy.state="chase"
		elif enemy.state=="warn":
			if enemy.timer<=0:
				if enemy.pos.distance_to(player)<70: hurt()
				burst(enemy.pos,7,Color("bc96c7"))
				enemy.state="rest"
				enemy.timer=.65
		elif enemy.state=="rest":
			if enemy.timer<=0: enemy.state="chase"
		else:
			if diff.length()<61:
				enemy.state="warn"
				enemy.timer=.95 if enemy.type!=2 else 1.15
			else:
				var speed: float = 39.0+enemy.type*7+wave*3
				var v: Vector2 = diff.normalized()
				if enemy.type==1: v = v.rotated(sin(time*2+enemy.pos.x)*.65)
				var target: Vector2 = enemy.pos+v*speed*delta
				if not blocked(target): enemy.pos=target
				elif not blocked(enemy.pos+Vector2(v.x,0)*speed*delta): enemy.pos+=Vector2(v.x,0)*speed*delta
				else: enemy.pos+=Vector2(0,v.y)*speed*delta

func attack() -> void:
	if paused or level!=1 or combat_done or attack_cd>0: return
	attack_cd = .34
	attack_flash = .19
	if touch_mode:
		var closest := INF
		for enemy in enemies:
			var d: float = player.distance_to(enemy.pos)
			if d<closest:
				closest = d
				aim = (enemy.pos-player).normalized()
	else: aim = Vector2.RIGHT
	if aim.length()<.1: aim=Vector2.RIGHT
	sfx("attack")
	shake = 2.5
	haptic(14)
	for i in range(enemies.size()-1,-1,-1):
		var enemy := enemies[i]
		var diff: Vector2 = enemy.pos-player
		if enemy.state!="spawn" and diff.length()<117 and (aim.dot(diff.normalized())>-.05 or diff.length()<48):
			enemy.hp -= 1
			enemy.state="rest"
			enemy.timer=.4
			var target: Vector2 = enemy.pos+diff.normalized()*20
			if not blocked(target): enemy.pos=target
			burst(enemy.pos,8,Color("e9c2d5"))
			if enemy.hp<=0: enemies.remove_at(i)

func hurt() -> void:
	if invincible>0: return
	health -= 1
	invincible = 1.3
	sfx("hurt")
	shake = 8
	haptic(60)
	burst(player,12,PINK)
	if health<=0:
		var box := modal_box(590,330)
		box.add_child(label("Давай ещё раз, вместе", 30, CREAM, true))
		box.add_child(label("Ничего не потеряно. Все письма с тобой.\n\nДвигайся, когда появляется розовый круг. Атакуй с небольшого расстояния — твоя искра достаёт дальше хранителей.",18))
		box.add_child(button("Попробовать снова", func(): build_level(1); clear_modal()))
		box.add_child(button("Меню", show_menu))

func screen(pos: Vector2) -> Vector2:
	return (pos-camera+get_viewport_rect().size/2+shake_offset).round()

func draw_sprite(name: String, pos: Vector2, color: Color = Color.WHITE, scale_factor: float = 1.0) -> void:
	var id := int(sprites.get(name,0))
	var size := Vector2(64,96)*scale_factor
	draw_texture_rect_region(atlas,Rect2(pos-Vector2(32,86)*scale_factor,size),Rect2(Vector2(id%16*32,id/16*48),Vector2(32,48)),color)

func draw_shadow(pos: Vector2, width: float = 24) -> void:
	draw_set_transform(pos,0,Vector2(1,.3))
	draw_circle(Vector2.ZERO,width,Color(0.06,.09,.15,.28))
	draw_set_transform(Vector2.ZERO)

func symbol(id: String, pos: Vector2, color: Color) -> void:
	if id=="sun":
		draw_circle(pos,6,color)
		for i in range(8):
			var v := Vector2.from_angle(i*TAU/8)
			draw_line(pos+v*10,pos+v*14,color,2)
	elif id=="flower":
		for i in range(5): draw_circle(pos+Vector2.from_angle(i*TAU/5)*7,5,color)
		draw_circle(pos,4,Color("ffe5ad"))
	elif id=="star":
		var points := PackedVector2Array()
		for i in range(10): points.append(pos+Vector2.from_angle(i*PI/5-PI/2)*(13 if i%2==0 else 5))
		draw_colored_polygon(points,color)

func draw_heart(pos: Vector2, size: float, color: Color) -> void:
	var p := PackedVector2Array([Vector2(-4,-2),Vector2(-4,-4),Vector2(-2,-5),Vector2(0,-3),Vector2(2,-5),Vector2(4,-4),Vector2(4,-2),Vector2(0,3)])
	for i in range(p.size()): p[i]=pos+p[i]*size
	draw_colored_polygon(p,color)

func _draw() -> void:
	if grid.is_empty(): return
	var view := get_viewport_rect().size
	var from := Vector2i((camera-view/2)/TILE)-Vector2i(2,3)
	var to := Vector2i((camera+view/2)/TILE)+Vector2i(3,4)
	var renderables: Array[Dictionary] = []
	for y in range(maxi(0,from.y),mini(grid.size(),to.y)):
		for x in range(maxi(0,from.x),mini(grid[0].length(),to.x)):
			var p := screen(Vector2(x,y)*TILE)
			var tile := 0
			if level==1 or level==3: tile=2 if (x+y)%3 else 1
			elif level==2 and (x==13 or y==15 or (watered.size()==6 and y<8 and x>=12 and x<=14)): tile=1
			elif level==0 and grid[y][x]==".": tile=3
			draw_texture_rect_region(ground,Rect2(p,Vector2.ONE*TILE),Rect2(Vector2(tile*24,0),Vector2(24,24)))
			if level==3 and x>=10 and x<=16 and y>=5 and y<=15:
				draw_rect(Rect2(p,Vector2.ONE*TILE),Color(.49,.26,.39,.5))
				if x==10 or x==16: draw_line(p+Vector2(5,0),p+Vector2(5,48),Color("c5918e"),2)
			if grid[y][x]=="#": renderables.append({"kind":"hedge" if level!=1 else "stone","pos":Vector2(x+.5,y+.5)*TILE,"id":"","wall":true})
	for obj in objects:
		var p := screen(obj.pos)
		if p.x < -100 or p.y < -100 or p.x>view.x+100 or p.y>view.y+150: continue
		if obj.id=="courage" and not combat_done: continue
		if obj.id=="garden" and (watered.size()!=6 or not blooms_ready()): continue
		if obj.kind=="note" and obj.id in save_data.letters: continue
		if obj.id=="can" and garden_can: continue
		renderables.append(obj)
	for enemy in enemies: renderables.append({"kind":"enemy"+str(enemy.type),"pos":enemy.pos,"id":"","enemy":enemy})
	renderables.append({"kind":"player","pos":player,"id":""})
	renderables.sort_custom(func(a,b): return a.pos.y<b.pos.y)
	for item in renderables:
		var p := screen(item.pos)
		var kind: String = item.kind
		if kind=="player":
			draw_shadow(p,19)
			var frame := int(time*12)%4 if moving and not paused else 0
			var color := Color(1,.65,.73) if invincible>0 and int(time*12)%2==0 else Color.WHITE
			draw_sprite("hero"+str(direction)+"_"+str(frame),p+Vector2(sin(time*9)*1.2 if moving else 0, sin(time*3)*1.4 if not moving else -absf(sin(time*12))*3),color)
			if attack_flash>0:
				var angle := aim.angle()
				draw_arc(p+Vector2(0,-20),88,angle-1.1,angle+1.1,22,Color(1,.84,.75,attack_flash/.19),7)
				draw_arc(p+Vector2(0,-20),101,angle-.8,angle+.8,18,Color(1,.65,.79,attack_flash/.19),3)
		elif item.has("enemy"):
			var enemy: Dictionary = item.enemy
			if enemy.state=="warn":
				draw_circle(p,70,Color(.91,.43,.58,.19))
				draw_arc(p,70,0,TAU,32,PINK,2)
				draw_string(body_font,p+Vector2(-5,-69),"!",HORIZONTAL_ALIGNMENT_LEFT,-1,24,CREAM)
			draw_shadow(p,20)
			draw_sprite(kind,p+Vector2(0,sin(time*5+item.pos.x)*3),Color(1,1,1,.45 if enemy.state=="spawn" else 1))
			for h in range(enemy.hp): draw_rect(Rect2(p+Vector2(-12+h*9,-57),Vector2(7,3)),PINK)
		else:
			if not item.has("wall"): draw_shadow(p,20 if kind!="tree" else 30)
			if kind=="sprout" and item.id in watered:
				var growth: float = bloom_times.get(item.id,1.0)
				draw_sprite("bloom",p,Color.WHITE,0.65+growth*.35)
			elif kind=="chest": draw_sprite("chest_open" if ((item.id=="final" and chest_open) or item.id in save_data.letters) else "chest",p,Color.WHITE,3.0 if item.id=="final" else 1.0)
			elif kind=="note": draw_sprite(kind,p+Vector2(0,sin(time*2+item.pos.x)*4))
			else: draw_sprite(kind,p+Vector2(sin(time*1.3+item.pos.x)*1.3,0) if kind in ["tree","flowers","blueflowers"] else p)
			if level==3 and kind=="stone" and not item.id.is_empty(): symbol(item.id,p+Vector2(0,-42),Color("ffe4ad") if item.id in puzzle else Color("635770"))
			if kind=="arch":
				var open: bool = (level==0 and has_maze_letters()) or (level==1 and "courage" in save_data.letters) or (level==2 and "garden" in save_data.letters)
				draw_texture_rect(glow,Rect2(p-Vector2(65,110),Vector2(130,150)),false,Color(.9,1,.9,1 if open else .2))
				if not open: draw_line(p+Vector2(-18,-36),p+Vector2(18,-36),Color("ab839a"),4)
	# Batched radial textures approximate soft warm light without expensive real-time lights.
	for item in renderables:
		if item.kind in ["lamp","candle","note"] or (item.kind=="chest" and chest_open):
			var p := screen(item.pos)-Vector2(0,42)
			var size := 150.0+sin(time*3+item.pos.x)*5
			draw_texture_rect(glow,Rect2(p-Vector2.ONE*size/2,Vector2.ONE*size),false)
	if nearest>=0 and playing and not paused:
		var p := screen(objects[nearest].pos)+Vector2(0,-88+sin(time*4)*3)
		draw_colored_polygon(PackedVector2Array([p+Vector2(-6,-5),p+Vector2(6,-5),p+Vector2(0,2)]),Color("ffe4a8"))
	# Deterministic ambient fireflies and butterflies, no nodes allocated per frame.
	for i in range(64):
		var p := Vector2(fposmod(i*137.7+sin(time*.3+i)*26-camera.x*.13,view.x),fposmod(i*93.3+cos(time*.4+i)*18-camera.y*.13,view.y))
		var alpha := .25+.4*(sin(time*1.7+i)+1)/2
		if level==2 and i%3==0:
			var flap := absf(sin(time*6+i))*5+1
			draw_rect(Rect2(p-Vector2(flap,2),Vector2(flap*2,4)),Color(.92,.66,.84,alpha))
		else:
			draw_texture_rect(glow,Rect2(p-Vector2(13,13),Vector2(28,28)),false,Color(1,.9,.65,alpha))
			draw_rect(Rect2(p,Vector2(2,2)),Color(1,.87,.62,alpha))
		if i%4==0:
			var petal := p+Vector2(sin(time*.7+i)*20, sin(time*.4+i)*30)
			draw_set_transform(petal,time*.3+i)
			draw_rect(Rect2(Vector2(-2,-1),Vector2(4,2)),Color(.95,.65,.78,.35))
			draw_set_transform(Vector2.ZERO)
	for part in particles:
		var c: Color = part.color
		c.a = minf(1,part.life)
		if part.heart: draw_heart(screen(part.pos),1.2,c)
		else: draw_rect(Rect2(screen(part.pos),Vector2(3,3)),c)
	# Soft framing, retained UI contrast.
	for i in range(8):
		var c := Color(.06,.07,.13,.025*(8-i))
		draw_rect(Rect2(Vector2(i*5,i*5),view-Vector2.ONE*i*10),c,false,5)
	if playing and not paused:
		if level==0: draw_minimap(view)
		if touch_mode:
			var p := joy_origin if joy_id>=0 else Vector2(110,view.y-110)
			draw_circle(p,57,Color(.9,.8,.9,.09))
			draw_arc(p,57,0,TAU,32,Color(.9,.8,.9,.25),2)
			draw_circle(p+joy_vector*43,22,Color(.92,.75,.82,.45))

func draw_minimap(view: Vector2) -> void:
	var origin := Vector2(view.x-150,235)
	draw_style_box(panel_style(Color(.1,.12,.19,.85)),Rect2(origin-Vector2(9,9),Vector2(143,111)))
	for y in range(grid.size()):
		for x in range(grid[0].length()):
			if grid[y][x]==".": draw_rect(Rect2(origin+Vector2(x,y)*4,Vector2(4,4)),Color("667b75"))
	for obj in objects:
		if (obj.id in REQUIRED and obj.id not in save_data.letters) or obj.id=="exit":
			draw_rect(Rect2(origin+obj.pos/TILE*4-Vector2(2,2),Vector2(4,4)),Color("ead5a0"))
	draw_circle(origin+player/TILE*4,3,PINK)
