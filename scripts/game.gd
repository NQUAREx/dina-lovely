extends Node2D
## All coordinates are world pixels. Artwork is a shared nearest-filtered atlas.
const HEDGE_LIFT := 16.0
const HedgeField := preload("res://scripts/hedge_field.gd")
const TILE := 48.0
const GROUND_DEPTH := .58
const ACCESSORIES := ["black_dress","dark_scarf","wreath","veil","crown","rose_scarf","peach_dress","heart_tiara","pink_watch","white_scarf","white_dress","daisy_wreath","silver_crown","rose_wreath","lavender_dress","white_veil"]
const ACCESSORY_SLOTS := {"black_dress":"dress","dark_scarf":"scarf","wreath":"head","crown":"head","heart_tiara":"head","daisy_wreath":"head","silver_crown":"head","rose_wreath":"head","veil":"face","white_veil":"face","rose_scarf":"scarf","white_scarf":"scarf","peach_dress":"dress","white_dress":"dress","lavender_dress":"dress","pink_watch":"wrist"}
const ROOM_ACCESSORIES := [["wreath","pink_watch"],["veil","white_scarf"],["crown","white_dress"],["rose_scarf","daisy_wreath"],["peach_dress","silver_crown"],["rose_wreath","lavender_dress"],["heart_tiara","white_veil"]]
const OUTFIT_ORDER := ["black_dress","dark_scarf","peach_dress","white_dress","lavender_dress","rose_scarf","white_scarf","veil","white_veil","wreath","crown","heart_tiara","daisy_wreath","silver_crown","rose_wreath","pink_watch"]
const HALL_SEAM := 0.0
var drawing_neighbor := false
var reply_deposit_active := false
var reply_deposit_progress := -1.0
var reply_slot := Vector2.ZERO
var reply_hand_start := Vector2.ZERO
const ROOM_FIELDS := ["poison_zones","grid","objects","enemies","shots","particles","skulls","damage_numbers","path_meshes","path_texture","path_pads","hedge_trees","grass_details","path_targets","path_navigation","path_terminals","footprints","stride_distance","left_foot","hedge_field","berry_cells","paths","obstacle_specs","skull_clock","obstacle_cooldown","room_clock","grass_texture","health","invincible","wave","wave_timer","combat_done","bloom_times","puzzle","chest_open","magazine","reload_time","rpg_reload","attack_cd","attack_flash","player"]
var room_cache:Dictionary={}
var room_cache_seed := -1
var room_build_count := 0
var interaction_clock:=0.0
var arena_save:=preload("res://scripts/arena_checkpoint.gd").new(self)
var web_save_callback:JavaScriptObject
const stats:=preload("res://scripts/journey_stats.gd")
var torch:=preload("res://scripts/flashlight_state.gd").new(self)
var companion:=preload("res://scripts/cat_companion.gd").new(self)
var world_tools := preload("res://scripts/world_tools.gd").new(self)
const SPEED := 150.0
const SAVE_PATH := "user://garden_save_v1.json"
const TITLES := ["room_maze", "room_darkness", "room_obstacles", "room_digging", "room_combat", "room_garden", "room_final"]
const REQUIRED := ["dawn", "flower", "star"]
const CREAM := Color("f5e3cf")
const PINK := Color("e5a6bd")
const INK := Color("45394f")
var hedge_tree_textures:Dictionary={"hedge_tree":preload("res://assets/hedge_tree.png"),"hedge_tree_apples":preload("res://assets/hedge_tree_apples.png")}
var hedge_material: Texture2D = preload("res://assets/hedge_material.png")
var rpg_textures:Dictionary={"loaded":preload("res://assets/rpg_loaded.png"),"empty":preload("res://assets/rpg_empty.png")}
var tool_table_texture:Texture2D=preload("res://assets/tool_table.png")
var atlas: Texture2D = preload("res://assets/atlas.png")
var romance_ground: Texture2D = preload("res://assets/ground_romance.png")
var ground: Texture2D = preload("res://assets/ground.png")
var glow: Texture2D = preload("res://assets/glow.png")
var body_font: Font = preload("res://assets/body.ttf")
var label_atlas_pixels:Image
var label_sprite_bounds:Dictionary={}
var title_font: Font = preload("res://assets/title.ttf")
var outlines: Dictionary = {}
var sprites: Dictionary
var content: Dictionary
var save_data: Dictionary
var fog: ColorRect
var skulls: Array[Dictionary] = []
var damage_numbers: Array[Dictionary] = []
var room_remains: Dictionary = {}
var rocket_voice: AudioStreamPlayer
var path_meshes: Array = []
var path_texture: Texture2D
var path_pads: Array[Dictionary] = []
var hedge_trees: Dictionary = {}
var rpg_windup := -1.0
var rpg_aim := Vector2.RIGHT
var grass_details: Array[Dictionary] = []
var path_targets: Array[Dictionary] = []
var path_navigation: AStarGrid2D
var path_terminals: Array[bool] = []
var footprints: Array[Dictionary] = []
var stride_distance := 0.0
var left_foot := false
var hedge_field: RefCounted
var berry_cells: Dictionary = {}
var paths: Array = []
var obstacle_specs: Array[Dictionary] = []
var hazard_session_seed := randi()
var foliage_contact := false
var skull_clock := 2.0
var obstacle_cooldown := 0.0
var room_clock := 0.0
var held_item := ""
var magazine := 30
var reload_time := 0.0
var rpg_reload := 0.0
const RPG_RELOAD := 3.24
var grass_texture: Texture2D
var generating_paths := false
var resting := ""
var rest_anchor := Vector2.ZERO
var weapon := ""
var shots: Array[Dictionary] = []
var plants: Dictionary = {}
var fertilized: Array = []
var has_fertilizer := false
var task_time := 0.0
var task_duration := 1.0
var task_return_direction := 2
var task_return_facing := Vector2.DOWN
var task_return_aim := Vector2.RIGHT
var walk_facing := Vector2.DOWN
var food_hearts_left := 0
var food_heart_clock := .13
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
var health := 8.0
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
var stuck_seconds := 0.0
var joy_active := false
var joy_id := 0
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
var foliage_voice: AudioStreamPlayer
var foliage_gain:=0.0
var foliage_motion:=0.0
var hedge_contact := false
var gate_creak_delay := -1.0
var poison_zones:Array[Dictionary]=[]
var rune_stones:=preload("res://scripts/riddle_stones.gd").new(self)
var battle:=preload("res://scripts/battle_director.gd").new(self)
var rifle_kick := 0.0
var rifle_kick_dir := Vector2.ZERO
var shake := 0.0
var shake_offset := Vector2.ZERO
var ambience_clock := 3.0
var sound: AudioStreamPlayer
var sound_on := true
var fps_average := 60.0
var low_fx := false
var save_error := false

func tx(key: String) -> String:
	return str(content.get("ui",{}).get(key,{}).get("text",""))

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	label_atlas_pixels=atlas.get_image()
	sprites = JSON.parse_string(FileAccess.get_file_as_string("res://assets/atlas.json"))
	if not OS.has_feature("web"):content = JSON.parse_string(FileAccess.get_file_as_string("res://content/letters.json"))
	if OS.has_feature("web"):
		var live = JavaScriptBridge.eval("JSON.stringify(window.gardenContent || null)")
		if live is String:
			var parsed = JSON.parse_string(live)
			if parsed is Dictionary and parsed.get("letters") is Array: content = parsed
	load_save()
	ensure_riddle()
	held_item = save_data.get("held_item","")
	body_font.fallbacks = [preload("res://assets/symbols.ttf")]
	title_font.fallbacks = [preload("res://assets/symbols.ttf")]
	setup_audio()
	setup_fog()
	setup_ui()
	build_level(clampi(int(save_data.level),0,6) if save_data.started else 0)
	camera = camera_target()
	sync_room_theme()
	touch_mode = true
	show_menu()
	get_viewport().size_changed.connect(layout_ui)
	layout_ui()
	if OS.has_feature("web"):
		web_save_callback=JavaScriptBridge.create_callback(func(_args):
			if playing:persist())
		JavaScriptBridge.get_interface("window").gardenSaveNow=web_save_callback
		JavaScriptBridge.eval("window.gardenHideLoading && window.gardenHideLoading()")

func default_save() -> Dictionary:
	return {"arena_checkpoint":{},"flashlight_location":{},"stats":stats.DEFAULTS.duplicate(),"cat_tamed":false,"cat_fish":false,"cat_room":-1,"cat_position":[],"world_edits":{},"world_tool_locations":{},"bed_serial":0,"house_open":false,"skull_taken":false,"skull_inserted":false,"reply_sent":false,"gate_keys":[],"gate_key_drops":{},"loose_accessories":[],"accessory_drop_version":1,"accessories":["black_dress","dark_scarf"],"wearing":["black_dress","dark_scarf"],"open_gates":[],"riddle_stones":[],"riddle_inserted":[],"riddle_stone_order":[],"riddle_stone_positions":{},"riddle_stone_exposed":false,"riddle_order":[],"riddle_clues":[],"riddle_letters":[],"riddle_input":[],"held_item":"","tool_positions":{},"cleaned":[],"rake":false,"eaten":[],"seed":randi(),"loose_weapons":[],"buried_exposed":false,"plants":{},"fertilized":[],"has_fertilizer":false,"weapon":"","weapons_taken":[],"dig_target":[],"flashlight":false,"shovel":false,"dug":[],"obstacles":[],"version":2,"level":0,"completed_levels":[],"letters":[],"secrets":[],"finished":false,"garden_can":false,"water":0,"watered":[],"sound":true,"started":false}

func load_save() -> void:
	save_data = default_save()
	var legacy_accessories:=false
	if FileAccess.file_exists(SAVE_PATH):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
		if parsed is Dictionary and int(parsed.get("version", 0)) in [1,2]:
			for key in save_data:
				if parsed.has(key) and typeof(parsed[key]) == typeof(save_data[key]):
					save_data[key] = parsed[key]
			legacy_accessories=not parsed.has("accessory_drop_version")
			# JSON numbers decode as floats.
			var old_level := int(parsed.get("level",0))
			if int(parsed.get("version",1))==1:
				old_level = old_level+3 if old_level>0 else 0
				save_data.completed_levels = save_data.completed_levels.map(func(v): return int(v)+3 if int(v)>0 else 0)
			save_data.version = 2
			save_data.level = clampi(old_level,0,6)
			save_data.seed = int(parsed.get("seed",save_data.seed))
			save_data.bed_serial=int(parsed.get("bed_serial",0))
			save_data.cat_room=int(parsed.get("cat_room",-1))
			if not parsed.has("stats"):
				for eaten in save_data.eaten:
					stats.add(self,"berries" if str(eaten).begins_with("berry_") else "apples")
			save_data.water = clampi(int(parsed.get("water", 0)), 0, 6)
			if not parsed.has("weapons_taken") and not str(save_data.weapon).is_empty(): save_data.weapons_taken.append(save_data.weapon)
	stats.repair(self)
	arena_save.sanitize_dead_save()
	repair_accessory_save(legacy_accessories)
	sound_on = save_data.sound

func persist() -> void:
	companion.save()
	arena_save.capture()
	save_data.erase("music")
	save_data.plants = plants
	save_data.fertilized = fertilized
	save_data.has_fertilizer = has_fertilizer
	save_data.weapon = weapon
	save_data.sound = sound_on
	save_data.held_item = held_item
	if level==6:save_data.riddle_input=puzzle.duplicate()
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.flush()
	else:
		save_error = true
		if is_instance_valid(toast): notify(tx("storage_unavailable"))

func setup_audio() -> void:
	rocket_voice=AudioStreamPlayer.new();rocket_voice.volume_db=-10
	var flight := preload("res://assets/rpg_flight.wav").duplicate() as AudioStreamWAV
	flight.loop_mode=AudioStreamWAV.LOOP_FORWARD;flight.loop_begin=0;flight.loop_end=int(flight.get_length()*flight.mix_rate)
	rocket_voice.stream=flight
	if OS.has_feature("web"):rocket_voice.playback_type=AudioServer.PLAYBACK_TYPE_SAMPLE
	add_child(rocket_voice)
	foliage_voice = AudioStreamPlayer.new()
	var leaves:=preload("res://assets/rustle.wav").duplicate() as AudioStreamWAV
	leaves.loop_mode=AudioStreamWAV.LOOP_FORWARD;leaves.loop_begin=0;leaves.loop_end=int(leaves.get_length()*leaves.mix_rate)
	foliage_voice.stream=leaves
	foliage_voice.volume_db = -80
	if OS.has_feature("web"):foliage_voice.playback_type=AudioServer.PLAYBACK_TYPE_SAMPLE
	add_child(foliage_voice)
	for i in range(10):
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -12
		if OS.has_feature("web"):voice.playback_type=AudioServer.PLAYBACK_TYPE_SAMPLE
		add_child(voice)
		audio_pool.append(voice)

func sfx(name: String = "chime") -> void:
	if not sound_on or DisplayServer.get_name()=="headless": return
	var voice := audio_pool[audio_cursor % audio_pool.size()]
	audio_cursor += 1
	var sample_name := name
	if name in ["step_grass","step_stone","attack"]: sample_name += ["","_2","_3"][randi()%3]
	voice.stream = preload("res://scripts/audio_bank.gd").STREAMS.get(sample_name)
	voice.volume_db = {"birds":-29,"crickets":-28,"gate_open":-11,"gate_unlock":-13,"rustle":-12,"step_grass":-21,"step_stone":-21,"ambient":-32,"water":-14,"fill":-14,"ui":-23,"explosion":-11,"rpg_launch":-10,"rpg_explosion":-8,"rpg_load":-22,"rifle":-13,"pistol":-10}.get(name,-15)
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
	l.add_theme_font_size_override("font_size", maxi(14, roundi(size * 1.1)))
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func button(text: String, callback: Callable, width: float = 250) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(minf(width, 420), 60)
	b.add_theme_font_override("font", title_font)
	b.add_theme_font_size_override("font_size", 30)
	b.clip_text = true
	b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	b.add_theme_color_override("font_color", CREAM)
	b.add_theme_stylebox_override("normal", panel_style(Color("51445f")))
	b.add_theme_stylebox_override("hover", panel_style(Color("70536e"), PINK))
	b.add_theme_stylebox_override("pressed", panel_style(Color("97677d"), CREAM))
	b.resized.connect(fit_button_text.bind(b))
	b.pressed.connect(callback)
	return b

func fit_button_text(control: Button) -> void:
	var available_width := maxf(1, control.size.x - control.get_theme_stylebox("normal").get_minimum_size().x - 4)
	var font_size := 30
	while font_size > 16 and control.get_theme_font("font").get_string_size(control.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > available_width:
		font_size -= 1
	control.add_theme_font_size_override("font_size", font_size)

func setup_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 2
	add_child(ui)
	root = Control.new()
	root.theme = Theme.new()
	root.theme.default_font = body_font
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(root)
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)
	var top := Panel.new()
	top.position = Vector2(16, 36)
	top.size = Vector2(508, 100)
	top.add_theme_stylebox_override("panel", panel_style(Color(0.12,0.14,0.22,0.92)))
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(top)
	objective = label("", 22)
	objective.add_theme_font_override("font", title_font)
	objective.autowrap_mode = TextServer.AUTOWRAP_OFF
	objective.clip_text = true
	objective.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	objective.position = Vector2(32, 45)
	objective.size = Vector2(374, 42)
	hud.add_child(objective)
	status = label("", 18, Color("c1bdce"))
	status.add_theme_font_override("font", title_font)
	status.autowrap_mode = TextServer.AUTOWRAP_OFF
	status.clip_text = true
	status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	status.position = Vector2(32, 92)
	status.size = Vector2(374, 30)
	hud.add_child(status)
	var menu_button := button("", show_menu, 68)
	menu_button.tooltip_text=tx("menu_action")
	menu_button.icon=preload("res://assets/pause_icon.png")
	menu_button.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER
	menu_button.expand_icon=true
	menu_button.add_theme_constant_override("icon_max_width",40)
	menu_button.custom_minimum_size=Vector2(68,68)
	menu_button.size=Vector2(68,68)
	menu_button.name = "MenuButton"
	hud.add_child(menu_button)
	hint = label("", 15)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.add_child(hint)
	action_button = button(tx("read_letter"), interact, 155)
	hud.add_child(action_button)
	attack_button = button(tx("attack_action"), func(): attack(), 120)
	attack_button.button_down.connect(func(): attack_held = true)
	attack_button.button_up.connect(func(): attack_held = false)
	hud.add_child(attack_button)
	switch_button = button(tx("switch_weapon"),cycle_weapon,150)
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
	var tip := label(tx("portrait_overlay"), 24, CREAM, true)
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
	hud.get_node("MenuButton").position = Vector2(440, 52)
	action_button.position = Vector2(337, 824)
	action_button.custom_minimum_size = Vector2(180,76)
	attack_button.position = Vector2(365, 720)
	attack_button.custom_minimum_size = Vector2(150,82)
	hint.position = Vector2(36, 914)
	hint.size = Vector2(468, 32)
	toast.position = Vector2(32, 146)
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
	joy_active = false
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
	box.add_child(label(tx("menu_tagline"), 12, PINK))
	box.add_child(label(content.game_title, 35, CREAM, true))
	box.add_child(label(tx("menu_goal"), 15, Color("c1bdce")))
	if playing: box.add_child(button(tx("return_to_garden") if health>0 else tx("retry_room"), func():
		if health<=0: arena_save.restart()
		clear_modal()))
	elif save_data.started: box.add_child(button(tx("continue_game"), resume_game))
	box.add_child(button(tx("new_game"), confirm_new if save_data.started else new_game))
	box.add_child(button(tx("collected_letters_prefix") + str(save_data.letters.size()) + "/" + str(content.letters.size()), show_journal))
	box.add_child(button(tx("sound_settings"), show_settings))
	if save_data.finished: box.add_child(button(tx("replay_card"), show_card))
	box.add_child(label(tx("sound_hint"), 12, Color("b5adc4")))
	hud.visible = playing

func confirm_new() -> void:
	var box := modal_box(540, 260)
	box.add_child(label(tx("new_game_title"), 28, CREAM, true))
	box.add_child(label(tx("new_game_warning"), 17))
	box.add_child(button(tx("start_new_story"), new_game))
	box.add_child(button(tx("back"), show_menu))

func new_game() -> void:
	room_remains.clear();food_hearts_left=0;room_cache.clear();room_cache_seed=-1
	save_data = default_save()
	held_item="";sync_hands();save_data.started=true;ensure_riddle()
	playing=false;paused=true
	if OS.has_feature("web"):await prepare_rooms_web(0)
	else:prepare_room_cache(0)
	playing=true;sync_room_theme();persist();show_intro()

func resume_game() -> void:
	if playing and level==int(save_data.level):clear_modal();hud.show();return
	playing=false;paused=true
	var target:=int(save_data.level)
	if OS.has_feature("web") and (room_cache_seed!=int(save_data.seed) or room_cache.size()!=7):await prepare_rooms_web(target)
	else:prepare_room_cache(target)
	arena_save.restore_hands();companion.restore();playing=true;sync_room_theme();clear_modal();hud.show()

func sync_room_theme() -> void:
	if OS.has_feature("web"):JavaScriptBridge.eval("window.gardenSetRoom?.("+str(level)+")")

func cache_current_room() -> void:
	var state:Dictionary={"saved_at":time}
	for field in ROOM_FIELDS:
		var value:Variant=get(field)
		state[field]=value.duplicate(true) if value is Array or value is Dictionary else value
	room_cache[level]=state

func activate_cached_room(index: int) -> void:
	var state:Dictionary=room_cache[index]
	level=index
	for field in ROOM_FIELDS:
		var value:Variant=state[field]
		set(field,value.duplicate(true) if value is Array or value is Dictionary else value)
	var elapsed:float=maxf(0,time-float(state.saved_at))
	for list in [particles,footprints,damage_numbers,skulls]:
		for item in list:item.life-=elapsed
		for n in range(list.size()-1,-1,-1):
			if list[n].life<=0:list.remove_at(n)
	plants=save_data.plants.duplicate(true);fertilized=save_data.fertilized.duplicate();watered=save_data.watered.duplicate();water=int(save_data.water)
	chest_open=save_data.finished
	weapon=held_item if held_item in ["sword","rifle","rpg"] else "";sync_hands()
	objects.assign(objects.filter(func(obj):return not obj.get("dropped_accessory",false)))
	restore_accessory_drops();restore_gate_key();normalize_dig_site();world_tools.install();restore_weapon_drops();torch.install();companion.install();rune_stones.install()
	for door in objects:
		if door.kind=="doorway":door.gate_amount=1.0 if door_is_open(str(door.id)) else 0.0
	task_time=0;rpg_windup=-1;resting="";nearest=-1
	if is_instance_valid(fog):fog.visible=level==1
	camera=camera_target();update_hud();update_fog()

func prepare_room_cache(target: int) -> void:
	if room_cache_seed!=int(save_data.seed) or room_cache.size()!=7:
		room_cache.clear()
		for room in range(7):build_level(room);cache_current_room()
		room_cache_seed=int(save_data.seed)
	activate_cached_room(target)

func prepare_rooms_web(target: int) -> void:
	# Prepare static room data once; never generate rooms while walking through a hall.
	JavaScriptBridge.eval("window.gardenShowLoading?.();window.gardenRoomProgress?.(0)")
	await get_tree().process_frame
	room_cache.clear()
	for room in range(7):
		build_level(room);cache_current_room()
		JavaScriptBridge.eval("window.gardenRoomProgress?.("+str(float(room+1)/7)+")")
		await get_tree().process_frame
	room_cache_seed=int(save_data.seed);activate_cached_room(target)
	JavaScriptBridge.eval("window.gardenHideLoading?.()")

func show_intro() -> void:
	var box:=modal_box(650,410)
	box.add_child(label(str(content.game_title),30,CREAM,true))
	box.add_child(label(tx("start_intro"),18))
	box.add_child(label(tx("gate_key_intro"),14,Color("c1bdce")))
	box.add_child(label(tx("controls_help"),18,Color("c1bdce")))
	box.add_child(button(tx("begin_room"),func():clear_modal();hud.show()))

func show_settings() -> void:
	var box := modal_box(550, 350)
	box.add_child(label(tx("sound_settings_title"), 28, CREAM, true))
	box.add_child(button(tx("effects_prefix") + (tx("sound_on") if sound_on else tx("sound_off")), func(): sound_on = not sound_on; persist(); show_settings()))
	box.add_child(label(tx("storage_help"), 14, Color("c1bdce")))
	box.add_child(button(tx("back"), show_menu))

func show_journal() -> void:
	var box := modal_box(670, 460)
	box.add_child(label(tx("journal_title"), 29, CREAM, true))
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
	if save_data.letters.is_empty(): list.add_child(label(tx("journal_empty"), 18))
	box.add_child(button(tx("back"), show_menu))

func show_letter(id: String, journal: bool = false, source_stack: Control = null) -> void:
	var letter: Dictionary = {}
	for item in content.letters:
		if item.id == id: letter = item
	if letter.is_empty(): return
	if is_instance_valid(source_stack):
		if id not in save_data.letters: return
		source_stack.active = false
		source_stack.set_process(false)
	else:
		clear_modal()
	paused=true;hud.hide()
	var view := Control.new()
	view.set_script(preload("res://scripts/letter_view.gd"))
	view.game=self;view.letter=letter_with_clue(letter);view.journal=journal
	view.stack_view = source_stack
	if is_instance_valid(source_stack):
		var index: int = source_stack.letters.find(letter)
		view.stack_rect = source_stack.card_rect(index)
		view.stack_rotation = source_stack.card_rotation(index)
	view.start=screen(player)
	for obj in objects:
		if obj.id==id:view.start=screen(obj.pos)
	root.add_child(view);modal=view

