extends Node2D
## All coordinates are world pixels. Artwork is a shared nearest-filtered atlas.
const TILE := 48.0
const SPEED := 150.0
const SAVE_PATH := "user://garden_save_v1.json"
const TITLES := ["Записки в саду", "Без света", "Три прохода", "Под травой", "Три раунда", "Заброшенный сад", "Сундук наверху"]
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
var fog: ColorRect
var skulls: Array[Dictionary] = []
var skull_clock := 4.0
var obstacle_cooldown := 0.0
var room_clock := 0.0
var weapon := ""
var shots: Array[Dictionary] = []
var plants: Dictionary = {}
var fertilized: Array = []
var has_fertilizer := false
var task_time := 0.0
var task_kind := ""
var task_target := Vector2.ZERO
var transition := false
var touch_scrolls: Dictionary = {}
var scroll_starts: Dictionary = {}
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
var switch_button: Button
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
	setup_fog()
	setup_ui()
	build_level(5)
	camera = Vector2(13.5,9.5)*TILE
	touch_mode = true
	show_menu()
	get_viewport().size_changed.connect(layout_ui)
	layout_ui()

func default_save() -> Dictionary:
	return {"seed":randi(),"loose_weapons":[],"buried_exposed":false,"plants":{},"fertilized":[],"has_fertilizer":false,"weapon":"","weapons_taken":[],"dig_target":[],"flashlight":false,"shovel":false,"dug":[],"obstacles":[],"version":2,"level":0,"completed_levels":[],"letters":[],"secrets":[],"finished":false,"garden_can":false,"water":0,"watered":[],"sound":true,"started":false}

func load_save() -> void:
	save_data = default_save()
	if FileAccess.file_exists(SAVE_PATH):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
		if parsed is Dictionary and int(parsed.get("version", 0)) in [1,2]:
			for key in save_data:
				if parsed.has(key) and typeof(parsed[key]) == typeof(save_data[key]):
					save_data[key] = parsed[key]
			# JSON numbers decode as floats.
			var old_level := int(parsed.get("level",0))
			if int(parsed.get("version",1))==1:
				old_level = old_level+3 if old_level>0 else 0
				save_data.completed_levels = save_data.completed_levels.map(func(v): return int(v)+3 if int(v)>0 else 0)
			save_data.version = 2
			save_data.level = clampi(old_level,0,6)
			save_data.seed = int(parsed.get("seed",save_data.seed))
			save_data.water = clampi(int(parsed.get("water", 0)), 0, 6)
			if not parsed.has("weapons_taken") and not str(save_data.weapon).is_empty(): save_data.weapons_taken.append(save_data.weapon)
	sound_on = save_data.sound

func persist() -> void:
	save_data.erase("music")
	save_data.plants = plants
	save_data.fertilized = fertilized
	save_data.has_fertilizer = has_fertilizer
	save_data.weapon = weapon
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
	if not sound_on or DisplayServer.get_name()=="headless": return
	var voice := audio_pool[audio_cursor % audio_pool.size()]
	audio_cursor += 1
	var sample_name := name
	if name in ["step_grass","step_stone","attack"]: sample_name += ["","_2","_3"][randi()%3]
	voice.stream = load("res://assets/" + sample_name + ".wav")
	voice.volume_db = {"birds":-29,"crickets":-28,"rustle":-22,"step_grass":-21,"step_stone":-21,"ambient":-32,"water":-14,"fill":-14,"ui":-23,"explosion":-11,"rifle":-13}.get(name,-15)
	voice.pitch_scale = randf_range(.98,1.02) if name in ["rifle","water","fill"] else randf_range(.94,1.06)
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
	ui.layer = 2
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
	switch_button = button("Сменить оружие",cycle_weapon,150)
	switch_button.position=Vector2(365,630)
	hud.add_child(switch_button)
	var stick := Control.new()
	stick.set_script(preload("res://scripts/touch_stick.gd"))
	stick.game = self
	stick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stick.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.add_child(stick)
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
	box.add_child(label("Я КОЕ-ЧТО ДЛЯ ТЕБЯ СПРЯТАЛ", 12, PINK))
	box.add_child(label(content.game_title, 35, CREAM, true))
	box.add_child(label("Найди записки и поднимись к сундуку.", 15, Color("c1bdce")))
	if playing: box.add_child(button("Вернуться в сад" if health>0 else "Повторить комнату", func():
		if health<=0: build_level(4)
		clear_modal()))
	elif save_data.started: box.add_child(button("Продолжить", resume_game))
	box.add_child(button("Новая игра", confirm_new if save_data.started else new_game))
	box.add_child(button("Собранные письма · " + str(save_data.letters.size()) + "/12", show_journal))
	box.add_child(button("Настройки звука", show_settings))
	if save_data.finished: box.add_child(button("Посмотреть открытку", show_card))
	box.add_child(label("Со звуком здесь приятнее.", 12, Color("b5adc4")))
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
	box.add_child(label("Глава " + str(level + 1) + " / 7", 13, PINK))
	box.add_child(label(TITLES[level], 30, CREAM, true))
	var texts := ["В лабиринте три записки. Собери их и иди к северному выходу. Две дополнительные записки можно не искать.\n\nВсе комнаты стоят одна над другой. Назад тоже можно вернуться.","В коридоре лежит фонарик. Подбери его и найди три записки. Света немного: поворачивайся, чтобы осмотреть углы. Черепа на полу исчезают сами и не причиняют вреда.","Три балки ездят поперёк прохода. Дождись свободного края и пройди вверх. При столкновении тебя отодвинет назад; здоровье не теряется.","Лопата стоит слева от входа. Возьми её и копай в любом месте газона. На ямку — четверть секунды. Письмо спрятано случайно; подсказка скажет, когда ты рядом.","На стойках у входа лежат РПГ, автомат и меч. Подойди к стойке и возьми оружие. Менять его можно в любой момент.\n\nПройди три волны. Розовый круг означает, что сейчас будет удар.","Возьми лейку и пакет удобрения слева. Каждому цветку нужна одна порция удобрения и три полива.\n\nПосле полива дай растению подрасти. Лейки хватает на шесть порций воды.","В записках были три знака и их порядок. Нажми знаки на камнях, потом открой сундук.\n\nЕсли забыла порядок, записки есть в журнале."]
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
	box.add_child(label("Найденные записки", 29, CREAM, true))
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
	if save_data.letters.is_empty(): list.add_child(label("Пока ничего нет. Первые записки лежат в лабиринте.", 18))
	box.add_child(button("Назад", show_menu))

