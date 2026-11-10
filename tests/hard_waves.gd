extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame;g.new_game();g.clear_modal();g.set_process(false);g.set_physics_process(false);g.sound_on=false;g.activate_cached_room(4)
 var first=[]
 for wave in range(1,11):
  g.enemies.clear();g.wave=wave;g.battle.spawn(false,false);var hp=0.0;var old=0.0
  for kind in g.battle.PREVIOUS_WAVES[wave-1]:old+=g.battle.base_hp(kind)
  assert(g.enemies.size()==g.battle.WAVES[wave-1].size())
  for e in g.enemies:
   hp+=e.hp;assert(g.battle.spawn_clear(e.pos));assert(e.pos.distance_to(g.player)>=190)
   for other in g.enemies:
    if other!=e:assert(e.pos.distance_to(other.pos)>=60)
  assert(abs(hp/old-2.5)<.05)
  if wave<=5:assert(not g.enemies.any(func(e):return e.type>=5))
  else:assert(g.enemies.filter(func(e):return e.type>=5).size()>=6)
  if wave==1:first=g.enemies.map(func(e):return e.pos)
 g.enemies.clear();g.wave=1;g.battle.spawn(false,false);assert(first!=g.enemies.map(func(e):return e.pos))
 print("PASS ten waves: 2.5x HP budget, random clear spaced spawns, safe player distance and more shooters")
 quit()