func show_letter_stack(obj: Dictionary) -> void:
	clear_modal()
	paused = true
	hud.hide()
	var view := Control.new()
	view.set_script(preload("res://scripts/letter_stack.gd"))
	view.game = self
	view.box_object = obj
	view.start = screen(obj.pos)
	root.add_child(view)
	modal = view
	sfx("paper")

func collect(id: String) -> void:
	if id not in save_data.letters:
		save_data.letters.append(id)
		if id.begins_with("secret"):
			save_data.secrets.append(id)
		burst(player, 22, PINK)
		spawn_gate_key(id)
		persist()
		sfx()
	sfx("paper")
	show_letter(id)

func ensure_riddle() -> void:
	rune_stones.ensure()
	var symbols: Array = content.get("puzzle",{}).get("symbols",[])
	if symbols.size()!=7:return
	if save_data.riddle_order.size()==7 and save_data.riddle_clues.size()==7 and save_data.riddle_letters.size()==7:return
	var rng := RandomNumberGenerator.new();rng.seed=int(save_data.seed)^0x4c4f5645
	var order: Array = symbols.duplicate()
	var clues: Array = range(7)
	for array in [order,clues]:
		for i in range(6,0,-1):
			var j := rng.randi_range(0,i);var temp=array[i];array[i]=array[j];array[j]=temp
	save_data.riddle_order=order;save_data.riddle_clues=clues;save_data.riddle_letters=[];save_data.riddle_input=[]
	for candidates in content.puzzle.room_letters:save_data.riddle_letters.append(candidates[rng.randi_range(0,candidates.size()-1)])

func riddle_clue(room: int) -> String:
	var index := int(save_data.riddle_clues[room])
	var order: Array = save_data.riddle_order
	if index==0:return tx("riddle_start_clue").format({"symbol":tx("symbol_"+str(order[0]))})
	return tx("riddle_link_clue").format({"before":tx("symbol_"+str(order[index-1])),"after":tx("symbol_"+str(order[index]))})

func letter_with_clue(letter: Dictionary) -> Dictionary:
	var result := letter.duplicate(true)
	var room: int = save_data.riddle_letters.find(str(letter.id))
	if room>=0:result.text=str(letter.text)+"\n\n"+tx("riddle_note_heading")+"\n"+riddle_clue(room)
	return result

func press_riddle_symbol(id: String, pos: Vector2) -> void:
	if id=="puzzle_reset":
		puzzle.clear();persist();sfx("ui");notify(tx("puzzle_reset_notice"));return
	if id not in content.puzzle.symbols:return
	if not rune_stones.ready():notify(tx("rune_need_all"));return
	if puzzle.size()>=7:notify(tx("puzzle_full_input"));return
	puzzle.append(id);persist();sfx("ui");burst(pos,8,Color("ffe1a6"))
	notify(tx("puzzle_full_input") if puzzle.size()==7 else tx("puzzle_symbol_added").format({"symbol":tx("symbol_"+id)}))

func check_riddle_chest() -> void:
	if chest_open:show_card();return
	if not rune_stones.ready():notify(tx("rune_need_all"));return
	for id in save_data.riddle_letters:
		if id not in save_data.letters:notify(tx("puzzle_notes_missing"));return
	if puzzle.size()!=7:notify(tx("puzzle_short_input"));return
	if puzzle==save_data.riddle_order:finish_game()
	else:notify(tx("puzzle_wrong_input"))

func show_card() -> void:
	var box := modal_box(900, 490, true)
	box.add_child(label(tx("card_heading"), 12, Color("a26c7e")))
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
	box.add_child(button(tx("return_to_menu"), show_menu))
	sfx()

func put_object(kind: String, cell: Vector2i, id: String = "", solid: bool = false) -> void:
	objects.append({"kind":kind,"pos":Vector2(cell)*TILE+Vector2.ONE*TILE/2,"id":id,"solid":solid})

func set_cell(x: int, y: int, value: String) -> void:
	grid[y] = grid[y].substr(0,x) + value + grid[y].substr(x+1)

func build_level(index: int) -> void:
	poison_zones=[]
	room_build_count+=1
	level = index
	hedge_trees.clear();hedge_field=null;path_texture=null;path_pads.clear();rpg_windup=-1
	if not save_data.has("open_gates"):save_data.open_gates=[]
	berry_cells.clear();paths.clear();grass_details.clear();path_targets.clear();path_navigation=null;path_terminals.clear();path_meshes.clear();footprints.clear();stride_distance=0.0;obstacle_specs.clear();damage_numbers.clear()
	skull_clock=2.0
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
	if level==6:puzzle.assign(save_data.riddle_input)
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
		# A sheltered central starting alcove, connected to the first maze row.
		for y in range(1,4):
			for x in range(14,17): set_cell(x,y,".")
		player = Vector2(15.5,1.5)*TILE
	else:
		for y in range(19):
			grid.append("#".repeat(27) if y==0 or y==18 else "#"+".".repeat(25)+"#")
		player = Vector2(13.5,15.5)*TILE
		if level==1:
			put_object("stand_flashlight",Vector2i(13,11),"flashlight")
			put_object("note",Vector2i(5,5),"shade_1")
			put_object("note",Vector2i(21,8),"shade_2")
			put_object("note",Vector2i(7,13),"shade_3")
			for x in [8,18]:
				for y in [5,11]: put_object("stone",Vector2i(x,y),"",true)
			put_object("arch",Vector2i(13,2),"exit")
		elif level==2:
			grid.clear()
			for y in range(29):grid.append("#".repeat(27) if y in [0,28] else "#"+".".repeat(25)+"#")
			player=Vector2(13.5,25.5)*TILE
			var hazard_rng := RandomNumberGenerator.new()
			hazard_rng.seed=hazard_session_seed+int(save_data.seed)
			for n in range(5):
				obstacle_specs.append({"width":float(hazard_rng.randi_range(3,7)*40),"speed":hazard_rng.randf_range(.65,1.8),"phase":hazard_rng.randf_range(0,TAU),"warp":hazard_rng.randf_range(.0,.3)})
			for y in range(1,28):
				for x in range(1,26):
					if x<9 or x>17: set_cell(x,y,"#" if x in [8,18] else " ")
			put_object("arch",Vector2i(13,2),"exit")
		elif level==3:
			grid.clear()
			for y in range(13): grid.append("#".repeat(27) if y in [0,12] else "#"+".".repeat(25)+"#")
			player=Vector2(13.5,10.5)*TILE
			put_object("shovel",Vector2i(8,8),"shovel")
			if save_data.dig_target.size()!=2 or float(save_data.dig_target[1])>=16*TILE or float(save_data.dig_target[1])<7*TILE:
				save_data.dig_target=[randf_range(4,22)*TILE,randf_range(7,15)*TILE]
			for key in save_data.dug:
				var parts: PackedStringArray = str(key).split(":")
				if parts.size()==2: objects.append({"kind":"dug","id":"","solid":false,"pos":Vector2(float(parts[0]),float(parts[1])-5*TILE)})
			put_object("arch",Vector2i(13,2),"exit")
		elif level == 4:
			for p in [Vector2i(5,5),Vector2i(21,5),Vector2i(5,13),Vector2i(21,13)]:
				put_object("stone",p,"",true)
				put_object("lamp",p+Vector2i(0,-1))
			put_object("chest",Vector2i(13,7),"courage")
			for i in range(3): put_object("rack_"+["rpg","rifle","sword"][i],Vector2i(9+i*4,14),["rpg","rifle","sword"][i])
			put_object("arch",Vector2i(13,2),"exit")
		elif level == 5:
			put_object("rake",Vector2i(7,14),"rake")
			put_object("can",Vector2i(5,14),"can")
			put_object("fertilizer",Vector2i(5,12),"fertilizer")
			put_object("well",Vector2i(13,8),"well",true)
			put_object("bench",Vector2i(4,9),"seat",true)
			put_object("swing",Vector2i(22,13),"swing",true)
			var cells := [Vector2i(6,5),Vector2i(20,5),Vector2i(7,10),Vector2i(19,10),Vector2i(9,14),Vector2i(17,14)]
			for i in range(cells.size()): put_object("sprout",cells[i],str(i))
			put_object("note",Vector2i(13,5),"garden")
			put_object("arch",Vector2i(13,2),"exit")
			for p in [Vector2i(3,4),Vector2i(23,4),Vector2i(3,12),Vector2i(23,12)]: put_object("tree",p,"",true)
		else:
			put_object("chest",Vector2i(13,6),"final")
			var buttons := [Vector2i(8,10),Vector2i(11,10),Vector2i(14,10),Vector2i(17,10),Vector2i(9,13),Vector2i(13,13),Vector2i(17,13)]
			for n in range(7):put_object("stone",buttons[n],str(content.puzzle.symbols[n]),true)
			put_object("stone",Vector2i(21,13),"puzzle_reset",true)
			put_object("note",Vector2i(13,16),"final_hint")
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
	companion.place(rng)
	for obj in objects:
		var key := str(level)+":"+str(obj.id)
		if save_data.tool_positions.has(key):
			obj.pos = Vector2(save_data.tool_positions[key][0],save_data.tool_positions[key][1]);obj.ground_tool=true
	if level==5:
		var beds := objects.filter(func(o):return o.kind=="sprout")
		var choices: Array[Vector2] = []
		for y in range(8,grid.size()-9,3):
			for x in range(4,grid[0].length()-4,4):
				var candidate := Vector2(x+.5,y+.5)*TILE
				if garden_bed_clear(candidate,false):choices.append(candidate)
		if choices.size()<6:
			for y in range(8,grid.size()-7):
				for x in range(3,grid[0].length()-3):
					var point:=Vector2(x+.5,y+.5)*TILE
					if garden_bed_clear(point,false) and point not in choices:choices.append(point)
		for bed in beds:
			if choices.is_empty():break
			var n := rng.randi_range(0,choices.size()-1);bed.pos=choices[n];choices=choices.filter(func(point):return point.distance_to(bed.pos)>=112)
		sync_hands()
	if level==3: objects.assign(objects.filter(func(o): return o.kind in ["shovel","dug","doorway","note"]))
	for id in watered:
		if id not in save_data.cleaned:save_data.cleaned.append(id)
		if id not in fertilized:fertilized.append(id)
		if not plants.has(id): plants[id] = {"stage":2,"remaining":0.0}
	normalize_dig_site()
	place_accessory(rng)
	prepare_foliage_and_paths(rng)
	prepare_room_details(rng)
	if level not in [1,2,4]:
		var foliage_grid:Array[String]=grid.duplicate()
		for row in range(grid.size()):
			if corridor_row(row):foliage_grid[row]=foliage_grid[row].replace("#"," ")
		hedge_field=HedgeField.new();hedge_field.build(foliage_grid,int(save_data.seed)+level*16427,hedge_trees,berry_cells,hedge_material.get_image())
	if level==6:
		objects.assign(objects.filter(func(obj):return obj.kind not in ["crate","column","column_wreath","lamp","candle","candle_heart","heart_stand"] or not Rect2(Vector2(20.8*48,8.8*48),Vector2(3.4*48,9.7*48)).has_point(obj.pos)))
	prepare_grass_details()
	restore_accessory_drops()
	restore_gate_key()
	world_tools.install();restore_weapon_drops();torch.install();companion.install();rune_stones.install()
	if index==4:arena_save.restore_room();rune_stones.install()
	camera = camera_target()
	nearest = -1
	update_hud()

func corridor_row(row: int) -> bool:
	return (level<6 and row<5) or (level>0 and row>=grid.size()-5)

func corridor_floor_point(point: Vector2) -> bool:
	var north:float=(15.5 if level==0 else 13.5)*TILE
	var south:float=13.5*TILE
	return (level<6 and point.y<0 and point.y>=-24*TILE and absf(point.x-north)<1.5*TILE) or (level>0 and point.y>=grid.size()*TILE and point.y<(grid.size()+24)*TILE and absf(point.x-south)<1.5*TILE)

func inside_main_room() -> bool:
	return player.y>=7*TILE and player.y<=(grid.size()-7)*TILE

func camera_target() -> Vector2:
	var half := get_viewport_rect().size/2
	var y:=player.y if not inside_main_room() else clampf(player.y,half.y-220,grid.size()*TILE-half.y+64)
	return Vector2(clampf(player.x,half.x-48,grid[0].length()*TILE-half.x+48),y)

func blocked(pos: Vector2) -> bool:
	if level==6 and save_data.finished and Rect2(Vector2(21.75*48,11.65*48),Vector2(1.5*48,6.2*48)).grow(10).has_point(pos):return true
	if pos.y<0 or pos.y>=grid.size()*TILE:
		for offset in [Vector2(-10,-7),Vector2(10,-7),Vector2(-10,7),Vector2(10,7)]:
			var point:Vector2=pos+offset
			if point.y>=0 and point.y<grid.size()*TILE:continue
			if not corridor_floor_point(point):return true
		return false
	if level<6 and not door_is_open("exit") and pos.y<7*TILE and absf(pos.x-(15.5 if level==0 else 13.5)*TILE)<75:return true
	for offset in [Vector2(-10,-7),Vector2(10,-7),Vector2(-10,7),Vector2(10,7)]:
		var c := Vector2i((pos+offset)/TILE)
		if c.y<0 or c.y>=grid.size():
			if corridor_floor_point(pos+offset):continue
			return true
		if c.x<0 or c.x>=grid[0].length() or grid[c.y][c.x]==" ": return true
		if grid[c.y][c.x]=="#" and (hedge_field==null or corridor_row(c.y)):return true
	if hedge_field!=null and hedge_field.blocks(pos):return true
	for obj in objects:
		if obj.kind=="doorway" and obj.id=="exit" and door_is_open("exit"):
			var p: Vector2=pos-obj.pos
			if float(obj.get("gate_amount",0))<.25 and absf(p.x)<82 and absf(p.y)<12:return true
			if Rect2(Vector2(-82,-12),Vector2(92,24)).has_point(p):return true
		if obj.solid:
			if obj.kind=="pond":
				# Full drawn pond footprint; its anchor is the bottom, not its centre.
				if ((pos-obj.pos-Vector2(0,-44))/Vector2(73,65)).length()<1:return true
			elif obj.kind=="cat_hut":
				if Rect2(obj.pos+Vector2(-34,-48),Vector2(68,76)).has_point(pos):return true
			elif pos.distance_to(obj.pos)<(58 if obj.kind=="house" else 24):return true
	return false

func move_player(delta: float, input: Vector2) -> void:
	moving = input.length()>0.1
	if not moving: return
	walk_facing=input.normalized()
	var before := player
	var motion := input.limit_length()*SPEED*delta
	var next := player+Vector2(motion.x,0)
	if not blocked(next): player = next
	next = player+Vector2(0,motion.y)
	if not blocked(next): player = next
	var travelled := before.distance_to(player)
	stats.add(self,"distance",travelled)
	companion.record()
	stride_distance += travelled
	if stride_distance>=24.0:
		stride_distance=fmod(stride_distance,24.0)
		leave_footprint(input.normalized())
	step_clock -= delta
	if step_clock<=0:
		var cell := Vector2i(player/TILE)
		sfx("step_stone" if stone_surface(player) else "step_grass")
		step_clock = .31
	if not weapon.is_empty() and (level==4 or save_data.finished) and attack_flash<=0:aim=input.normalized()
	if not weapon.is_empty() and (level==4 or save_data.finished) and attack_flash>0:return
	if abs(input.x)>abs(input.y): direction = 1 if input.x<0 else 3
	else: direction = 0 if input.y<0 else 2

func touching_hedge(pos: Vector2) -> bool:
	if level!=0: return false
	for offset in [Vector2(-20,-16),Vector2(20,-16),Vector2(-20,16),Vector2(20,16)]:
		var c := Vector2i((pos+offset)/TILE)
		if c.y>=0 and c.y<grid.size() and c.x>=0 and c.x<grid[0].length() and grid[c.y][c.x]=="#": return true
	return false

func _physics_process(delta: float) -> void:
	if playing and not paused and not transition:update_vegetation(minf(delta,.04))
	# Simulation must not depend on audio, particles or HUD updating successfully.
	if reload_time>0 and playing and not paused:
		reload_time=maxf(0,reload_time-delta)
		if reload_time==0: magazine=30;sfx("reload")
	if not resting.is_empty():
		if joy_vector.length()>.2:stand_up()
		else:return
	if playing and not paused and not transition and task_time<=0:
		var before := player
		move_player(delta,joy_vector if joy_active else Vector2.ZERO)
		hedge_contact=pushing_hedge(player,joy_vector if joy_active else Vector2.ZERO)
		if joy_vector.length()>.2 and player.distance_to(before)<.01:
			stuck_seconds += delta
			if stuck_seconds>.8:
				hint.text = tx("hedge_collision_prefix") + str(Vector2i(player/TILE))
		else: stuck_seconds = 0.0

func _process(delta: float) -> void:
	world_tools.update(delta)
	rune_stones.update()
	companion.update(delta)
	arena_save.update(delta)
	update_foliage_audio(delta)
	if playing and not paused:
		var previous := rpg_reload;rpg_reload=maxf(0,rpg_reload-delta)
		if previous>.3 and rpg_reload<=.3 and weapon=="rpg":sfx("rpg_load")
	if is_instance_valid(rocket_voice):
		var distance := INF
		for shot in shots:
			if shot.kind in ["rpg","enemy_rocket"]:distance=minf(distance,player.distance_to(shot.pos))
		if sound_on and playing and not paused and distance<1400:
			rocket_voice.volume_db=lerpf(rocket_voice.volume_db,-10-20*log(1+distance/420)/log(10.0),minf(1,delta*12))
			if not rocket_voice.playing:rocket_voice.play()
		else:rocket_voice.stop()
	for door in objects:
		if door.kind=="doorway":
			door.gate_amount=move_toward(float(door.get("gate_amount",0)),1.0 if door_is_open(str(door.id)) else 0.0,delta*2.5)
			if door.id=="exit" and door_is_open("exit"):resolve_gate_overlap(door)
	for i in range(footprints.size()-1,-1,-1):
		footprints[i].life-=delta
		if footprints[i].life<=0:footprints.remove_at(i)
	for i in range(damage_numbers.size()-1,-1,-1):
		damage_numbers[i].life-=delta;damage_numbers[i].pos.y-=delta*30
		if damage_numbers[i].life<=0:damage_numbers.remove_at(i)
	# Browser visibility already suspends rendering; the DOM orientation gate
	# covers landscape. Never gate simulation on a JavaScriptBridge value:
	# its Variant conversion can disagree with native touch processing on WebKit.
	time += delta
	toast_time -= delta
	toast.visible = toast_time>0
	fps_average = lerpf(fps_average, 1.0/maxf(delta,0.001), 0.01)
	low_fx = false
	if gate_creak_delay>=0:
		gate_creak_delay-=delta
		if gate_creak_delay<0:sfx("gate_open")
	rifle_kick = maxf(0,rifle_kick-delta*23)
	shake = maxf(0,shake-delta*13)
	shake_offset = Vector2(sin(time*47),cos(time*53))*shake
	ambience_clock -= delta
	if ambience_clock<=0 and playing and not paused:
		sfx("birds" if level==0 else "crickets" if level==1 else "ambient")
		ambience_clock = 10.0 if level in [0,1] else randf_range(7,13)
	if not paused and not transition and playing and not rotate_overlay.visible:
		update_food_hearts(delta)
		update_new_rooms(delta)
		update_tasks(delta)
		if level==5: update_plants(delta)
		if not shots.is_empty():update_shots(delta)
		if level<6 and player.y < -HALL_SEAM:next_level()
		elif level>0 and player.y>grid.size()*TILE+HALL_SEAM:travel(level-1)
		camera = camera.lerp(camera_target(),1-exp(-delta*9))
		invincible = maxf(0,invincible-delta)
		attack_cd -= delta
		attack_flash = maxf(0,attack_flash-delta)
		if rpg_windup>=0:
			aim=rpg_aim
			direction=(1 if aim.x<0 else 3) if absf(aim.x)>absf(aim.y) else (0 if aim.y<0 else 2)
			rpg_windup-=delta
			if rpg_windup<0 and weapon=="rpg":attack(true)
		if attack_held and task_time<=0: attack()
		if level == 4 and not combat_done and inside_main_room(): update_combat(minf(delta,0.04))
		for id in bloom_times: bloom_times[id] = minf(1.0,bloom_times[id]+delta/2.8)
		interaction_clock-=delta
		if interaction_clock<=0:
			interaction_clock=.07;find_nearest();update_hud()
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
	# Handle the active finger before GUI Controls consume iOS drag events.
	if playing and not paused and not transition and not rotate_overlay.visible:
		if event is InputEventScreenDrag and joy_active and event.index==joy_id:
			joy_vector = ((event.position-joy_origin)/52.0).limit_length()
			get_viewport().set_input_as_handled()
			return
		if event is InputEventScreenTouch and event.pressed and not joy_active and event.position.x<get_viewport_rect().size.x*0.48 and touch_button_at(root,event.position)==null:
			joy_active = true
			joy_id = event.index
			joy_origin = event.position
			joy_vector = Vector2.ZERO
			get_viewport().set_input_as_handled()
			return
	if event is InputEventScreenDrag and touch_scrolls.has(event.index):
		var sc = touch_scrolls[event.index].get_ref()
		if is_instance_valid(sc): sc.scroll_vertical -= int(event.relative.y)
		if absf(event.position.y-float(scroll_starts[event.index]))>9: touch_buttons.erase(event.index)
		get_viewport().set_input_as_handled()
		return
	if not event is InputEventScreenTouch: return
	touch_mode = true
	if not event.pressed and joy_active and event.index==joy_id:
		joy_active = false
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
		if event.pressed and event.position.x<get_viewport_rect().size.x*0.48 and not joy_active:
			joy_active = true
			joy_id = event.index
			joy_origin = event.position
			joy_vector = Vector2.ZERO
		elif not event.pressed and joy_active and event.index==joy_id:
			joy_active = false
			joy_vector = Vector2.ZERO
	if event is InputEventScreenDrag and joy_active and event.index==joy_id:
		joy_vector = ((event.position-joy_origin)/52).limit_length()

func available(obj: Dictionary) -> bool:
	if obj.kind=="letter_box":return true
	if obj.kind=="riddle_stone":return obj.id not in save_data.riddle_stones and (not obj.get("hidden_hedge",false) or obj.pos.distance_to(player)<=54)
	if obj.kind=="medkit":return true
	if obj.kind=="flashlight_pedestal":return false
	if obj.kind=="cat_fish":return not save_data.cat_fish and not save_data.cat_tamed
	if obj.kind=="cat_hut":return not save_data.cat_tamed
	if obj.kind=="pet_cat":return corridor_row(floori(player.y/TILE)) and corridor_row(floori(obj.pos.y/TILE)) and save_data.cat_tamed and held_item.is_empty() and (nearest<0 or nearest>=objects.size() or objects[nearest].kind=="pet_cat")
	if obj.kind=="stats_stone":return true
	if obj.get("integrated_tree",false):return world_tools.tree_target(obj) or obj.kind=="hedge_tree_apples"
	if obj.kind=="skull_relic":return save_data.get("house_open",false) and not save_data.get("skull_taken",false) and not save_data.get("skull_inserted",false)
	if obj.kind=="skull_stand":return true
	if obj.kind=="house_door":return not obj.get("opened",false)
	if obj.kind in ["axe","shears","drill"]:return save_data.finished and held_item!=obj.kind
	if obj.kind=="secret_book":return true
	if world_tools.tree_target(obj) or world_tools.flower_target(obj) or obj.kind=="hedge_target":return true
	if obj.kind=="gate_key":return int(obj.room) not in save_data.gate_keys and int(obj.room) not in save_data.open_gates
	if obj.kind=="accessory":return obj.accessory not in save_data.wearing and (obj.get("dropped_accessory",false) or obj.accessory not in save_data.accessories)
	if obj.kind=="doorway":return obj.id=="exit" and not door_is_open("exit")
	if obj.id in ["rpg","rifle","sword"]: return obj.id not in save_data.weapons_taken
	if obj.id in ["seat","swing"]:return true
	if obj.id=="rake": return held_item!="rake"
	if obj.get("hidden_hedge",false) and obj.pos.distance_to(player)>54:return false
	if obj.kind in ["berries","tree_apples"]: return obj.id not in save_data.eaten
	if obj.id=="flashlight": return held_item!="flashlight"
	if obj.id=="shovel": return held_item!="shovel"
	if obj.kind=="mound": return obj.id not in save_data.dug
	var id: String = obj.id
	if id.is_empty(): return false
	if id == "crossing": return id not in save_data.letters
	if id == "courage": return combat_done and id not in save_data.letters
	if id == "garden": return required_flowers_ready() and id not in save_data.letters and blooms_ready()
	if obj.kind == "note": return id not in save_data.letters
	if id == "can": return held_item!="can"
	if id == "fertilizer": return not has_fertilizer
	if obj.kind == "sprout": return id not in watered or held_item=="rake"
	return true

