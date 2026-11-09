extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var game=load("res://main.tscn").instantiate()
	root.add_child(game);await process_frame
	game.new_game();game.clear_modal();game.set_process(false);game.set_physics_process(false)
	game.playing=true;game.paused=false;game.transition=false;game.sound_on=true;game.task_time=0
	game.foliage_motion=.7
	var finished:=[0]
	game.foliage_voice.finished.connect(func():finished[0]+=1)
	var stream:AudioStreamWAV=game.foliage_voice.stream
	assert(stream.loop_mode==AudioStreamWAV.LOOP_FORWARD and stream.get_length()>1)
	for n in range(12):game.update_foliage_audio(.016)
	assert(game.foliage_voice.playing and game.foliage_gain>.6)
	await create_timer(stream.get_length()*2.2).timeout
	assert(game.foliage_voice.playing and finished[0]==0,"Rustle stopped at a clip boundary")
	game.foliage_motion=0;game.update_foliage_audio(.016)
	assert(game.foliage_voice.playing and game.foliage_gain>0,"Rustle cut off without release envelope")
	for n in range(24):game.update_foliage_audio(.016)
	assert(not game.foliage_voice.playing and game.foliage_gain==0)
	print("PASS continuous recorded rustle over two loops, no restarts, attack/release envelopes")
	game.queue_free();await process_frame
	quit()
