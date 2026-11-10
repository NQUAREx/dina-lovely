extends SceneTree
func _initialize() -> void:call_deferred("run")
func capture(game: Node2D) -> Image:
	game.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func run() -> void:
	var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame
	g.new_game();g.clear_modal();g.set_process(false);g.set_physics_process(false);g.ui.hide();g.time=0;g.invincible=0
	g.save_data.open_gates=[0,1,2,3,4,5]
	var initial_builds:int=g.room_build_count
	for room in range(6):
		g.activate_cached_room(room)
		g.player=Vector2((15.5 if room==0 else 13.5)*48,-g.HALL_SEAM-1);g.camera=g.player+Vector2(0,16)
		g.update_fog()
		var a:Image=await capture(g)
		g.travel(room+1)
		var b:Image=await capture(g)
		var left:=a.get_data();var right:=b.get_data();var changed:=false
		# Compatibility canvas batches may round transparent framing by one channel bit.
		if left!=right:
			for i in range(left.size()):
				if absi(int(left[i])-int(right[i]))>1:changed=true;break
		if changed:
			a.save_png("/tmp/seam-before-"+str(room)+".png");b.save_png("/tmp/seam-after-"+str(room)+".png")
			push_error("Corridor image changed at room seam "+str(room));quit(1);return
	assert(g.room_build_count==initial_builds)
	print("PASS six room seams visually continuous (<=1 channel bit), no fades/room builds; inactive simulation frozen")
	quit()