func show_letter(id: String, journal: bool = false) -> void:
	var letter: Dictionary = {}
	for item in content.letters:
		if item.id == id: letter = item
	if letter.is_empty(): return
	var box := modal_box(690, 440, true)
	box.add_child(label("ЗАПИСКА ДЛЯ ТЕБЯ", 12, Color("a26c7e")))
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
	box.add_child(label("Есть в журнале. Можно перечитать.", 12, Color("a26c7e")))
	box.add_child(button("Вернуться к письмам" if journal else "Убрать записку", show_journal if journal else clear_modal))

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
	box.add_child(label("ПОСЛЕДНЯЯ ЗАПИСКА", 12, Color("a26c7e")))
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
	box.add_child(button("Вернуться в меню", show_menu))
	sfx()

func put_object(kind: String, cell: Vector2i, id: String = "", solid: bool = false) -> void:
	objects.append({"kind":kind,"pos":Vector2(cell)*TILE+Vector2.ONE*TILE/2,"id":id,"solid":solid})

func set_cell(x: int, y: int, value: String) -> void:
	grid[y] = grid[y].substr(0,x) + value + grid[y].substr(x+1)

func build_level(index: int) -> void:
	level = index
	skulls.clear()
	room_clock = 0
	if is_instance_valid(fog): fog.visible = level==1
	shots.clear()
	task_time = 0
	plants = save_data.get("plants",{}).duplicate(true)
	fertilized = save_data.get("fertilized",[]).duplicate()
	has_fertilizer = save_data.get("has_fertilizer",false)
	weapon = save_data.get("weapon","")
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
	rng.seed = int(save_data.seed)+level*16427
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
		if level==1:
			put_object("stand_flashlight",Vector2i(13,18),"flashlight")
			put_object("note",Vector2i(5,5),"shade_1")
			put_object("note",Vector2i(21,8),"shade_2")
			put_object("note",Vector2i(7,13),"shade_3")
			for x in [8,18]:
				for y in [5,11]: put_object("stone",Vector2i(x,y),"",true)
			put_object("arch",Vector2i(13,2),"exit")
		elif level==2:
			for y in range(1,18):
				for x in range(1,26):
					if x<9 or x>17: set_cell(x,y,"#" if x in [8,18] else " ")
			put_object("arch",Vector2i(13,2),"exit")
		elif level==3:
			grid.clear()
			for y in range(13): grid.append("#".repeat(27) if y in [0,12] else "#"+".".repeat(25)+"#")
			player=Vector2(13.5,10.5)*TILE
			put_object("shovel",Vector2i(8,8),"shovel")
			if save_data.dig_target.is_empty():
				save_data.dig_target=[randf_range(4,22)*TILE,randf_range(7,15)*TILE]
			for key in save_data.dug:
				var parts: PackedStringArray = str(key).split(":")
				if parts.size()==2: objects.append({"kind":"dug","id":"","solid":false,"pos":Vector2(float(parts[0]),float(parts[1]))})
			put_object("arch",Vector2i(13,2),"exit")
		elif level == 4:
			for p in [Vector2i(5,5),Vector2i(21,5),Vector2i(5,13),Vector2i(21,13)]:
				put_object("stone",p,"",true)
				put_object("lamp",p+Vector2i(0,-1))
			put_object("chest",Vector2i(13,7),"courage")
			for i in range(3): put_object("rack_"+["rpg","rifle","sword"][i],Vector2i(9+i*4,14),["rpg","rifle","sword"][i])
			put_object("arch",Vector2i(13,2),"exit")
		elif level == 5:
			put_object("can",Vector2i(5,14),"can")
			put_object("fertilizer",Vector2i(5,12),"fertilizer")
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
					put_object("blueflowers" if level==4 else "flowers",Vector2i(x,y))
		for y in range(3,17,4):
			for x in [2,24]: put_object("tree",Vector2i(x,y),"",true)
		if level==6:
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
	add_corridors()
	finish_room_layout(rng)
	if level==3: objects.assign(objects.filter(func(o): return o.kind in ["shovel","dug","doorway"]))
	for id in watered:
		if not plants.has(id): plants[id] = {"stage":3,"remaining":0.0}
	camera = camera_target()
	nearest = -1
	update_hud()

func camera_target() -> Vector2:
	var half := get_viewport_rect().size/2
	return Vector2(clampf(player.x,half.x-48,grid[0].length()*TILE-half.x+48),clampf(player.y,half.y-220,grid.size()*TILE-half.y+64))

func blocked(pos: Vector2) -> bool:
	for offset in [Vector2(-10,-7),Vector2(10,-7),Vector2(-10,7),Vector2(10,7)]:
		var c := Vector2i((pos+offset)/TILE)
		if c.y<0 or c.x<0 or c.y>=grid.size() or c.x>=grid[0].length() or grid[c.y][c.x] in ["#"," "]: return true
	for obj in objects:
		if obj.solid and pos.distance_to(obj.pos) < (58 if obj.kind in ["house","pond"] else 24): return true
	return false

