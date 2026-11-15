extends Control
## Quiet pixel motifs, drawn once per resize beneath menu content.
var panel:Control
func _ready()->void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 clip_contents=true
 panel.resized.connect(fit_panel)
 call_deferred("fit_panel")
 resized.connect(queue_redraw)
func fit_panel()->void:
 position=Vector2.ZERO
 size=panel.size
func _draw()->void:
 var heart:=PackedVector2Array([Vector2(-9,-12),Vector2(-3,-12),Vector2(-3,-9),Vector2(3,-9),Vector2(3,-12),Vector2(9,-12),Vector2(9,-9),Vector2(12,-9),Vector2(12,0),Vector2(9,0),Vector2(9,3),Vector2(6,3),Vector2(6,6),Vector2(3,6),Vector2(3,9),Vector2(-3,9),Vector2(-3,6),Vector2(-6,6),Vector2(-6,3),Vector2(-9,3),Vector2(-9,0),Vector2(-12,0),Vector2(-12,-9),Vector2(-9,-9),Vector2(-9,-12)])
 var star:=PackedVector2Array([Vector2(0,-12),Vector2(3,-12),Vector2(3,-6),Vector2(6,-6),Vector2(6,-3),Vector2(12,-3),Vector2(12,0),Vector2(6,0),Vector2(6,3),Vector2(3,3),Vector2(3,9),Vector2(0,9),Vector2(0,3),Vector2(-3,3),Vector2(-3,0),Vector2(-9,0),Vector2(-9,-3),Vector2(-3,-3),Vector2(-3,-6),Vector2(0,-6),Vector2(0,-12)])
 var columns:=maxi(3,roundi(size.x/76.0))
 var rows:=maxi(1,roundi(size.y/62.0))
 var step:=size/Vector2(columns,rows)
 for row in range(-1,rows+1):
  for column in range(-1,columns+1):
   var p:Vector2=(Vector2(column,row)*step+Vector2(4,4)).round()
   var shape:=PackedVector2Array()
   for point in (star if (row+column)%3==0 else heart):shape.append(point+p)
   draw_polyline(shape,Color(1,.78,.87,.055),2.0,false)
