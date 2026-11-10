extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame;g.new_game();g.clear_modal();g.sound_on=false;g.set_process(false);g.set_physics_process(false);g.build_level(4);g.health=3
 for wave in range(1,11):
  g.enemies.clear();g.spawn_wave();assert(g.health==3)
  var pistols=g.enemies.filter(func(e):return e.type==5);var rifles=g.enemies.filter(func(e):return e.type==6)
  assert(pistols.size()==g.battle.WAVES[wave-1].count(5) and rifles.size()==g.battle.WAVES[wave-1].count(6))
  var kits=g.objects.filter(func(o):return o.kind=="medkit")
  if wave not in [3,6,9]:assert(kits.is_empty())
  if wave in [3,6,9]:
   assert(kits.size()==1 and not g.blocked(kits[0].pos))
   var kit=kits[0];g.player=kit.pos+Vector2(0,25);g.nearest=g.objects.find(kit);g.health=8;g.interact();assert(g.objects.has(kit))
   g.health=2;g.nearest=g.objects.find(kit);g.interact();assert(g.health==8 and not g.objects.has(kit));g.health=3
  if wave==10:assert(pistols.size()==0 and rifles.size()==2 and g.enemies.filter(func(e):return e.type==7).size()==2)
 for kind in [5,6,7]:
  g.objects.assign(g.objects.filter(func(o):return not o.solid));g.enemies.clear();g.battle.enemy(kind,Vector2(650,700),40);var e=g.enemies[0];e.state="chase";g.player=Vector2(750,850);var values={}
  for n in range(12):
   e.cooldown=0;e.reload_left=0;e.ammo=g.battle.GUNS[kind].clip;g.update_gunner(e,.01);values[e.cooldown]=true
   assert(e.cooldown>=g.battle.GUNS[kind].interval.x and e.cooldown<=g.battle.GUNS[kind].interval.y)
  assert(values.size()>8)
 g.held_item="rpg";g.weapon="rpg";g.rpg_reload=0;g.attack_cd=0;g.reload_time=0;g.attack();g.attack(true);assert(is_equal_approx(g.rpg_reload,3.24) and is_equal_approx(g.attack_cd,3.24))
 g.build_level(3);g.world_tools.excavate(Vector2(600,600));g.world_tools.excavate(Vector2(624,600))
 var image:Image=g.world_tools.images["3"];var upper:Color=image.get_pixel(300,294);var bottom:Color=image.get_pixel(300,306)
 assert(bottom.a>0 and upper.v>.18 and bottom.v>.13 and bottom.v<.24 and bottom.v<upper.v*.8)
 print("PASS ten waves without regeneration, third/sixth/ninth-wave reusable/full-heal medkit, more shooters, random cadence, 3.24s RPG reload and dark merged-pit bottom")
 quit()