func move_player(delta: float, input: Vector2) -> void:
	moving = input.length()>0.1
	if not moving: return
	step_clock -= delta
	if level==0 and (blocked(player+input.normalized()*18)) and step_clock<=0:
		sfx("rustle")
	if step_clock<=0:
		var cell := Vector2i(player/TILE)
		sfx("step_stone" if level in [4,6] or (level==5 and (cell.x==13 or cell.y==15)) else "step_grass")
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
		sfx("birds" if level==0 else "crickets" if level==1 else "ambient")
		ambience_clock = 10.0 if level in [0,1] else randf_range(7,13)
	if not paused and not transition and playing and not browser_paused and not rotate_overlay.visible:
		var input := Vector2.ZERO
		if joy_id>=0: input = joy_vector
		if task_time<=0: move_player(minf(delta,0.04),input)
		else: moving = false
		update_new_rooms(delta)
		update_tasks(delta)
		if level==5: update_plants(delta)
		if level==4: update_shots(delta)
		if player.y<2.8*TILE: use_exit()
		elif level>0 and player.y>(grid.size()-2.8)*TILE: travel(level-1)
		camera = camera.lerp(camera_target(),1-exp(-delta*9))
		invincible = maxf(0,invincible-delta)
		attack_cd -= delta
		attack_flash = maxf(0,attack_flash-delta)
		if attack_held and task_time<=0: attack()
		if level == 4 and not combat_done: update_combat(minf(delta,0.04))
		for id in bloom_times: bloom_times[id] = minf(1.0,bloom_times[id]+delta/2.8)
		find_nearest()
		update_hud()
	for i in range(particles.size()-1,-1,-1):
		particles[i].life -= delta
		particles[i].pos += particles[i].vel*delta
		particles[i].vel *= 0.98
		if particles[i].life<=0: particles.remove_at(i)
	update_fog()
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
	if event is InputEventScreenDrag and touch_scrolls.has(event.index):
		var sc = touch_scrolls[event.index].get_ref()
		if is_instance_valid(sc): sc.scroll_vertical -= int(event.relative.y)
		if absf(event.position.y-float(scroll_starts[event.index]))>9: touch_buttons.erase(event.index)
		get_viewport().set_input_as_handled()
		return
	if not event is InputEventScreenTouch: return
	touch_mode = true
	if not event.pressed and event.index==joy_id:
		joy_id = -1
		joy_vector = Vector2.ZERO
	if rotate_overlay.visible: return
	if event.pressed:
		var sc := scroll_at(modal,event.position) if is_instance_valid(modal) else null
		if sc:
			touch_scrolls[event.index] = weakref(sc)
			scroll_starts[event.index] = event.position.y
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

	if not event.pressed:
		touch_scrolls.erase(event.index)
		scroll_starts.erase(event.index)

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
	if obj.id in ["rpg","rifle","sword"]: return obj.id not in save_data.weapons_taken
	if obj.id=="flashlight": return not save_data.flashlight
	if obj.id=="shovel": return not save_data.shovel
	if obj.kind=="mound": return obj.id not in save_data.dug
	var id: String = obj.id
	if id.is_empty(): return false
	if id == "crossing": return id not in save_data.letters
	if id == "courage": return combat_done and id not in save_data.letters
	if id == "garden": return watered.size()==6 and id not in save_data.letters and blooms_ready()
	if obj.kind == "note": return id not in save_data.letters
	if id == "can": return not garden_can
	if id == "fertilizer": return not has_fertilizer
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
	if obj.id=="flashlight": return "Взять фонарик"
	if obj.id=="shovel": return "Взять лопату"
	if str(obj.id).begins_with("drop_"):return "Взять "+str({"rpg":"РПГ","rifle":"АК-47","sword":"Меч"}.get(obj.weapon,obj.weapon))
	if obj.kind=="mound": return "Копать"
	if obj.id=="back": return "Назад"
	if obj.id=="fertilizer": return "Взять удобрение"
	if obj.id in ["rpg","rifle","sword"]: return {"rpg":"Взять РПГ","rifle":"Взять АК-47","sword":"Взять меч"}[obj.id]
	if obj.id == "exit": return "Дальше"
	if obj.id == "well": return "Набрать воду"
	if obj.id == "can": return "Взять лейку"
	if obj.kind == "sprout":
		if obj.id not in fertilized: return "Удобрить"
		if float(plants.get(obj.id,{}).get("remaining",0))>0: return "Растёт…"
		return "Полить · этап " + str(int(plants.get(obj.id,{}).get("stage",0))+1)
	if obj.id == "final": return "Открыть"
	if level==6 and obj.kind=="stone": return {"sun":"Солнце","flower":"Цветок","star":"Звезда"}[obj.id]
	return "Читать"

func interact() -> void:
	if paused or transition: return
	if level==3 and save_data.shovel and task_time<=0 and (nearest<0 or objects[nearest].id not in ["exit","back","buried"]):
		dig_here()
		return
	if nearest<0: return
	var obj := objects[nearest]
	var id: String = obj.id
	if task_time>0: return
	if id in ["flashlight","shovel"]:
		save_data[id] = true
		persist()
		sfx("ui")
	elif obj.kind=="mound":
		if not save_data.shovel: notify("Лопата осталась у входа.")
		else: begin_task("dig:"+id,obj.pos,.25)
	elif id=="exit": use_exit()
	elif id=="back": travel(level-1)
	elif id in ["rpg","rifle","sword"]:
		if id in save_data.weapons_taken: return
		if not weapon.is_empty():
			var dropped := {"kind":"weapon_"+weapon,"id":"drop_"+weapon+"_"+str(Time.get_ticks_msec()),"weapon":weapon,"pos":player+Vector2(0,25),"solid":false}
			objects.append(dropped)
			var saved := dropped.duplicate();saved.pos=[dropped.pos.x,dropped.pos.y];save_data.loose_weapons.append(saved)
		weapon = id
		if id not in save_data.weapons_taken: save_data.weapons_taken.append(id)
		attack_cd = .3
		persist()
		sfx("ui")
		notify({"rpg":"РПГ: прямое попадание убирает одного врага.","rifle":"Автомат: удерживай атаку, чтобы стрелять.","sword":"Меч: широкий удар вблизи."}[id])
	elif id.begins_with("drop_"):
		var previous := weapon
		weapon=obj.weapon
		objects.erase(obj)
		save_data.loose_weapons=save_data.loose_weapons.filter(func(d):return d.id!=id)
		if not previous.is_empty():
			var dropped := {"kind":"weapon_"+previous,"id":"drop_"+previous+"_"+str(Time.get_ticks_msec()),"weapon":previous,"pos":player+Vector2(0,25),"solid":false}
			objects.append(dropped)
			var saved := dropped.duplicate();saved.pos=[dropped.pos.x,dropped.pos.y];save_data.loose_weapons.append(saved)
		persist()
	elif id=="fertilizer":
		has_fertilizer = true
		persist()
		notify("Пакет взят. Каждому растению нужна одна порция.")
	elif id=="can":
		garden_can = true
		save_data.garden_can = true
		persist()
		sfx()
		notify("Лейка взята. Вода в колодце.")
	elif id=="well":
		if not garden_can: notify("Сначала возьми лейку слева от колодца.")
		else: begin_task("fill",obj.pos,2.4)
	elif obj.kind=="sprout":
		if id not in fertilized:
			if not has_fertilizer: notify("Удобрение в пакете рядом с лейкой.")
			else:
				fertilized.append(id)
				begin_task("fertilize",obj.pos,1.6)
				persist()
		elif float(plants.get(id,{}).get("remaining",0))>0: notify("Пока растёт. Можно заняться другим цветком.")
		elif not garden_can: notify("Возьми лейку у западной стены.")
		elif water==0: notify("Вода закончилась. Набери ещё в колодце.")
		else:
			plants[id] = {"stage":int(plants.get(id,{}).get("stage",0)),"remaining":-1.0}
			begin_task("water:"+id,obj.pos,2.2)
	elif id=="final":
		if chest_open: show_card()
		elif puzzle==["sun","flower","star"]: finish_game()
		else: notify("Зажги знаки по порядку: подсказка в собранных письмах.")
	elif level==6 and obj.kind=="stone":
		var order := ["sun","flower","star"]
		if puzzle.size()==3: notify("Все знаки сияют. Твой подарок ждёт в сундуке.")
		elif id==order[puzzle.size()]:
			puzzle.append(id)
			sfx()
			burst(obj.pos,20,Color("ffe1a6"))
			notify("Три знака зажглись. Можно открыть сундук." if puzzle.size()==3 else "Верно. Нажми следующий знак.")
		else:
			puzzle.clear()
			notify("Попробуем ещё раз: сначала утро, потом цветение, потом ночь.")
	else: collect(id)
	find_nearest()

func has_maze_letters() -> bool:
	for id in REQUIRED:
		if id not in save_data.letters: return false
	return true

