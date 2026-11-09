extends Control
## An envelope unfolds in the world; its paper then moves toward the viewer.
var game: Node2D
var letter: Dictionary
var journal := false
var start := Vector2.ZERO
var age := 0.0
var paper: Control
var text_scroll: ScrollContainer
var close_button: Button
func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter=Control.MOUSE_FILTER_STOP
 paper=Control.new();paper.set_script(preload('res://scripts/letter_paper.gd'));add_child(paper)
 paper.size=Vector2(464,660)
 var title=game.label(str(letter.title),25,game.INK,true);title.position=Vector2(30,38);title.size=Vector2(370,90);paper.add_child(title)
 text_scroll=ScrollContainer.new();text_scroll.position=Vector2(30,140);text_scroll.size=Vector2(404,440);paper.add_child(text_scroll)
 var column=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;text_scroll.add_child(column)
 var body=game.label(str(letter.text),20,game.INK);body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_child(body)
 if not str(letter.get('image','')).is_empty() and ResourceLoader.exists(letter.image):
  var picture=TextureRect.new();picture.texture=load(letter.image);picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;picture.custom_minimum_size=Vector2(380,180);column.add_child(picture)
 close_button=Button.new();close_button.text='×';close_button.flat=true;close_button.add_theme_font_size_override('font_size',28);close_button.add_theme_color_override('font_color',game.INK)
 close_button.pressed.connect(func():
  if journal:game.show_journal()
  else:game.clear_modal())
 close_button.position=Vector2(416,10);close_button.size=Vector2(38,38);paper.add_child(close_button)
 if journal:age=1.5
func _process(delta:float) -> void:
 age+=delta
 var t=smoothstep(.7,1.5,age)
 paper.scale=Vector2.ONE*lerpf(.065,1.0,t)
 paper.rotation=sin(t*PI)*-.1
 var destination=(get_viewport_rect().size-paper.size)/2
 paper.position=(start+Vector2(-15,-65)).lerp(destination,t)
 paper.modulate.a=clampf((age-.28)/.2,0,1)
 for node in [text_scroll,close_button,paper.get_child(0)]:node.modulate.a=clampf((age-1.25)*5,0,1)
 close_button.disabled=age<1.5
 queue_redraw()
func _draw() -> void:
 draw_rect(get_viewport_rect(),Color(.03,.04,.08,.58*smoothstep(.7,1.5,age)))
 var p=start+Vector2(0,-12)
 var atlas:Texture2D=game.atlas
 var index:int=game.sprites['note_open' if age>.25 else 'note']
 draw_texture_rect_region(atlas,Rect2(p-Vector2(32,86),Vector2(64,96)),Rect2(Vector2(index%16*32,index/16*48),Vector2(32,48)))

 if age<.55:
  var lift=smoothstep(0.0,.35,age)
  draw_colored_polygon(PackedVector2Array([p+Vector2(-20,-30),p+Vector2(0,lerpf(-20,-58,lift)),p+Vector2(20,-30)]),Color('#f6dfc8'))
