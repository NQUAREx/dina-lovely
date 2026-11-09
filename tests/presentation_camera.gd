extends SceneTree
class View extends "res://scripts/game.gd":
	var mode:=0
	var observed_outlines:Dictionary={}
	var observed_sprites:Dictionary={}
	func _draw() -> void:
		if hedge_field==null:return
		if mode==0:
			for tree in hedge_trees.values():draw_cast_shadow("hedge_tree",screen(tree.pos),1)
		elif mode==1:
			draw_hedge_body(Rect2(camera-get_viewport_rect().size/2-Vector2(48,96),get_viewport_rect().size+Vector2(96,192)))
		else:
			observed_outlines.clear();observed_sprites.clear();super._draw()
	func draw_pickup_outline(name: String, pos: Vector2, scale_factor: float) -> void:
		observed_outlines[name]=pos;super.draw_pickup_outline(name,pos,scale_factor)
	func draw_sprite(name: String, pos: Vector2, color: Color = Color.WHITE, scale_factor: float = 1.0) -> void:
		observed_sprites[name]=pos;super.draw_sprite(name,pos,color,scale_factor)

func _initialize() -> void:call_deferred("run")
func capture(game: Node2D, position: Vector2) -> Image:
	game.camera=position;game.queue_redraw()
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func run() -> void:
	var game:=View.new();root.add_child(game);await process_frame
	var previous_save:=FileAccess.get_file_as_string(game.SAVE_PATH) if FileAccess.file_exists(game.SAVE_PATH) else ""
	game.new_game();game.clear_modal();game.sound_on=false;game.save_data.seed=541;game.build_level(0)
	game.ui.hide();game.set_process(false);game.set_physics_process(false);game.time=0
	var start:Vector2=game.player
	var width:float=game.grid[0].length()*48
	for origin in [Vector2(600.1,700.1),Vector2(width-100.1,700.1)]:
		var a:Image=await capture(game,origin)
		var b:Image=await capture(game,origin+Vector2(.2,.2))
		assert(a.get_data()==b.get_data(),"Tree shadow changed during fractional camera pan")
		var c:Image=await capture(game,origin+Vector2(1,0))
		assert(a.get_region(Rect2i(11,10,520,940)).get_data()==c.get_region(Rect2i(10,10,520,940)).get_data(),"Tree shadow changed during integer camera pan")
		game.time+=1
		assert(a.get_data()==(await capture(game,origin)).get_data(),"Static tree shadow flickers with time")
	game.mode=1
	var row:=10
	for y in range(10,game.grid.size()-8):
		if game.grid[y][game.grid[0].length()-2]==".":row=y;break
	game.player=Vector2(width-72,(row+.5)*48)
	for n in range(30):game.move_player(.016,Vector2.RIGHT);game.hedge_field.update(.016,game.player)
	var image:Image=await capture(game,Vector2(width-100,game.player.y))
	var edge:=roundi(game.screen(Vector2(width,0)).x)
	var outside:=image.get_region(Rect2i(edge,0,image.get_width()-edge,image.get_height()))
	var empty:=Image.create(outside.get_width(),outside.get_height(),false,outside.get_format())
	empty.fill(image.get_pixel(image.get_width()-1,0))
	assert(outside.get_data()==empty.get_data(),"Hedge mesh paints stripes beyond right map boundary")
	game.mode=2;game.player=start;game.invincible=0
	game.objects.assign([{"kind":"note","id":"shade_1","pos":start+Vector2(-16,12),"solid":false},{"kind":"accessory","id":"pose_wreath","accessory":"wreath","pos":start+Vector2(16,22),"solid":false}])
	for t in [0.0,.4,.8]:
		game.time=t
		await capture(game,start)
		for name in ["note","accessory_wreath"]:
			assert(game.observed_outlines.has(name) and game.observed_sprites.has(name))
			assert(game.observed_outlines[name]==game.observed_sprites[name],"Floating item and outline lost their shared pose")
	for letter in game.content.letters:assert(game.item_name({"kind":"note","id":letter.id})==game.tx("item_letter"))
	game.particles.clear();game.food_heart_burst();assert(game.particles.size()==18)
	game.food_hearts_left=10;game.food_heart_clock=.13
	game.update_food_hearts(.129);assert(game.particles.size()==18)
	game.update_food_hearts(.0015);assert(game.particles.size()==19)
	game.update_food_hearts(1.17);assert(game.food_hearts_left==0 and game.particles.size()==28)
	print("PASS stable/clipped tree shadows, sealed right edge, animated outline alignment, generic note tags and 10 hearts / 1.3s")
	var path:=game.SAVE_PATH;game.queue_free();await process_frame
	if previous_save.is_empty():DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	else:
		var file:=FileAccess.open(path,FileAccess.WRITE);file.store_string(previous_save);file.close()
	quit()
