extends SceneTree
# Crossing a corridor hands the room containers over by reference instead of
# deep copies. No two cached rooms may ever share a container, the live
# fields may only alias the active room's own cache entry, and rebuilding a
# room must never clear another room's data.
var g
func _initialize():call_deferred('run')
func check_rooms(where:String)->void:
	for field in ["objects","grid","particles","enemies","paths","hedge_trees"]:
		for a in g.room_cache:
			for b in g.room_cache:
				if a<b:assert(not is_same(g.room_cache[a][field],g.room_cache[b][field]),"%s: rooms %d and %d share %s"%[where,a,b,field])
			if a!=g.level:assert(not is_same(g.get(field),g.room_cache[a][field]),"%s: live %s aliases room %d"%[where,field,a])
func run():
	g=load('res://main.tscn').instantiate();root.add_child(g);await process_frame
	g.new_game();g.clear_modal();g.sound_on=false;g.playing=true;g.paused=false
	g.save_data.open_gates=[0,1,2,3,4,5,6]
	var sizes:={}
	for room in g.room_cache:sizes[room]=g.room_cache[room].objects.size()
	for destination in [1,2,1,0,1]:
		g.travel(destination)
		assert(g.level==destination)
		check_rooms("after travel to %d"%destination)
	# The live room keeps its data across a hand-over.
	assert(is_same(g.objects,g.room_cache[1].objects) or g.room_cache[1].objects.size()==g.objects.size())
	# Rebuilding the active room detaches first: the other rooms keep their objects.
	g.build_level(1);g.cache_current_room()
	for room in [0,2,3]:assert(g.room_cache[room].objects.size()>0,"room %d lost its objects"%room)
	check_rooms("after rebuild")
	print('PASS corridor hand-over by reference keeps every room separate')
	g.queue_free();await process_frame;quit()
