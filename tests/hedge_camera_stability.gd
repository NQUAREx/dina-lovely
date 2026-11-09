extends SceneTree
## Rendering regression: moving the camera cannot change overlapping crown order or spacing.
class CanopyView extends "res://scripts/game.gd":
	func _draw() -> void:
		if hedge_field==null:return
		draw_hedge_canopy(hedge_field.visible_ids(Rect2(Vector2.ZERO,Vector2(10000,10000))))

		for tree in hedge_trees.values():draw_hedge_tree_top("hedge_tree",tree.pos)

func _initialize() -> void:call_deferred("run")

func capture(game: Node2D, camera_position: Vector2) -> Image:
	game.camera=camera_position
	game.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func run() -> void:
	var game:=CanopyView.new()
	root.add_child(game)
	await process_frame
	game.new_game();game.clear_modal();game.sound_on=false
	game.save_data.seed=541;game.build_level(0);game.set_process(false);game.set_physics_process(false)
	for child in game.get_children():
		if child is CanvasLayer:child.hide()
	var origin:=Vector2(600.1,700.1)
	var closest:Dictionary=game.hedge_field.crowns[0]
	for node in game.hedge_field.crowns:
		if node.base.distance_squared_to(origin)<closest.base.distance_squared_to(origin):closest=node
	game.player=closest.base+Vector2(23,0)
	for n in range(32):game.hedge_field.update(.016,game.player)
	var a:Image=await capture(game,origin)
	var b:Image=await capture(game,origin+Vector2(.2,.2))
	assert(a.get_data()==b.get_data(),"Fractional camera movement changed relative crown pixels")
	var c:Image=await capture(game,origin+Vector2(1,0))
	var size:=a.get_size()-Vector2i(20,20)
	assert(a.get_region(Rect2i(Vector2i(11,10),size)).get_data()==c.get_region(Rect2i(Vector2i(10,10),size)).get_data(),"Camera translation changed crown overlap")
	print("PASS canopy/tree pixels and overlap remain identical across fractional and integer camera movement")
	quit()
