extends SceneTree
var g
func _initialize():call_deferred('run')
func run():
 g=load('res://main.tscn').instantiate();root.add_child(g);await process_frame;g.new_game();g.clear_modal();g.sound_on=false
 for room in range(6):
  g.build_level(room);assert(not g.level_complete());var pos=Vector2(15.5 if room==0 else 13.5,6.8)*48;assert(g.blocked(pos))
  if room>0:assert(g.blocked(Vector2(13.5,g.grid.size()-6.8)*48))
  match room:
   0:g.save_data.letters.append_array(['dawn','flower','star'])
   1:g.save_data.letters.append_array(['shade_1','shade_2','shade_3'])
   2:g.save_data.obstacles=range(5);g.save_data.letters.append('crossing')
   3:g.save_data.letters.append('buried')
   4:g.save_data.letters.append('courage')
   5:g.save_data.letters.append('garden')
  assert(g.level_complete() and not g.blocked(pos))
 print('PASS six forward gates lock and unlock with level completion')
 g.build_level(4);g.save_data.letters.erase('courage');g.combat_done=false;g.spawn_wave();assert(g.enemies.all(func(e):return not g.blocked(e.pos)));g.enemies.clear();g.weapon='rpg';g.held_item='rpg';g.attack_cd=0;g.rpg_reload=0;g.attack()
 assert(is_equal_approx(g.rpg_reload,1.62) and g.shots.size()==1);g.attack_cd=0;g.attack();assert(g.shots.size()==1);g.update_shots(.1);assert(g.shots[0].vel.length()<200);print('PASS RPG reload +20 percent and slower flight')
 g.build_level(5);assert(g.grass_texture!=null)
 for bed in g.objects:
  if bed.kind=='sprout':assert(g.bed_beside_path(bed.pos,bed))
 print('PASS baked ground texture and beds beside organic paths')
 g.build_level(0);assert(g.sprites.has('gate_panel') and g.sprites.has('weapon_rpg_empty'));print('PASS gate and empty launcher artwork')
 g.queue_free();await process_frame;quit()
