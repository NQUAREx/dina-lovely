extends SceneTree
var g
func _initialize():call_deferred('run')
func check(v:bool,t:String):assert(v,t);print('PASS ',t)
func run():
	g=load('res://main.tscn').instantiate();root.add_child(g);await process_frame;g.new_game();g.clear_modal()
	var first=g.grid.duplicate();var seed=g.save_data.seed
	check(g.grid[g.grid.size()-6].count('#')==g.grid[0].length(),'first room south perimeter sealed')
	check(g.grid[6][0]=='#' and g.grid[6][-1]=='#','maze east and west edges sealed')
	g.new_game();g.clear_modal();check(g.save_data.seed!=seed and g.grid!=first,'new game creates different maze')
	g.build_level(6);check(g.grid[5].count('#')==g.grid[0].length(),'final north perimeter sealed')
	g.build_level(2);check(g.grid[12][7]==' ' and g.grid[12][8]=='#' and g.grid[12][9]=='.','obstacle side is one block')
	check(g.objects.filter(func(o):return o.kind=='tree').is_empty(),'no trees inside obstacle walls')
	g.player=g.obstacle_rect(0).get_center();g.update_new_rooms(.001);check(g.player.distance_to(Vector2(13.5,g.grid.size()-7.5)*48)<1,'collision returns to start')
	g.build_level(3);g.save_data.shovel=true;g.player=Vector2(12,11)*48;g.dig_here();check(g.task_time==.25,'dig lasts quarter second')
	g.save_data.dig_target=[g.task_target.x,g.task_target.y];g.update_tasks(.26);check(g.save_data.buried_exposed and 'buried' not in g.save_data.letters,'letter emerges before reading')
	check(g.objects.any(func(o):return o.id=='buried'),'emerged letter is interactable')
	g.build_level(4);g.weapon='sword'
	for o in g.objects:
		if o.id=='rifle':g.player=o.pos
	g.find_nearest();g.interact();check(g.weapon=='rifle' and g.objects.any(func(o):return o.id.begins_with('drop_')),'old weapon dropped on pickup')
	g.enemies.clear();g.enemies.append({'pos':g.player+Vector2(0,-60),'hp':3,'state':'chase','type':0,'timer':0.,'cooldown':0.})
	g.enemies.append({'pos':g.player+Vector2(60,-60),'hp':3,'state':'chase','type':0,'timer':0.,'cooldown':0.})
	g.weapon='rpg';g.attack_cd=0;g.attack();g.shots[0].pos=g.enemies[0].pos;g.shots[0].vel=Vector2.ZERO;g.update_shots(.01)
	check(g.enemies.size()==1 and g.enemies[0].hp==3,'rocket kills direct target only')
	g.queue_free();await process_frame;quit()