func use_exit() -> void:
	if transition: return
	if level==0 and not has_maze_letters(): notify("Нужно найти три письма.")
	elif level==1 and not dark_letters_found(): notify("В темноте осталось письмо. Нужно найти все три.")
	elif level==2 and (save_data.obstacles.size()<3 or "crossing" not in save_data.letters): notify("Пройди балки и забери записку посередине.")
	elif level==3 and "buried" not in save_data.letters: notify("Записка ещё под землёй.")
	elif level==4 and "courage" not in save_data.letters: notify("Прочитай письмо из сундука.")
	elif level==5 and "garden" not in save_data.letters: notify("Выращены не все цветы. Письмо появится в центре.")
	elif level<6: next_level()
	if player.y<3*TILE: player.y=3.2*TILE

func next_level() -> void:
	if level>=6: return
	if level not in save_data.completed_levels: save_data.completed_levels.append(level)
	travel(level+1)

func finish_game() -> void:
	chest_open = true
	shake = 14
	haptic(100)
	sfx("chest")
	save_data.finished = true
	if 6 not in save_data.completed_levels: save_data.completed_levels.append(6)
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
	objective.text = str(level+1) + " / 7   ·   " + TITLES[level]
	match level:
		0:
			var count := 0
			for id in REQUIRED:
				if id in save_data.letters: count+=1
			status.text = "Письма %d / 3   ·   Секреты %d / 2   ·   %s" % [count,save_data.secrets.size(),"Арка открыта" if count==3 else "Ищи золотые искорки"]
		1: status.text = "Письма %d / 3 · %s" % [dark_letter_count(),"Фонарик включён" if save_data.flashlight else "Подбери фонарик у входа"]
		2: status.text = "Пройдено %d / 3 · жди свободного прохода" % save_data.obstacles.size()
		3: status.text = "Записка найдена" if "buried" in save_data.letters else ("Копай в любом месте газона" if save_data.shovel else "Лопата у входа")
		4: status.text = "♥ ".repeat(health) + "   Волна %d / 3   ·   %s" % [mini(wave,3),"Открой сундук" if combat_done else {"sword":"Меч","rifle":"АК-47","rpg":"РПГ"}.get(weapon,"Выбери оружие")]
		5: status.text = "Цветы %d / 6   ·   %s" % [watered.size(),"Вода: "+str(water)+" / 6" if garden_can else "Найди лейку на юго-западе"]
		6: status.text = "Знаки %d / 3   ·   Подсказка в журнале писем" % puzzle.size()
	action_button.visible = (nearest>=0 or (level==3 and save_data.shovel)) and playing
	if nearest>=0: action_button.text = ""+action_text(objects[nearest])
	if level==3 and save_data.shovel and (nearest<0 or objects[nearest].id not in ["exit","back","buried"]): action_button.text="Копать" if task_time<=0 else "Копаю…"
	switch_button.visible = false
	attack_button.visible = level==4 and not combat_done and playing
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
	notify("Волна %d из 3 · Выбери оружие на стойке." % wave)

func update_combat(delta: float) -> void:
	if enemies.is_empty():
		wave_timer -= delta
		if wave_timer<=0:
			if wave<3: spawn_wave()
			else:
				combat_done = true
				health = 8
				notify("Готово. Забери письмо из появившегося сундука.")
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
	if paused or level!=4 or combat_done or attack_cd>0 or transition or weapon.is_empty(): return
	attack_cd = {"sword":.48,"rifle":.13,"rpg":1.35}[weapon]
	attack_flash = .22
	var closest := INF
	for enemy in enemies:
		var d: float = player.distance_to(enemy.pos)
		if d<closest:
			closest = d
			aim = (enemy.pos-player).normalized()
	if aim.length()<.1: aim = Vector2.UP
	sfx("attack" if weapon=="sword" else "rifle" if weapon=="rifle" else "rocket")
	shake = 2.5 if weapon!="rpg" else 5
	haptic(14)
	if weapon=="sword":
		for i in range(enemies.size()-1,-1,-1):
			var diff: Vector2 = enemies[i].pos-player
			if diff.length()<130 and aim.dot(diff.normalized())>-.35:
				damage_enemy(i,2,diff.normalized()*28)
	else:
		shots.append({"pos":player+Vector2(0,-15),"vel":aim*(570 if weapon=="rifle" else 95),"life":1.4 if weapon=="rifle" else 3.2,"kind":weapon,"age":0.0})

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
		box.add_child(label("Попробуем ещё раз?", 30, CREAM, true))
		box.add_child(label("Записки сохранены. Бой начнётся заново.\n\nОтходи от розовых кругов. Меч подходит для ближнего боя, автомат и РПГ — для стрельбы издалека.",18))
		box.add_child(button("Попробовать снова", func(): build_level(4); clear_modal()))
		box.add_child(button("Меню", show_menu))

func screen(pos: Vector2) -> Vector2:
	return (pos-camera+get_viewport_rect().size/2+shake_offset).round()

