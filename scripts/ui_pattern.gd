extends Control
## Quiet pixel motifs, drawn once per resize beneath menu content.
func _ready()->void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 resized.connect(queue_redraw)
func _draw()->void:
 var heart:=PackedVector2Array([Vector2(-9,-12),Vector2(-3,-12),Vector2(-3,-9),Vector2(3,-9),Vector2(3,-12),Vector2(9,-12),Vector2(9,-9),Vector2(12,-9),Vector2(12,0),Vector2(9,0),Vector2(9,3),Vector2(6,3),Vector2(6,6),Vector2(3,6),Vector2(3,9),Vector2(-3,9),Vector2(-3,6),Vector2(-6,6),Vector2(-6,3),Vector2(-9,3),Vector2(-9,0),Vector2(-12,0),Vector2(-12,-9),Vector2(-9,-9),Vector2(-9,-12)])
 var star:=PackedVector2Array([Vector2(0,-12),Vector2(3,-12),Vector2(3,-6),Vector2(6,-6),Vector2(6,-3),Vector2(12,-3),Vector2(12,0),Vector2(6,0),Vector2(6,3),Vector2(3,3),Vector2(3,9),Vector2(0,9),Vector2(0,3),Vector2(-3,3),Vector2(-3,0),Vector2(-9,0),Vector2(-9,-3),Vector2(-3,-3),Vector2(-3,-6),Vector2(0,-6),Vector2(0,-12)])
 for row in range(ceili(size.y/64.0)):
  for column in range(ceili(size.x/88.0)):
   var p:=Vector2(33+column*88+(24 if row%2 else 0),30+row*64)
   if p.x>size.x-18 or p.y>size.y-14:continue
   var shape:=PackedVector2Array()
   for point in (star if (row+column)%3==0 else heart):shape.append(point+p)
   draw_polyline(shape,Color(1,.78,.87,.055),2.0,false)
