extends SceneTree
var game
func _initialize(): call_deferred("run")
func capture(name: String):
	await create_timer(.6).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/screenshots/"+name+".png")
func run():
	game=load("res://main.tscn").instantiate()
	root.add_child(game)
	await capture("native_menu")
	game.new_game()
	await capture("native_intro")
	game.clear_modal()
	await capture("native_maze")
	game.build_level(1)
	game.spawn_wave()
	await capture("native_combat")
	game.build_level(2)
	game.camera=Vector2(13.5,9.5)*48
	game.player=game.camera
	await capture("native_garden")
	game.build_level(3)
	await capture("native_final")
	game.show_card()
	await capture("native_card")
	await create_timer(.2).timeout
	game.queue_free()
	await process_frame
	quit()