func draw_sprite(name: String, pos: Vector2, color: Color = Color.WHITE, scale_factor: float = 1.0) -> void:
	var id := int(sprites.get(name,0))
	if name=="hedge":
		draw_rect(Rect2(pos+Vector2(-24,-24),Vector2(48,40)),Color("25433d"))
		draw_texture_rect_region(atlas,Rect2(pos+Vector2(-24,-32),Vector2(48,48)),Rect2(Vector2(id%16*32,id/16*48+16),Vector2(32,32)),color)
		return
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
	draw_corridor_extensions()
	var renderables: Array[Dictionary] = []
	for y in range(maxi(0,from.y),mini(grid.size(),to.y)):
		for x in range(maxi(0,from.x),mini(grid[0].length(),to.x)):
			if grid[y][x]==" ": continue
			var p := screen(Vector2(x,y)*TILE)
			var tile := 0
			if level==4 or level==6: tile=2 if (x+y)%3 else 1
			elif level==5 and (x==13 or y==15 or (watered.size()==6 and y<8 and x>=12 and x<=14)): tile=1
			elif level==0 and grid[y][x]==".": tile=3
			draw_texture_rect_region(ground,Rect2(p,Vector2.ONE*TILE),Rect2(Vector2(tile*24,0),Vector2(24,24)))
			if level==6 and x>=10 and x<=16 and y>=5 and y<=15:
				draw_rect(Rect2(p,Vector2.ONE*TILE),Color(.49,.26,.39,.5))
				if x==10 or x==16: draw_line(p+Vector2(5,0),p+Vector2(5,48),Color("c5918e"),2)
			if grid[y][x]=="#": renderables.append({"kind":"stone" if level in [1,2,4] else "hedge","pos":Vector2(x+.5,y+.5)*TILE,"id":"","wall":true})
	for obj in objects:
		var p := screen(obj.pos)
		if p.x < -100 or p.y < -100 or p.x>view.x+100 or p.y>view.y+150: continue
		if obj.id=="courage" and not combat_done: continue
		if obj.id=="garden" and (watered.size()!=6 or not blooms_ready()): continue
		if obj.kind=="note" and obj.id in save_data.letters: continue
		if obj.id=="can" and garden_can: continue
		if obj.id=="fertilizer" and has_fertilizer: continue
		if obj.id=="shovel" and save_data.shovel: continue
		renderables.append(obj)
	for enemy in enemies: renderables.append({"kind":"enemy"+str(enemy.type),"pos":enemy.pos,"id":"","enemy":enemy})
	renderables.append({"kind":"player","pos":player,"id":""})
	if level==1:
		for i in range(24):
			var point := screen(Vector2(6+i*.6,21-i*.36+sin(i*.5)) * TILE)
			draw_texture_rect_region(ground,Rect2(point,Vector2(30,22)),Rect2(Vector2(24,0),Vector2(24,24)))
	renderables.sort_custom(func(a,b):
		if a.pos.y==b.pos.y: return a.pos.x<b.pos.x
		return a.pos.y<b.pos.y)
	for item in renderables:
		var p := screen(item.pos)
		var kind: String = item.kind
		if kind=="player":
			draw_shadow(p,19)
			var frame := int(time*12)%4 if moving and not paused else 0
			var color := Color(1,.65,.73) if invincible>0 and int(time*12)%2==0 else Color.WHITE
			draw_sprite("hero"+str(direction)+"_"+str(frame),p+Vector2(sin(time*9)*1.2 if moving else 0, sin(time*3)*1.4 if not moving else -absf(sin(time*12))*3),color)
			if attack_flash>0 and weapon=="sword":
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
			if kind=="sprout" and plants.has(item.id):
				var growth: float = bloom_times.get(item.id,1.0)
				draw_sprite(["sprout","plant1","plant2","bloom"][clampi(int(plants[item.id].get("stage",0)),0,3)],p,Color.WHITE,0.85+growth*.15)
			elif kind in ["house","pond"]: draw_sprite(kind,p,Color.WHITE,2.0)
			elif kind=="doorway":
				draw_sprite("doorpost",p+Vector2(-90,0));draw_sprite("doorpost",p+Vector2(90,0))
			elif kind=="stand_flashlight":
				draw_sprite("pedestal",p)
				if not save_data.flashlight: draw_sprite("flashlight",p+Vector2(0,-40))
			elif kind.begins_with("rack_") and item.id in save_data.weapons_taken: draw_sprite("rack_empty",p)
			elif kind=="mound": draw_sprite("dug" if item.id in save_data.dug else "mound",p)
			elif kind=="chest": draw_sprite("chest_open" if ((item.id=="final" and chest_open) or item.id in save_data.letters) else "chest",p,Color.WHITE,3.0 if item.id=="final" else 1.0)
			elif kind=="note": draw_sprite(kind,p+Vector2(0,sin(time*2+item.pos.x)*4))
			else: draw_sprite(kind,p)
			if kind.begins_with("rack_"):
				draw_string(body_font,p+Vector2(-25,-75),{"rpg":"РПГ","rifle":"АК-47","sword":"Меч"}[item.id],HORIZONTAL_ALIGNMENT_LEFT,-1,14,CREAM)
			if level==6 and kind=="stone" and not item.id.is_empty(): symbol(item.id,p+Vector2(0,-42),Color("ffe4ad") if item.id in puzzle else Color("635770"))
			if kind in ["arch","doorway"]:
				var open: bool = (level==1 and dark_letters_found()) or (level==2 and save_data.obstacles.size()==3) or (level==3 and "buried" in save_data.letters) or (level==0 and has_maze_letters()) or (level==4 and "courage" in save_data.letters) or (level==5 and "garden" in save_data.letters)
				draw_texture_rect(glow,Rect2(p-Vector2(65,110),Vector2(130,150)),false,Color(.9,1,.9,1 if open else .2))
				if not open and kind!="doorway": draw_line(p+Vector2(-18,-36),p+Vector2(18,-36),Color("ab839a"),4)
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
	for i in range(110):
		var world := Vector2(fposmod(i*137.7,grid[0].length()*TILE),fposmod(i*193.3,grid.size()*TILE))+Vector2(sin(time*.3+i)*26,cos(time*.4+i)*18)
		if not valid_ground(world): continue
		var p := screen(world)
		var alpha := .25+.4*(sin(time*1.7+i)+1)/2
		if level==5 and i%3==0:
			var flap := absf(sin(time*6+i))*5+1
			draw_rect(Rect2(p-Vector2(flap,2),Vector2(flap*2,4)),Color(.92,.66,.84,alpha))
		else:
			draw_texture_rect(glow,Rect2(p-Vector2(13,13),Vector2(28,28)),false,Color(1,.9,.65,alpha))
			draw_rect(Rect2(p,Vector2(2,2)),Color(1,.87,.62,alpha))
		if i%4==0:
			if not valid_ground(world+Vector2(sin(time*.7+i)*20,sin(time*.4+i)*30)): continue
			var petal := p+Vector2(sin(time*.7+i)*20, sin(time*.4+i)*30)
			draw_set_transform(petal,time*.3+i)
			draw_rect(Rect2(Vector2(-2,-1),Vector2(4,2)),Color(.95,.65,.78,.35))
			draw_set_transform(Vector2.ZERO)
	for part in particles:
		var c: Color = part.color
		c.a = minf(1,part.life)
		if part.heart: draw_heart(screen(part.pos),1.2,c)
		else: draw_rect(Rect2(screen(part.pos),Vector2(3,3)),c)
	draw_new_rooms()
	draw_extra_effects()
	# Soft framing, retained UI contrast.
	for i in range(8):
		var c := Color(.06,.07,.13,.025*(8-i))
		draw_rect(Rect2(Vector2(i*5,i*5),view-Vector2.ONE*i*10),c,false,5)

func scroll_at(node: Node, pos: Vector2) -> ScrollContainer:
	if not is_instance_valid(node): return null
	for child in node.get_children():
		var found := scroll_at(child,pos)
		if found: return found
	if node is ScrollContainer and node.is_visible_in_tree() and node.get_global_rect().has_point(pos): return node
	return null

func add_corridors() -> void:
	if level==0:
		grid.reverse()
		for obj in objects: obj.pos.y = grid.size()*TILE-obj.pos.y
		player.y = grid.size()*TILE-player.y
	var width := grid[0].length()
	for i in range(5):
		grid.push_front("#".repeat(width))
		grid.append("#".repeat(width))
	for obj in objects: obj.pos.y += 5*TILE
	player.y += 5*TILE
	var north := 15 if level==0 else 13
	var south := 1 if level==0 else 13
	for y in range(5):
		grid[y]=" ".repeat(width)
		grid[grid.size()-1-y]=" ".repeat(width)
	for y in range(0,7):
		for x in range(north-1,north+2): set_cell(x,y,".")
		if y<5:
			set_cell(north-2,y,"#");set_cell(north+2,y,"#")
	if level>0:
		for y in range(grid.size()-7,grid.size()):
			for x in range(south-1,south+2):set_cell(x,y,".")
			if y>=grid.size()-5:
				set_cell(south-2,y,"#");set_cell(south+2,y,"#")
	for obj in objects:
		if obj.id=="exit":
			obj.kind="doorway"
			obj.pos=Vector2(north+.5,6.5)*TILE
	if level>0: put_object("doorway",Vector2i(south,grid.size()-7),"back")

