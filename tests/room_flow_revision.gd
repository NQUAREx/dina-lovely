extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame
	var previous_save:=FileAccess.get_file_as_string(g.SAVE_PATH) if FileAccess.file_exists(g.SAVE_PATH) else ""
	g.sound_on=false;g.new_game();g.clear_modal();g.set_process(false);g.set_physics_process(false)
	assert(g.room_cache.size()==7)
	assert("black_dress" in g.save_data.wearing)
	g.collect_accessory("white_dress")
	assert("black_dress" not in g.save_data.wearing and g.save_data.loose_accessories.any(func(drop):return drop.accessory=="black_dress"))
	g.collect_accessory("black_dress");assert("black_dress" in g.save_data.wearing)
	g.build_level(3);g.save_data.buried_exposed=false;g.save_data.dug=[];g.save_data.dig_target=[600,600]
	g.task_kind="dig:600:600";g.task_target=Vector2(600,600);g.task_time=.1;g.update_tasks(.2)
	assert(g.save_data.buried_exposed)
	g.task_kind="dig:624:600";g.task_target=Vector2(624,600);g.task_time=.1;g.update_tasks(.2)
	assert(g.objects.filter(func(obj):return obj.id=="buried").size()==1)
	assert(g.world_tools.state().excavations.size()>=1 and g.objects.filter(func(obj):return obj.kind=="dug").is_empty())
	assert(Vector2(g.save_data.dig_target[0],g.save_data.dig_target[1])==Vector2(600,600))
	g.build_level(3);assert(g.objects.filter(func(obj):return obj.id=="buried").size()==1)
	g.build_level(1);var seat=g.objects.filter(func(obj):return obj.kind=="bench" and obj.id=="seat")[0]
	g.player=seat.pos+Vector2(0,45);g.nearest=g.objects.find(seat);g.interact();assert(g.resting=="seat");g.stand_up()
	g.build_level(5);var bed=g.objects.filter(func(obj):return obj.kind=="sprout")[0]
	assert(g.garden_need(bed)=="rake");g.save_data.cleaned.append(bed.id);assert(g.garden_need(bed)=="fertilizer")
	g.fertilized.append(bed.id);assert(g.garden_need(bed)=="water");g.plants[bed.id]={"stage":1,"remaining":2.0};assert(g.garden_need(bed)=="")
	g.plants[bed.id]={"stage":2,"remaining":0.0};assert(g.garden_need(bed)=="")
	g.save_data=g.default_save();g.held_item="";g.room_cache.clear();g.room_cache_seed=-1;g.ensure_riddle();g.prepare_room_cache(0)
	g.save_data.letters.assign(g.REQUIRED);g.use_exit();assert(not g.door_is_open("exit"))
	g.spawn_gate_key("star");assert(g.objects.filter(func(obj):return obj.kind=="gate_key").size()==1)
	g.spawn_gate_key("star");assert(g.objects.filter(func(obj):return obj.kind=="gate_key").size()==1)
	var key=g.objects.filter(func(obj):return obj.kind=="gate_key")[0]
	g.player=key.pos;g.find_nearest();g.nearest=g.objects.find(key);g.interact();assert(0 in g.save_data.gate_keys)
	g.use_exit();assert(g.door_is_open("exit") and 0 not in g.save_data.gate_keys)
	var builds:int=g.room_build_count
	g.player=Vector2(15.5*48,-g.HALL_SEAM-2);g.camera=g.player+Vector2(0,16)
	g.joy_active=true;g.joy_vector=Vector2.UP;g.joy_id=7
	var before:Vector2=g.screen(g.player)
	g.next_level();assert(g.level==1 and g.room_build_count==builds and not g.paused and not g.transition)
	assert(g.joy_active and g.joy_vector==Vector2.UP and g.joy_id==7 and g.screen(g.player).is_equal_approx(before))
	assert(not g.blocked(g.player))
	var frozen:float=g.room_cache[0].room_clock;g.update_new_rooms(.5);assert(g.room_cache[0].room_clock==frozen)
	g.player=Vector2(13.5*48,(g.grid.size()*48)+g.HALL_SEAM+2);g.camera=g.player;g.travel(0)
	assert(g.level==0 and g.room_build_count==builds and not g.blocked(g.player))
	g.activate_cached_room(4);g.playing=true;g.paused=false;g.weapon="rpg";g.held_item="rpg";g.rpg_reload=0;g.attack_cd=0;g.combat_done=false;g.aim=Vector2.RIGHT
	g.attack();assert(is_equal_approx(g.rpg_windup,.20) and g.shots.is_empty())
	g._process(.19);assert(g.shots.is_empty());g._process(.02);assert(g.shots.size()==1)
	var creak:AudioStreamWAV=load("res://assets/gate_open.wav");assert(creak.get_length()>.6)
	print("PASS base dress swap, unique letter pit, night bench, garden needs, key-gated exit and no-build/no-pause joystick-preserving corridor handoff")
	var path:String=g.SAVE_PATH;g.queue_free();await process_frame
	if previous_save.is_empty():DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	else:
		var file:=FileAccess.open(path,FileAccess.WRITE);file.store_string(previous_save);file.close()
	quit()