func required_flower_count() -> int:
	var count:=0
	for id in range(6):
		if str(id) in watered:count+=1
	return count

func required_flowers_ready() -> bool:return required_flower_count()==6

func blooms_ready() -> bool:return required_flowers_ready()

func interaction_reachable(obj: Dictionary) -> bool:
	if obj.kind=="cat_hut":return companion.can_feed(obj)
	var target:Vector2=obj.pos
	var length:=player.distance_to(target)
	var embedded:bool=obj.get("hidden_hedge",false) or obj.kind in ["berries","tree_apples","hedge_target"] or (world_tools.tree_target(obj) and obj.get("integrated_hedge",false))
	for step in range(1,ceili(length/2)):
		var point:=player.lerp(target,float(step)*2/maxf(length,1))
		var cell:=Vector2i(point/TILE)
		if cell.y<0 or cell.y>=grid.size():
			if corridor_floor_point(point):continue
			return false
		if cell.x<0 or cell.x>=grid[0].length():return false
		if hedge_field!=null:
			if hedge_field.blocks(point):
				# Reach into the near face for fruit/hidden letters, never through the wall.
				return embedded and hedge_field.blocks(target) and point.distance_to(target)<=22
		elif grid[cell.y][cell.x]=="#":return false
	return true

func find_nearest() -> void:
	world_tools.refresh_targets()
	companion.refresh_target()
	nearest = -1
	var distance_squared:=95.0*95.0
	for i in range(objects.size()):
		if objects[i].kind=="pet_cat":continue
		var d:=player.distance_squared_to(objects[i].pos)
		var reach:=95.0 if objects[i].kind=="cat_hut" else 79.0
		if d<distance_squared and d<reach*reach and available(objects[i]) and interaction_reachable(objects[i]):
			distance_squared=d
			nearest=i

	if nearest<0 and held_item.is_empty():
		for i in range(objects.size()):
			if objects[i].kind=="pet_cat" and available(objects[i]) and player.distance_to(objects[i].pos)<60 and interaction_reachable(objects[i]):nearest=i;break

func item_name(obj: Dictionary) -> String:
	if obj.kind=="letter_box":return tx("journal_title")
	if obj.kind=="riddle_stone":return rune_stones.name_for(obj)
	if obj.kind=="medkit":return tx("item_medkit")
	if obj.kind in ["cat_fish","cat_hut","pet_cat","stats_stone"]:return tx("item_"+obj.kind)
	if obj.kind=="secret_book":return tx("secret_book_name")
	if obj.kind in ["axe","shears","drill"]:return tx("item_"+obj.kind)
	if world_tools.tree_target(obj):return tx("item_tree")
	if world_tools.flower_target(obj):return tx("item_flower")
	if obj.kind=="hedge_target":return tx("item_hedge")
	if obj.kind=="skull_relic":return tx("item_skull")
	if obj.kind=="skull_stand":return tx("item_skull_stand")
	if obj.kind=="house_door":return tx("item_house_door")
	if obj.kind=="gate_key":return tx("item_gate_key")
	if obj.kind=="accessory":return tx("accessory_"+str(obj.accessory))
	if obj.kind.begins_with("rack_") or obj.kind.begins_with("weapon_"):
		var weapon_name:String=obj.get("weapon",str(obj.id))
		return tx("weapon_"+weapon_name)
	if obj.kind in ["note","note_open"]:return tx("item_letter")
	if obj.kind=="chest":return tx("item_final_chest") if obj.id=="final" else tx("item_chest")
	if obj.kind=="berries":return tx("item_berries")
	if obj.kind=="tree_apples":return tx("item_apple")
	if obj.kind in ["doorway","arch"]:return tx("item_gate")
	if obj.id in ["can","rake","fertilizer","shovel","flashlight","well"]:return tx("item_"+str(obj.id))
	if obj.id=="seat":return tx("item_bench")
	if obj.id=="swing":return tx("item_swing")
	if level==6 and obj.kind=="stone":return tx("item_puzzle_reset") if obj.id=="puzzle_reset" else rune_stones.name_for(obj)
	return ""

func item_display_position(obj: Dictionary) -> Vector2:
	var pos:Vector2=obj.pos
	if obj.kind=="skull_relic":pos.y-=46
	if obj.kind=="gate_key" and obj.has("key_origin"):
		var t:=clampf((time-float(obj.get("rise_start",time-1)))/.55,0,1)
		pos=Vector2(obj.key_origin).lerp(pos,smoothstep(0,1,t))+Vector2(0,-sin(t*PI)*30)
	elif obj.kind in ["accessory","cat_fish","riddle_stone"] and not obj.get("buried_stone",false):pos.y+=sin(time*2)*2
	elif obj.kind=="note" and obj.id!="buried":pos.y+=sin(time*2+pos.x)*4+25*(1-clampf((time-float(obj.get("rise_start",time-1)))/.45,0,1))
	return pos

func item_visual_bounds(obj: Dictionary) -> Rect2:
	var position:Vector2=item_display_position(obj)
	if obj.kind=="berries" and hedge_field!=null:
		var bounds:=Rect2()
		for index in hedge_field.near_ids(position,52):
			if hedge_field.crowns[index].berry!=obj.id:continue
			var pose:Vector3=hedge_field.draw_poses.get(index,Vector3.ZERO)
			var part:=Rect2(Vector2(pose.x,pose.y)-Vector2.ONE*pose.z,Vector2.ONE*pose.z*2)
			bounds=bounds.merge(part) if bounds.has_area() else part
		if bounds.has_area():return bounds
	if obj.get("integrated_hedge",false):return Rect2(position+Vector2(-32,-96),Vector2(64,80))
	if obj.kind in ["doorway","arch"]:return Rect2(position+Vector2(-100,-90),Vector2(200,90))
	var name:String=rune_stones.texture(obj) if obj.kind=="riddle_stone" or (level==6 and obj.kind=="stone") else "house_door_open" if obj.kind=="house_door" and obj.get("opened",false) else "accessory_"+str(obj.accessory) if obj.kind=="accessory" else ("flashlight" if obj.get("ground_tool",false) else "flashlight_rest") if obj.kind=="stand_flashlight" else obj.kind
	if not sprites.has(name):return Rect2(position-Vector2(24,32),Vector2(48,32))
	if not label_sprite_bounds.has(name):
		var id:int=sprites[name]
		label_sprite_bounds[name]=Rect2(label_atlas_pixels.get_region(Rect2i(id%16*32,id/16*48,32,48)).get_used_rect())
	var source:Rect2=label_sprite_bounds[name]
	if obj.get("ground_tool",false):
		var local:=Rect2((source.position*2-Vector2(32,86))*.65+Vector2(0,20),source.size*1.3)
		var result:=Rect2(position+local.position.rotated(PI/2),Vector2.ZERO)
		for corner in [local.position,local.position+Vector2(local.size.x,0),local.end,local.position+Vector2(0,local.size.y)]:result=result.expand(position+corner.rotated(PI/2))
		return result
	var scale_factor:=3.0 if obj.kind=="chest" and obj.id=="final" else .5 if obj.kind=="gate_key" else .7 if obj.kind=="skull_relic" else 2.0 if obj.kind=="house_door" else 1.0
	var bounds:=Rect2(position+(source.position*2-Vector2(32,86))*scale_factor,source.size*2*scale_factor)
	if level==6 and obj.kind=="stone":bounds=bounds.expand(position+Vector2(0,-60))
	return bounds

func draw_item_names() -> void:
	if not playing or paused:return
	var candidates:Array[Dictionary]=[]
	for obj in objects:
		if obj.pos.distance_squared_to(player)>95*95 or not available(obj) or not interaction_reachable(obj):continue
		var text:=item_name(obj)
		if text.is_empty():continue
		var bounds:=item_visual_bounds(obj)
		var p:=screen(Vector2(bounds.get_center().x,bounds.position.y)-Vector2(0,8)).round()
		var width:=ceilf(minf(240,body_font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x))+8
		var box:=Rect2(p+Vector2(-width/2,-16),Vector2(width,21))
		candidates.append({"box":box,"p":p,"text":text,"distance":obj.pos.distance_squared_to(player)})
	candidates.sort_custom(func(a,b):return a.distance<b.distance)
	var occupied:Array[Rect2]=[]
	for candidate in candidates:
		var box:Rect2=candidate.box
		if occupied.any(func(other):return other.intersects(box)):continue
		occupied.append(box)
		var p:Vector2=candidate.p;var text:String=candidate.text
		# Neutral translucent backing only; text keeps full opacity.
		draw_rect(box,Color(.3,.3,.3,.25))
		draw_string(body_font,p+Vector2(-120,0),text,HORIZONTAL_ALIGNMENT_CENTER,240,16,CREAM)

func action_text(obj: Dictionary) -> String:
	if obj.kind=="letter_box":return tx("read_letter")
	if obj.kind=="riddle_stone":return tx("pickup_rune")
	if obj.kind=="medkit":return tx("use_medkit")
	if obj.kind=="cat_fish":return tx("take_fish")
	if obj.kind=="cat_hut":return tx("feed_cat" if save_data.cat_fish else "meet_cat")
	if obj.kind=="pet_cat":return tx("pet_cat_action")
	if obj.kind=="stats_stone":return tx("read_statistics")
	if obj.kind=="secret_book":return tx("read_book")
	if obj.kind in ["axe","shears","drill"]:return tx("pickup_"+obj.kind)
	if world_tools.tree_target(obj):return tx("chop_tree")
	if world_tools.flower_target(obj) or obj.kind=="hedge_target":return tx("snip_plant")
	if obj.kind=="sprout" and held_item=="rake" and int(plants.get(obj.id,{}).get("stage",0))>=2:return tx("uproot_flower")
	if obj.kind=="skull_relic":return tx("take_skull")
	if obj.kind=="skull_stand":return tx("write_reply") if save_data.get("skull_inserted",false) else tx("insert_skull")
	if obj.kind=="house_door":return tx("open_house_door")
	if obj.kind=="gate_key":return tx("pickup_gate_key")
	if obj.kind=="accessory":return tx("wear_accessory")
	if not resting.is_empty():return tx("stand_action")
	if obj.id=="seat": return tx("sit_action")
	if obj.id=="swing": return tx("swing_action")
	if obj.id=="rake": return tx("pickup_rake")
	if obj.kind in ["berries","tree_apples"]: return tx("eat_apple") if obj.kind=="tree_apples" else tx("eat_berries")
	if obj.id=="flashlight": return tx("pickup_flashlight")
	if obj.id=="shovel": return tx("pickup_shovel")
	if str(obj.id).begins_with("drop_"):return tx("pickup_prefix")+str({"rpg":tx("weapon_rpg"),"rifle":tx("weapon_rifle"),"sword":tx("weapon_sword")}.get(obj.weapon,obj.weapon))
	if obj.kind=="mound": return tx("dig_action")
	if obj.id=="back": return tx("back") if door_is_open("back") else tx("gate_locked_action")
	if obj.id=="fertilizer": return tx("pickup_fertilizer")
	if obj.id in ["rpg","rifle","sword"]: return {"rpg":tx("pickup_rpg"),"rifle":tx("pickup_rifle"),"sword":tx("pickup_sword")}[obj.id]
	if obj.id == "exit": return tx("open_gate") if level in save_data.gate_keys or door_is_open("exit") or not room_letters_complete() else tx("gate_key_action")
	if obj.id == "well": return tx("fill_water")
	if obj.id == "can": return tx("pickup_can")
	if obj.kind == "sprout":
		if obj.id not in save_data.cleaned: return tx("clean_bed")
		if obj.id not in fertilized: return tx("fertilize_bed")
		if float(plants.get(obj.id,{}).get("remaining",0))>0: return tx("plant_growing")
		return tx("water_action")
	if obj.id == "final": return tx("open_chest")
	if level==6 and obj.kind=="stone":return tx("puzzle_reset_action") if obj.id=="puzzle_reset" else tx("press_rune") if obj.id in save_data.riddle_inserted else tx("insert_rune")
	return tx("read_letter")

func interact() -> void:
	if paused or transition: return
	if not resting.is_empty(): stand_up();return
	if task_time>0:return
	if nearest>=0 and world_tools.use_object(objects[nearest]):return
	if new_bed_action_ready():world_tools.make_bed();return
	if level==3 and save_data.shovel and task_time<=0 and (nearest<0 or (objects[nearest].id not in ["exit","back","buried","gate_key_3"] and objects[nearest].kind not in ["accessory","riddle_stone"])):
		dig_here()
		return
	if nearest<0: return
	var obj := objects[nearest]
	if not interaction_reachable(obj):find_nearest();return
	var id: String = obj.id
	if task_time>0: return
	if companion.interact(obj):find_nearest();return
	if obj.kind=="riddle_stone":rune_stones.collect(obj);return
	if obj.kind=="medkit":
		if health>=8:notify(tx("health_full"));return
		health=8;objects.erase(obj);burst(player,12,Color("a9e7b6"));sfx("chime");notify(tx("medkit_used"));find_nearest();persist();return
	if obj.kind=="letter_box":show_letter_stack(obj);return
	if obj.kind=="stats_stone":stats.show(self);return
	if obj.kind in ["axe","shears","drill"]:world_tools.pickup(obj.kind);return
	if obj.kind=="secret_book":show_secret_book();return
	if obj.kind=="skull_relic":
		save_data.skull_taken=true;persist();sfx("chime");notify(tx("skull_collected"));find_nearest();return
	if obj.kind=="skull_stand":
		if not save_data.get("skull_inserted",false):
			if not save_data.get("skull_taken",false):notify(tx("skull_missing"));return
			save_data.skull_taken=false;save_data.skull_inserted=true;persist();sfx("chest");burst(obj.pos,12,PINK)
		open_reply_letter();return
	if obj.kind=="house_door":
		obj.opened=true;save_data.house_open=true;persist();sfx("gate_open");find_nearest();return
	if obj.kind=="gate_key":
		if int(obj.room) not in save_data.gate_keys:save_data.gate_keys.append(int(obj.room))
		objects.erase(obj);persist();sfx("chime");notify(tx("gate_key_found"));find_nearest();return
	if obj.kind=="accessory":
		collect_accessory(str(obj.accessory));return
	if id in ["seat","swing"]:
		resting=id;rest_anchor=obj.pos;player=obj.pos+Vector2(0,8);direction=2;joy_active=false;joy_vector=Vector2.ZERO
	elif id in ["rake","can","fertilizer","shovel","flashlight"]:
		equip_tool(id);persist();sfx("ui")
	elif obj.kind in ["berries","tree_apples"]:
		stats.add(self,"berries" if obj.kind=="berries" else "apples")
		save_data.eaten.append(id);health=minf(8,health+2);sfx("eat");persist()
		food_hearts_left=10;food_heart_clock=.13
		food_heart_burst()
	elif obj.kind=="mound":
		if not save_data.shovel: notify(tx("shovel_required"))
		else: begin_task("dig:"+id,obj.pos,.25)
	elif id=="exit":
		if not door_is_open("exit"):use_exit()
	elif id=="back":return
	elif id in ["rpg","rifle","sword"]:
		return_held_tool()
		if id in save_data.weapons_taken: return
		if not weapon.is_empty():
			var dropped := {"kind":"weapon_"+weapon,"id":"drop_"+weapon+"_"+str(Time.get_ticks_msec()),"weapon":weapon,"room":level,"pos":player+Vector2(0,25),"solid":false}
			objects.append(dropped)
			var saved := dropped.duplicate();saved.pos=[dropped.pos.x,dropped.pos.y];save_data.loose_weapons.append(saved)
		held_item=id
		weapon = id
		if id not in save_data.weapons_taken: save_data.weapons_taken.append(id)
		attack_cd = .3
		persist()
		sfx("ui")
		notify({"rpg":tx("rpg_help"),"rifle":tx("rifle_help"),"sword":tx("sword_help")}[id])
	elif id.begins_with("drop_"):
		return_held_tool()
		var previous := weapon
		held_item=str(obj.weapon)
		weapon=obj.weapon
		objects.erase(obj)
		save_data.loose_weapons=save_data.loose_weapons.filter(func(d):return d.id!=id)
		if not previous.is_empty():
			var dropped := {"kind":"weapon_"+previous,"id":"drop_"+previous+"_"+str(Time.get_ticks_msec()),"weapon":previous,"room":level,"pos":player+Vector2(0,25),"solid":false}
			objects.append(dropped)
			var saved := dropped.duplicate();saved.pos=[dropped.pos.x,dropped.pos.y];save_data.loose_weapons.append(saved)
		persist()
	elif id=="well":
		if not garden_can: notify(tx("can_required"))
		else: begin_task("fill",obj.pos,2.4)
	elif obj.kind=="sprout":
		if id not in save_data.cleaned:
			if not save_data.rake: notify(tx("rake_required"))
			else: begin_task("rake:"+id,obj.pos,1.0)
		elif id not in fertilized:
			if not has_fertilizer: notify(tx("fertilizer_required"))
			else:
				begin_task("fertilize:"+id,obj.pos,1.6)
				persist()
		elif float(plants.get(id,{}).get("remaining",0))>0: notify(tx("plant_wait"))
		elif not garden_can: notify(tx("can_location"))
		elif water==0: notify(tx("water_empty"))
		else:
			plants[id] = {"stage":int(plants.get(id,{}).get("stage",0)),"remaining":-1.0}
			begin_task("water:"+id,obj.pos,2.2)
	elif id=="final":
		check_riddle_chest()
	elif level==6 and obj.kind=="stone":
		rune_stones.use_socket(id,obj.pos)
	else: collect(id)
	find_nearest()

func stand_up() -> void:
	player=rest_anchor+Vector2(0,46);resting=""

func sync_hands() -> void:
	garden_can=held_item=="can";save_data.garden_can=garden_can
	has_fertilizer=held_item=="fertilizer";save_data.has_fertilizer=has_fertilizer
	save_data.rake=held_item=="rake";save_data.shovel=held_item=="shovel";save_data.flashlight=held_item=="flashlight"
	if held_item not in ["sword","rifle","rpg"]:weapon=""

func return_held_tool() -> void:
	if held_item=="flashlight":torch.drop(player);return
	world_tools.drop_held()
	if held_item in ["sword","rifle","rpg"]:
		var dropped := {"kind":"weapon_"+held_item,"id":"drop_"+held_item+"_"+str(Time.get_ticks_usec()),"weapon":held_item,"room":level,"pos":Vector2(player.x,clampf(player.y+25,7.5*TILE,(grid.size()-7.5)*TILE)),"solid":false}
		objects.append(dropped)
		var saved := dropped.duplicate();saved.pos=[dropped.pos.x,dropped.pos.y];save_data.loose_weapons.append(saved)
		held_item="";weapon="";sync_hands()
	if held_item in ["rake","can","fertilizer","shovel","flashlight"]:
		for obj in objects:
			if obj.id==held_item:
				obj.ground_tool=true
				obj.pos=Vector2(player.x,clampf(player.y+25,7.5*TILE,(grid.size()-7.5)*TILE))
				save_data.tool_positions[str(level)+":"+held_item]=[obj.pos.x,obj.pos.y]
		held_item="";sync_hands()

func equip_tool(id: String) -> void:
	return_held_tool()
	held_item=id;sync_hands()

func has_maze_letters() -> bool:
	for id in REQUIRED:
		if id not in save_data.letters: return false
	return true

func room_letters_complete() -> bool:
	match level:
		0:return has_maze_letters()
		1:return dark_letters_found()
		2:return "crossing" in save_data.letters
		3:return "buried" in save_data.letters
		4:return "courage" in save_data.letters
		5:return "garden" in save_data.letters
	return false

func key_letter_candidates() -> Array:
	return [REQUIRED,["shade_1","shade_2","shade_3"],["crossing"],["buried"],["courage"],["garden"],[]][level]

func gate_key_position(source: Vector2) -> Vector2:
	for offset in [Vector2(56,8),Vector2(-56,8),Vector2(0,56),Vector2(0,-56),Vector2(40,40),Vector2(-40,40),Vector2(40,-40),Vector2(-40,-40)]:
		var point:Vector2=source+offset
		if valid_ground(point) and not blocked(point):return point
	return accessory_drop_position(source+Vector2(0,60))

func spawn_gate_key(letter_id: String, animated: bool = true) -> void:
	if level>=6 or not room_letters_complete() or door_is_open("exit") or level in save_data.gate_keys or save_data.gate_key_drops.has(str(level)):return
	var source:=player
	for obj in objects:
		if obj.id==letter_id:source=obj.pos;break
	var pos:=gate_key_position(source)
	save_data.gate_key_drops[str(level)]={"letter":letter_id,"pos":[pos.x,pos.y]}
	objects.append({"kind":"gate_key","id":"gate_key_"+str(level),"room":level,"pos":pos,"solid":false,"key_origin":source,"rise_start":time if animated else time-1})

func restore_gate_key() -> void:
	objects.assign(objects.filter(func(obj):return obj.kind!="gate_key"))
	if level>=6 or door_is_open("exit") or level in save_data.gate_keys:return
	if not save_data.gate_key_drops.has(str(level)) and room_letters_complete():
		var source:=""
		for id in save_data.letters:
			if id in key_letter_candidates():source=id
		spawn_gate_key(source,false)
		return
	if save_data.gate_key_drops.has(str(level)):
		var drop:Dictionary=save_data.gate_key_drops[str(level)]
		objects.append({"kind":"gate_key","id":"gate_key_"+str(level),"room":level,"pos":Vector2(drop.pos[0],drop.pos[1]),"solid":false})

func normalize_dig_site() -> void:
	if level!=3 or not save_data.buried_exposed or save_data.dig_target.size()!=2:return
	var pos:=Vector2(save_data.dig_target[0],save_data.dig_target[1])
	var notes:Array=objects.filter(func(obj):return obj.id=="buried")
	for index in range(1,notes.size()):objects.erase(notes[index])
	if notes.is_empty():objects.append({"kind":"note","id":"buried","pos":pos,"solid":false})
	else:notes[0].pos=pos

func garden_need(bed: Dictionary) -> String:
	var id:String=bed.id
	if task_time>0 and task_target==bed.pos:return ""
	if id not in save_data.cleaned:return "rake"
	if id not in fertilized:return "fertilizer"
	if float(plants.get(id,{}).get("remaining",0))>0:return ""
	if int(plants.get(id,{}).get("stage",0))<2:return "water"
	return ""

