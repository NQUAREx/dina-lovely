extends Control
func _draw() -> void:
 draw_rect(Rect2(Vector2(8,12),size),Color(0,0,0,.25))
 draw_colored_polygon(PackedVector2Array([Vector2(0,4),Vector2(size.x-8,0),Vector2(size.x,size.y-4),Vector2(4,size.y)]),Color('#fffaf1'))
 draw_rect(Rect2(Vector2(15,16),size-Vector2(30,32)),Color('#d8c6b1'),false,2)
 for y in range(145,580,29):draw_line(Vector2(29,y),Vector2(size.x-29,y),Color(.55,.55,.6,.1),1)