func travel(destination: int) -> void:
	if transition or destination<0 or destination>6: return
	transition = true
	paused = true
	joy_id = -1
	joy_vector = Vector2.ZERO
	attack_held = false
	moving = true
	var upwards := destination>level
	direction = 0 if upwards else 2
	var exit_x := 15 if level==0 else 13
	var entry_x := 1 if level==0 else 13
	var end := Vector2((exit_x+.5)*TILE,1.8*TILE) if upwards else Vector2((entry_x+.5)*TILE,(grid.size()-1.8)*TILE)
	if level==3: save_data.shovel=false
	if level==5: garden_can=false;save_data.garden_can=false
	var tween := create_tween()
	tween.tween_method(corridor_position,player,end,1.1)
	await tween.finished
	var veil := ColorRect.new()
	veil.color = Color(0.07,0.09,0.14,0)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(veil)
	var fade := create_tween()
	fade.tween_property(veil,"color:a",1.0,.12)
	await fade.finished
	persist()
	save_data.level = destination
	build_level(destination)
	var x := (1.5 if destination==0 else 13.5) if upwards else (15.5 if destination==0 else 13.5)
	var start := Vector2(x*TILE,(grid.size()-2.0)*TILE) if upwards else Vector2(x*TILE,2.0*TILE)
	var arrival := Vector2(x*TILE,(grid.size()-6.5)*TILE) if upwards else Vector2(x*TILE,6.5*TILE)
	player = start
	camera = camera_target()
	var reveal := create_tween()
	reveal.tween_property(veil,"color:a",0.0,.18)
	reveal.tween_callback(veil.queue_free)
	var entry_tween := create_tween()
	entry_tween.tween_method(corridor_position,start,arrival,1.2)
	await entry_tween.finished
	moving = false
	transition = false
	paused = false
	persist()
	notify("Сад" if destination==5 else TITLES[destination])

func corridor_position(pos: Vector2) -> void:
	player = pos
	camera = camera_target()

func begin_task(kind: String, target: Vector2, duration: float) -> void:
	task_kind = kind
	task_target = target
	task_time = duration
	moving = false
	direction = 0 if target.y<player.y else 2
	sfx("fill" if kind=="fill" else "step_grass" if kind.begins_with("dig:") else "paper" if kind=="fertilize" else "water")

func update_tasks(delta: float) -> void:
	if task_time<=0: return
	task_time -= delta
	if task_time>0: return
	if task_kind=="fill":
		water = 6
		save_data.water = water
		notify("Лейка полная: шесть порций воды.")
	elif task_kind.begins_with("water:"):
		var id := task_kind.trim_prefix("water:")
		water -= 1
		save_data.water = water
		plants[id].remaining = [12.0,18.0,24.0][clampi(int(plants[id].stage),0,2)]
		burst(task_target,12,Color("9fdce1"))
	elif task_kind.begins_with("dig:"):
		objects.append({"kind":"dug","id":"","solid":false,"pos":task_target})
		var id := task_kind.trim_prefix("dig:")
		if id not in save_data.dug: save_data.dug.append(id)
		burst(task_target,16,Color("aa8263"))
		var hidden: Vector2 = Vector2(save_data.dig_target[0],save_data.dig_target[1]) if save_data.dig_target.size()==2 else Vector2.ZERO
		if task_target.distance_to(hidden)<90 and "buried" not in save_data.letters:
			save_data.buried_exposed=true
			objects.append({"kind":"note","id":"buried","solid":false,"pos":hidden})
			notify("Из земли показалась записка. Подойди и открой её.")
		else: notify("Ближе к записке." if task_target.distance_to(hidden)<260 else "Здесь пусто.")
	elif task_kind=="fertilize": burst(task_target,10,Color("c8aa7d"))
	persist()

func update_plants(delta: float) -> void:
	for id in plants:
		var plant: Dictionary = plants[id]
		if float(plant.remaining)<=0: continue
		plant.remaining = maxf(0,float(plant.remaining)-delta)
		if plant.remaining==0:
			plant.stage = mini(3,int(plant.stage)+1)
			if plant.stage==3 and id not in watered:
				watered.append(id)
				save_data.watered = watered.duplicate()
				sfx("chime")
			persist()

func damage_enemy(index: int, damage: int, push: Vector2) -> void:
	if index<0 or index>=enemies.size(): return
	var enemy := enemies[index]
	if enemy.state=="spawn": return
	if weapon=="sword": sfx("sword_hit")
	enemy.hp -= damage
	enemy.state = "rest"
	enemy.timer = .3
	var target: Vector2 = enemy.pos+push
	if not blocked(target): enemy.pos=target
	burst(enemy.pos,8,Color("e9c2d5"))
	if enemy.hp<=0: enemies.remove_at(index)

func update_shots(delta: float) -> void:
	for i in range(shots.size()-1,-1,-1):
		var shot := shots[i]
		shot.age += delta
		if shot.kind=="rpg": shot.vel=shot.vel.normalized()*(95.0+525.0*(1.0-exp(-shot.age*3.2)))
		if shot.kind=="rpg" and particles.size()<420:
			particles.append({"pos":shot.pos-shot.vel.normalized()*12,"vel":-shot.vel.normalized()*22+Vector2(randf_range(-9,9),randf_range(-9,9)),"life":.55,"color":Color(.5,.47,.44,.35),"heart":false})
		shot.pos += shot.vel*delta
		shot.life -= delta
		var hit: bool = blocked(shot.pos) or shot.life<=0
		for enemy in enemies:
			if enemy.state!="spawn" and shot.pos.distance_to(enemy.pos)<27: hit=true
		if not hit: continue
		if shot.kind=="rpg":
			shake = 10
			sfx("explosion")
			burst(shot.pos,42,Color("ffd69c"))
			for j in range(enemies.size()-1,-1,-1):
				var diff: Vector2 = enemies[j].pos-shot.pos
				if diff.length()<35:
					damage_enemy(j,99,diff.normalized()*35)
					break
		else:
			for j in range(enemies.size()-1,-1,-1):
				if shot.pos.distance_to(enemies[j].pos)<35:
					damage_enemy(j,1,shot.vel.normalized()*9)
					break
		shots.remove_at(i)

