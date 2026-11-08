extends SceneTree
var game
func _initialize(): call_deferred('run')
func check(ok: bool, text: String):
	assert(ok,text);print('PASS ',text)
func run():
	game=load('res://main.tscn').instantiate();root.add_child(game)
	await process_frame
	game.new_game();game.clear_modal()
	game.build_level(1)
	check(game.fog.visible,'darkness overlay enabled')
	for obj in game.objects:
		if obj.id=='flashlight':game.player=obj.pos
	game.find_nearest();game.interact()
	check(game.save_data.flashlight,'flashlight taken from corridor pedestal')
	check(not game.dark_letters_found(),'dark exit requires three letters')
	for id in ['shade_1','shade_2','shade_3']:game.collect(id);game.clear_modal()
	check(game.dark_letters_found(),'all dark letters unlock exit')
	game.travel(2)
	await create_timer(2.7).timeout
	check(game.level==2 and not game.fog.visible,'corridor enters obstacle room and removes fog')
	var start: Vector2=game.obstacle_rect(0).position
	game.room_clock+=1
	check(game.obstacle_rect(0).position.x!=start.x,'obstacle moves along X')
	game.player=game.obstacle_rect(2).get_center()
	game.obstacle_cooldown=0;game.update_new_rooms(.001)
	check(game.player.y>game.obstacle_rect(2).end.y,'collision pushes player south without damage')
	check(game.health==8,'obstacles do not take health')
	game.player=Vector2(13.5*48,8*48);game.update_new_rooms(.01)
	check(game.save_data.obstacles.size()==3,'three obstacle rows can be completed')
	game.travel(3)
	await create_timer(2.7).timeout
	check(game.level==3,'corridor enters lawn')
	game.save_data.shovel=true
	game.begin_task('dig:dig_0',Vector2.ZERO,2.6);game.update_tasks(2.7)
	check('buried' not in game.save_data.letters and 'dig_0' in game.save_data.dug,'empty dig spot persists')
	game.save_data.dig_target=[200,200]
	game.begin_task('dig:200:200',Vector2(200,200),.5);game.update_tasks(.51)
	check('buried' in game.save_data.letters,'digging finds buried letter')
	game.clear_modal();game.travel(2)
	await create_timer(2.7).timeout
	check(game.level==2,'backtracking works through new rooms')
	var f=FileAccess.open(game.SAVE_PATH,FileAccess.WRITE)
	f.store_string(JSON.stringify({'version':1,'level':2,'water':5,'completed_levels':[0,1],'letters':['dawn']}));f.close()
	game.load_save()
	check(game.save_data.level==5 and game.save_data.completed_levels==[0,4],'old save migrates original chapters')
	check(game.save_data.water==5 and game.save_data.version==2,'save migration preserves can capacity')
	game.persist();game.load_save()
	check(game.save_data.level==5,'new save is not migrated twice')
	print('NEW ROOM CHECKS COMPLETE')
	for voice in game.audio_pool:voice.stop()
	await create_timer(.15).timeout
	game.queue_free();await process_frame;await process_frame;quit()
