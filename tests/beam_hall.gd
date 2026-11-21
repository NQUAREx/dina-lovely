extends SceneTree

const ENTRY := Vector2i(13,32)
const EXIT := Vector2i(13,6)

func _initialize() -> void:
	call_deferred("run")

func route_exists(game:Node2D) -> bool:
	var frontier:Array[Vector2i]=[ENTRY]
	var visited:Dictionary={ENTRY:true}
	while not frontier.is_empty():
		var cell:Vector2i=frontier.pop_back()
		if cell==EXIT:return true
		for direction in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next:Vector2i=cell+direction
			if next.y<EXIT.y or next.y>ENTRY.y or visited.has(next):continue
			if game.blocked((Vector2(next)+Vector2(.5,.5))*game.TILE):continue
			visited[next]=true
			frontier.append(next)
	return false

func run() -> void:
	var game:Node2D=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.activate_cached_room(2)
	assert(game.grid.size()==39 and game.grid[5].length()==31)
	var gates:Array=game.objects.filter(func(obj):return obj.kind=="doorway")
	assert(gates.size()==2 and gates[0].pos.x==gates[1].pos.x)
	for y in range(5,game.grid.size()-5):
		assert(game.grid[y][0]=="#" and game.grid[y][30]=="#")
	# The gate can only be reached by crossing from left to centre near the
	# top and from centre to right near the bottom.
	assert(route_exists(game))
	for gap in [Vector2i(10,10),Vector2i(20,26)]:
		var rows:Array[String]=[]
		rows.assign(game.grid)
		for offset in range(3):game.set_cell(gap.x,gap.y+offset,"#")
		assert(not route_exists(game))
		game.grid.assign(rows)
	# Block a cross-section of each lane, one at a time, to prove none can be skipped.
	for from_x in [1,11,21]:
		var row:String=game.grid[19]
		for x in range(from_x,from_x+9):game.set_cell(x,19,"#")
		assert(not route_exists(game))
		game.grid[19]=row
	assert(game.objects.all(func(obj):return obj.kind in ["doorway","accessory","note","riddle_stone","tree","tree_apples","flowers","blueflowers","crate"]))
	for beam in game.beam_traps.beams:
		var row:=floori(beam.y/game.TILE)
		assert(game.grid[row][0]=="#" and game.grid[row][10]=="#")
	var obstacles:Array=game.objects.filter(func(obj):return obj.id.begins_with("beam_gap_"))
	assert(obstacles.size()>=12 and obstacles.size()<=24)
	for index in range(game.beam_traps.spikes.size()):
		for side in range(2):
			var prefix:="beam_gap_%d_%d_"%[index,side]
			var count:=obstacles.filter(func(obj):return obj.id.begins_with(prefix)).size()
			assert(count>=2 and count<=4)
	for obstacle in obstacles:
		assert(obstacle.solid and game.blocked(obstacle.pos))
		if obstacle.kind=="crate":assert(not game.available(obstacle))
		for beam in game.beam_traps.beams:assert(absf(obstacle.pos.y-beam.y)>36)
		for spikes in game.beam_traps.spikes:assert(absf(obstacle.pos.y-spikes.rect.get_center().y)>38)
	assert(game.objects.filter(func(obj):return obj.kind in ["tree","tree_apples"] and not obj.id.begins_with("beam_gap_")).size()==22)
	assert(not game.level_complete())
	var pond:Rect2=game.beam_pond.BOUNDS
	var edge_column:=floori(pond.end.x/game.TILE)
	var final_water_row:=ceili(pond.end.y/game.TILE)-1
	assert(game.grid[final_water_row][edge_column]=="#")
	var crossing:Array=game.objects.filter(func(obj):return obj.id=="crossing")
	assert(crossing.size()==1)
	assert(not game.blocked(crossing[0].pos) and crossing[0].pos.y>pond.end.y)
	game.playing=true
	game.clear_modal()
	game.rotate_overlay.hide()
	var entrance:=Vector2(13.5,31.5)*48
	game.player=entrance
	game.beam_traps.clock=0
	game.beam_pond.seconds=0
	game.beam_crusher.elapsed=0
	game._physics_process(.1)
	assert(is_equal_approx(game.beam_traps.clock,.085))
	assert(is_equal_approx(game.beam_pond.seconds,.085))
	assert(is_equal_approx(game.beam_crusher.elapsed,.085))
	game.player=game.beam_traps.beam_box(game.beam_traps.beams.front()).get_center()
	game._physics_process(0.001)
	assert(game.player==entrance)
	game.beam_traps.clock=0
	assert(game.beam_traps.spikes.size()==3)
	for row in game.beam_traps.spikes:
		assert(row.rect.position.x==48 and row.rect.end.x==480)
	var spike:Dictionary=game.beam_traps.spikes.front()
	spike.phase=PI/2
	spike.warp=0.0
	game.player=spike.rect.get_center()
	game._physics_process(0.001)
	assert(game.player==entrance)
	game.beam_crusher.elapsed=game.beam_crusher.stroke*.5
	game.player=game.beam_crusher.footprint().get_center()
	game._physics_process(0.001)
	assert(game.player==entrance)
	game.player=Vector2(529,950)
	assert(game.beam_pond.support(game.player)<0)
	game._physics_process(0.001)
	assert(game.player==entrance)
	assert(game.beam_traps.beams.size()==4 and not game.beam_traps.spikes.is_empty())
	game.collect("crossing")
	assert(game.level_complete())
	print("PASS rectangular beam hall, aligned gates, all three lanes mandatory and story reward preserved; each hazard resets to entry")
	quit()
