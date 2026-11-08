extends SceneTree
var game
func _initialize():call_deferred('run')
func check(ok: bool,text:String):assert(ok,text);print('PASS ',text)
func run():
	game=load('res://main.tscn').instantiate();root.add_child(game);await process_frame
	game.new_game();game.clear_modal();game.build_level(1)
	check(game.grid[0][13]=='.' and game.grid[game.grid.size()-1][13]=='.','corridor has open ends')
	check(game.grid[0][0]==' ','corridor surroundings are void, not solid wall')
	for obj in game.objects:
		if obj.id=='flashlight':check(obj.kind=='stand_flashlight','flashlight on visible pedestal')
	check(not game.save_data.flashlight,'flashlight is not auto-created in hand')
	game.build_level(3);game.save_data.shovel=true
	check(game.objects.filter(func(o):return o.kind=='mound').is_empty(),'no pre-marked dig spots')
	game.player=Vector2(12,14)*48;game.dig_here()
	check(game.task_time==.5,'dig animation lasts half second')
	game.save_data.dig_target=[game.task_target.x,game.task_target.y];game.update_tasks(.51)
	check('buried' in game.save_data.letters,'digging at random target reveals letter')
	game.clear_modal();game.build_level(4)
	check(game.weapon.is_empty(),'no weapon duplicated before pickup')
	for obj in game.objects:
		if obj.id=='rifle':game.player=obj.pos
	game.find_nearest();game.interact()
	check(game.weapon=='rifle' and 'rifle' in game.save_data.weapons_taken,'weapon is taken once')
	for obj in game.objects:
		if obj.id=='rifle':check(not game.available(obj),'empty stand cannot be picked up again')
	game.weapon='rpg';game.attack_cd=0;game.attack();var initial:float=game.shots[0].vel.length();game.update_shots(.05)
	check(game.shots[0].vel.length()>initial,'rocket accelerates after launch')
	for voice in game.audio_pool:voice.stop()
	await create_timer(.15).timeout;game.queue_free();await process_frame;await process_frame;quit()
