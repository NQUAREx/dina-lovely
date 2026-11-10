extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame;g.new_game();g.clear_modal();g.set_process(false);g.set_physics_process(false);g.sound_on=false;g.save_data.seed=723;g.build_level(0)
 var hut=g.objects.filter(func(o):return o.kind=="cat_hut")[0];g.objects.assign([hut]);var tested:=0
 for x in [-28,-20,0,20,28]:
  for y in [30,48,72,88]:
   g.player=hut.pos+Vector2(x,y)
   if g.blocked(g.player) or g.player.distance_to(hut.pos)>=95:continue
   var front:Vector2=hut.pos+Vector2(clampf(x,-18,18),36)
   if not g.companion.clear_segment(g.player,front):continue
   for facing in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
    g.walk_facing=facing;g.find_nearest();assert(g.interaction_reachable(hut) and g.nearest>=0 and g.objects[g.nearest].id=="cat_hut");tested+=1
 for offset in [Vector2(-48,16),Vector2(48,16),Vector2(0,-48)]:g.player=hut.pos+offset;assert(not g.interaction_reachable(hut))
 assert(tested>=20)
 g.player=hut.pos+Vector2(0,88);g.walk_facing=Vector2.DOWN;g.save_data.cat_fish=true;g.find_nearest();g.interact();assert(g.save_data.cat_tamed)
 var shader=FileAccess.get_file_as_string("res://shaders/flashlight.gdshader");assert("exp(-1.8" in shader and "158.0" in shader and not "near_light" in shader)
 print("PASS ",tested," position/facing hut checks, 88px interaction, blocked rear/corners and soft wide shorter lens beam")
 quit()
