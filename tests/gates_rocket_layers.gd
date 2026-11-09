extends SceneTree
var g
func _initialize():call_deferred('run')
func run():
 g=load('res://main.tscn').instantiate();root.add_child(g);await process_frame;g.new_game();g.clear_modal();g.sound_on=false
 for room in range(6):
  g.build_level(room);assert(not g.level_complete());var pos=Vector2(15.5 if room==0 else 13.5,6.8)*48;assert(g.blocked(pos))
  if room>0:assert(g.door_is_open("back") and not g.blocked(Vector2(13.5,g.grid.size()-6.8)*48))
  match room:
   0:g.save_data.letters.append_array(['dawn','flower','star'])
   1:g.save_data.letters.append_array(['shade_1','shade_2','shade_3'])
   2:g.save_data.obstacles=range(5);g.save_data.letters.append('crossing')
   3:g.save_data.letters.append('buried')
   4:g.save_data.letters.append('courage')
   5:g.save_data.letters.append('garden')
  assert(g.level_complete() and g.blocked(pos));g.use_exit();assert(g.door_is_open("exit") and not g.blocked(pos))
 print('PASS six gates require completion and explicit interaction; entrances always accessible')
 g.build_level(4);g.save_data.letters.erase('courage');g.combat_done=false;g.spawn_wave();assert(g.enemies.all(func(e):return not g.blocked(e.pos)));g.enemies.clear();g.weapon='rpg';g.held_item='rpg';g.attack_cd=0;g.rpg_reload=0;g.attack();assert(g.shots.is_empty() and g.rpg_windup>0);g.rpg_windup=-1;g.attack(true)
 assert(is_equal_approx(g.rpg_reload,1.62) and g.shots.size()==1);g.attack_cd=0;g.attack();assert(g.shots.size()==1);g.update_shots(.1);assert(g.shots[0].vel.length()<200);print('PASS RPG reload +20 percent and slower flight')
 g.build_level(5);assert(g.grass_texture!=null)
 for bed in g.objects:
  if bed.kind=='sprout':assert(g.bed_beside_path(bed.pos,bed))
 print('PASS baked ground texture and connected bed pads')
 g.build_level(0);assert(g.sprites.has('gate_panel') and g.sprites.has('weapon_rpg_empty'));print('PASS gate and empty launcher artwork')
 for seed in [17,2026]:
  g.save_data.seed=seed;g.build_level(5)
  var well=g.objects.filter(func(o):return o.kind=='well')[0]
  for path in g.paths:
   var joined=g.path_pads.any(func(p):return path[-1].distance_to(p.pos)<p.radius-15)
   for other in g.paths:
    if other==path:continue
    for point in other:
     if path[-1].distance_to(point)<4:joined=true
   assert(joined)
  for bed in g.objects:
   if bed.kind=='sprout':assert(g.bed_beside_path(bed.pos,bed))
 g.build_level(1);assert(g.objects.all(func(o):return o.kind!='lamp'))
 g.build_level(4);assert(g.objects.all(func(o):return o.kind not in ['flowers','blueflowers','tree','tree_apples']));assert(g.objects.any(func(o):return o.kind=='crate'))
 g.enemies.clear();g.enemies.append({'pos':g.player+Vector2(80,-80),'hp':3,'type':1,'state':'rest','timer':1.0});g.damage_enemy(0,1,Vector2.ZERO);assert(g.enemies[0].hit_until>g.time);g.damage_enemy(0,9,Vector2.ZERO);assert(g.enemies.is_empty());assert(g.room_remains[4].any(func(r):return r.kind=='corpse1'))
 g.build_level(5);g.build_level(4);assert(g.room_remains[4].any(func(r):return r.kind=='corpse1'))
 g.build_level(0);g.objects.append({'kind':'tree_apples','id':'test_apple','pos':g.player,'solid':false});g.nearest=g.objects.size()-1;g.interact();assert('test_apple' in g.save_data.eaten and g.objects[-1].kind=='tree_apples' and not g.available(g.objects[-1]))
 print('PASS connected circular pads, dark lamps, concrete props, hit flashes, persistent remains and edible fruit')
 g.queue_free();await process_frame;quit()
