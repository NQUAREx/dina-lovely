extends Control
## The ruled paper moves with the text, clipped to the same reading window.
var scroll: ScrollContainer
func _draw() -> void:
    var offset := scroll.scroll_vertical % 29
    for y in range(5-offset,ceili(size.y),29):
        draw_line(Vector2(0,y),Vector2(size.x-4,y),Color(.55,.55,.6,.1),1)
