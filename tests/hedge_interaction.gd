extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var game=load("res://main.tscn").instantiate()
	root.add_child(game);await process_frame
	game.new_game();game.clear_modal();game.sound_on=false;game.set_process(false)
	for vertical in [false,true]:
		game.grid.clear()
		for y in range(22):game.grid.append(".".repeat(22))
		for n in range(3,19):game.set_cell(10 if vertical else n,n if vertical else 10,"#")
		game.hedge_field=load("res://scripts/hedge_field.gd").new()
		game.hedge_field.build(game.grid,541,{}, {})
		var centre:=Vector2(10.5,10.5)*48
		var normal:=Vector2.RIGHT if vertical else Vector2.DOWN
		var tangent:=normal.orthogonal()
		for side in [-1,1]:
			for slant in [-18,0,18]:
				game.player=centre+normal*30*side+tangent*slant
				assert(not game.interaction_reachable({"pos":centre-normal*30*side,"kind":"note"}),"Picked through hedge")
				assert(game.interaction_reachable({"pos":centre+normal*40*side+tangent*8,"kind":"note"}),"Near-side pickup blocked")
				assert(game.interaction_reachable({"pos":centre,"kind":"note","hidden_hedge":true}),"Embedded secret inaccessible")
				assert(game.interaction_reachable({"pos":centre,"kind":"berries"}),"Embedded fruit inaccessible")
				assert(not game.interaction_reachable({"pos":centre-normal*25*side,"kind":"berries"}),"Fruit picked through hedge")
	print("PASS interaction rays: four sides, diagonal approaches, embedded secrets/fruit, no through-wall pickups")
	quit()
