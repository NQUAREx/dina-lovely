extends Control
## A physical paper pile. Drag its exposed sheet edges or step through with arrows.
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
var previous_button: Button
var next_button: Button
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
    previous_button = game.button("", func(): step(-1), 68)
    previous_button.icon = preload("res://assets/archive_up.png")
    previous_button.tooltip_text = game.tx("back")
    next_button = game.button("", func(): step(1), 68)
    next_button.icon = preload("res://assets/archive_down.png")
    next_button.tooltip_text = game.tx("next_room")
    for button in [previous_button, next_button]:
        button.expand_icon = true
        button.add_theme_constant_override("icon_max_width", 28)
        add_child(button)
    exit_button = game.button(game.tx("return_to_garden"), game.clear_modal, 280)
    add_child(exit_button)
    layout()
    resized.connect(layout)

func layout() -> void:
    var center := get_viewport_rect().size / 2
    heading.position = Vector2(40, center.y - 365)
    heading.size = Vector2(460, 55)
    counter.position = Vector2(40, center.y + 315)
    counter.size = Vector2(460, 30)
    previous_button.position = Vector2(40, center.y + 360)
    next_button.position = Vector2(432, center.y + 360)
    exit_button.position = Vector2(130, center.y + 360)
    exit_button.size = Vector2(280, 60)

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
        cursor = lerpf(cursor, target_cursor, minf(1, delta * 13))
    var ready := active and age >= 1.2
    previous_button.disabled = not ready or target_cursor <= 0
    next_button.disabled = not ready or target_cursor >= max_cursor()
    exit_button.disabled = not ready
    var first := mini(letters.size(), floori(cursor) + 1)
    var last := mini(letters.size(), floori(cursor) + VISIBLE_COUNT)
    counter.text = "%d–%d / %d" % [first, last, letters.size()] if not letters.is_empty() else ""
    for node in [heading, counter, previous_button, next_button, exit_button]:
        node.modulate.a = smoothstep(.75, 1.2, age)
    queue_redraw()

func begin_drag(position: Vector2) -> void:
    press_position = position
    last_position = position
    moved = false
    dragging = true

func continue_drag(position: Vector2) -> void:
    if not dragging:
        return
    moved = moved or position.distance_to(press_position) > 10
    cursor = clampf(cursor - (position.y - last_position.y) / 62, 0, max_cursor())
    target_cursor = cursor
    last_position = position

func end_drag(position: Vector2) -> void:
    if not dragging:
        return
    dragging = false
    moved = moved or position.distance_to(press_position) > 10
    if moved:
        target_cursor = clampf(roundf(cursor), 0, max_cursor())
        return
    for index in range(letters.size() - 1, -1, -1):
        var offset := float(index) - cursor
        if offset < -1 or offset > 4.99:
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
        if offset < -1 or offset > 4.99 or letters[index].id == selected_id:
            continue
        var destination := card_rect(index)
        var position := (start - Vector2(16, 42)).lerp(destination.position, progress)
        var scale_factor := lerpf(.08, 1, progress)
        draw_set_transform(position, card_rotation(index) * progress, Vector2.ONE * scale_factor)
        draw_texture_rect(SHEETS[index % SHEETS.size()], Rect2(Vector2.ZERO, destination.size), false)
        if progress > .8:
            var title := str(letters[index].title)
            var font_size := 22
            while font_size > 16 and game.title_font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > 340:
                font_size -= 1
            draw_string(game.title_font, Vector2(26, 53), title, HORIZONTAL_ALIGNMENT_LEFT, 340, font_size, game.INK)
        draw_set_transform(Vector2.ZERO)

func resume() -> void:
    active = true
    selected_id = ""
    set_process(true)
    queue_redraw()

func _exit_tree() -> void:
    box_object.archive_open = false
