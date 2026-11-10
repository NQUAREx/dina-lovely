extends SceneTree
func _initialize():call_deferred("run")
func shot(pos:Vector2,vel:Vector2,remaining:float,cap:float)->Dictionary:
 return {"kind":"enemy_bullet","pos":pos,"vel":vel,"life":3.0,"age":0.0,"range_left":remaining,"max_range":cap,"shooter_type":6}
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame;g.new_game();g.clear_modal();g.set_process(false);g.set_physics_process(false);g.sound_on=false;g.activate_cached_room(4);g.objects.assign(g.objects.filter(func(o):return not o.solid));g.player=Vector2(1000,900)
 assert(g.battle.bullet_length({"kind":"rifle"})==10 and g.battle.bullet_length({"shooter_type":6})==10 and g.battle.bullet_length({"shooter_type":5})==5)
 g.shots.append(shot(Vector2(600,700),Vector2(410,0),.00003,336));g.update_shots(.016);assert(g.shots.is_empty())
 g.shots.append(shot(Vector2(600,700),Vector2.ZERO,100,336));g.update_shots(.016);assert(g.shots.is_empty())
 g.shots.append(shot(Vector2(600,700),Vector2(410,0),6.56003,336));g.update_shots(.016);assert(g.shots.is_empty())
 var legacy=shot(Vector2(600,700),Vector2(410,0),.00003,420);legacy.erase("max_range");g.shots.append(legacy);g.update_shots(.016);assert(g.shots.is_empty())
 var e={"pos":Vector2(600,700),"type":6,"state":"chase","timer":0.0,"cooldown":0.0};g.player=Vector2(850,700);g.update_gunner(e,.016);assert(g.shots.back().max_range==336 and g.shots.back().shooter_type==6)
 g.shots.clear();g.player=Vector2(1000,900);g.shots.append(shot(Vector2(400,700),Vector2(410,0),336,336));g.update_shots(1.0);assert(g.shots.is_empty())
 g.enemies.assign([{"pos":Vector2(650,700),"hp":10.0,"max_hp":10.0,"type":0,"boss":false,"state":"chase","timer":0.0,"cooldown":1.0}]);g.weapon="rifle";g.player=Vector2(400,700)
 g.shots.append({"kind":"rifle","pos":Vector2(550,684),"vel":Vector2(570,0),"life":1.4,"age":0.0});g.update_shots(.2);assert(g.enemies[0].hp==5.0)
 g.activate_cached_room(3);g.world_tools.excavate(Vector2(600,600));var color:Color=g.world_tools.images["3"].get_pixel(300,306);assert(color.v>.13 and color.v<.24)
 print("PASS shared AK tracer, half-length pistol tracer, tiny-range and zero-speed cleanup, legacy migration, 336px cap, 5 HP AK and lighter earth pit")
 quit()