func draw_extra_effects() -> void:
	for shot in shots:
		var p := screen(shot.pos)
		if shot.kind=="rpg":
			var backwards: Vector2 = -shot.vel.normalized()
			var side := backwards.orthogonal()
			var length := 36+12*sin(time*49)
			draw_colored_polygon(PackedVector2Array([p+backwards*8+side*7,p+backwards*8-side*7,p+backwards*length]),Color("f79e51"))
			draw_colored_polygon(PackedVector2Array([p+backwards*9+side*3,p+backwards*9-side*3,p+backwards*(length*.7)]),Color("fff2b7"))
			draw_set_transform(p,shot.vel.angle())
			draw_sprite("rocket_item",Vector2(0,20),Color.WHITE,.55)
			draw_set_transform(Vector2.ZERO)
			draw_texture_rect(glow,Rect2(p-Vector2(25,25),Vector2(50,50)),false,Color(1,.7,.35,.6))
		else: draw_line(p,p-shot.vel.normalized()*20,Color("ffe3a7"),3)
	if level==4 and not weapon.is_empty():
		var p := screen(player)+Vector2(14,-28)-aim*attack_flash*24
		var swing := sin((1-attack_flash/.22)*PI)*1.5 if weapon=="sword" and attack_flash>0 else 0.0
		var left := aim.x<0
		var rotation := (aim.angle()+PI/2) if weapon=="sword" else (atan2(-aim.y,-aim.x) if left else aim.angle())
		draw_set_transform(p,rotation+swing,Vector2(-1 if left and weapon!="sword" else 1,1))
		draw_sprite("weapon_"+weapon,Vector2(0,0 if weapon=="sword" else 20),Color.WHITE,.6)
		draw_set_transform(Vector2.ZERO)
		if attack_flash>0 and weapon=="sword":
			var angle := aim.angle()
			var progress := 1.0-attack_flash/.22
			for trail in range(4):
				var sweep := angle-1.2+progress*2.4-trail*.12
				draw_arc(screen(player)+Vector2(0,-20),95+trail*5,sweep-.65,sweep+.2,18,Color(1,.93,.79,(1-progress)*(.55-trail*.1)),4-trail*.5)
		if attack_flash>0 and weapon!="sword":
			var muzzle := p+aim*20
			draw_texture_rect(glow,Rect2(muzzle-Vector2(30,30),Vector2(60,60)),false,Color(1,.8,.5,attack_flash*4))
	if level==5 and garden_can and task_time<=0:
		var hand := screen(player)+Vector2(-10,-35+sin(time*(9 if moving else 3))*1.5)
		draw_set_transform(hand,sin(time*8)*.08 if moving else -.1)
		draw_sprite("can",Vector2(0,25),Color.WHITE,.65)
		draw_set_transform(Vector2.ZERO)
	if level==3 and save_data.shovel and task_time<=0: draw_sprite("shovel",screen(player)+Vector2(-14,12),Color.WHITE,.65)
	if level==5:
		for obj in objects:
			if obj.kind!="sprout" or obj.id in watered: continue
			var plant: Dictionary = plants.get(obj.id,{"stage":0,"remaining":0.0})
			var caption := str(int(plant.stage))+"/3"
			if float(plant.remaining)>0: caption += " · "+str(ceili(plant.remaining))+" с"
			elif obj.id not in fertilized: caption = "Удобрение"
			draw_string(body_font,screen(obj.pos)+Vector2(-25,-68),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,12,CREAM)
	if task_time>0:
		var origin := screen(player)+Vector2(12,-25)
		var target := screen(task_target)+Vector2(0,-10)
		if task_kind=="fill":
			draw_set_transform(origin,-.1)
			draw_sprite("can",Vector2(0,25),Color.WHITE,.65)
			draw_set_transform(Vector2.ZERO)
			origin = target+Vector2(0,-45)
			target = screen(player)+Vector2(12,-15)
		elif task_kind.begins_with("water:"):
			origin = origin.lerp(target+Vector2(-32,-48),clampf((2.2-task_time)*5.0,0,1))
			var angle := -.45+sin(time*5)*.06
			draw_set_transform(origin,angle)
			draw_sprite("can",Vector2(0,25),Color.WHITE,.65)
			draw_set_transform(Vector2.ZERO)
			origin += Vector2(18.2,5.5).rotated(angle)
		elif task_kind.begins_with("dig:"):
			draw_set_transform(origin,sin(time*9)*.6)
			draw_sprite("shovel",Vector2(0,40),Color.WHITE,.8)
			draw_set_transform(Vector2.ZERO)
		else: draw_sprite("fertilizer",origin+Vector2(0,sin(time*8)*3),Color.WHITE,.7)
		for i in range(22):
			var progress := fposmod(time*2.1+i*.047,1.0)
			var p := origin.lerp(target,progress)+Vector2(sin(i*3.1)*6,progress*progress*12)
			draw_circle(p,1.5,Color("b8e8ed") if task_kind!="fertilize" and not task_kind.begins_with("dig:") else Color("bb9270"))
		var bar := screen(player)+Vector2(-25,-93)
		draw_rect(Rect2(bar,Vector2(50,5)),INK)
		draw_rect(Rect2(bar,Vector2(50*clampf(1-task_time/(.25 if task_kind.begins_with("dig:") else 2.4),0,1),5)),PINK)

func setup_fog() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 1
	add_child(layer)
	fog = ColorRect.new()
	fog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = """shader_type canvas_item;
render_mode unshaded;
uniform vec2 light_pos = vec2(270.0,480.0);
uniform vec2 view_size = vec2(540.0,960.0);
uniform vec2 light_dir = vec2(0.0,-1.0);
uniform bool enabled = false;
uniform vec2 pedestal_pos = vec2(-1000.0);
void fragment(){
 vec2 offset = UV * view_size - light_pos;
 float distance = length(offset);
 float beam = smoothstep(0.72,0.94,dot(normalize(offset+vec2(0.001)),light_dir));
 float reach = 1.0-smoothstep(90.0,190.0,distance);
 float near_light = 0.0;
 float light = max(near_light,enabled ? beam*reach : 0.0);
 light = max(light,0.7*(1.0-smoothstep(45.0,115.0,length(UV*view_size-pedestal_pos))));
 COLOR = vec4(vec3(0.0),1.0-light);
}"""
	var material := ShaderMaterial.new()
	material.shader = shader
	fog.material = material
	layer.add_child(fog)

func update_fog() -> void:
	if not is_instance_valid(fog) or not fog.visible: return
	var material: ShaderMaterial = fog.material
	var facing: Vector2 = [Vector2.UP,Vector2.LEFT,Vector2.DOWN,Vector2.RIGHT][direction]
	if joy_vector.length()>.2: facing=joy_vector.normalized()
	material.set_shader_parameter("light_pos",screen(player)+Vector2(14,-33))
	material.set_shader_parameter("view_size",get_viewport_rect().size)
	material.set_shader_parameter("light_dir",facing)
	material.set_shader_parameter("enabled",save_data.flashlight)
	for obj in objects:
		if obj.id=="flashlight": material.set_shader_parameter("pedestal_pos",screen(obj.pos)-Vector2(0,40))

