extends SceneTree
# Every room with diggable soil hides one secret letter that the drill (after
# the finale) uncovers; each id exists in both content variants.
var g
func _initialize():call_deferred('run')
func run():
	g=load('res://main.tscn').instantiate();root.add_child(g);await process_frame
	g.new_game();g.clear_modal();g.sound_on=false
	g.save_data.finished=true;g.playing=true;g.paused=false
	var letters:Dictionary=g.world_tools.SECRET_DIG_LETTERS
	assert(letters.keys().size()==5 and not letters.has(4) and not letters.has(6))
	var ids:={}
	for entry in g.content.letters:ids[entry.id]=true
	for name in ["letters.json","letters.backup.json"]:
		var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://content/"+name))
		var found:={}
		for entry in data.letters:found[entry.id]=true
		for id in letters.values():assert(found.has(id),name+" lacks "+id)
	var spots:={}
	for room in letters:
		g.activate_cached_room(room);g.world_tools.install()
		var id:String=letters[room]
		var data:Dictionary=g.world_tools.state()
		var target:Vector2=g.world_tools.secret_dig_target(data)
		assert(target!=Vector2.INF,"no soil for the secret letter in room %d"%room)
		assert(g.world_tools.soil(target))
		spots[room]=target
		# Same spot every time (stored in the save).
		assert(g.world_tools.secret_dig_target(data)==target)
		assert(not g.objects.any(func(o):return o.id==id))
		g.world_tools.excavate(target)
		var notes:Array=g.objects.filter(func(o):return o.id==id and o.kind=="note")
		assert(notes.size()==1,"drilling did not uncover %s"%id)
		g.collect(id)
		assert(id in g.save_data.letters and id in g.save_data.secrets)
		g.clear_modal()
		# Leaving and re-entering the room does not respawn a collected note.
		g.activate_cached_room(room);g.world_tools.install()
		assert(not g.objects.any(func(o):return o.id==id))
	assert(spots.size()==5)
	print('PASS a drill-only secret letter in each of the five soil rooms, stable spots, both JSON variants')
	g.queue_free();await process_frame;quit()