func draw_garden_needs() -> void:
	if level!=5:return
	for bed in objects:
		if bed.kind!="sprout":continue
		var kind:=garden_need(bed)
		if kind.is_empty():continue
		var plant_name:="weeds" if bed.id not in save_data.cleaned else "seedling"+str(world_tools.variant(bed.id)) if int(plants.get(bed.id,{}).get("stage",0))==1 else "bloom"+str(world_tools.variant(bed.id)) if int(plants.get(bed.id,{}).get("stage",0))>=2 else "bed_empty"
		if not label_sprite_bounds.has(plant_name):
			var plant_id:int=sprites[plant_name]
			label_sprite_bounds[plant_name]=Rect2(label_atlas_pixels.get_region(Rect2i(plant_id%16*32,plant_id/16*48,32,48)).get_used_rect())
		var top:float=bed.pos.y+(label_sprite_bounds[plant_name].position.y*2-86)*(.9+float(world_tools.variant(bed.id))*.035)
		var pos:=screen(Vector2(bed.pos.x,top-42+sin(time*2.2+float(world_tools.variant(bed.id)))*3)).round()
		if not get_viewport_rect().grow(45).has_point(pos):continue
		var name:="need_"+kind;var id:int=sprites[name]
		if not outlines.has(name):
			var source:=label_atlas_pixels.get_region(Rect2i(id%16*32+4,id/16*48+16,24,28))
			var border:=Image.create(26,30,false,Image.FORMAT_RGBA8)
			for y in range(28):
				for x in range(24):
					if source.get_pixel(x,y).a<.2:continue
					for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:border.set_pixel(x+1+d.x,y+1+d.y,Color("fff3a6"))
			outlines[name]=ImageTexture.create_from_image(border)
		for offset in [Vector2(-1,0),Vector2(1,0),Vector2(0,-1),Vector2(0,1)]:draw_texture_rect(outlines[name],Rect2(pos+Vector2(-19.5,-1.5)+offset,Vector2(39,45)),false,Color(.2,.13,.25))
		draw_texture_rect(outlines[name],Rect2(pos+Vector2(-19.5,-1.5),Vector2(39,45)),false)
		draw_texture_rect_region(atlas,Rect2(pos-Vector2(18,0),Vector2(36,42)),Rect2(Vector2(id%16*32+4,id/16*48+16),Vector2(24,28)))
		var arrow:=pos+Vector2(0,38)
		draw_colored_polygon(PackedVector2Array([arrow+Vector2(-5,-3),arrow+Vector2(5,-3),arrow+Vector2(0,3)]),Color("ffe4a8"))

func use_exit(walking: bool = false) -> void:
	if transition:return
	if level_complete() and level<6 and not door_is_open("exit"):
		if walking:return
		if level not in save_data.gate_keys:notify(tx("gate_key_required"));return
		save_data.gate_keys.erase(level)
		save_data.open_gates.append(level);persist();sfx("gate_unlock");gate_creak_delay=.14;haptic(30)
		for door in objects:
			if door.kind=="doorway" and door.id=="exit":door.unlock_time=time
		return
	if level==0 and not has_maze_letters(): notify(tx("maze_notes_required"))
	elif level==1 and not dark_letters_found(): notify(tx("darkness_notes_required"))
	elif level==2 and (save_data.obstacles.size()<5 or "crossing" not in save_data.letters): notify(tx("obstacles_required"))
	elif level==3 and "buried" not in save_data.letters: notify(tx("buried_note_required"))
	elif level==4 and "courage" not in save_data.letters: notify(tx("combat_note_required"))
	elif level==5 and "garden" not in save_data.letters: notify(tx("garden_flowers_required"))
	elif level<6: next_level()
	if player.y<3*TILE: player.y=3.2*TILE

func next_level() -> void:
	if level>=6 or not door_is_open("exit"): return
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
	objective.text = tx(TITLES[level])
	match level:
		0:
			var count := 0
			for id in REQUIRED:
				if id in save_data.letters: count+=1
			status.text = tx("maze_status") % [count,(tx("maze_exit_open") if door_is_open("exit") else tx("gate_key_ready") if level in save_data.gate_keys else tx("gate_key_ground")) if count==3 else tx("maze_search_hint")]
		1: status.text = tx("darkness_status") % [dark_letter_count(),tx("flashlight_on") if save_data.flashlight else tx("flashlight_location")]
		2: status.text = tx("obstacles_status") % save_data.obstacles.size()
		3: status.text = tx("buried_note_found") if "buried" in save_data.letters else (tx("digging_hint") if save_data.shovel else tx("shovel_location"))
		4: status.text = tx("combat_status") % [mini(wave,battle.WAVE_COUNT),tx("combat_chest_hint") if combat_done else {"sword":tx("weapon_sword"),"rifle":tx("weapon_rifle"),"rpg":tx("weapon_rpg")}.get(weapon,tx("weapon_required"))]
		5: status.text = tx("garden_status") % [required_flower_count(),tx("water_prefix")+str(water)+" / 6" if garden_can else tx("can_search_hint")]
		6: status.text = tx("rune_status").format({"found":save_data.riddle_stones.size(),"inserted":save_data.riddle_inserted.size()}) if not rune_stones.ready() else tx("puzzle_status") % puzzle.size()
	if level==4 and wave>0 and not combat_done:
		status.text+=" · "+tx("combat_enemies_left").format({"count":enemies.size()})
	if level>0 and level<6 and room_letters_complete() and not door_is_open("exit"):
		status.text+=" · "+tx("gate_key_ready" if level in save_data.gate_keys else "gate_key_ground")
	action_button.disabled = task_time>0
	action_button.visible = (nearest>=0 or world_tools.can_bed() or (level==3 and save_data.shovel)) and playing
	if new_bed_action_ready():action_button.text=tx("new_bed_action")
	elif nearest>=0:action_button.text=action_text(objects[nearest])
	if level==3 and save_data.shovel and (nearest<0 or (objects[nearest].id not in ["exit","back","buried","gate_key_3"] and objects[nearest].kind not in ["accessory","riddle_stone"])): action_button.text=tx("dig_action") if task_time<=0 else tx("digging_progress")
	fit_button_text(action_button)
	switch_button.visible = false
	attack_button.visible = playing and not weapon.is_empty() and ((level==4 and not combat_done) or save_data.finished)
	hint.text = (tx("hedge_collision_prefix") + str(Vector2i(player/TILE))) if stuck_seconds>.8 else (tx("movement_hint") if not joy_active else "")

func notify(text: String) -> void:
	toast.text = text
	toast_time = 4.0

func burst(pos: Vector2, count: int, color: Color) -> void:
	for i in range(count*2):
		if particles.size()>=420: break
		particles.append({"pos":pos+Vector2(0,-22),"vel":Vector2(randf_range(-65,65),randf_range(-100,20)),"life":randf_range(.7,1.6),"color":color,"heart":i%4==0})

func spawn_wave() -> void:
	wave += 1
	poison_zones.clear()
	wave_timer = 3.0
	battle.spawn()
	persist()

func update_combat(delta: float) -> void:
	battle.update_poison(delta)
	if enemies.is_empty():
		wave_timer -= delta
		if wave_timer<=0:
			if wave<battle.WAVE_COUNT: spawn_wave()
			else:
				combat_done = true
				shots.assign(shots.filter(func(shot):return shot.kind not in ["enemy_bullet","enemy_rocket"]))
				poison_zones.clear()
				notify(tx("combat_complete"))
				sfx()
		return
	battle.tick(delta)

func rifle_muzzle() -> Vector2:
	# Atlas barrel tip (31,25), sprite anchor (16,43), rendered at 1.2x.
	var left := aim.x<0
	var angle := atan2(-aim.y,-aim.x) if left else aim.angle()
	return player+Vector2(14,-28)+Vector2(-18.0 if left else 18.0,-1.6).rotated(angle)

func attack(launch_ready: bool = false) -> void:
	if (rpg_windup>=0 and not launch_ready) or paused or (not save_data.finished and (level!=4 or combat_done)) or attack_cd>0 or transition or weapon.is_empty() or reload_time>0 or (weapon=="rpg" and rpg_reload>0): return
	if weapon=="rifle" and magazine<=0:
		reload_time=1.8;sfx("reload");return
	if not launch_ready and save_data.finished:
		aim=walk_facing.normalized()
	elif not launch_ready:
		var closest := INF
		for enemy in enemies:
			var d: float = player.distance_to(enemy.pos)
			if d<closest:closest=d;aim=(enemy.pos-player).normalized()
		if aim.length()<.1:aim=Vector2.UP
	else:aim=rpg_aim
	if absf(aim.x)>absf(aim.y):direction=1 if aim.x<0 else 3
	else:direction=0 if aim.y<0 else 2
	if weapon=="rpg" and not launch_ready:
		rpg_aim=aim;rpg_windup=.20;return
	attack_cd = {"sword":.48,"rifle":.13,"rpg":RPG_RELOAD}[weapon]
	attack_flash=.22
	sfx("attack" if weapon=="sword" else "rifle" if weapon=="rifle" else "rpg_launch")
	shake = 2.5 if weapon!="rpg" else 5
	haptic(14)
	if weapon=="sword":
		for i in range(enemies.size()-1,-1,-1):
			var diff: Vector2 = enemies[i].pos-player
			if diff.length()<130 and aim.dot(diff.normalized())>-.35:
				damage_enemy(i,16,diff.normalized()*28)
	else:
		shots.append({"pos":rpg_muzzle() if weapon=="rpg" else rifle_muzzle(),"vel":aim.rotated(randf_range(-.036,.036) if weapon=="rifle" else 0)*(570 if weapon=="rifle" else 75),"life":1.4 if weapon=="rifle" else 4.5,"kind":weapon,"age":0.0})
		if weapon=="rpg":
			stats.add(self,"rockets")
			rpg_reload=RPG_RELOAD
			if sound_on and not rocket_voice.playing:rocket_voice.volume_db=-10;rocket_voice.play()
			for step in range(12):
				var recoil := player-aim*6
				if blocked(recoil):break
				player=recoil
		if weapon=="rifle":
			rifle_kick=4.025;rifle_kick_dir=aim;shake=maxf(shake,3.68)
			for step in range(4):
				if blocked(player-aim*1.15):break
				player-=aim*1.15
			magazine-=1
			if magazine==0:reload_time=1.8;sfx("reload")

func hurt(amount:float=1.0) -> void:
	if invincible>0: return
	health = maxf(0,health-amount)
	invincible = 1.3
	sfx("hurt")
	shake = 8
	haptic(60)
	burst(player,12,PINK)
	if health<=0:
		stats.add(self,"retries")
		arena_save.mark_dead()
		var box := modal_box(590,330)
		box.add_child(label(tx("death_title"), 30, CREAM, true))
		box.add_child(label(tx("death_help"),18))
		box.add_child(button(tx("retry_action"), func(): arena_save.restart()))
		box.add_child(button(tx("menu_action"), show_menu))

	persist()

func screen(pos: Vector2) -> Vector2:
	return pos+(get_viewport_rect().size/2-camera+shake_offset).round()

func draw_sprite(name: String, pos: Vector2, color: Color = Color.WHITE, scale_factor: float = 1.0) -> void:
	var id := int(sprites.get(name,0))
	if name in ["hedge_tree","hedge_tree_apples"]:
		draw_texture_rect(hedge_tree_textures[name],Rect2(pos+Vector2(-32,-96)*scale_factor,Vector2(64,96)*scale_factor),false,color)
		return
	var size := Vector2(64,96)*scale_factor
	draw_texture_rect_region(atlas,Rect2(pos-Vector2(32,86)*scale_factor,size),Rect2(Vector2(id%16*32,id/16*48),Vector2(32,48)),color)

func draw_pickup_outline(name: String, pos: Vector2, scale_factor: float) -> void:
	if hedge_tree_textures.has(name):
		if not outlines.has(name):
			var source:Image=hedge_tree_textures[name].get_image().get_region(Rect2i(0,0,64,80))
			var border:=Image.create(68,84,false,Image.FORMAT_RGBA8)
			for y in range(80):
				for x in range(64):
					if source.get_pixel(x,y).a<.2:continue
					for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:border.set_pixel(x+2+d.x,y+2+d.y,Color("fff3a6"))
			for y in range(80):
				for x in range(64):
					if source.get_pixel(x,y).a>.2:border.set_pixel(x+2,y+2,Color.TRANSPARENT)
			outlines[name]=ImageTexture.create_from_image(border)
		draw_texture_rect(outlines[name],Rect2(pos-Vector2(34,98),Vector2(68,84)),false);return
	if not outlines.has(name):
		var id := int(sprites.get(name,0))
		var source := atlas.get_image().get_region(Rect2i(id%16*32,id/16*48+(16 if (name.begins_with("hedge") and not name.begins_with("hedge_tree")) else 0),32,32 if (name.begins_with("hedge") and not name.begins_with("hedge_tree")) else 48))
		var border := Image.create(34,source.get_height()+2,false,Image.FORMAT_RGBA8)
		for y in range(source.get_height()):
			for x in range(32):
				if source.get_pixel(x,y).a<.2: continue
				for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
					border.set_pixel(x+1+d.x,y+1+d.y,Color("fff3a6"))
		for y in range(source.get_height()):
			for x in range(32):
				if source.get_pixel(x,y).a>.2:border.set_pixel(x+1,y+1,Color.TRANSPARENT)
		outlines[name] = ImageTexture.create_from_image(border)
	var box := Rect2(pos-Vector2(25.5,33.5),Vector2(51,51)) if (name.begins_with("hedge") and not name.begins_with("hedge_tree")) else Rect2(pos-Vector2(34,88)*scale_factor,Vector2(68,100)*scale_factor)
	for offset in [Vector2(-2,0),Vector2(2,0),Vector2(0,-2),Vector2(0,2)]:draw_texture_rect(outlines[name],Rect2(box.position+offset,box.size),false,Color(.2,.13,.25))
	draw_texture_rect(outlines[name],box,false)

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
	elif id=="moon":
		draw_arc(pos,10,PI*.3,PI*1.7,12,color,4)
	elif id=="heart":draw_heart(pos,1.8,color)
	elif id=="leaf":
		draw_colored_polygon(PackedVector2Array([pos+Vector2(-9,9),pos+Vector2(-9,-2),pos+Vector2(1,-9),pos+Vector2(10,-10),pos+Vector2(8,3),pos]),color)
		draw_line(pos+Vector2(-8,8),pos+Vector2(6,-6),INK,2)
	elif id=="drop":draw_colored_polygon(PackedVector2Array([pos+Vector2(0,-12),pos+Vector2(8,1),pos+Vector2(7,8),pos+Vector2(0,11),pos+Vector2(-7,8),pos+Vector2(-8,1)]),color)
	elif id=="puzzle_reset":
		draw_arc(pos,10,.4,TAU-.4,16,Color("e59aaf"),3)
		draw_line(pos+Vector2(9,-5),pos+Vector2(13,-5),Color("e59aaf"),3)

func draw_heart(pos: Vector2, size: float, color: Color) -> void:
	var p := PackedVector2Array([Vector2(-4,-2),Vector2(-4,-4),Vector2(-2,-5),Vector2(0,-3),Vector2(2,-5),Vector2(4,-4),Vector2(4,-2),Vector2(0,3)])
	for i in range(p.size()): p[i]=pos+p[i]*size
	draw_colored_polygon(p,color)

func _draw() -> void:
	if grid.is_empty():return
	# Only draw the visible edge of one cached neighbour. Its simulation stays frozen.
	var night_band:=Rect2()
	var corridor_pedestal:=Vector2.INF
	var corridor_torch:=Vector2.INF
	var corridor_torch_ground:=false
	var destination:=-1
	if level<6 and camera.y<get_viewport_rect().size.y/2+100:destination=level+1
	elif level>0 and camera.y>grid.size()*TILE-get_viewport_rect().size.y/2-100:destination=level-1
	if destination<=level:_draw_world()
	if destination>=0 and room_cache.has(destination):
		var old_level:=level;var old_camera:=camera;var old_height:=grid.size()*TILE
		var old_state:Dictionary={}
		for field in ROOM_FIELDS:old_state[field]=get(field)
		var state:Dictionary=room_cache[destination]
		var old_center:float=(15.5 if level==0 else 13.5)*TILE if destination>level else 13.5*TILE
		for field in ROOM_FIELDS:set(field,state[field])
		level=destination
		var new_center:float=13.5*TILE if destination>old_level else (15.5 if destination==0 else 13.5)*TILE
		var offset:=Vector2(new_center-old_center,grid.size()*TILE+HALL_SEAM*2 if destination>old_level else -old_height-HALL_SEAM*2)
		camera=old_camera+offset;player=old_state.player+offset;drawing_neighbor=true
		_draw_world()
		if level==1:
			night_band=Rect2(screen(Vector2(0,5*TILE)),Vector2(grid[0].length()*TILE,(grid.size()-10)*TILE))
			for obj in objects:
				if obj.kind=="flashlight_pedestal":corridor_pedestal=screen(obj.pos)
				if obj.kind=="stand_flashlight" and held_item!="flashlight" and int(save_data.flashlight_location.get("room",1))==1:corridor_torch=screen(obj.pos);corridor_torch_ground=obj.get("ground_tool",false)
		drawing_neighbor=false;level=old_level;camera=old_camera
		for field in ROOM_FIELDS:set(field,old_state[field])
	if destination>level:_draw_world()
	# Corridor props must survive the foreground room floor pass.
	if corridor_pedestal!=Vector2.INF:
		draw_sprite("pedestal",corridor_pedestal)
	if corridor_torch!=Vector2.INF:
		if corridor_torch_ground:
			draw_set_transform(corridor_torch,PI/2);draw_sprite("flashlight",Vector2(0,20),Color.WHITE,.65);draw_set_transform(Vector2.ZERO)
		else:draw_sprite("flashlight_rest",corridor_torch)
	var view:=get_viewport_rect().size
	for i in range(8):
		var c:=Color(.06,.07,.13,.025*(8-i))
		draw_rect(Rect2(Vector2(i*5,i*5),view-Vector2.ONE*i*10),c,false,5)
	if night_band.has_area():draw_night_mask(night_band)

func draw_night_mask(area: Rect2) -> void:
	var feather:=64.0
	draw_rect(Rect2(area.position+Vector2(0,feather),area.size-Vector2(0,feather*2)),Color.BLACK)
	for n in range(128):
		var distance:float=-feather+n
		var alpha:=smoothstep(-feather,feather,distance+.5)
		draw_rect(Rect2(area.position+Vector2(0,distance),Vector2(area.size.x,1)),Color(0,0,0,alpha))
		draw_rect(Rect2(Vector2(area.position.x,area.end.y-distance-1),Vector2(area.size.x,1)),Color(0,0,0,alpha))

func open_reply_letter() -> void:
	if OS.has_feature("web"):
		paused=true;joy_active=false;joy_vector=Vector2.ZERO;attack_held=false
		var stand:Dictionary=objects.filter(func(obj):return obj.kind=="skull_stand")[0]
		var origin:=screen(stand.pos);var hand:=screen(player+Vector2(10,-32))
		JavaScriptBridge.eval("window.gardenOpenReply?.("+JSON.stringify({"start":[origin.x,origin.y],"hand":[hand.x,hand.y]})+")")
		while bool(JavaScriptBridge.eval("Boolean(document.getElementById('reply-letter'))")):
			await get_tree().process_frame
		if str(JavaScriptBridge.eval("window.gardenReplyResult || \"\""))=="sent":await deposit_reply()
		paused=false
	else:
		var box:=modal_box(500,320,true)
		box.add_child(label(tx("reply_title"),28,INK,true));box.add_child(label(tx("reply_browser_only"),18,INK))
		box.add_child(button(tx("back"),clear_modal))

func deposit_reply() -> void:
	var stands:=objects.filter(func(obj):return obj.kind=="skull_stand")
	if stands.is_empty():return
	paused=true;reply_deposit_active=true
	var stand:Vector2=stands[0].pos
	var points:Array[Vector2]=[]
	if player.y<stand.y+40:points.append(Vector2(stand.x+(70 if player.x>=stand.x else -70),player.y))
	points.append(Vector2(player.x if points.is_empty() else points[-1].x,stand.y+70))
	points.append(stand+Vector2(0,70));points.append(stand+Vector2(0,50))
	for point in points:
		var budget:float=player.distance_to(point)/SPEED+.4
		var stamp:=Time.get_ticks_usec()
		while player.distance_to(point)>3 and budget>0:
			await get_tree().process_frame
			var now:=Time.get_ticks_usec();var delta:=clampf(float(now-stamp)/1000000,.001,.04);stamp=now;budget-=delta
			move_player(delta,(point-player).normalized()*minf(1,player.distance_to(point)/(SPEED*delta)))
			camera=camera.lerp(camera_target(),1-exp(-delta*9));queue_redraw()
	moving=false;direction=0;walk_facing=Vector2.UP
	reply_slot=stand+Vector2(0,-20);reply_hand_start=player+Vector2(10,-32);reply_deposit_progress=0
	sfx("paper")
	var tween:=create_tween()
	tween.tween_method(func(value):reply_deposit_progress=value;queue_redraw(),0.0,1.0,1.25)
	await tween.finished
	reply_deposit_progress=-1;reply_deposit_active=false;save_data.reply_sent=true;persist();sfx("paper");notify(tx("reply_sent"))

func draw_reply_deposit() -> void:
	if not reply_deposit_active:return
	if reply_deposit_progress<0:
		draw_sprite("note",screen(player+Vector2(10,-32)),Color.WHITE,.5);return
	var progress:=reply_deposit_progress
	var reach:=smoothstep(0,.6,progress)
	var hand:=reply_hand_start.lerp(reply_slot+Vector2(5,7),reach*.75)
	var dress:="black_dress"
	for item in save_data.wearing:
		if item in ["white_dress","peach_dress","lavender_dress"]:dress=item
	var cloth:Color={"black_dress":Color("55516c"),"white_dress":Color("d9d4da"),"peach_dress":Color("a96872"),"lavender_dress":Color("8b77a6")}[dress]
	draw_line(screen(reply_hand_start),screen(hand),cloth.darkened(.2),7)
	draw_line(screen(reply_hand_start)+Vector2(-1,0),screen(hand)+Vector2(-1,0),cloth,4)
	draw_sprite("reply_hand_"+dress,screen(hand)+Vector2(0,10),Color.WHITE,.55)
	var bottom:=hand.lerp(reply_slot,smoothstep(.12,.65,progress))
	var push:=smoothstep(.65,1,progress)
	if not label_sprite_bounds.has("note"):
		var sprite_id:int=sprites.note
		label_sprite_bounds.note=Rect2(label_atlas_pixels.get_region(Rect2i(sprite_id%16*32,sprite_id/16*48,32,48)).get_used_rect())
	var source:Rect2=label_sprite_bounds.note
	var height:=source.size.y*(1-push)
	if height>.1:
		var id:int=sprites.note
		draw_texture_rect_region(atlas,Rect2(screen(bottom)+Vector2(-source.size.x/2,-height),Vector2(source.size.x,height)),Rect2(Vector2(id%16*32,id/16*48)+source.position,Vector2(source.size.x,height)))
	if progress>.6:
		var lip:=screen(reply_slot)+Vector2(0,2)
		draw_line(lip-Vector2(14,0),lip+Vector2(14,0),Color("e1c5be"),3)