func dark_letter_count() -> int:
	var count := 0
	for id in ["shade_1","shade_2","shade_3"]:
		if id in save_data.letters: count+=1
	return count

func dark_letters_found() -> bool:
	return dark_letter_count()==3

func obstacle_rect(index: int) -> Rect2:
	var center := Vector2(13.5*TILE+sin(room_clock*(1.05+index*.13)+index*1.9)*90,(12.5+index*3)*TILE)
	return Rect2(center-Vector2(140,14),Vector2(280,28))

func update_new_rooms(delta: float) -> void:
	room_clock += delta
	if level==1:
		skull_clock -= delta
		if skull_clock<=0:
			skull_clock=randf_range(4.0,7.0)
			var pos := player+Vector2.from_angle(randf()*TAU)*randf_range(70,145)
			if not blocked(pos): skulls.append({"pos":pos,"life":.8})
		for i in range(skulls.size()-1,-1,-1):
			skulls[i].life -= delta
			if skulls[i].life<=0: skulls.remove_at(i)
	elif level==2:
		obstacle_cooldown=maxf(0,obstacle_cooldown-delta)
		for i in range(3):
			var obstacle := obstacle_rect(i)
			if obstacle.grow(10).has_point(player) and obstacle_cooldown<=0:
				player=Vector2(13.5,grid.size()-7.5)*TILE
				obstacle_cooldown=.65
				shake=5;sfx("hurt");haptic(25);notify("Попробуй ещё раз от входа.")
			if player.y<obstacle.position.y-24 and i not in save_data.obstacles:
				save_data.obstacles.append(i);persist()

func draw_new_rooms() -> void:
	if level==1:
		for skull in skulls:
			draw_sprite("skull",screen(skull.pos),Color(1,1,1,minf(1,skull.life)))
		if save_data.flashlight: draw_sprite("flashlight",screen(player)+Vector2(14,-10),Color.WHITE,.5)
	elif level==2:
		for i in range(3):
			var rect := obstacle_rect(i)
			var y := screen(rect.get_center()).y
			draw_line(screen(Vector2(9*TILE,rect.get_center().y)),screen(Vector2(18*TILE,rect.get_center().y)),Color("786878"),5)
			for x in range(7): draw_sprite("moving_bar",Vector2(screen(rect.position).x+x*40+20,y+16))
			var middle := screen(rect.get_center())
			draw_texture_rect(glow,Rect2(middle-Vector2(55,55),Vector2(110,110)),false,Color(1,.7,.4,.5))

func cycle_weapon() -> void:
	var inventory: Array = save_data.weapons_taken
	if inventory.is_empty(): return
	weapon = inventory[(inventory.find(weapon)+1)%inventory.size()]
	persist();sfx("ui")

func dig_here() -> void:
	if task_time>0: return
	var pos := (player+Vector2(0,-35)).snapped(Vector2(24,24))
	var cell := Vector2i(pos/TILE)
	if cell.x<2 or cell.x>=grid[0].length()-2 or cell.y<7 or cell.y>=grid.size()-7:
		notify("Копать можно на газоне, внутри комнаты.");return
	var key := str(int(pos.x))+":"+str(int(pos.y))
	if key in save_data.dug: notify("Здесь уже выкопано.");return
	begin_task("dig:"+key,pos,.25)

func draw_corridor_extensions() -> void:
	var north := 15 if level==0 else 13
	var south := 1 if level==0 else 13
	for end in [0,1]:
		if (level==0 and end==1) or (level==6 and end==0): continue
		var center: int = north if end==0 else south
		for j in range(1,12):
			var y := -j if end==0 else grid.size()-1+j
			for x in range(center-2,center+3):
				var pos := screen(Vector2(x,y)*TILE)
				if x==center-2 or x==center+2: draw_sprite("stone",screen(Vector2(x+.5,y+.5)*TILE))
				else: draw_texture_rect_region(ground,Rect2(pos,Vector2(48,48)),Rect2(Vector2(24,0),Vector2(24,24)))

func valid_ground(pos: Vector2) -> bool:
	var c := Vector2i(pos/TILE)
	return c.x>=0 and c.y>=0 and c.y<grid.size() and c.x<grid[0].length() and grid[c.y][c.x]=="."

func finish_room_layout(rng: RandomNumberGenerator) -> void:
	if level==0:
		for x in range(15,30):set_cell(x,6,".")
		for y in range(grid.size()-5,grid.size()):grid[y]=" ".repeat(grid[0].length())
		grid[grid.size()-6]="#".repeat(grid[0].length())
	if level==6:
		for y in range(5):grid[y]=" ".repeat(grid[0].length())
		grid[5]="#".repeat(grid[0].length())
	if level==2:
		for y in range(grid.size()):
			for x in range(grid[0].length()):
				if x<8 or x>18:set_cell(x,y," ")
		objects.assign(objects.filter(func(o):return o.kind=="doorway"))
		put_object("note",Vector2i(13,15),"crossing")
	objects.assign(objects.filter(func(o):return o.kind=="doorway" or valid_ground(o.pos)))
	if level==1:
		for spec in [["house",Vector2i(10,12)],["pond",Vector2i(19,15)],["bench",Vector2i(17,19)],["tree",Vector2i(8,17)],["tree",Vector2i(20,10)]]:
			put_object(spec[0],spec[1],"",true)
	# Do not place trees on hedge cells or shuffle previously opened doors.
	var candidates: Array[Vector2] = []
	for y in range(8,grid.size()-8):
		for x in range(2,grid[0].length()-2):
			var pos := Vector2(x+.5,y+.5)*TILE
			if valid_ground(pos) and not blocked(pos) and not objects.any(func(o): return o.kind in ["house","pond"] and Rect2(o.pos-Vector2(75,160),Vector2(150,185)).has_point(pos)):candidates.append(pos)
	for obj in objects:
		if obj.id=="crossing":
			obj.pos=Vector2(rng.randf_range(10.5,16.5),14.5)*TILE
			continue
		if (obj.kind!="note" and obj.id!="courage") or obj.id=="buried":continue
		if candidates.is_empty():break
		var index := rng.randi_range(0,candidates.size()-1)
		obj.pos=candidates[index];candidates.remove_at(index)
	if level==3 and save_data.buried_exposed and "buried" not in save_data.letters:
		objects.append({"kind":"note","id":"buried","pos":Vector2(save_data.dig_target[0],save_data.dig_target[1]),"solid":false})
	if level==4:
		for data in save_data.loose_weapons:
			var obj: Dictionary=data.duplicate();obj.pos=Vector2(data.pos[0],data.pos[1]);objects.append(obj)
