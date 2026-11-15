extends Control
var game: Node2D
func _process(_delta: float) -> void:
	queue_redraw()
func _draw() -> void:
	if not is_instance_valid(game) or not game.playing or game.paused or game.transition: return
	var p: Vector2 = game.joy_origin if game.joy_active else Vector2(110, get_viewport_rect().size.y-110)
	draw_circle(p,57,Color(.29,.21,.31,.30))
	draw_arc(p,57,0,TAU,32,Color(.84,.60,.69,.65),2)
	draw_circle(p+game.joy_vector*43,22,Color(.89,.66,.72,.7))

	draw_arc(p,53,0,TAU,32,Color("6c4a65"),2)
	draw_arc(p+game.joy_vector*43,22,0,TAU,16,Color("efc3b3"),2)
