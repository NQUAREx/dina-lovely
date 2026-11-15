extends Control
## Quiet pixel motifs, drawn once per resize beneath menu content.
var panel:Control
var ink:Node2D
func _ready()->void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 clip_contents=true
 ink=Node2D.new()
 add_child(ink)
 ink.draw.connect(paint_pattern)
 panel.resized.connect(fit_panel)
 call_deferred("fit_panel")
 resized.connect(func():ink.queue_redraw())
func fit_panel()->void:
 position=Vector2.ZERO
 size=panel.size
 ink.queue_redraw()
func paint_pattern()->void:
 var heart:=PackedVector2Array([Vector2(-9,-12),Vector2(-3,-12),Vector2(-3,-9),Vector2(3,-9),Vector2(3,-12),Vector2(9,-12),Vector2(9,-9),Vector2(12,-9),Vector2(12,0),Vector2(9,0),Vector2(9,3),Vector2(6,3),Vector2(6,6),Vector2(3,6),Vector2(3,9),Vector2(-3,9),Vector2(-3,6),Vector2(-6,6),Vector2(-6,3),Vector2(-9,3),Vector2(-9,0),Vector2(-12,0),Vector2(-12,-9),Vector2(-9,-9),Vector2(-9,-12)])
 var star:=PackedVector2Array([Vector2(0,-12),Vector2(3,-12),Vector2(3,-6),Vector2(6,-6),Vector2(6,-3),Vector2(12,-3),Vector2(12,0),Vector2(6,0),Vector2(6,3),Vector2(3,3),Vector2(3,9),Vector2(0,9),Vector2(0,3),Vector2(-3,3),Vector2(-3,0),Vector2(-9,0),Vector2(-9,-3),Vector2(-3,-3),Vector2(-3,-6),Vector2(0,-6),Vector2(0,-12)])
 # Fixed diamond lattice: panel size changes the crop, never motif density.
 var pitch:=Vector2(76,44)
 var rows:=ceili(size.y/pitch.y)+1
 var columns:=ceili(size.x/pitch.x)+1
 for row in range(-1,rows+1):
  var shift:=pitch.x*.5 if posmod(row,2)==1 else 0.0
  for column in range(-1,columns+1):
   var p:=Vector2(column*pitch.x+shift,row*pitch.y)
   var shape:=PackedVector2Array()
   for point in (star if posmod(row+column,3)==0 else heart):shape.append(point+p)
   ink.draw_polyline(shape,Color(1,.78,.87,.055),2.0,false)
