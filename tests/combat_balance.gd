extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame;g.new_game();g.clear_modal();g.set_process(false);g.set_physics_process(false);g.sound_on=false;g.activate_cached_room(4);g.save_data.level=4;g.health=3.5
 for wave in range(1,11):
  g.enemies.clear();g.spawn_wave();assert(g.wave==wave and is_equal_approx(g.health,3.5))
  var guns=g.enemies.filter(func(e):return e.type in [5,6,7])
  if wave<=5:assert(guns.is_empty())
  if wave in [6,7,8,9]:assert(guns.size()>=6)
  if wave==10:
   assert(g.enemies.size()==24 and g.enemies.filter(func(e):return e.type==7).size()==4 and g.enemies.filter(func(e):return e.type==6).size()==6 and g.enemies.filter(func(e):return e.type==3).size()==5 and g.enemies.filter(func(e):return e.boss).size()==1)
 g.objects.assign(g.objects.filter(func(o):return not o.solid));g.enemies.clear();g.player=Vector2(850,700)
 for kind in [5,6,7]:
  g.enemies.clear();g.battle.enemy(kind,Vector2(600,700),40);var e=g.enemies[0];e.state="patrol";e.cooldown=0;e.sense=0;g.player=Vector2(800,700);g.shots.clear()
  var clip:int=g.battle.GUNS[kind].clip
  for n in range(clip):e.cooldown=0;g.update_gunner(e,.001)
  assert(g.shots.size()==clip and e.reload_left>2 and e.ammo==0)
  var count=g.shots.size();e.cooldown=0;g.update_gunner(e,.2);assert(g.shots.size()==count)
  assert(g.shots[0].damage==(1.0 if kind==5 else 1.5 if kind==6 else 2.0))
  e.reload_left=.01;e.cooldown=0;g.update_gunner(e,.02);assert(g.shots.size()==count+1)
  e.reload_left=1;e.pos=Vector2(700,700);g.player=Vector2(710,700);var before:float=e.pos.distance_to(g.player);g.update_gunner(e,.1);assert(e.pos.distance_to(g.player)>before)
 g.enemies.clear();g.battle.enemy(0,Vector2(500,650),20);var idle=g.enemies[0];idle.state="patrol";g.player=Vector2(1000,1000);var origin:Vector2=idle.pos
 for n in range(120):g.time+=.016;g.battle.tick(.016)
 assert(not idle.aggro and idle.pos.distance_to(g.player)>400 and idle.pos.distance_to(origin)>1)
 g.player=idle.pos+Vector2(100,0);idle.sense=0;g.battle.tick(.016);assert(idle.aggro)
 g.enemies.clear();g.player=Vector2(1000,1000)
 for n in range(6):g.battle.enemy(0,Vector2(650,700),20)
 for n in range(20):g.battle.separate()
 for i in range(g.enemies.size()):
  for j in range(i+1,g.enemies.size()):assert(g.enemies[i].pos.distance_to(g.enemies[j].pos)>40)
 g.enemies.assign([{"pos":Vector2(650,700),"hp":20.0,"max_hp":20.0,"type":0,"boss":false,"state":"chase","timer":0.0,"cooldown":1.0}]);g.weapon="rifle";g.player=Vector2(400,700)
 g.shots.clear();g.shots.append({"kind":"rifle","pos":Vector2(550,684),"vel":Vector2(570,0),"life":1.4,"age":0.0});g.update_shots(.2);assert(is_equal_approx(g.enemies[0].hp,11.5))
 g.enemies.clear();g.shots.clear();g.health=8;g.invincible=0;g.weapon="sword";g.held_item="sword";g.attack_cd=0;g.player=Vector2(450,700)
 g.battle.enemy(6,Vector2(650,700),32);var reloading=g.enemies[0];reloading.state="chase";reloading.aggro=true;reloading.ammo=0;reloading.reload_left=3;reloading.reload_duration=3
 for n in range(200):
  if g.enemies.is_empty():break
  g.time+=.016;g.attack_cd=maxf(0,g.attack_cd-.016)
  if g.player.distance_to(reloading.pos)>110:g.player+=g.player.direction_to(reloading.pos)*140*.016
  g.battle.tick(.016);g.update_shots(.016)
  if g.player.distance_to(reloading.pos)<125 and g.attack_cd<=0:g.attack()
 assert(g.enemies.is_empty() and g.health==8)
 g.health=.5;g.wave=8;g.held_item="rifle";g.persist();assert(g.arena_save.valid());g.load_save();g.arena_save.restore_room();assert(is_equal_approx(g.health,.5))
 var checkpoint=g.save_data.arena_checkpoint;checkpoint.erase("balance");g.wave=3;checkpoint.fields.wave=3;g.arena_save.restore_room();assert(g.wave==3 and not g.enemies.any(func(e):return e.type in [5,6,7]) and is_equal_approx(g.health,.5))
 print("PASS ten balanced waves, exact finale, clips/reload/damage, slow retreat, local aggro/patrol, six-body separation, 8.5 HP AK, fractional checkpoint and old-wave migration")
 quit()
