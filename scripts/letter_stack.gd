extends Control
## A physical paper pile. Drag exposed sheet edges to browse; sheets fade at the scroll boundaries.
const SHEETS := [preload("res://assets/archive_sheet_0.png"), preload("res://assets/archive_sheet_1.png"), preload("res://assets/archive_sheet_2.png")]
const VISIBLE_COUNT := 5
var game: Node2D
var box_object: Dictionary
var start := Vector2.ZERO
var letters: Array[Dictionary] = []
var age := 0.0
var cursor := 0.0
var target_cursor := 0.0
var active := true
var selected_id := ""
var press_position := Vector2.ZERO
var last_position := Vector2.ZERO
var dragging := false
var moved := false
var last_touch := -1000
var scroll_bar: VScrollBar
var scroll_velocity := 0.0
var exit_button: Button
var heading: Label
var counter: Label

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    box_object.archive_open = true
    for letter in game.content.letters:
        if letter.id in game.save_data.letters:
            letters.append(letter)
    heading = game.label(game.tx("journal_title"), 28, game.CREAM, true)
    heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    add_child(heading)
    counter = game.label("", 18)
    counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    add_child(counter)
    scroll_bar = VScrollBar.new()
    scroll_bar.page = VISIBLE_COUNT
    scroll_bar.max_value = maxf(VISIBLE_COUNT, letters.size())
    scroll_bar.step = .001
    scroll_bar.value_changed.connect(func(value):
        target_cursor = value
        scroll_velocity = 0)
    add_child(scroll_bar)
    exit_button = game.button("", game.clear_modal, 60)
    exit_button.icon = preload("res://assets/close_icon_light.png")
    exit_button.expand_icon = true
    exit_button.add_theme_color_override("icon_normal_color",game.CREAM)
    exit_button.add_theme_constant_override("icon_max_width", 38)
    exit_button.tooltip_text = game.tx("reply_close_symbol")
    add_child(exit_button)
    layout()
    resized.connect(layout)

func layout() -> void:
    var center := get_viewport_rect().size / 2
    heading.position = Vector2(30, center.y - 365)
    heading.size = Vector2(410, 65)
    heading.add_theme_font_size_override("font_size", 27)
    counter.position = Vector2(40, center.y + 315)
    counter.size = Vector2(460, 30)
    exit_button.position = Vector2(448, center.y - 365)
    exit_button.size = Vector2(60, 60)
    scroll_bar.position = Vector2(506, center.y - 248)
    scroll_bar.size = Vector2(16, 545)

func max_cursor() -> float:
    return maxf(0, letters.size() - VISIBLE_COUNT)

func card_rect(index: int) -> Rect2:
    var center := get_viewport_rect().size / 2
    var offset := float(index) - cursor
    return Rect2(center + Vector2(-200 + sin(index * 2.7) * 7, -240 + offset * 62), Vector2(400, 250))

func card_rotation(index: int) -> float:
    return (posmod(index, 3) - 1) * .012

func step(amount: int) -> void:
    if not active or age < 1.2:
        return
    target_cursor = clampf(roundf(target_cursor) + amount, 0, max_cursor())
    game.sfx("paper")

func _process(delta: float) -> void:
    age += delta
    if not dragging:
        target_cursor = clampf(target_cursor + scroll_velocity*delta, 0, max_cursor())
        scroll_velocity *= exp(-delta*7)
        cursor = lerpf(cursor, target_cursor, 1-exp(-delta*13))
        if absf(cursor-target_cursor)<.001:cursor=target_cursor
    scroll_bar.set_value_no_signal(cursor)
    var ready := active and age >= 1.2
    exit_button.disabled = not ready
    var first := mini(letters.size(), floori(cursor) + 1)
    var last := mini(letters.size(), floori(cursor) + VISIBLE_COUNT)
    counter.text = "%d–%d / %d" % [first, last, letters.size()] if not letters.is_empty() else ""
    for node in [heading, counter, scroll_bar, exit_button]:
        node.modulate.a = smoothstep(.75, 1.2, age)
    queue_redraw()

func begin_drag(position: Vector2) -> void:
    press_position = position
    last_position = position
    moved = false
    scroll_velocity = 0
    dragging = true