func _draw_world() -> void:
	if grid.is_empty(): return
	var view := get_viewport_rect().size
	var from := Vector2i((camera-view/2)/TILE)-Vector2i(2,3)
	var to := Vector2i((camera+view/2)/TILE)+Vector2i(3,4)
	var renderables: Array[Dictionary] = []
	if not drawing_neighbor:renderables=draw_corridor_extensions()
	for y in range(maxi(0,from.y),mini(grid.size(),to.y)):
		for x in range(maxi(0,from.x),mini(grid[0].length(),to.x)):
			if grid[y][x]==" " or (drawing_neighbor and corridor_row(y)): continue
			var p := screen(Vector2(x,y)*TILE)
			var tile := 0
			if level==4 or level==6: tile=2 if (x+y)%3 else 1
			
			elif level==0: tile=3
			if corridor_row(y):draw_texture_rect_region(ground,Rect2(p,Vector2.ONE*TILE),Rect2(Vector2(24,0),Vector2(24,24)))
			elif grass_texture!=null and level not in [4,6]:draw_texture_rect_region(grass_texture,Rect2(p,Vector2.ONE*TILE),Rect2(Vector2(x,y)*24,Vector2(24,24)))
			else:draw_texture_rect_region(romance_ground if level==6 else ground,Rect2(p,Vector2.ONE*TILE),Rect2(Vector2(tile*24,0),Vector2(24,24)))
			if level==6 and x>=10 and x<=16 and y>=5 and y<=15:
				draw_rect(Rect2(p,Vector2.ONE*TILE),Color(.49,.26,.39,.5))
				if x==10 or x==16: draw_line(p+Vector2(5,0),p+Vector2(5,48),Color("c5918e"),2)
			if grid[y][x]=="#" and (level in [1,2,4] or corridor_row(y)):
				renderables.append({"kind":"stone","pos":Vector2(x+.5,y+.5)*TILE,"id":"","wall":true,"cell":Vector2i(x,y)})

	for obj in objects:
		if obj.kind in ["axe","shears","drill","tool_table"] and not save_data.finished:continue
		if obj.kind in ["hedge_target","tool_table","pet_cat"]:continue
		if obj.kind=="cat_fish" and (save_data.cat_fish or save_data.cat_tamed):continue
		if obj.kind=="riddle_stone" and obj.id in save_data.riddle_stones:continue
		if obj.kind=="stand_flashlight" and (held_item=="flashlight" or int(save_data.flashlight_location.get("room",1))!=level):continue
		if drawing_neighbor and corridor_row(floori(obj.pos.y/TILE)):continue
		if obj.kind=="accessory" and not available(obj):continue
		if obj.get("integrated_hedge",false):
			if get_viewport_rect().grow(120).has_point(screen(obj.pos)):
				var tree:Dictionary=obj.duplicate();tree.kind="hedge_tree_apples" if obj.kind=="tree_apples" and obj.id not in save_data.eaten else "hedge_tree";tree.integrated_tree=true
				renderables.append(tree)
			continue
		var p := screen(obj.pos)
		if p.x < -100 or p.y < -100 or p.x>view.x+100 or p.y>view.y+150: continue
		if obj.kind in ["berries","dug"]:continue
		if obj.kind=="skull_relic" and (not save_data.get("house_open",false) or save_data.get("skull_taken",false) or save_data.get("skull_inserted",false)):continue
		if obj.get("hidden_hedge",false) and obj.pos.distance_to(player)>54:continue
		if obj.id=="courage" and not combat_done: continue
		if obj.id=="garden" and (not required_flowers_ready() or not blooms_ready()): continue
		if obj.kind=="note" and obj.id in save_data.letters:
			var opened := obj.duplicate();opened.kind="note_open";renderables.append(opened);continue
		if obj.id=="can" and garden_can: continue
		if obj.id=="rake" and save_data.rake: continue
		if obj.kind=="berries" and obj.id in save_data.eaten: continue
		if obj.id=="fertilizer" and has_fertilizer: continue
		if obj.id=="shovel" and save_data.shovel: continue
		renderables.append(obj)
	for enemy in enemies: renderables.append({"kind":"enemy_rocketeer" if enemy.type==7 else "enemy_gunner" if enemy.type in [5,6] else "enemy"+str(int(enemy.type)%3),"pos":enemy.pos,"id":"","enemy":enemy})
	renderables.append({"kind":"player","pos":player,"id":""})
	if not drawing_neighbor and playing and save_data.cat_tamed:renderables.append({"kind":"pet_cat","pos":companion.position,"id":"pet_cat"})
	draw_paths()
	world_tools.draw_ground()
	if level==6 and save_data.finished:draw_tool_table()
	draw_footprints()
	if not drawing_neighbor:companion.draw_prints()
	battle.draw_poison()
	for part in particles:
		if part.get("ground",false) and shadow_floor_cell(Vector2i(part.pos/TILE)):
			var dust_color:Color=part.color;dust_color.a=minf(1,part.life*2)
			draw_rect(Rect2(screen(part.pos),Vector2(3,3)),dust_color)
	for remains in room_remains.get(level,[]):
		draw_sprite(remains.kind,screen(remains.pos),Color.WHITE,float(remains.get("scale",1.0)))
	for hole in objects:
		if hole.kind=="dug":draw_sprite("dug",screen(hole.pos))
	if not drawing_neighbor and (level not in [1,2,4] or not inside_main_room()):
		draw_cast_shadow("hero"+str(direction)+"_0",screen(player),1.0)
		var contact_shadow:=PackedVector2Array()
		for n in range(24):contact_shadow.append(screen(player)+Vector2(cos(n*TAU/24)*19,sin(n*TAU/24)*5.7))
		draw_floor_shadow(contact_shadow,Color(.06,.09,.15,.28))
	var visible_crowns:=PackedInt32Array()
	if hedge_field!=null:
		visible_crowns=hedge_field.visible_ids(Rect2(camera-view/2-Vector2(48,96),view+Vector2(96,192)))
		hedge_field.prepare_draw(visible_crowns,player)
		for item in renderables:
			if item.get("integrated_tree",false):draw_cast_shadow(item.kind,screen(item.pos),1)
		for index in visible_crowns:
			var crown:Dictionary=hedge_field.crowns[index]
			var r:float=crown.radius
			var pos:=screen(crown.base+crown.offset)
			draw_texture_rect(glow,Rect2(pos-Vector2(r+8,r*.85),Vector2(r*2+16,r*1.8+8)),false,Color(0,0,0,.65))
		draw_hedge_body(Rect2(camera-view/2-Vector2(48,96),view+Vector2(96,192)))
		# Each tree has one visible crown/trunk layer, sorted with the heroine below.
		draw_hedge_canopy(visible_crowns,-1)

	renderables.sort_custom(func(a,b):
		if a.pos.y==b.pos.y:
			if a.kind=="dug" and b.kind!="dug":return true
			if b.kind=="dug" and a.kind!="dug":return false
			return a.pos.x<b.pos.x
		return a.pos.y<b.pos.y)
	for item in renderables:
		var p := screen(item.pos)
		var kind: String = "tree" if item.kind=="tree_apples" and item.id in save_data.eaten else item.kind
		if kind=="player":
			if drawing_neighbor:
				if hedge_field!=null:draw_hedge_canopy(visible_crowns,1)
				continue
			if level in [1,2,4] and inside_main_room():
				draw_cast_shadow("hero"+str(direction)+"_0",p,1.0)
				draw_shadow(p,19)
			var frame := int(time*12)%4 if moving and (not paused or reply_deposit_active) else 0
			if not resting.is_empty():p+=Vector2(0,-18+sin(time*2.4)*12 if resting=="swing" else -18)
			var color := Color(1,.65,.73) if invincible>0 and int(time*12)%2==0 else Color.WHITE
			var hero_pos:=p-rifle_kick_dir*rifle_kick+Vector2(sin(time*9)*1.2 if moving else 0,sin(time*3)*1.4 if not moving else -absf(sin(time*12))*3)
			draw_player_outfit(hero_pos,frame,color)
			if attack_flash>0 and weapon=="sword":
				var angle := aim.angle()
				draw_arc(p+Vector2(0,-20),88,angle-1.1,angle+1.1,22,Color(1,.84,.75,attack_flash/.19),7)
				draw_arc(p+Vector2(0,-20),101,angle-.8,angle+.8,18,Color(1,.65,.79,attack_flash/.19),3)
			if hedge_field!=null:
				draw_hedge_canopy(visible_crowns,1)
		elif kind=="pet_cat":companion.draw_cat()
		elif item.get("integrated_tree",false):
			draw_hedge_tree_top(item.kind,item.pos)
		elif item.has("enemy"):
			var enemy: Dictionary = item.enemy
			if enemy.state=="warn":
				draw_circle(p,125 if enemy.get("boss",false) else 70,Color(.91,.43,.58,.19))
				draw_arc(p,125 if enemy.get("boss",false) else 70,0,TAU,32,PINK,2)
				draw_string(body_font,p+Vector2(-5,-69),"!",HORIZONTAL_ALIGNMENT_LEFT,-1,24,CREAM)
			draw_cast_shadow(kind,p,1.8 if enemy.get("boss",false) else 1.0)
			draw_shadow(p,20)
			draw_sprite(kind,p+Vector2(0,sin(time*5+item.pos.x)*3),Color(1,.2,.25) if time<float(enemy.get("hit_until",0)) else Color(1,.65,.75,.45 if enemy.state=="spawn" else 1) if enemy.get("boss",false) else (Color(.65,1,.85) if enemy.type==3 else Color(.75,.8,1) if enemy.type==4 else Color.WHITE),1.8 if enemy.get("boss",false) else 1.2 if enemy.type==4 else .72 if enemy.type==5 else .85 if enemy.type==3 else 1.0)
			if enemy.type in [5,6,7]:battle.draw_gun(enemy,p)
			if enemy.get("boss",false): draw_string(body_font,p+Vector2(-62,-115),tx("boss_name"),HORIZONTAL_ALIGNMENT_LEFT,-1,16,CREAM)
			var bar_width := 100.0 if enemy.get("boss",false) else 36.0
			draw_rect(Rect2(p+Vector2(-bar_width/2,-100 if enemy.get("boss",false) else -57),Vector2(bar_width,5)),INK)
			draw_rect(Rect2(p+Vector2(-bar_width/2,-100 if enemy.get("boss",false) else -57),Vector2(bar_width*float(enemy.hp)/float(enemy.get("max_hp",enemy.hp)),5)),PINK)
		else:
			if not drawing_neighbor and task_time<=0 and not item.has("wall") and item.pos.distance_squared_to(player)<9025 and available(item) and interaction_reachable(item) and kind not in ["doorway","arch"]:
				var highlight := rune_stones.texture(item) if kind=="riddle_stone" or (level==6 and kind=="stone") else "house_door" if kind=="house_door" else "accessory_"+str(item.accessory) if kind=="accessory" else "dug" if item.id=="buried" else ("flashlight" if item.get("ground_tool",false) else "flashlight_rest") if kind=="stand_flashlight" else kind
				if kind=="sprout":draw_pickup_outline("bed_border"+str(world_tools.variant(item.id)),p,.9+float(world_tools.variant(item.id))*.035)
				elif item.get("ground_tool",false):
					draw_set_transform(p,PI/2);draw_pickup_outline(highlight,Vector2(0,20),.65);draw_set_transform(Vector2.ZERO)
				elif item.get("integrated_tree",false):draw_pickup_outline(highlight,p,1.0)
				else:draw_pickup_outline(highlight,screen(item_display_position(item)),3.0 if kind=="chest" and item.id=="final" else .5 if kind=="gate_key" else .7 if kind=="skull_relic" else 2.0 if kind=="house_door" else 1.0)
			if not item.has("wall") and item.id!="buried" and not item.get("integrated_tree",false):
				if kind in ["tree","tree_apples","crate","column","column_wreath","heart_stand","well","bench"]:draw_cast_shadow(kind,p,1.0)
				draw_shadow(p,30 if kind in ["tree","tree_apples"] else 20)
			if item.get("ground_tool",false):
				draw_set_transform(p,PI/2);draw_sprite("flashlight" if kind=="stand_flashlight" else kind,Vector2(0,20),Color.WHITE,.65);draw_set_transform(Vector2.ZERO)
			elif kind=="cat_hut":
				draw_sprite(kind,p)
				if not save_data.cat_tamed:draw_sprite("cat_sit"+str(1 if fposmod(time,4.7)>4.55 else 0),p,Color.WHITE,.8)
			elif kind=="cat_fish":draw_sprite(kind,screen(item_display_position(item)))
			elif kind=="sprout":
				var stage := int(plants.get(item.id,{}).get("stage",0))
				var remaining := float(plants.get(item.id,{}).get("remaining",0))
				var texture := "weeds"
				if item.id in save_data.cleaned:
					texture="bed_empty"
					if item.id in fertilized:texture="bed_fertilized"
					if remaining>0 and stage==0:texture="bed_wet"
					if stage==1:texture="seedling"+str(world_tools.variant(item.id))
					if stage>=2:texture="bloom"+str(world_tools.variant(item.id))
				var bed_scale:=.9+float(world_tools.variant(item.id))*.035
				# Soil and stones are foreground layers above the shared path pad.
				draw_sprite("bed_wet" if stage>0 or remaining>0 else "bed_fertilized" if item.id in fertilized else "bed_empty",p,Color.WHITE,bed_scale)
				draw_sprite("bed_border"+str(world_tools.variant(item.id)),p,Color.WHITE,bed_scale)
				if sprites.has(texture+"_plant"):draw_sprite(texture+"_plant",p,Color.WHITE,bed_scale)

			elif kind=="swing":
				draw_sprite(kind,p)
				var swing_offset := sin(time*2.4)*12 if resting=="swing" else sin(time*1.5)*2
				draw_line(p+Vector2(-10,-66),p+Vector2(-10,-18+swing_offset),CREAM,2)
				draw_line(p+Vector2(12,-66),p+Vector2(12,-18+swing_offset),CREAM,2)
				draw_rect(Rect2(p+Vector2(-17,-20+swing_offset),Vector2(36,7)),Color("aa8066"))
			elif kind in ["house","pond"]: draw_sprite(kind,p,Color.WHITE,2.0)
			elif kind=="house_door":draw_sprite("house_door_empty" if save_data.get("skull_taken",false) or save_data.get("skull_inserted",false) else "house_door_open" if item.get("opened",false) else "house_door",p,Color.WHITE,2.0)
			elif kind=="skull_relic":draw_sprite(kind,screen(item_display_position(item)),Color.WHITE,.7)
			elif kind=="letter_box":draw_sprite("letter_box_open" if item.get("archive_open",false) else "letter_box",p)
			elif kind=="skull_stand":draw_sprite("skull_stand_full" if save_data.get("skull_inserted",false) else "skull_stand",p)
			elif kind=="doorway":
				draw_sprite("doorpost",p+Vector2(-90,0));draw_sprite("doorpost",p+Vector2(90,0))
				if item.id=="exit":draw_gate(p,float(item.get("gate_amount",0.0)))
			elif kind=="flashlight_pedestal":draw_sprite("pedestal",p)
			elif kind=="stand_flashlight":draw_sprite("flashlight_rest",p)
			elif kind.begins_with("rack_") and item.id in save_data.weapons_taken: draw_sprite("rack_empty",p)
			elif kind=="mound": draw_sprite("dug" if item.id in save_data.dug else "mound",p)
			elif kind=="chest": draw_sprite("chest_open" if ((item.id=="final" and chest_open) or item.id in save_data.letters) else "chest",p,Color.WHITE,3.0 if item.id=="final" else 1.0)
			elif kind=="riddle_stone":draw_sprite(rune_stones.texture(item),screen(item_display_position(item)))
			elif level==6 and kind=="stone":draw_sprite(rune_stones.texture(item),p)
			elif kind=="note" and item.id=="buried":draw_buried_paper(p,item.id in save_data.letters)
			elif kind=="note_open" and item.id=="buried":draw_buried_paper(p,true)
			elif kind in ["flowers","blueflowers"]:
				draw_sprite(kind+"_pressed_"+str(clampi(roundi(float(item.get("press",0))*2),0,2)),p)
			elif kind=="gate_key":draw_sprite(kind,screen(item_display_position(item)),Color.WHITE,.5)
			elif kind=="accessory":draw_sprite("accessory_"+str(item.accessory),screen(item_display_position(item)))
			elif kind=="note": draw_sprite(kind,screen(item_display_position(item)))
			else: draw_sprite(kind,p)
			if kind in ["arch","doorway"]:
				var open: bool = door_is_open(str(item.id))
				draw_texture_rect(glow,Rect2(p-Vector2(65,110),Vector2(130,150)),false,Color(.9,1,.9,1 if open else .2))
				if not open and kind!="doorway": draw_line(p+Vector2(-18,-36),p+Vector2(18,-36),Color("ab839a"),4)

	rune_stones.draw_insertions()
	# Batched radial textures approximate soft warm light without expensive real-time lights.
	for item in renderables:
		if level==6 and item.kind=="stone" and rune_stones.activated(str(item.id)):
			var center:=screen(item.pos)+Vector2(0,-48)
			var breathing:=1.0+sin(time*2.2+item.pos.x*.01)*.055
			draw_texture_rect(glow,Rect2(center-Vector2.ONE*58*breathing,Vector2.ONE*116*breathing),false,Color(1,.88,.72,.9))
			draw_texture_rect(glow,Rect2(center-Vector2.ONE*29,Vector2.ONE*58),false,Color(1,.92,.8,1))
		if item.kind in ["lamp","candle","candle_heart","heart_stand","note"] or (item.kind=="chest" and chest_open):
			var p := screen(item.pos)-Vector2(0,42)
			var size := 150.0+sin(time*3+item.pos.x)*5
			draw_texture_rect(glow,Rect2(p-Vector2.ONE*size/2,Vector2.ONE*size),false)
	if not drawing_neighbor and nearest>=0 and playing and not paused and objects[nearest].kind!="sprout" and available(objects[nearest]):
		var p := screen(objects[nearest].pos)+Vector2(0,-88+sin(time*4)*3)
		draw_colored_polygon(PackedVector2Array([p+Vector2(-6,-5),p+Vector2(6,-5),p+Vector2(0,2)]),Color("ffe4a8"))
	draw_garden_needs()
	if not drawing_neighbor:draw_item_names()
	# Deterministic ambient fireflies and butterflies, no nodes allocated per frame.
	for i in range(132):
		var world := Vector2(fposmod(i*137.7,grid[0].length()*TILE),fposmod(i*193.3,grid.size()*TILE))+Vector2(sin(time*.3+i)*26,cos(time*.4+i)*18)
		if not valid_ground(world) or corridor_row(floori(world.y/TILE)) or world.y<6*TILE or world.y>(grid.size()-6)*TILE: continue
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
		if part.get("ground",false):continue
		var c: Color = part.color
		c.a = minf(1,part.life)
		if part.heart: draw_heart(screen(part.pos),1.2,c)
		else: draw_rect(Rect2(screen(part.pos),Vector2(3,3)),c)
	draw_new_rooms()
	if not drawing_neighbor:
		draw_extra_effects()
		draw_reply_deposit()
		world_tools.draw_falling()
	for number in damage_numbers:draw_string(body_font,screen(number.pos),tx("damage_amount").format({"amount":number.value}),HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color(1,.55,.61,minf(1,number.life*3)))
	if level==6 and not drawing_neighbor:
		for n in range(puzzle.size()):
			var center := Vector2(74+n*65,225)
			draw_circle(center,23,Color(.12,.1,.18,.8));symbol(puzzle[n],center,CREAM)

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
	if transition or destination<0 or destination>6:return
	if room_cache_seed!=int(save_data.seed) or room_cache.size()!=7:prepare_room_cache(level)
	transition=true
	var previous:=level;var old_height:float=grid.size()*TILE
	var old_player:=player;var old_camera:=camera;var old_invincible:=invincible;var old_health:=health
	var return_torch:=held_item=="flashlight" and previous==1 and destination==0
	var carry_torch_in:=held_item=="flashlight" and previous==0 and destination==1
	var carried_weapon:Dictionary={}
	var carried_shots:Array=[]
	if save_data.finished and held_item in ["sword","rifle","rpg"]:
		for field in ["magazine","reload_time","rpg_reload","attack_cd","attack_flash","rpg_windup","rpg_aim"]:carried_weapon[field]=get(field)
		carried_shots=shots.filter(func(shot):return shot.pos.distance_to(old_player)<650).duplicate(true)
		shots.assign(shots.filter(func(shot):return shot.pos.distance_to(old_player)>=650))
	var north:float=(15.5 if level==0 else 13.5)*TILE
	var old_center:float=north if destination>level else 13.5*TILE
	if not return_torch and not carry_torch_in and held_item not in ["axe","shears","drill"] and not (save_data.finished and held_item in ["sword","rifle","rpg"]):return_held_tool()
	persist()
	var carried_prints:Array=footprints.filter(func(item):return item.pos.distance_to(old_player)<650).duplicate(true)
	var carried_particles:Array=particles.filter(func(item):return item.pos.distance_to(old_player)<650).duplicate(true)
	footprints.assign(footprints.filter(func(item):return item.pos.distance_to(old_player)>=650));particles.assign(particles.filter(func(item):return item.pos.distance_to(old_player)>=650))
	if destination<previous and destination not in save_data.open_gates:save_data.open_gates.append(destination)
	cache_current_room();activate_cached_room(destination)
	var new_center:float=13.5*TILE if destination>previous else (15.5 if destination==0 else 13.5)*TILE
	var delta:=Vector2(new_center-old_center,grid.size()*TILE+HALL_SEAM*2 if destination>previous else -old_height-HALL_SEAM*2)
	player=old_player+delta;camera=old_camera+delta;invincible=old_invincible;health=old_health
	companion.handoff(delta)
	if return_torch:torch.drop(player+Vector2(0,-18))
	for field in carried_weapon:set(field,carried_weapon[field])
	for shot in carried_shots:shot.pos+=delta;shots.append(shot)
	for item in carried_prints:item.pos+=delta;footprints.append(item)
	for item in carried_particles:item.pos+=delta;particles.append(item)
	save_data.level=destination;transition=false
	if is_instance_valid(fog):fog.visible=level==1
	update_fog();find_nearest();update_hud();sync_room_theme();persist()

func corridor_position(pos: Vector2) -> void:
	var travel_direction := (pos-player).normalized()
	if travel_direction.length()>.1:walk_facing=travel_direction
	stride_distance+=pos.distance_to(player)
	player = pos
	if stride_distance>=24 and travel_direction.length()>.1:
		stride_distance=fmod(stride_distance,24.0);leave_footprint(travel_direction)
	camera = camera_target()

func begin_task(kind: String, target: Vector2, duration: float) -> void:
	task_return_direction=direction;task_return_facing=walk_facing;task_return_aim=aim
	task_kind = kind
	task_target = target
	task_time = duration
	task_duration = duration
	moving = false
	var toward := target-player
	walk_facing=toward.normalized()
	if absf(toward.x)>absf(toward.y):direction=1 if toward.x<0 else 3
	else:direction=0 if toward.y<0 else 2
	sfx("axe" if kind.begins_with("axe:") else "shears" if kind.begins_with("snip") else "rake" if kind in ["new_bed"] or kind.begins_with("uproot:") else "rake" if kind.begins_with("rake:") else "fill" if kind=="fill" else "step_grass" if kind.begins_with("dig:") else "paper" if kind.begins_with("fertilize:") else "water")

func update_tasks(delta: float) -> void:
	if task_time<=0: return
	task_time -= delta
	if task_time>0: return
	if world_tools.complete(task_kind,task_target):pass
	elif task_kind=="fill":
		water = 6
		save_data.water = water
		notify(tx("water_filled"))
	elif task_kind.begins_with("water:"):
		var id := task_kind.trim_prefix("water:")
		stats.add(self,"waterings")
		water -= 1
		save_data.water = water
		plants[id].remaining = [8.0,12.0][clampi(int(plants[id].stage),0,1)]*(.75+world_tools.variant(id)*.15)
		burst(task_target,12,Color("9fdce1"))
	elif task_kind.begins_with("dig:"):
		world_tools.excavate(task_target)
	elif task_kind.begins_with("rake:"):
		save_data.cleaned.append(task_kind.trim_prefix("rake:"));burst(task_target,8,Color("8ca465"))
	elif task_kind.begins_with("fertilize:"):
		fertilized.append(task_kind.trim_prefix("fertilize:"));burst(task_target,10,Color("c8aa7d"))
	if task_kind.begins_with("dig:"):normalize_dig_site()
	direction=task_return_direction;walk_facing=task_return_facing;aim=task_return_aim
	persist()

