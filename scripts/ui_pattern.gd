extends Control
## Quiet pixel motifs, drawn once per resize beneath menu content.
func _ready()->void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 clip_contents=true
 get_parent().resized.connect(fit_panel)
 if get_parent() is Container:get_parent().sort_children.connect(func():call_deferred("fit_panel"))
 call_deferred("fit_panel")
 resized.connect(queue_redraw)
func fit_panel()->void:
 position=Vector2.ZERO
 size=get_parent().size
func _draw()->void:
 var heart:=PackedVector2Array([Vector2(-9,-12),Vector2(-3,-12),Vector2(-3,-9),Vector2(3,-9),Vector2(3,-12),Vector2(9,-12),Vector2(9,-9),Vector2(12,-9),Vector2(12,0),Vector2(9,0),Vector2(9,3),Vector2(6,3),Vector2(6,6),Vector2(3,6),Vector2(3,9),Vector2(-3,9),Vector2(-3,6),Vector2(-6,6),Vector2(-6,3),Vector2(-9,3),Vector2(-9,0),Vector2(-12,0),Vector2(-12,-9),Vector2(-9,-9),Vector2(-9,-12)])
 var star:=PackedVector2Array([Vector2(0,-12),Vector2(3,-12),Vector2(3,-6),Vector2(6,-6),Vector2(6,-3),Vector2(12,-3),Vector2(12,0),Vector2(6,0),Vector2(6,3),Vector2(3,3),Vector2(3,9),Vector2(0,9),Vector2(0,3),Vector2(-3,3),Vector2(-3,0),Vector2(-9,0),Vector2(-9,-3),Vector2(-3,-3),Vector2(-3,-6),Vector2(0,-6),Vector2(0,-12)])
 for row in range(-1,ceili(size.y/64.0)+1):
  for column in range(-1,ceili(size.x/88.0)+1):
   var p:=Vector2(5+column*88+(24 if row%2 else 0),5+row*64)
   var shape:=PackedVector2Array()
   for point in (star if (row+column)%3==0 else heart):shape.append(point+p)
   draw_polyline(shape,Color(1,.78,.87,.055),2.0,false)
