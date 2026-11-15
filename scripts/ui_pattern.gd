extends Control
## Native-size ornaments overlay clean nine-slice rails; no stretched decoration.
var panel:Control
const FLOWER:Texture2D=preload("res://assets/ui/flower_corner.png")
func _ready()->void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 clip_contents=false
 panel.resized.connect(fit_panel)
 call_deferred("fit_panel")
 resized.connect(queue_redraw)
func fit_panel()->void:
 position=Vector2.ZERO
 size=panel.size
func _draw()->void:
 var is_button:=panel is Button
 if not is_button:
  # The wallpaper belongs below content, inset from the border. Child buttons
  # paint their own opaque background over it, so motifs never cross a label.
  for y in range(30,int(size.y)-22,55):
   for x in range(28,int(size.x)-20,70):
    var p:=Vector2(x,y)
    var heart:=PackedVector2Array([Vector2(-5,-3),Vector2(-3,-5),Vector2(0,-2),Vector2(3,-5),Vector2(5,-3),Vector2(5,0),Vector2(0,6),Vector2(-5,0)])
    var star:=PackedVector2Array([Vector2(-1,-6),Vector2(1,-6),Vector2(1,-2),Vector2(5,-2),Vector2(5,0),Vector2(1,0),Vector2(1,5),Vector2(-1,5),Vector2(-1,0),Vector2(-5,0),Vector2(-5,-2),Vector2(-1,-2)])
    var shape:=star if (x/70+y/55)%2==0 else heart
    for i in range(shape.size()):shape[i]+=p
    shape.append(shape[0])
    draw_polyline(shape,Color(.95,.74,.83,.065),1,false)
 var disabled:bool=is_button and panel.disabled
 var tint:=Color(.65,.58,.66,.7) if disabled else Color.WHITE
 var flower_size:=Vector2(45,33) if is_button else Vector2(60,44)
 var overhang:=14.0 if is_button else 20.0
 # Short system buttons have a frame, without crowding their icon with flowers.
 if not is_button or size.x>=110:
  draw_texture_rect(FLOWER,Rect2(Vector2(-2,-overhang),flower_size),false,tint)
  draw_set_transform(Vector2(size.x+2,-overhang),0,Vector2(-1,1))
  draw_texture_rect(FLOWER,Rect2(Vector2.ZERO,flower_size),false,tint)
  draw_set_transform(Vector2.ZERO)
 if size.x>=110:
  var texture:Texture2D=preload("res://assets/ui/crest_button.png") if is_button else preload("res://assets/ui/crest_panel.png")
  var target:=Vector2(texture.get_size())
  draw_texture_rect(texture,Rect2(Vector2(floorf((size.x-target.x)/2),-5),target),false,tint)