func update_plants(delta: float) -> void:
	for id in plants:
		var plant: Dictionary = plants[id]
		if float(plant.remaining)<=0: continue
		plant.remaining = maxf(0,float(plant.remaining)-delta)
		if plant.remaining==0:
			plant.stage = mini(2,int(plant.stage)+1)
			if plant.stage==2 and id not in watered:
				stats.add(self,"blooms")
				watered.append(id)
				save_data.watered = watered.duplicate()
				sfx("chime")
			persist()

func damage_enemy(index: int, damage: float, push: Vector2) -> void:
	if index<0 or index>=enemies.size(): return
	var enemy := enemies[index]
	if enemy.state=="spawn": return
	damage_numbers.append({"pos":enemy.pos+Vector2(randf_range(-10,10),-65),"value":snappedf(minf(damage,float(enemy.hp)),.1),"life":.85})
	enemy.hit_until=time+.18
	if not room_remains.has(level):room_remains[level]=[]
	var pool := Vector2(roundf(enemy.pos.x/28)*28,roundf(enemy.pos.y/28)*28)
	if not room_remains[level].any(func(r):return r.kind=="blood_pool" and r.pos.distance_to(pool)<20):
		room_remains[level].append({"kind":"blood_pool","pos":pool+Vector2(0,5),"scale":randf_range(1.0,1.5)})
	for n in range(22):particles.append({"pos":enemy.pos+Vector2(0,-28),"vel":Vector2(randf_range(-65,65),randf_range(-85,0)),"life":randf_range(.3,.6),"color":Color("c74960"),"heart":false})
	if weapon=="sword": sfx("sword_hit")
	enemy.hp -= damage
	enemy.alert=4.0;enemy.aggro=true
	if not enemy.get("boss",false):enemy.state = "rest";enemy.timer = .3
	var target: Vector2 = enemy.pos+push
	if not blocked(target): enemy.pos=target
	burst(enemy.pos,8,Color("e9c2d5"))
	if enemy.hp<=0:
		stats.add(self,"kills")
		room_remains[level].append({"kind":"corpse"+str(5 if enemy.get("boss",false) else 6 if enemy.type in [5,6] else 7 if enemy.type==7 else int(enemy.type)),"pos":enemy.pos,"scale":1.8 if enemy.get("boss",false) else .72 if enemy.type==5 else 1.0})
		enemies.remove_at(index)

func update_shots(delta: float) -> void:
	for i in range(shots.size()-1,-1,-1):
		var shot := shots[i]
		if float(shot.life)<=0 or not Vector2(shot.vel).is_finite() or Vector2(shot.vel).length_squared()<.001:
			shots.remove_at(i);continue
		if shot.kind in ["enemy_bullet","enemy_rocket"]:
			battle.normalize_projectile(shot)
			if float(shot.range_left)<=.25:shots.remove_at(i);continue
		shot.age += delta
		if shot.kind=="rpg":shot.vel=shot.vel.normalized()*(75.0+425.0*(1.0-exp(-shot.age*2.7)))
		var start: Vector2 = shot.pos
		var motion:Vector2=shot.vel*delta
		if shot.kind in ["enemy_bullet","enemy_rocket"] and shot.has("range_left"):motion=motion.limit_length(maxf(0,float(shot.range_left)))
		var end: Vector2 = start+motion
		var segment := end-start
		var distance := segment.length()
		var wall_t := 1.1
		for step in range(1,maxi(2,ceili(distance/8.0)+1)):
			var t := minf(1.0,float(step)*8.0/maxf(distance,.001))
			if blocked(start.lerp(end,t)):wall_t=t;break
		if shot.kind in ["enemy_bullet","enemy_rocket"]:
			var t:=clampf((player+Vector2(0,-26)-start).dot(segment)/maxf(.001,segment.length_squared()),0,1)
			var contact:=start.lerp(end,t).distance_to(player+Vector2(0,-26))<18 and t<=wall_t
			shot.pos=end;shot.life-=delta
			if shot.has("range_left"):shot.range_left=maxf(0,float(shot.range_left)-motion.length())
			var expired:bool=shot.life<=0 or float(shot.get("range_left",1))<=.25
			if contact:hurt(float(shot.get("damage",1.0)))
			if shot.kind=="enemy_rocket" and (contact or wall_t<=1 or expired):burst(end,18,Color("ee9d59"));sfx_at("rpg_explosion",end)
			if contact or wall_t<=1 or expired:shots.remove_at(i)
			continue
		var hit_index := -1
		var hit_t := wall_t
		for j in range(enemies.size()):
			var enemy := enemies[j]
			if enemy.state=="spawn":continue
			var center: Vector2 = enemy.pos+Vector2(0,-24 if enemy.get("boss",false) else -16)
			var radius := 48.0 if enemy.get("boss",false) else 22.0 if enemy.type==5 else 30.0
			var offset := start-center
			var a := segment.length_squared()
			if a<.0001:
				if offset.length()<=radius and hit_t>0:hit_t=0;hit_index=j
				continue
			var b := 2.0*offset.dot(segment)
			var c := offset.length_squared()-radius*radius
			var discriminant := b*b-4*a*c
			if discriminant<0:continue
			var t := 0.0 if c<=0 else (-b-sqrt(discriminant))/(2*a)
			if t>=0 and t<=1 and t<hit_t:hit_t=t;hit_index=j
		shot.pos=start.lerp(end,minf(1.0,hit_t))
		shot.life-=delta
		if shot.kind=="rpg" and particles.size()<420:
			particles.append({"pos":shot.pos-shot.vel.normalized()*12,"vel":-shot.vel.normalized()*22,"life":.55,"color":Color(.5,.47,.44,.35),"heart":false})
		var hit: bool = hit_index>=0 or wall_t<=1 or shot.life<=0
		if not hit:continue
		if shot.kind=="rpg":
			shake=maxf(shake,10.0*clampf(1-player.distance_to(shot.pos)/750,0,1));sfx_at("rpg_explosion",shot.pos);burst(shot.pos,42,Color("ffd69c"))
		if hit_index>=0:damage_enemy(hit_index,99.0 if shot.kind=="rpg" else 8.5,shot.vel.normalized()*9)
		shots.remove_at(i)

func draw_extra_effects() -> void:
	if level==4 and inside_main_room() and wave>0 and not combat_done and playing:
		var p:=screen(player)+Vector2(-27,-104)
		draw_rect(Rect2(p-Vector2.ONE,Vector2(56,9)),Color("292735"));draw_rect(Rect2(p,Vector2(54,7)),Color("574153"))
		draw_rect(Rect2(p,Vector2(54*clampf(health/8.0,0,1),7)),Color("d38fa8") if invincible>0 else Color("99b990"))
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
		elif shot.kind=="enemy_rocket":
			draw_set_transform(p,shot.vel.angle());draw_sprite("rocket_item",Vector2(0,20),Color.WHITE,.55);draw_set_transform(Vector2.ZERO)
			draw_circle(p-shot.vel.normalized()*13,randf_range(4,7),Color("ffc56b"))
		elif shot.kind=="enemy_bullet":battle.draw_bullet(shot,p)
		else:battle.draw_bullet(shot,p)
	if (level==4 or save_data.finished) and not weapon.is_empty():
		var p := screen(player)+Vector2(14,-28)-aim*(attack_flash/.22)*(14.0 if weapon=="rpg" else 11.5)
		var swing := sin((1-attack_flash/.22)*PI)*1.5 if weapon=="sword" and attack_flash>0 else 0.0
		var left := aim.x<0
		var rotation := (aim.angle()+PI/2) if weapon=="sword" else (atan2(-aim.y,-aim.x) if left else aim.angle())
		draw_set_transform(p,rotation+swing,Vector2(-1 if left and weapon!="sword" else 1,1))
		if weapon=="rpg":draw_texture_rect(rpg_textures["empty" if rpg_reload>0 else "loaded"],Rect2(Vector2(-32,-18),Vector2(76.8,38.4)),false)
		else:draw_sprite("weapon_"+weapon,Vector2(0,0 if weapon=="sword" else 20),Color.WHITE,.6)
		draw_set_transform(Vector2.ZERO)
		if attack_flash>0 and weapon=="sword":
			var angle := aim.angle()
			var progress := 1.0-attack_flash/.22
			for trail in range(4):
				var sweep := angle-1.2+progress*2.4-trail*.12
				draw_arc(screen(player)+Vector2(0,-20),95+trail*5,sweep-.65,sweep+.2,18,Color(1,.93,.79,(1-progress)*(.55-trail*.1)),4-trail*.5)
		if attack_flash>0 and weapon!="sword":
			var muzzle := screen(rifle_muzzle()) if weapon=="rifle" else screen(rpg_muzzle())
			draw_texture_rect(glow,Rect2(muzzle-Vector2(30,30),Vector2(60,60)),false,Color(1,.8,.5,attack_flash*4))
	if weapon=="rpg" and rpg_reload>0 and (level==4 or save_data.finished):
		var bar := screen(player)+Vector2(-25,-95)
		draw_rect(Rect2(bar,Vector2(50,5)),INK);draw_rect(Rect2(bar,Vector2(50*(1-rpg_reload/RPG_RELOAD),5)),CREAM)
		if rpg_reload<.3:
			var insertion := screen(player)+Vector2(14,-28)-aim*(rpg_reload/.3)*26
			draw_set_transform(insertion,aim.angle());draw_sprite("rocket_item",Vector2(0,16),Color.WHITE,.45);draw_set_transform(Vector2.ZERO)
	if weapon=="rifle" and (level==4 or save_data.finished):
		draw_string(body_font,screen(player)+Vector2(6,-55),str(magazine)+"/30",HORIZONTAL_ALIGNMENT_LEFT,-1,13,CREAM)
		if reload_time>0:
			var bar := screen(player)+Vector2(-28,-102)
			draw_rect(Rect2(bar,Vector2(56,6)),INK);draw_rect(Rect2(bar,Vector2(56*(1-reload_time/1.8),6)),CREAM)
	if held_item in ["can","rake","fertilizer","shovel","flashlight","axe","shears","drill"]:
		var pose:=held_tool_pose()
		var texture:String="fertilizer_open" if task_time>0 and task_kind.begins_with("fertilize:") else "shears_closed" if held_item=="shears" and task_time>0 and task_time<task_duration*.55 else "drill_spin"+str(int(time*22)%2) if held_item=="drill" and world_tools.drilling else held_item
		draw_set_transform(screen(pose.hand),pose.angle,pose.flip)
		var id:int=sprites[texture]
		draw_texture_rect_region(atlas,Rect2(-pose.anchor*pose.scale,Vector2(32,48)*pose.scale),Rect2(Vector2(id%16*32,id/16*48),Vector2(32,48)))
		draw_set_transform(Vector2.ZERO)
	if task_time>0 and (task_kind=="fill" or task_kind.begins_with("water:") or task_kind.begins_with("rake:") or task_kind.begins_with("fertilize:")):
		var pose:=held_tool_pose()
		var origin:=screen(pose.tip)
		var target:=screen(task_target)+Vector2(0,-10)
		if task_kind=="fill":origin=target+Vector2(0,-45);target=screen(pose.hand)+Vector2(0,10)
		var watering:=task_kind=="fill" or task_kind.begins_with("water:")
		for i in range(22 if watering else 12):
			var progress:=fposmod((task_duration-task_time)*2.1+i*.047,1.0)
			var drop:=origin.lerp(target,progress)+Vector2(sin(i*3.1)*2,progress*progress*8)
			draw_rect(Rect2(drop,Vector2(2,3) if watering else Vector2(2,2)),Color("b8e8ed") if watering else Color("8b9c61") if task_kind.begins_with("rake:") else Color("e4c99d"))
		var bar:=screen(player)+Vector2(-25,-93)
		draw_rect(Rect2(bar,Vector2(50,5)),INK)
		draw_rect(Rect2(bar,Vector2(50*clampf(1-task_time/maxf(.01,task_duration),0,1),5)),PINK)

func setup_fog() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 1
	add_child(layer)
	fog = ColorRect.new()
	fog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader:=preload("res://shaders/flashlight.gdshader")
	var material := ShaderMaterial.new()
	material.shader = shader
	fog.material = material
	layer.add_child(fog)

func update_fog() -> void:
	if not is_instance_valid(fog):return
	if level!=1:fog.visible=false;return
	var material: ShaderMaterial = fog.material
	var north:=clampf(player.y/(5*TILE),0,1)
	var south:=clampf((grid.size()*TILE-player.y)/(5*TILE),0,1)
	var opacity:=smoothstep(0,1,minf(north,south))
	fog.visible=true
	material.set_shader_parameter("room_band",Vector2(screen(Vector2(0,5*TILE)).y,screen(Vector2(0,(grid.size()-5)*TILE)).y))
	material.set_shader_parameter("room_opacity",opacity)
	if not fog.visible:return
	var facing: Vector2 = walk_facing.normalized()
	if joy_vector.length()>.2: facing=joy_vector.normalized()
	material.set_shader_parameter("light_pos",screen(held_tool_pose().tip) if held_item=="flashlight" else screen(player)+Vector2(14,-33))
	material.set_shader_parameter("hero_pos",screen(player)+Vector2(0,-35))
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
	var spec: Dictionary = obstacle_specs[index]
	var width: float = spec.width
	var phase: float = room_clock*float(spec.speed)+float(spec.phase)
	var sway := sin(phase+sin(phase*.61)*float(spec.warp))
	var center := Vector2(13.5*TILE+sway*(215-width*.5),(10.5+index*4.4)*TILE)
	return Rect2(center-Vector2(width*.5,14),Vector2(width,28))

func update_new_rooms(delta: float) -> void:
	room_clock += delta
	if level==1:
		skull_clock -= delta
		if skull_clock<=0:
			skull_clock=randf_range(2.0,3.5)
			if held_item=="flashlight":
				var facing: Vector2 = walk_facing.normalized()
				if joy_vector.length()>.2:facing=joy_vector.normalized()
				for attempt in range(6):
					var pos := player+Vector2(14,-33)+facing.rotated(randf_range(-.25,.25))*randf_range(75,145)
					if not blocked(pos):skulls.append({"pos":pos,"life":.8});break

		for i in range(skulls.size()-1,-1,-1):
			skulls[i].life -= delta
			if skulls[i].life<=0: skulls.remove_at(i)
	elif level==2:
		obstacle_cooldown=maxf(0,obstacle_cooldown-delta)
		for i in range(5):
			var obstacle := obstacle_rect(i)
			if obstacle.grow(10).has_point(player) and obstacle_cooldown<=0:
				player=Vector2(13.5,grid.size()-7.5)*TILE
				obstacle_cooldown=.65
				shake=5;sfx("hurt");haptic(25);notify(tx("obstacle_retry"))
			if player.y<obstacle.position.y-24 and i not in save_data.obstacles:
				save_data.obstacles.append(i);persist()

func draw_new_rooms() -> void:
	if level==1:
		for skull in skulls:
			draw_sprite("skull",screen(skull.pos),Color(1,1,1,minf(1,skull.life)))
	elif level==2:
		for i in range(5):
			var rect := obstacle_rect(i)
			var y := screen(rect.get_center()).y
			draw_line(screen(Vector2(9*TILE,rect.get_center().y)),screen(Vector2(18*TILE,rect.get_center().y)),Color("786878"),5)
			for x in range(int(rect.size.x/40)): draw_sprite("moving_bar",Vector2(screen(rect.position).x+x*40+20,y+16))
			var middle := screen(rect.get_center())
			draw_texture_rect(glow,Rect2(middle-Vector2(55,55),Vector2(110,110)),false,Color(1,.7,.4,.5))

func cycle_weapon() -> void:
	var inventory: Array = save_data.weapons_taken
	if inventory.is_empty(): return
	weapon = inventory[(inventory.find(weapon)+1)%inventory.size()]
	persist();sfx("ui")

func dig_here() -> void:
	if task_time>0:return
	var pos:Vector2=world_tools.ground_point()
	if not world_tools.soil(pos):notify(tx("digging_bounds"));return
	if world_tools.has_sample(pos):return
	begin_task("dig:%d:%d"%[pos.x,pos.y],pos,.25)

func draw_corridor_extensions() -> Array[Dictionary]:
	var walls:Array[Dictionary]=[]
	var north := 15 if level==0 else 13
	var south := 13
	for end in [0,1]:
		if (level==0 and end==1) or (level==6 and end==0):continue
		var center:int=north if end==0 else south
		for j in range(1,25):
			var y:=-j if end==0 else grid.size()-1+j
			if (end==0 and y*TILE < -HALL_SEAM*2-5*TILE) or (end==1 and y*TILE >= grid.size()*TILE+HALL_SEAM*2+5*TILE):continue
			if screen(Vector2(0,y*TILE)).y < -120 or screen(Vector2(0,y*TILE)).y>get_viewport_rect().size.y+120:continue
			for x in range(center-2,center+3):
				var pos:=screen(Vector2(x,y)*TILE)
				draw_texture_rect_region(ground,Rect2(pos,Vector2(48,48)),Rect2(Vector2(24,0),Vector2(24,24)))
				if x==center-2 or x==center+2:walls.append({"kind":"stone","id":"","pos":Vector2(x+.5,y+.5)*TILE,"wall":true})
	return walls

func valid_ground(pos: Vector2) -> bool:
	if pos.x<0 or pos.y<0 or pos.x>=grid[0].length()*TILE or pos.y>=grid.size()*TILE: return false
	var c := Vector2i(pos/TILE)
	return c.x>=0 and c.y>=0 and c.y<grid.size() and c.x<grid[0].length() and grid[c.y][c.x]=="."

func finish_room_layout(rng: RandomNumberGenerator) -> void:
	if level==0:
		for x in range(15,30):set_cell(x,6,".")
		for y in range(grid.size()-5,grid.size()):grid[y]=" ".repeat(grid[0].length())
		grid[grid.size()-6]="#".repeat(grid[0].length())
	if level==6:
		put_object("skull_stand",Vector2i(4,14),"skull_stand",true)
		put_object("secret_book",Vector2i(4,10),"secret_book",true)
		put_object("stats_stone",Vector2i(22,10),"stats_stone",true)
		put_object("letter_box",Vector2i(4,18),"letter_archive",true)
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
		for obj in objects:
			if obj.kind=="stand_flashlight":obj.pos=Vector2(14.1,grid.size()-2.5)*TILE
		for spec in [["house",Vector2i(10,12)],["pond",Vector2i(19,15)],["bench",Vector2i(17,19)],["tree",Vector2i(8,17)],["tree",Vector2i(20,10)]]:
			put_object(spec[0],spec[1],"seat" if spec[0]=="bench" else "",true)
	if level in [1,5]:scatter_room_props(rng)
	if level==1:
		for obj in objects.duplicate():
			if obj.kind=="house":objects.append({"kind":"house_door","id":"house_door","pos":obj.pos+Vector2(0,.5),"solid":false,"opened":save_data.get("house_open",false)});objects.append({"kind":"skull_relic","id":"skull_relic","pos":obj.pos+Vector2(0,14),"solid":false})
	# Do not place trees on hedge cells or shuffle previously opened doors.
	var candidates: Array[Vector2] = []
	for y in range(8,grid.size()-8):
		for x in range(2,grid[0].length()-2):
			var pos := Vector2(x+.5,y+.5)*TILE
			if valid_ground(pos) and not blocked(pos) and not objects.any(func(o): return o.kind in ["house","pond"] and Rect2(o.pos-Vector2(75,160),Vector2(150,185)).has_point(pos)):candidates.append(pos)
	for obj in objects:
		if obj.id=="final_hint":
			obj.pos=Vector2(rng.randf_range(9.5,17.5),grid.size()-8.5)*TILE
			continue
		if obj.id=="crossing":
			obj.pos=Vector2(rng.randf_range(10.5,16.5),21.5)*TILE
			continue
		if (obj.kind!="note" and obj.id!="courage") or obj.id=="buried":continue
		if candidates.is_empty():break
		var index := rng.randi_range(0,candidates.size()-1)
		obj.pos=candidates[index];candidates.remove_at(index)
	if level==3 and save_data.buried_exposed and "buried" not in save_data.letters:
		objects.append({"kind":"note","id":"buried","pos":Vector2(save_data.dig_target[0],save_data.dig_target[1]),"solid":false})

func scatter_room_props(rng: RandomNumberGenerator) -> void:
	# Each new game's seed places landmarks and tools independently across the room.
	# Saves rebuild the exact same layout; returning through a corridor never rerolls it.
	var kinds:=["house","pond","bench","tree","tree_apples","well","swing","can","rake","fertilizer","stand_flashlight"]
	var placed:Array[Dictionary]=[]
	for obj in objects:
		if obj.kind not in kinds or obj.get("ground_tool",false):continue
		if obj.kind=="stand_flashlight":continue # Its pedestal belongs in the entrance corridor.
		for attempt in range(180):
			var candidate:=Vector2(rng.randf_range(3.5,grid[0].length()-3.5),rng.randf_range(9.5,grid.size()-9.5))*TILE
			var radius:=105.0 if obj.kind in ["house","pond"] else 64.0
			if not valid_ground(candidate) or blocked(candidate):continue
			if placed.any(func(other):return candidate.distance_to(other.pos)<radius+float(other.radius)):continue
			obj.pos=candidate;placed.append({"pos":candidate,"radius":radius});break

