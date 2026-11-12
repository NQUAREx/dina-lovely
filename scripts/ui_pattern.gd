extends Control
## Quiet pixel motifs, drawn once per resize beneath menu content.
func _ready()->void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 resized.connect(queue_redraw)
func _draw()->void:
 var heart:=PackedVector2Array([Vector2(-4,-1),Vector2(-4,-3),Vector2(-2,-4),Vector2(0,-2),Vector2(2,-4),Vector2(4,-3),Vector2(4,-1),Vector2(0,3)])
 for row in range(ceili(size.y/48.0)):
  for column in range(ceili(size.x/64.0)):
   var p:=Vector2(26+column*64+(16 if row%2 else 0),23+row*48)
   if p.x>size.x-12 or p.y>size.y-10:continue
   if (row+column)%3==0:
    draw_rect(Rect2(p-Vector2(1,4),Vector2(2,8)),Color(1,.82,.9,.055))
    draw_rect(Rect2(p-Vector2(4,1),Vector2(8,2)),Color(1,.82,.9,.055))
   else:
    var shape:=PackedVector2Array()
    for point in heart:shape.append(point+p)
    draw_colored_polygon(shape,Color(1,.75,.84,.045))
