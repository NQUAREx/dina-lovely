extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame;g.new_game();g.clear_modal();g.set_process(false);g.set_physics_process(false);g.sound_on=false;g.activate_cached_room(4)
 var first=[]
 for wave in range(1,8):
  g.enemies.clear();g.wave=wave;g.battle.spawn(false,false)
  assert(g.enemies.size()==g.battle.WAVES[wave-1].size())
  for e in g.enemies:
   assert(g.battle.spawn_clear(e.pos));assert(e.pos.distance_to(g.player)>=190)
   for other in g.enemies:
    if other!=e:assert(e.pos.distance_to(other.pos)>=60)
  if wave<=3:assert(not g.enemies.any(func(e):return e.type>=5))
  else:assert(g.enemies.filter(func(e):return e.type>=5).size()>=2)
  if wave==1:first=g.enemies.map(func(e):return e.pos)
 g.enemies.clear();g.wave=1;g.battle.spawn(false,false);assert(first!=g.enemies.map(func(e):return e.pos))
 print("PASS seven waves: random clear spaced spawns, safe player distance and gradual shooters")
 quit()
