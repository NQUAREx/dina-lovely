extends Control
## An envelope unfolds in the world, or a selected sheet lifts out of its pile.
var game: Node2D
var letter: Dictionary
var journal := false
var start := Vector2.ZERO
var age := 0.0
var paper: Control
var text_scroll: ScrollContainer
var close_button: Button
var title: Label
var stack_view: Control
var stack_rect := Rect2()
var stack_rotation := 0.0
var returning := false
var return_age := 0.0
var returned_to_stack := false

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    paper = Control.new()
    paper.set_script(preload("res://scripts/letter_paper.gd"))
    add_child(paper)
    paper.size = Vector2(464, 660)
    title = game.label(str(letter.title), 25, game.INK, true)
    title.position = Vector2(30, 58 if is_instance_valid(stack_view) else 38)
    title.size = Vector2(370, 70 if is_instance_valid(stack_view) else 90)
    paper.add_child(title)
    text_scroll = ScrollContainer.new()
    text_scroll.position = Vector2(30, 140)
    text_scroll.size = Vector2(404, 440)
    paper.add_child(text_scroll)
    var column := VBoxContainer.new()
    column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    text_scroll.add_child(column)
    var body := RichTextLabel.new()
    body.fit_content = true
    body.scroll_active = false
    body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    body.add_theme_font_override("normal_font", game.body_font)
    body.add_theme_font_size_override("normal_font_size", 24)
    body.add_theme_color_override("default_color", game.INK)
    column.add_child(body)
    body.add_text(str(letter.get("body_text", letter.text)))
    if letter.has("clue_room"):
        body.add_text("\n\n"+game.tx("riddle_note_heading")+"\n")
        var clue: String = game.riddle_clue(int(letter.clue_room), true)
        var markers := RegEx.new()
        markers.compile("\\{rune:([a-z_]+)\\}")
        var offset := 0
        for marker in markers.search_all(clue):
            body.add_text(clue.substr(offset, marker.get_start()-offset))
            var symbol: String = marker.get_string(1)
            var tile: int = game.sprites["rune_"+symbol]
            var origin := Vector2i(tile%16*32,tile/16*48)
            var crop: Rect2i = game.label_atlas_pixels.get_region(Rect2i(origin,Vector2i(32,48))).get_used_rect()
            var icon := AtlasTexture.new()
            icon.atlas = game.atlas
            icon.region = Rect2(Vector2(origin+crop.position),Vector2(crop.size))
            body.add_image(icon, int(34.0*crop.size.x/maxi(1,crop.size.y)), 34, Color.WHITE, INLINE_ALIGNMENT_CENTER)
            offset = marker.get_end()
        body.add_text(clue.substr(offset))
    if not str(letter.get("image", "")).is_empty() and ResourceLoader.exists(letter.image):
        var picture := TextureRect.new()
        picture.texture = load(letter.image)
        picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        picture.custom_minimum_size = Vector2(380, 180)
        column.add_child(picture)
    close_button = Button.new()
    close_button.icon = preload("res://assets/close_icon.png")
    close_button.expand_icon = true
    close_button.add_theme_constant_override("icon_max_width", 38)
    close_button.tooltip_text = game.tx("reply_close_symbol")
    close_button.flat = true
    close_button.position = Vector2(400, 8)
    close_button.size = Vector2(60, 60)
    close_button.pressed.connect(close)
    paper.add_child(close_button)
    if journal and not is_instance_valid(stack_view):
        age = 1.5

func close() -> void:
    if returning:
        return
    if is_instance_valid(stack_view):
        returning = true
        return_age = 0.0
        game.sfx("paper")
    elif journal:
        game.show_journal()
    else:
        game.clear_modal()

func _process(delta: float) -> void:
    age += delta
    var destination := (get_viewport_rect().size - paper.size) / 2
    if is_instance_valid(stack_view):
        var progress := smoothstep(0, .7, age)
        if returning:
            return_age += delta
            progress = 1 - smoothstep(0, .5, return_age)
        paper.scale = (stack_rect.size / paper.size).lerp(Vector2.ONE, progress)
        paper.rotation = lerpf(stack_rotation, 0, progress) - sin(progress * PI) * .045
        paper.position = stack_rect.position.lerp(destination, progress) + Vector2(0, -sin(progress * PI) * 44)
        paper.modulate.a = 1.0
        for node in [text_scroll, close_button, title]:
            node.modulate.a = smoothstep(.45, .9, progress)
        close_button.disabled = age < .7 or returning
        if returning and return_age >= .5:
            returned_to_stack = true
            game.modal = stack_view
            stack_view.resume()
            get_parent().remove_child(self)
            queue_free()
            return
    else:
        var progress := smoothstep(.7, 1.5, age)
        paper.scale = Vector2.ONE * lerpf(.065, 1, progress)
        paper.rotation = sin(progress * PI) * -.1
        paper.position = (start + Vector2(-15, -65)).lerp(destination, progress)
        paper.modulate.a = clampf((age - .28) / .2, 0, 1)
        for node in [text_scroll, close_button, title]:
            node.modulate.a = clampf((age - 1.25) * 5, 0, 1)
        close_button.disabled = age < 1.5
    queue_redraw()

func _draw() -> void:
    if is_instance_valid(stack_view):
        var progress := smoothstep(0, .7, age)
        if returning:
            progress = 1 - smoothstep(0, .5, return_age)
        draw_rect(get_viewport_rect(), Color(.03, .04, .08, .24 * progress))
        return
    draw_rect(get_viewport_rect(), Color(.03, .04, .08, .58 * smoothstep(.7, 1.5, age)))
    var position := start + Vector2(0, -12)
    var index: int = game.sprites["note_open" if age > .25 else "note"]
    draw_texture_rect_region(game.atlas, Rect2(position - Vector2(32, 86), Vector2(64, 96)), Rect2(Vector2(index % 16 * 32, index / 16 * 48), Vector2(32, 48)))
    if age < .55:
        var lift := smoothstep(0, .35, age)
        draw_colored_polygon(PackedVector2Array([position + Vector2(-20, -30), position + Vector2(0, lerpf(-20, -58, lift)), position + Vector2(20, -30)]), Color("f6dfc8"))

func _exit_tree() -> void:
    if is_instance_valid(stack_view) and not returned_to_stack:
        stack_view.queue_free()
