extends Control
func _draw() -> void:
 draw_rect(Rect2(Vector2(8,12),size),Color(0,0,0,.25))
 draw_colored_polygon(PackedVector2Array([Vector2(0,4),Vector2(size.x-8,0),Vector2(size.x,size.y-4),Vector2(4,size.y)]),Color('#fffaf1'))
 draw_rect(Rect2(Vector2(15,16),size-Vector2(30,32)),Color('#ba879a'),false,2)

 draw_rect(Rect2(Vector2(19,20),size-Vector2(38,40)),Color("#e2b5b5"),false,1)
 for p in [Vector2(16,16),Vector2(size.x-16,size.y-16)]:
  draw_line(p+Vector2(-5,10),p+Vector2(9,-5),Color("#8f9a67"),2)
  for offset in [Vector2(-3,0),Vector2(3,0),Vector2(0,-3),Vector2(0,3)]:draw_rect(Rect2(p+offset-Vector2(2,2),Vector2(4,4)),Color("#dba6b5"))
  draw_rect(Rect2(p-Vector2(1,1),Vector2(2,2)),Color("#e3bf7e"))