func prepare_foliage_and_paths(rng: RandomNumberGenerator) -> void:
	if level==0:
		var edges: Array[Vector2i] = []
		for y in range(8,grid.size()-8):
			for x in range(2,grid[0].length()-2):
				if grid[y][x]!="#":continue
				if objects.any(func(obj):return obj.kind=="cat_hut" and obj.pos.distance_to(Vector2(x+.5,y+.5)*TILE)<100):continue
				if grid[y][x-1]=="." or grid[y][x+1]=="." or grid[y-1][x]=="." or grid[y+1][x]==".":edges.append(Vector2i(x,y))
		for obj in objects:
			if not str(obj.id).begins_with("secret"):continue
			var n := rng.randi_range(0,edges.size()-1)
			obj.pos=(Vector2(edges[n])+Vector2(.5,.5))*TILE;obj.hidden_hedge=true;edges.remove_at(n)
		for i in range(mini(12,edges.size())):
			var n := rng.randi_range(0,edges.size()-1)
			var cell := edges[n];edges.remove_at(n)
			var id := "berry_%d_%d"%[cell.x,cell.y]
			berry_cells[cell]=id
			put_object("berries",cell,id)
	if level not in [1,5]:return
	# A main garden walk connects the two doors; each destination joins it once.
	generating_paths=true
	var start:=Vector2(13.5,grid.size()-6.5)*TILE
	var end:=Vector2(13.5,7.5)*TILE
	var spine:=Curve2D.new();spine.bake_interval=6
	var spine_points:Array[Vector2]=[start]
	for n in range(1,5):
		var point:=start.lerp(end,float(n)/5)
		point.x+=rng.randf_range(-200,240);point.y+=rng.randf_range(-38,38)
		spine_points.append(point)
	spine_points.append(end)
	for n in range(spine_points.size()):
		var tangent:Vector2=(spine_points[mini(n+1,spine_points.size()-1)]-spine_points[maxi(0,n-1)])/7
		spine.add_point(spine_points[n],-tangent,tangent)
	var main_path:=roughen_path(continuous_path(spine.get_baked_points(),start,end,rng),int(save_data.seed)+level)
	if main_path.size()>1:paths.append(main_path);path_terminals.append(false)
	if main_path.size()>12:
		# A second independent walk reconnects with the main route at both ends.
		var from:=main_path[int(main_path.size()*.15)]
		var to:=main_path[int(main_path.size()*.82)]
		var left_x:=start.x-rng.randf_range(360,420)
		var knots:Array[Vector2]=[from,Vector2(left_x+rng.randf_range(-25,25),start.lerp(end,.34).y),Vector2(left_x+rng.randf_range(-25,25),start.lerp(end,.69).y),to]
		var alternate:=Curve2D.new();alternate.bake_interval=6
		for n in range(knots.size()):
			var handle:Vector2=(knots[mini(n+1,knots.size()-1)]-knots[maxi(0,n-1)])/5
			alternate.add_point(knots[n],-handle,handle)
		paths.append(roughen_path(alternate.get_baked_points(),int(save_data.seed)+9811));path_terminals.append(false)
	path_pads.append({"pos":start,"radius":43.0})
	path_pads.append({"pos":end,"radius":43.0})
	var targets:Array[Dictionary]=[]
	for obj in objects:
		if obj.kind=="stand_flashlight" and corridor_row(floori(obj.pos.y/TILE)):continue
		if obj.kind in ["sprout","well","bench","swing","can","rake","fertilizer","note","stand_flashlight","house","pond","accessory"]:
			var radius:=90.0 if obj.kind=="house" else 80.0 if obj.kind=="pond" else 52.0 if obj.kind in ["well","bench","swing"] else 42.0 if obj.kind=="sprout" else 30.0
			obj.path_pad_radius=radius
			path_pads.append({"pos":obj.pos,"radius":radius})
			targets.append(obj)
	while not targets.is_empty():
		var best:=INF;var selected:=0;var anchor:=start
		for n in range(targets.size()):
			for path in anchor_paths(targets[n]):
				for point in path:
					var distance:float=point.distance_to(targets[n].pos)
					if distance<best:best=distance;selected=n;anchor=point
		var target:Dictionary=targets[selected];targets.remove_at(selected)
		var radius:float=target.path_pad_radius
		if best<=radius*.65:continue
		# Select a clear approach from the existing walk instead of routing
		# around an object. The shortest visible gentle curve wins.
		var branch:=PackedVector2Array()
		var approach_cost:=INF
		var clearance:=path_clearance_grid()
		var bend_fraction:=rng.randf_range(.34,.52)*(1 if rng.randf()<.5 else -1)
		for path in anchor_paths(target):
			for sample in range(0,path.size(),6):
				var candidate:Vector2=path[sample]
				var distance:float=candidate.distance_to(target.pos)
				if distance>=approach_cost:continue
				var outward:Vector2=(candidate-target.pos).normalized()
				var tip:Vector2=target.pos+outward*radius*.15
				var side:Vector2=(tip-candidate).normalized().orthogonal()
				for bend_sign in [-1,1]:
					var bend_amount:=clampf(distance*absf(bend_fraction)*bend_sign,-180,180)
					var curve:=Curve2D.new();curve.bake_interval=6
					# Broad offset waypoints give a wandering route, not a direct link.
					var waypoint_a:=candidate.lerp(tip,.34)+side*bend_amount
					var waypoint_b:=candidate.lerp(tip,.7)+side*bend_amount*.45
					var knots:Array[Vector2]=[candidate,waypoint_a,waypoint_b,tip]
					for k in range(knots.size()):
						var handle:Vector2=(knots[mini(k+1,knots.size()-1)]-knots[maxi(0,k-1)])/5
						curve.add_point(knots[k],-handle,handle)
					var points:=roughen_path(curve.get_baked_points(),int(save_data.seed)+selected*137+level*731)
					var clear:=true
					for point in points:
						if not path_point_safe(point):clear=false;break
					if clear:
						var cost:=distance+parallel_path_cost(points,clearance)
						if cost<approach_cost:branch=points;approach_cost=cost
		if branch.size()<2:continue
		# Begin at the last shared contact, so close parallel strips cannot form loops.
		var merge:=0;var junction:=branch[0]
		for n in range(branch.size()-2):
			for path in paths:
				for point in path:
					if branch[n].distance_to(point)<20:merge=n;junction=point;break
		var trimmed:=PackedVector2Array([junction])
		for n in range(merge+1,branch.size()):trimmed.append(branch[n])
		if trimmed.size()>1:
			paths.append(trimmed);path_terminals.append(true)
			path_targets.append({"id":target.id,"object":target,"path":paths.size()-1,"end":trimmed[-1]})
	generating_paths=false
	build_path_meshes()

func path_clearance_grid() -> Dictionary:
	var cells:Dictionary={}
	for path in paths:
		for n in range(1,path.size()-1,6):
			var cell:=Vector2i(path[n]/112)
			if not cells.has(cell):cells[cell]=[]
			cells[cell].append({"pos":path[n],"tangent":(path[n+1]-path[n-1]).normalized()})
	return cells

func parallel_path_cost(points: PackedVector2Array, cells: Dictionary) -> float:
	var penalty:=0.0
	for n in range(9,points.size()-9,6):
		var centre:=Vector2i(points[n]/112)
		var tangent:Vector2=(points[n+1]-points[n-1]).normalized()
		var nearest:=112.0
		var shared:=false
		for y in range(centre.y-1,centre.y+2):
			for x in range(centre.x-1,centre.x+2):
				for other in cells.get(Vector2i(x,y),[]):
					var distance:float=points[n].distance_to(other.pos)
					if distance<20:nearest=112;shared=true;break
					if absf(tangent.dot(other.tangent))>.82:nearest=minf(nearest,distance)
		if not shared:penalty+=maxf(0,112-nearest)*1.5
	return penalty

func anchor_paths(target: Dictionary) -> Array:
	# Nearby tools can form a short sequence. Other destinations branch off
	# the two main walks; some beds may share a smaller branch and a fork.
	if target.kind in ["can","rake","fertilizer"] or (target.kind=="sprout" and int(target.id)%3==1):return paths
	return paths.slice(0,mini(2,paths.size()))

func roughen_path(points: PackedVector2Array, path_seed: int) -> PackedVector2Array:
	if points.size()<3:return points
	var noise:=FastNoiseLite.new();noise.seed=path_seed;noise.frequency=.014;noise.fractal_octaves=3
	var result:=points.duplicate()
	var travelled:=0.0;var total:=0.0
	for n in range(1,points.size()):total+=points[n].distance_to(points[n-1])
	for n in range(1,points.size()-1):
		travelled+=points[n].distance_to(points[n-1])
		var strength:=clampf(minf(travelled,total-travelled)/40,0,1)
		var tangent:Vector2=(points[n+1]-points[n-1]).normalized()
		var candidate:=points[n]+tangent.orthogonal()*noise.get_noise_2d(points[n].x,points[n].y)*16*strength
		if valid_ground(candidate):result[n]=candidate
	return result

func draw_paths() -> void:
	if path_texture!=null:
		draw_texture_rect(path_texture,Rect2(screen(Vector2.ZERO),Vector2(grid[0].length(),grid.size())*TILE),false)

func update_vegetation(delta: float) -> void:
	if hedge_field!=null:hedge_field.update(delta,player)
	var contact := false
	for obj in objects:
		if obj.kind not in ["flowers","blueflowers"]:continue
		var away: Vector2 = obj.pos-player
		var target := clampf((25-away.length())/15,0,1)
		if away.length()<25:contact=true
		if target>.01 or obj.has("press"):obj.press=lerpf(float(obj.get("press",0)),target,1-exp(-delta*11))
	foliage_contact=contact
	var intent:=joy_vector.length() if joy_active else 0.0
	foliage_motion=maxf(hedge_field.contact_strength if hedge_field!=null else 0.0,1.0 if contact else 0.0)*minf(1,intent*2)
	if hedge_field!=null:foliage_motion=maxf(foliage_motion,clampf((hedge_field.motion_strength-3)/90,0,1)*.3)

func update_foliage_audio(delta: float) -> void:
	if not is_instance_valid(foliage_voice):return
	var target:=foliage_motion if sound_on and playing and not paused and not transition and task_time<=0 else 0.0
	# One continuous recording, with gain envelopes. No periodic play()/stop() retriggers.
	foliage_gain=move_toward(foliage_gain,target,delta*(12 if target>foliage_gain else 5))
	if foliage_gain>.001:
		foliage_voice.volume_db=-18+linear_to_db(maxf(.001,foliage_gain*foliage_gain))
		if not foliage_voice.playing:foliage_voice.play()
	elif foliage_voice.playing:foliage_voice.stop()

var buried_paper_cache: Dictionary = {}
func draw_buried_paper(pos: Vector2, opened: bool) -> void:
	var name := "note_open" if opened else "note"
	if not buried_paper_cache.has(name):
		var source := atlas.get_image()
		var id: int = sprites[name]
		var image := Image.create(32,48,false,Image.FORMAT_RGBA8)
		for y in range(16 if opened else 26,43):
			for x in range(5,28):
				if y>=37 and Vector2((x-16)/10.0,(y-37)/5.0).length()>.9:continue
				image.set_pixel(x,y,source.get_pixel(id%16*32+x,id/16*48+y))
		buried_paper_cache[name]=ImageTexture.create_from_image(image)
	draw_texture_rect(buried_paper_cache[name],Rect2(pos-Vector2(32,86),Vector2(64,96)),false)


func build_path_meshes() -> void:
	# Rasterise the whole network once. Shared junctions become one surface,
	# with no overlapping strips, stone borders, caps or camera-dependent edges.
	var size:=Vector2i(grid[0].length()*24,grid.size()*24)
	var coverage:=PackedFloat32Array();coverage.resize(size.x*size.y)
	for path_index in range(paths.size()):
		var path:PackedVector2Array=paths[path_index]
		var remaining:=0.0
		var distances:Array[float]=[];distances.resize(path.size())
		for n in range(path.size()-2,-1,-1):remaining+=path[n].distance_to(path[n+1]);distances[n]=remaining
		var terminal:=false
		for n in range(path.size()-1):
			var steps:=maxi(1,ceili(path[n].distance_to(path[n+1])/2))
			for step in range(steps):
				var t:=float(step)/steps
				var point:=path[n].lerp(path[n+1],t)/2
				var left:=lerpf(distances[n],distances[n+1],t)
				var radius:=7.5*(sqrt(clampf(left/42,0,1)) if terminal else 1.0)
				for y in range(maxi(0,int(point.y-9)),mini(size.y,int(point.y+10))):
					for x in range(maxi(0,int(point.x-9)),mini(size.x,int(point.x+10))):
						var distance:=((Vector2(x+.5,y+.5)-point)/Vector2(1,GROUND_DEPTH)).length()
						var value:=radius-distance
						coverage[y*size.x+x]=maxf(coverage[y*size.x+x],value+.01)
	# Pads and walks share the same union field and the same opaque soil pixels.
	for pad in path_pads:
		var centre:Vector2=pad.pos/2
		var radius:float=pad.radius/2
		for y in range(maxi(0,int(centre.y-radius*GROUND_DEPTH-1)),mini(size.y,int(centre.y+radius*GROUND_DEPTH+2))):
			for x in range(maxi(0,int(centre.x-radius-1)),mini(size.x,int(centre.x+radius+2))):
				var value:=radius-((Vector2(x+.5,y+.5)-centre)/Vector2(1,GROUND_DEPTH)).length()
				coverage[y*size.x+x]=maxf(coverage[y*size.x+x],value)
	var image:=Image.create(size.x,size.y,false,Image.FORMAT_RGBA8)
	for y in range(size.y):
		for x in range(size.x):
			var value:=coverage[y*size.x+x]
			if value<=0:continue
			var noise:=posmod((x/2)*73+(y/2)*137+int(save_data.seed),17)
			if value<.75 and noise<6:continue
			var above:=coverage[maxi(0,y-1)*size.x+x]
			var below:=coverage[mini(size.y-1,y+1)*size.x+x]
			var rim:=Color("795b3e") if above>below+.2 else Color("c39b65") if below>above+.2 else Color("967047")
			var color:=rim if value<1.25 else Color("ac8050") if value<2.3 else Color("bc925d")
			if value>2.3 and posmod(x*97+y*71,43)==0:color=Color("cda572")
			image.set_pixel(x,y,color)
	path_texture=ImageTexture.create_from_image(image)

func is_path_terminal(index: int) -> bool:
	if index<path_terminals.size() and not path_terminals[index]:return false
	var tip: Vector2 = paths[index][-1]
	for j in range(paths.size()):
		if j==index:continue
		for point in paths[j]:
			if tip.distance_to(point)<28:return false
	return true

func leave_footprint(direction: Vector2) -> void:
	stats.add(self,"steps")
	left_foot=not left_foot
	var stone := stone_surface(player)
	var position := player-direction*5+direction.orthogonal()*(5 if left_foot else -5)
	footprints.append({"pos":position,"rotation":direction.angle()+PI/2,"life":9.0,"stone":stone})
	if footprints.size()>150:footprints.pop_front()
	for n in range(8):
		if particles.size()>=420:break
		particles.append({"pos":position+Vector2(randf_range(-3,3),0),"vel":-direction*randf_range(5,14)+Vector2(randf_range(-9,9),randf_range(-12,-3)),"life":randf_range(.25,.5),"color":Color("b6ab9b") if stone else Color("a6b786"),"heart":false,"ground":true})

func draw_footprints() -> void:
	var id:int=sprites["footprint"]
	for footprint in footprints:
		draw_set_transform(screen(footprint.pos),footprint.rotation)
		var garden_mark:bool=level==5 and footprint.pos.y>=7*TILE and footprint.pos.y<=(grid.size()-7)*TILE
		var color:=Color("74583f") if footprint.stone and garden_mark else Color("b8ab9a") if footprint.stone else Color("243a2d")
		color.a=(.78 if garden_mark else .56)*minf(1.0,footprint.life/2)
		draw_texture_rect_region(atlas,Rect2(Vector2(-4,-7),Vector2(8,14)),Rect2(Vector2(id%16*32+12,id/16*48+32),Vector2(8,14)),color)
	draw_set_transform(Vector2.ZERO)

func stone_surface(pos: Vector2) -> bool:
	if corridor_floor_point(pos) or corridor_row(floori(pos.y/TILE)):return true
	if level in [4,6]:return true
	for path in paths:
		for point in path:
			if pos.distance_squared_to(point)<225:return true
	return false

func path_point_safe(pos: Vector2) -> bool:
	if generating_paths:return valid_ground(pos)
	return valid_ground(pos) and not blocked(pos) and not objects.any(func(o):return o.solid and pos.distance_to(o.pos)<(110 if o.kind in ["house","pond"] else 72 if o.kind=="well" else 48)) and (generating_paths or not objects.any(func(o):return o.kind=="sprout" and o.pos.distance_to(pos)<45))

func continuous_path(points: PackedVector2Array, start: Vector2, end: Vector2, rng: RandomNumberGenerator) -> PackedVector2Array:
	var safe := true
	for point in points:
		if not path_point_safe(point):safe=false;break
	if safe:return points
	# Route around obstacles rather than splitting a branch into fading fragments.
	if path_navigation==null:
		path_navigation=AStarGrid2D.new();path_navigation.region=Rect2i(0,0,grid[0].length()*3,grid.size()*3)
		path_navigation.cell_size=Vector2(16,16);path_navigation.offset=Vector2(8,8)
		path_navigation.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES;path_navigation.update()
		for y in range(path_navigation.region.size.y):
			for x in range(path_navigation.region.size.x):
				var id := Vector2i(x,y);var pos := Vector2(id)*16+Vector2(8,8)
				path_navigation.set_point_solid(id,not path_point_safe(pos));path_navigation.set_point_weight_scale(id,rng.randf_range(.9,1.2))
	var from := nearest_path_node(start);var to := nearest_path_node(end)
	if from.x<0 or to.x<0:return PackedVector2Array()
	var route := path_navigation.get_point_path(from,to)
	for pass_index in range(8):
		for n in range(1,route.size()-1):
			var point := (route[n-1]+route[n]*2+route[n+1])/4
			if path_point_safe(point) and path_point_safe((point+route[n-1])/2) and path_point_safe((point+route[n+1])/2):route[n]=point
	return route

func nearest_path_node(pos: Vector2) -> Vector2i:
	var origin := Vector2i(pos/16)
	for radius in range(6):
		var best := Vector2i(-1,-1);var distance := INF
		for y in range(origin.y-radius,origin.y+radius+1):
			for x in range(origin.x-radius,origin.x+radius+1):
				var id := Vector2i(x,y)
				if not path_navigation.region.has_point(id) or path_navigation.is_point_solid(id):continue
				var d := pos.distance_squared_to(Vector2(id)*16+Vector2(8,8))
				if d<distance:distance=d;best=id
		if best.x>=0:return best
	return Vector2i(-1,-1)