func continue_drag(position: Vector2) -> void:
    if not dragging:
        return
    moved = moved or position.distance_to(press_position) > 10
    cursor = clampf(cursor - (position.y - last_position.y) / 62, 0, max_cursor())
    scroll_velocity = -(position.y-last_position.y)/62*30
    target_cursor = cursor
    last_position = position

func end_drag(position: Vector2) -> void:
    if not dragging:
        return
    dragging = false
    moved = moved or position.distance_to(press_position) > 10
    if moved:
        target_cursor = cursor
        return
    for index in range(letters.size() - 1, -1, -1):
        var offset := float(index) - cursor
        if offset < -4 or offset > 5:
            continue
        var rect := card_rect(index)
        var local := (position - rect.position).rotated(-card_rotation(index))
        if Rect2(Vector2.ZERO, rect.size).has_point(local):
            selected_id = str(letters[index].id)
            game.sfx("paper")
            game.show_letter(selected_id, false, self)
            return

func _gui_input(event: InputEvent) -> void:
    if not active or age < 1.2:
        return
    if event is InputEventScreenTouch:
        last_touch = Time.get_ticks_msec()
        if event.pressed:
            begin_drag(event.position)
        else:
            end_drag(event.position)
    elif event is InputEventScreenDrag:
        last_touch = Time.get_ticks_msec()
        continue_drag(event.position)
    elif event is InputEventMouseButton and Time.get_ticks_msec() - last_touch > 500:
        if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
            step(1)
        elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
            step(-1)
        elif event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                begin_drag(event.position)
            else:
                end_drag(event.position)
    elif event is InputEventMouseMotion and Time.get_ticks_msec() - last_touch > 500:
        continue_drag(event.position)
    accept_event()

func _draw() -> void:
    var progress := smoothstep(.65, 1.2, age)
    draw_rect(get_viewport_rect(), Color(.03, .04, .08, .58 * progress))
    if age < 1.2:
        var sprite_name := "letter_box_open" if age > .25 else "letter_box"
        var sprite_id: int = game.sprites[sprite_name]
        draw_texture_rect_region(game.atlas, Rect2(start - Vector2(32, 86), Vector2(64, 96)), Rect2(Vector2(sprite_id % 16 * 32, sprite_id / 16 * 48), Vector2(32, 48)))
    if letters.is_empty():
        if progress > 0:
            draw_string(game.body_font, get_viewport_rect().size / 2 + Vector2(-215, 0), game.tx("journal_empty"), HORIZONTAL_ALIGNMENT_CENTER, 430, 20, game.CREAM)
        return
    for index in range(letters.size()):
        var offset := float(index) - cursor
        if offset < -4 or offset > 5 or letters[index].id == selected_id:
            continue
        var destination := card_rect(index)
        var position := (start - Vector2(16, 42)).lerp(destination.position, progress)
        var scale_factor := lerpf(.08, 1, progress)
        draw_set_transform(position, card_rotation(index) * progress, Vector2.ONE * scale_factor)
        var texture: Texture2D = SHEETS[index % SHEETS.size()]
        for y in range(0, 250, 5):
            var alpha := edge_alpha(position.y + (y+2.5)*scale_factor)
            if alpha<=0:continue
            draw_texture_rect_region(texture, Rect2(0,y,400,5), Rect2(0,float(y)/250*texture.get_height(),texture.get_width(),5.0/250*texture.get_height()),Color(1,1,1,alpha))
        if progress > .8:
            var title := str(letters[index].title)
            var font_size := 24
            while font_size > 16 and game.title_font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > 340:
                font_size -= 1
            draw_string(game.title_font, Vector2(26, 53), title, HORIZONTAL_ALIGNMENT_LEFT, 340, font_size, Color(game.INK, edge_alpha(position.y+53*scale_factor)))
        draw_set_transform(Vector2.ZERO)

func edge_alpha(y: float) -> float:
    var center := get_viewport_rect().size.y / 2
    return smoothstep(center-260,center-215,y)*(1-smoothstep(center+255,center+300,y))

func suspend() -> void:
    active = false
    for node in [heading,counter,scroll_bar,exit_button]:node.hide()
    set_process(false)

func resume() -> void:
    active = true
    for node in [heading,counter,scroll_bar,exit_button]:node.show()
    selected_id = ""
    set_process(true)
    queue_redraw()

func _exit_tree() -> void:
    box_object.archive_open = false
