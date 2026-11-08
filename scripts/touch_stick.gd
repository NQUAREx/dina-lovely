extends Control
var game: Node2D
func _process(_delta: float) -> void:
	queue_redraw()
func _draw() -> void:
	if not is_instance_valid(game) or not game.playing or game.paused or game.transition: return
	var p: Vector2 = game.joy_origin if game.joy_active else Vector2(110, get_viewport_rect().size.y-110)
	draw_circle(p,57,Color(.9,.8,.9,.09))
	draw_arc(p,57,0,TAU,32,Color(.9,.8,.9,.35),2)
	draw_circle(p+game.joy_vector*43,22,Color(.92,.75,.82,.5))