func sample_line(start: Vector2, end: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	var count := maxi(1,ceili(start.distance_to(end)/8))
	for n in range(count+1):points.append(start.lerp(end,float(n)/count))
	return points

func pushing_hedge(pos: Vector2, input: Vector2) -> bool:
	if level!=0 or input.length()<.35:return false
	return touching_hedge(pos) and blocked(pos+input.normalized()*7)


func prepare_grass_details() -> void:
	var rng := RandomNumberGenerator.new();rng.seed=int(save_data.seed)+level*3763+9181
	for y in range(6,grid.size()-5):
		for x in range(1,grid[0].length()-1):
			if grid[y][x]!="." or rng.randf()>.34:continue
			grass_details.append({"pos":Vector2(x,y)*TILE+Vector2(rng.randf_range(5,43),rng.randf_range(6,44)),"kind":"grass_detail"+str(rng.randi_range(0,7))})

	grass_texture=null
	if level in [4,6]:return
	var base := ground.get_image();base.convert(Image.FORMAT_RGBA8)
	var image := Image.create(grid[0].length()*24,grid.size()*24,false,Image.FORMAT_RGBA8)
	for y in range(grid.size()):
		for x in range(grid[0].length()):image.blit_rect(base,Rect2i(72 if level==0 else 0,0,24,24),Vector2i(x*24,y*24))
	var sheet := atlas.get_image();sheet.convert(Image.FORMAT_RGBA8)
	for detail in grass_details:
		var id: int = sprites[detail.kind]
		var stamp := sheet.get_region(Rect2i(id%16*32,id/16*48,32,48));stamp.resize(19,29,Image.INTERPOLATE_NEAREST)
		image.blend_rect(stamp,Rect2i(0,0,19,29),Vector2i(detail.pos/2)+Vector2i(-10,-20))
	grass_texture=ImageTexture.create_from_image(image)

func draw_grass_details() -> void:
	var viewport := get_viewport_rect().grow(55)
	for detail in grass_details:
		var p := screen(detail.pos)
		if viewport.has_point(p):draw_sprite(detail.kind,p+Vector2(0,12),Color.WHITE,.6)

func level_complete() -> bool:
	match level:
		0:return has_maze_letters()
		1:return dark_letters_found()
		2:return save_data.obstacles.size()>=5 and "crossing" in save_data.letters
		3:return "buried" in save_data.letters
		4:return "courage" in save_data.letters
		5:return "garden" in save_data.letters
	return save_data.finished

func draw_gate(pos: Vector2, amount: float) -> void:
	draw_gate_leaf("gate_panel",pos+Vector2(-72,-65))
	draw_gate_leaf("gate_ajar" if amount>.25 else "gate_panel",pos+Vector2(0,-65))
	if amount<=0:
		draw_sprite("lock_closed",pos+Vector2(0,-23),Color.WHITE,.5)
	else:
		var fall := clampf(amount*2,0,1)
		var lock_pos := pos+Vector2(8*fall,lerpf(-23,30,fall*fall))
		draw_sprite("lock_open_key",lock_pos,Color.WHITE,.5)

func draw_gate_leaf(name: String, pos: Vector2) -> void:
	var id: int = sprites[name]
	draw_texture_rect_region(atlas,Rect2(pos,Vector2(72,68)),Rect2(Vector2(id%16*32,id/16*48+16),Vector2(32,32)))


func sfx_at(name: String, pos: Vector2) -> void:
	if not sound_on or DisplayServer.get_name()=="headless":return
	var distance := player.distance_to(pos)
	if distance>1400:return
	sfx(name)
	var voice := audio_pool[(audio_cursor-1)%audio_pool.size()]
	voice.volume_db-=linear_to_db(1.0+distance/180.0)

func bed_beside_path(pos: Vector2, bed: Dictionary) -> bool:
	if not valid_ground(pos) or not path_pads.any(func(p):return p.pos.distance_to(pos)<1 and p.radius>=40):return false
	for path in paths:
		for point in path:
			if point.distance_to(pos)<42:return true
	return false

func door_is_open(id: String) -> bool:
	return id=="back" or level in save_data.get("open_gates",[])

func draw_cast_shadow(name: String, pos: Vector2, scale_factor: float) -> void:
	var origin := pos-(get_viewport_rect().size/2-camera+shake_offset).round()
	var light := origin+Vector2(-180,-240)
	var nearest_light := INF
	var neutral_hall:=name.begins_with("hero") and not inside_main_room()
	for obj in objects:
		if neutral_hall:break
		if obj.kind not in ["lamp","candle","candle_heart","heart_stand"]:continue
		var d := origin.distance_squared_to(obj.pos)
		if d<nearest_light:nearest_light=d;light=obj.pos-Vector2(0,50)
	if level==1 and save_data.flashlight and not neutral_hall:light=player+aim*30
	var away := (origin-light).normalized()
	var stretch := .25+clampf(origin.distance_to(light)/900,0,.35)
	var flicker := 0.0 if neutral_hall or name in ["tree","tree_apples","hedge_tree","hedge_tree_apples"] else .02*sin(time*4+origin.x*.01)
	var projection:=Transform2D(Vector2(1,0),Vector2(-away.x*(.55+flicker),-away.y*stretch),pos+Vector2(0,3))
	if level not in [1,2,4] and name.begins_with("hero"):
		if absf(projection.determinant())<.01:return
		var quad:=PackedVector2Array()
		for vertex in [Vector2(-32,-86),Vector2(32,-86),Vector2(32,10),Vector2(-32,10)]:quad.append(projection*(vertex*scale_factor))
		draw_floor_shadow(quad,Color(.06,.055,.1,.28),projection,sprites[name],scale_factor)
		return
	if name in ["tree","tree_apples","hedge_tree","hedge_tree_apples"]:
		var world_projection:=projection;world_projection.origin=origin+Vector2(0,3)
		if draw_tree_shadow_clipped(name,world_projection,scale_factor):return
	draw_set_transform_matrix(projection)
	draw_sprite(name,Vector2.ZERO,Color(.06,.055,.1,.28),scale_factor)
	draw_set_transform(Vector2.ZERO)

func draw_tree_shadow_clipped(name: String, projection: Transform2D, scale_factor: float) -> bool:
	if absf(projection.determinant())<.0001:return true
	var integrated:=name.begins_with("hedge_tree")
	var anchor:=Vector2(32,96 if integrated else 86)
	var quad:=PackedVector2Array()
	var bounds:=Rect2()
	for corner in [Vector2.ZERO,Vector2(64,0),Vector2(64,96),Vector2(0,96)]:
		var point:Vector2=projection*((corner-anchor)*scale_factor)
		quad.append(point)
		bounds=Rect2(point,Vector2.ZERO) if quad.size()==1 else bounds.expand(point)
	var map_rect:=Rect2(Vector2.ZERO,Vector2(grid[0].length(),grid.size())*TILE)
	if map_rect.encloses(bounds):return false
	var map_polygon:=PackedVector2Array([Vector2.ZERO,Vector2(map_rect.end.x,0),map_rect.end,Vector2(0,map_rect.end.y)])
	var texture:Texture2D=hedge_tree_textures[name] if integrated else atlas
	var id:int=sprites[name];var inverse:=projection.affine_inverse()
	draw_set_transform((get_viewport_rect().size/2-camera+shake_offset).round())
	for clipped in Geometry2D.intersect_polygons(quad,map_polygon):
		var uv:=PackedVector2Array()
		for point in clipped:
			var local:Vector2=inverse*point/scale_factor+anchor
			uv.append(local/Vector2(64,96) if integrated else (Vector2(id%16*32,id/16*48)+local/2)/Vector2(atlas.get_size()))
		draw_polygon(clipped,PackedColorArray([Color(.06,.055,.1,.28)]),uv,texture)
	draw_set_transform(Vector2.ZERO)
	return true

func prepare_room_details(rng: RandomNumberGenerator) -> void:
	if level in [4,6]:
		objects.assign(objects.filter(func(o):return o.kind not in ["flowers","blueflowers","tree"]))
		for spec in [["crate",Vector2i(3,10)],["column",Vector2i(23,10)],["crate",Vector2i(22,19)],["column",Vector2i(4,19)],["crate",Vector2i(4,11)],["crate",Vector2i(22,18)],["column",Vector2i(5,8)],["column",Vector2i(21,8)],["crate",Vector2i(3,20)],["crate",Vector2i(23,20)]]:
			var prop_position := (Vector2(spec[1]) + Vector2(.5, .5)) * TILE
			if objects.any(func(obj): return obj.kind=="letter_box" and obj.pos.distance_to(prop_position)<100):continue
			if valid_ground(prop_position):put_object(spec[0],spec[1],"",true)
	if level==1:
		for obj in objects:
			if obj.kind=="lamp":obj.kind="lamp_off"
	if level==0:
		var candidates:Array[Vector2i]=[]
		for y in range(6,grid.size()-6):
			for x in range(grid[0].length()):
				if grid[y][x]!="#":continue
				var point:=(Vector2(x,y)+Vector2(.5,.5))*TILE
				if objects.any(func(o):return o.get("hidden_hedge",false) and o.pos.distance_to(point)<75):continue
				if (x>0 and grid[y][x-1]==".") or (x+1<grid[0].length() and grid[y][x+1]==".") or grid[y-1][x]=="." or grid[y+1][x]==".":candidates.append(Vector2i(x,y))
		var planted:=0
		while not candidates.is_empty() and planted<22:
			var n:=rng.randi_range(0,candidates.size()-1);var cell:=candidates[n];candidates.remove_at(n)
			var point:=(Vector2(cell)+Vector2(.5,.5))*TILE
			if objects.any(func(o):return o.kind=="tree" and o.pos.distance_to(point)<125):continue
			if berry_cells.has(cell):
				var id:String=berry_cells[cell];berry_cells.erase(cell)
				objects.assign(objects.filter(func(o):return o.kind!="berries" or o.id!=id))
			put_object("tree",cell,"",false);planted+=1
	if level==5:
		for x in [4,8,19,23]:
			var row := 6 if rng.randf()<.5 else grid.size()-7
			if grid[row][x]=="#":put_object("tree",Vector2i(x,row),"",false)
	if level==6:
		for obj in objects:
			if obj.kind=="column":obj.kind="column_wreath"
			elif obj.kind=="candle":obj.kind="candle_heart"
		for cell in [Vector2i(9,10),Vector2i(17,10),Vector2i(8,20),Vector2i(18,20)]:put_object("heart_stand",cell,"",true)
	var index := 0
	for obj in objects:
		if obj.kind!="tree":continue
		if rng.randf()<.55:
			obj.kind="tree_apples";obj.id="apple_%d_%d"%[level,index]
		index+=1
	for obj in objects:
		if obj.kind not in ["tree","tree_apples"]:continue
		var cell:=Vector2i(obj.pos/TILE)
		if cell.y>=0 and cell.y<grid.size() and cell.x>=0 and cell.x<grid[0].length() and grid[cell.y][cell.x]=="#":
			obj.integrated_hedge=true;hedge_trees[cell]=obj

func shadow_floor_cell(cell: Vector2i) -> bool:
	if cell.y<0 or cell.y>=grid.size():return corridor_floor_point((Vector2(cell)+Vector2(.5,.5))*TILE)
	return cell.x>=0 and cell.y>=0 and cell.y<grid.size() and cell.x<grid[0].length() and grid[cell.y][cell.x]=="."

func shadow_ray_clear(destination: Vector2) -> bool:
	var distance:=player.distance_to(destination)
	for step in range(5,ceili(distance/4)+1):
		if not shadow_floor_cell(Vector2i(player.lerp(destination,minf(1,step*4/distance))/TILE)):return false
	return true

func draw_floor_shadow(polygon: PackedVector2Array, color: Color, projection: Transform2D = Transform2D.IDENTITY, sprite_id: int = -1, scale_factor: float = 1.0) -> void:
	var bounds:=Rect2(polygon[0],Vector2.ZERO)
	for point in polygon:bounds=bounds.expand(point)
	var origin:=-(get_viewport_rect().size/2-camera+shake_offset).round()
	var first:=Vector2i((bounds.position+origin)/TILE)-Vector2i.ONE
	var last:=Vector2i((bounds.end+origin)/TILE)+Vector2i.ONE
	for y in range(first.y,last.y+1):
		for x in range(first.x,last.x+1):
			if not shadow_floor_cell(Vector2i(x,y)):continue
			var corner:=screen(Vector2(x,y)*TILE)
			var tile:=PackedVector2Array([corner,corner+Vector2(TILE,0),corner+Vector2(TILE,TILE),corner+Vector2(0,TILE)])
			for clipped in Geometry2D.intersect_polygons(polygon,tile):
				if clipped.size()<3:continue
				var centre:=Vector2.ZERO
				for point in clipped:centre+=point
				if not shadow_ray_clear(centre/clipped.size()+origin):continue
				if sprite_id<0:draw_colored_polygon(clipped,color)
				else:
					var uv:=PackedVector2Array()
					for point in clipped:
						var local:Vector2=projection.affine_inverse()*point/scale_factor+Vector2(32,86)
						uv.append((Vector2(sprite_id%16*32,sprite_id/16*48)+local/2)/Vector2(atlas.get_size()))
					draw_polygon(clipped,PackedColorArray([color]),uv,atlas)

func resolve_gate_overlap(door: Dictionary) -> void:
	var relative:Vector2=player-door.pos
	if absf(relative.y)>16 or absf(relative.x)>86 or not blocked(player):return
	for radius in range(4,101,4):
		for normal in [Vector2.DOWN,Vector2.UP,Vector2.RIGHT,Vector2.LEFT,Vector2(1,1).normalized(),Vector2(-1,1).normalized(),Vector2(1,-1).normalized(),Vector2(-1,-1).normalized()]:
			var candidate:Vector2=player+normal*radius
			if not blocked(candidate):player=candidate;return

func held_tool_pose() -> Dictionary:
	var toward:Vector2=walk_facing.normalized()
	if toward.length()<.1:toward=[Vector2.UP,Vector2.LEFT,Vector2.DOWN,Vector2.RIGHT][direction]
	var using:=task_time>0
	if using:toward=(task_target-player).normalized()
	var hand:=player+Vector2(toward.x*16 if absf(toward.x)>.2 else 12,-21+toward.y*3)
	if moving and not using:hand.y+=sin(time*12)*1.2
	if using:toward=(task_target+Vector2(0,-55 if task_kind=="fill" else -10)-hand).normalized()
	var anchors:Dictionary={"can":Vector2(14,24),"rake":Vector2(16,31),"fertilizer":Vector2(16,32),"shovel":Vector2(16,29),"flashlight":Vector2(16,32),"axe":Vector2(15,34),"shears":Vector2(16,35),"drill":Vector2(16,28)}
	var tips:Dictionary={"can":Vector2(30,28),"rake":Vector2(19,14),"fertilizer":Vector2(16,23),"shovel":Vector2(16,45),"flashlight":Vector2(16,21),"axe":Vector2(24,19),"shears":Vector2(18,19),"drill":Vector2(16,45)}
	var anchor:Vector2=anchors.get(held_item,Vector2(16,32));var tip:Vector2=tips.get(held_item,Vector2(25,23))
	var scale_factor:=1.3 if held_item!="flashlight" else 1.0
	var local_tip:Vector2=(tip-anchor)*scale_factor
	var flip:=Vector2(-1,1) if toward.x<0 else Vector2.ONE
	var angle:=toward.angle()-(local_tip*flip).angle()
	if using and task_kind.begins_with("fertilize:"):angle+=sin(time*16)*.07
	if using and (task_kind.begins_with("rake:") or task_kind=="new_bed" or task_kind.begins_with("uproot:")):hand+=toward*sin(time*13)*9
	if using and task_kind.begins_with("dig:"):angle+=sin((task_duration-task_time)/task_duration*PI)*.6
	if using and (task_kind.begins_with("axe:") or task_kind.begins_with("snip")):angle+=sin((task_duration-task_time)/task_duration*PI)*1.1
	if held_item=="drill" and world_tools.drilling:hand+=Vector2(sin(time*70),cos(time*60))*1.2
	return {"hand":hand,"angle":angle,"flip":flip,"anchor":anchor,"scale":scale_factor,"tip":hand+(local_tip*flip).rotated(angle)}

func place_accessory(rng: RandomNumberGenerator) -> void:
	var choices:Array[Vector2]=[]
	for y in range(8,grid.size()-7):
		for x in range(2,grid[0].length()-2):
			var point:=(Vector2(x,y)+Vector2(.5,.5))*TILE
			if not valid_ground(point) or blocked(point):continue
			if level==2 and y<30:continue
			if level==6 and Rect2(Vector2(21.2*48,9*48),Vector2(2.6*48,9*48)).has_point(point):continue
			if level in [4,6]:
				var reserved:=[Vector2i(3,10),Vector2i(23,10),Vector2i(22,19),Vector2i(4,19),Vector2i(4,11),Vector2i(22,18),Vector2i(5,8),Vector2i(21,8),Vector2i(3,20),Vector2i(23,20),Vector2i(9,10),Vector2i(17,10),Vector2i(8,20),Vector2i(18,20)]
				if reserved.any(func(cell):return point.distance_to((Vector2(cell)+Vector2(.5,.5))*TILE)<80):continue
			if objects.any(func(o):return o.pos.distance_to(point)<80):continue
			choices.append(point)
	if choices.is_empty():choices.append(player+Vector2(35,0))
	for slot in range(2):
		var pos:=accessory_drop_position(player+Vector2(40*slot,40)) if choices.is_empty() else choices[rng.randi_range(0,choices.size()-1)]
		var item:String=ROOM_ACCESSORIES[level][slot]
		objects.append({"kind":"accessory","id":"accessory_"+str(level)+"_"+str(slot),"accessory":item,"pos":pos,"solid":false})
		choices=choices.filter(func(point):return point.distance_squared_to(pos)>110*110)

func accessory_origin(item: String) -> int:
	for room in range(ROOM_ACCESSORIES.size()):
		if item in ROOM_ACCESSORIES[room]:return room
	return 0

func repair_accessory_save(legacy: bool) -> void:
	# Unknown/removed cosmetics are discarded; progress, letters and rooms are untouched.
	save_data.accessories=save_data.accessories.filter(func(item):return item in ACCESSORIES)
	save_data.wearing=save_data.wearing.filter(func(item):return item in ACCESSORIES)
	for base in ["black_dress","dark_scarf"]:
		if base in save_data.accessories:continue
		save_data.accessories.append(base)
		var slot:String=ACCESSORY_SLOTS[base]
		if not save_data.wearing.any(func(item):return ACCESSORY_SLOTS[item]==slot):save_data.wearing.append(base)
		elif not save_data.loose_accessories.any(func(drop):return drop.get("accessory","")==base):
			var originals:Array=save_data.accessories.filter(func(item):return item!=base and ACCESSORY_SLOTS[item]==slot)
			save_data.loose_accessories.append({"id":"accessory_drop_"+base,"accessory":base,"room":accessory_origin(originals[0]) if not originals.is_empty() else 0,"pos":[]})
	var slots:Dictionary={};var worn:Array=[]
	for item in save_data.wearing:
		var slot:String=ACCESSORY_SLOTS[item]
		if slots.has(slot):worn.erase(slots[slot])
		slots[slot]=item;worn.append(item)
	save_data.wearing=worn
	save_data.loose_accessories=save_data.loose_accessories.filter(func(drop):return drop is Dictionary and drop.get("accessory","") in ACCESSORIES and drop.accessory not in save_data.wearing)
	if legacy:
		for item in save_data.accessories:
			if item in save_data.wearing or save_data.loose_accessories.any(func(drop):return drop.accessory==item):continue
			save_data.loose_accessories.append({"id":"accessory_drop_"+item,"accessory":item,"room":accessory_origin(item),"pos":[]})
	save_data.accessory_drop_version=1

func accessory_drop_position(origin: Vector2) -> Vector2:
	for offset in [Vector2(0,16),Vector2(20,0),Vector2(-20,0),Vector2(0,-20),Vector2.ZERO]:
		var point:Vector2=origin+offset
		if valid_ground(point) and not blocked(point):return point
	var best:=player;var distance:=INF
	for y in range(7,grid.size()-6):
		for x in range(1,grid[0].length()-1):
			var point:=(Vector2(x,y)+Vector2(.5,.5))*TILE
			var d:=point.distance_squared_to(origin)
			if d<distance and valid_ground(point) and not blocked(point):best=point;distance=d
	return best

func restore_accessory_drops() -> void:
	for drop in save_data.loose_accessories:
		if int(drop.room)!=level or drop.accessory in save_data.wearing:continue
		var pos:=player
		if drop.pos.size()==2:pos=Vector2(drop.pos[0],drop.pos[1])
		else:
			for object in objects:
				if object.kind=="accessory" and object.accessory==drop.accessory:pos=object.pos;break
		if not valid_ground(pos) or blocked(pos):pos=accessory_drop_position(pos)
		drop.pos=[pos.x,pos.y]
		objects.append({"kind":"accessory","id":drop.id,"accessory":drop.accessory,"pos":pos,"solid":false,"dropped_accessory":true})

func drop_accessory(item: String) -> void:
	var pos:=accessory_drop_position(player)
	var id:="accessory_drop_"+item
	save_data.loose_accessories=save_data.loose_accessories.filter(func(drop):return drop.accessory!=item)
	save_data.loose_accessories.append({"id":id,"accessory":item,"room":level,"pos":[pos.x,pos.y]})
	objects.append({"kind":"accessory","id":id,"accessory":item,"pos":pos,"solid":false,"dropped_accessory":true})

func collect_accessory(item: String) -> void:
	if item not in ACCESSORIES or item in save_data.wearing:return
	objects.assign(objects.filter(func(object):return not (object.kind=="accessory" and object.accessory==item)))
	save_data.loose_accessories=save_data.loose_accessories.filter(func(drop):return drop.accessory!=item)
	for old in save_data.wearing.duplicate():
		if ACCESSORY_SLOTS[old]==ACCESSORY_SLOTS[item]:
			save_data.wearing.erase(old);drop_accessory(old)
	if item not in save_data.accessories:save_data.accessories.append(item)
	save_data.wearing.append(item)
	persist();sfx("chime");burst(player,8,PINK);find_nearest()
	notify(tx("accessory_found") % tx("accessory_"+item))

func draw_player_outfit(pos: Vector2, frame: int, color: Color) -> void:
	draw_sprite("hero"+str(direction)+"_"+str(frame),pos,color)
	for item in OUTFIT_ORDER:
		if item in save_data.wearing:draw_sprite("wear_"+item+"_"+str(direction)+"_"+str(frame),pos,color)

func food_heart_burst() -> void:
	for n in range(18):
		particles.append({"pos":player+Vector2(0,-32),"vel":Vector2(randf_range(-75,75),randf_range(-110,15)),"life":randf_range(.65,1.15),"color":Color("ef436b"),"heart":true})

func update_food_hearts(delta: float) -> void:
	if food_hearts_left<=0:return
	food_heart_clock-=delta
	while food_heart_clock<=0 and food_hearts_left>0:
		food_heart_clock+=.13;food_hearts_left-=1
		particles.append({"pos":player+Vector2(randf_range(-5,5),-48),"vel":Vector2(randf_range(-4,4),-23),"life":1.8,"color":Color("ef436b"),"heart":true})

func draw_hedge_tree_top(kind: String, position: Vector2) -> void:
	# Native-size pixels preserve the full ordinary canopy without scaling shimmer.
	draw_texture_rect_region(hedge_tree_textures[kind],Rect2(screen(position)+Vector2(-32,-96),Vector2(64,80)),Rect2(Vector2.ZERO,Vector2(64,80)))

func draw_hedge_canopy(indices: PackedInt32Array, side: int = 0) -> void:
	# Quantize the camera once, not each overlapping crown independently.
	# Relative crown positions remain constant while the camera moves.
	draw_set_transform((get_viewport_rect().size/2-camera+shake_offset).round())
	# A single fixed Y-order is split around the heroine. Each crown is drawn whole,
	# once. The margin includes maximum bend and radius, keeping front crowns below waist.
	for index in indices:
		var behind:bool=not hedge_field.front_crowns.has(index)
		if (side<0 and not behind) or (side>0 and behind):continue
		draw_leaf_crown(index)
	draw_set_transform(Vector2.ZERO)

func draw_leaf_crown(index: int) -> void:
	var node:Dictionary=hedge_field.crowns[index]
	var pose:Vector3=hedge_field.draw_poses.get(index,Vector3.ZERO)
	var radius:float=pose.z
	var centre:=Vector2(pose.x,pose.y)
	var berry:bool=not str(node.berry).is_empty() and node.berry not in save_data.eaten
	var texture_name:="crown_berry_" if berry else "crown_leaf_"
	texture_name+=str(node.variant)
	var id:int=sprites[texture_name]
	if (berry and node.base.distance_to(player)<79) or (not drawing_neighbor and held_item=="shears" and nearest>=0 and objects[nearest].kind=="hedge_target" and Vector2i(node.base/TILE)==objects[nearest].cell):
		if not outlines.has(texture_name):
			var source:=atlas.get_image().get_region(Rect2i(id%16*32+8,id/16*48+24,17,17))
			var border:=Image.create(19,19,false,Image.FORMAT_RGBA8)
			for y in range(17):
				for x in range(17):
					if source.get_pixel(x,y).a<.5:continue
					for offset in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:border.set_pixel(x+1+offset.x,y+1+offset.y,Color("ffe7a6"))
			outlines[texture_name]=ImageTexture.create_from_image(border)
		draw_texture_rect(outlines[texture_name],Rect2(centre-Vector2.ONE*radius*19/17,Vector2.ONE*radius*2*19/17),false)
	draw_texture_rect_region(atlas,Rect2(centre-Vector2.ONE*radius,Vector2.ONE*radius*2),Rect2(Vector2(id%16*32+8,id/16*48+24),Vector2(17,17)))

func draw_hedge_body(bounds: Rect2) -> void:
	if hedge_field==null or hedge_field.body_texture==null:return
	var texture:Texture2D=hedge_field.body_texture
	var region:=bounds.intersection(Rect2(Vector2.ZERO,Vector2(texture.get_size())*2))
	if not region.has_area():return
	draw_set_transform((get_viewport_rect().size/2-camera+shake_offset).round())
	# Most of the wall never deforms. Draw it as texture regions, not hundreds of meshes.
	var patch:=Rect2()
	for index in hedge_field.active:
		if hedge_field.crowns[index].offset.length_squared()<.002:continue
		var point:Vector2=hedge_field.crowns[index].base
		if point.distance_squared_to(player)>148*148:continue
		if patch.has_area():patch=patch.expand(point)
		else:patch=Rect2(point-Vector2.ONE,Vector2.ONE*2)
	if patch.has_area():
		patch=patch.grow(64)
		patch=Rect2((patch.position/32).floor()*32,(patch.end/32).ceil()*32-(patch.position/32).floor()*32).intersection(region)
	if not patch.has_area():
		draw_body_region(texture,region)
		draw_set_transform(Vector2.ZERO)
		return
	for rectangle in [Rect2(region.position,Vector2(region.size.x,patch.position.y-region.position.y)),Rect2(Vector2(region.position.x,patch.end.y),Vector2(region.size.x,region.end.y-patch.end.y)),Rect2(Vector2(region.position.x,patch.position.y),Vector2(patch.position.x-region.position.x,patch.size.y)),Rect2(Vector2(patch.end.x,patch.position.y),Vector2(region.end.x-patch.end.x,patch.size.y))]:
		if rectangle.has_area():draw_body_region(texture,rectangle)
	var first:Vector2i=Vector2i((patch.position/32).floor())
	var last:Vector2i=Vector2i((patch.end/32).ceil())
	var offsets:Dictionary={}
	for y in range(first.y,last.y):
		for x in range(first.x,last.x):
			if not hedge_field.body_tiles.has(Vector2i(x,y)):continue
			var polygon:=PackedVector2Array();var uv:=PackedVector2Array()
			for corner in [Vector2i(x,y),Vector2i(x+1,y),Vector2i(x+1,y+1),Vector2i(x,y+1)]:
				var extent:=Vector2(texture.get_size())*2
				var point:Vector2=(Vector2(corner)*32).clamp(Vector2.ZERO,extent)
				if not offsets.has(corner):offsets[corner]=hedge_field.body_offset(point)
				polygon.append((point+offsets[corner]).round().clamp(Vector2.ZERO,extent)-Vector2(0,HEDGE_LIFT))
				uv.append(point/(Vector2(texture.get_size())*2))
			draw_polygon(polygon,PackedColorArray([Color.WHITE]),uv,texture)
	draw_set_transform(Vector2.ZERO)

func draw_body_region(texture: Texture2D, region: Rect2) -> void:
	draw_texture_rect_region(texture,Rect2(region.position-Vector2(0,HEDGE_LIFT),region.size),Rect2(region.position/2,region.size/2))

func show_secret_book() -> void:show_text_page(tx("secret_book_title"),tx("secret_book_text"))

func show_text_page(title:String,body:String) -> void:
	clear_modal();paused=true
	modal=Control.new();modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.add_child(modal)
	var view:=Control.new();view.set_script(preload("res://scripts/letter_view.gd"));view.game=self
	view.letter={"title":title,"text":body};view.start=screen(objects[nearest].pos) if nearest>=0 else get_viewport_rect().size/2
	modal.add_child(view)

func draw_tool_table() -> void:
	draw_texture_rect(tool_table_texture,Rect2(screen(Vector2(22.5*48-48,14.5*48-160)),Vector2(96,320)),false)

func new_bed_action_ready() -> bool:
	return world_tools.can_bed() and (nearest<0 or objects[nearest].kind in ["bench","swing","tree","tree_apples"])

func restore_weapon_drops() -> void:
	objects.assign(objects.filter(func(obj):return not str(obj.id).begins_with("drop_")))
	for saved in save_data.loose_weapons:
		if int(saved.get("room",4))!=level:continue
		var obj:Dictionary=saved.duplicate();obj.pos=Vector2(saved.pos[0],saved.pos[1]);objects.append(obj)

func rpg_muzzle() -> Vector2:
	var left:=aim.x<0
	var angle:=atan2(-aim.y,-aim.x) if left else aim.angle()
	return player+Vector2(14,-28)+Vector2(-42 if left else 42,-2).rotated(angle)

func update_gunner(enemy: Dictionary, delta: float) -> void:
	battle.gunner(enemy,delta)

func garden_bed_clear(point:Vector2,include_beds:bool=true,ignore_id:String="") -> bool:
	if not valid_ground(point) or blocked(point):return false
	var plant:=Rect2(point-Vector2(42,96),Vector2(84,110))
	for obj in objects:
		if obj.kind=="sprout":
			if include_beds and obj.id!=ignore_id and obj.pos.distance_to(point)<64:return false
			continue
		var obstacle:=Rect2()
		if obj.kind=="well":obstacle=Rect2(obj.pos-Vector2(42,90),Vector2(84,104)).grow(12)
		elif obj.kind in ["tree","tree_apples","bench","swing"]:obstacle=Rect2(obj.pos-Vector2(38,95),Vector2(76,110)).grow(10)
		elif obj.solid:obstacle=Rect2(obj.pos-Vector2(28,50),Vector2(56,65)).grow(8)
		elif obj.kind!="pet_cat" and obj.pos.distance_to(point)<60:return false
		if obstacle.has_area() and plant.intersects(obstacle):return false
	return true
