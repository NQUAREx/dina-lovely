extends SceneTree
var g
func _initialize():call_deferred('run')
func run():
 g=load('res://main.tscn').instantiate();root.add_child(g);await process_frame;g.new_game();g.clear_modal();g.sound_on=false
 var original=g.grid.duplicate();g.grid.clear()
 for y in range(25):g.grid.append('#'+'.'.repeat(23)+'#')
 for y in range(7,18):g.set_cell(10,y,'#')
 for seam in range(8,18):assert(g.blocked(Vector2(10.5*48,seam*48)))
 for x in range(5,18):g.set_cell(x,12,'#')
 for seam in range(6,18):assert(g.blocked(Vector2(seam*48,12.5*48)))
 print('PASS continuous hedge core across horizontal and vertical seams')
 g.player=Vector2(10*48-3,10.5*48);g.update_vegetation(.04);assert(g.vegetation.size()>1);print('PASS independent leaf springs')
 g.grid=original;g.build_level(5);assert(g.path_meshes.size()>0)
 for path in g.paths:
  for p in path:
   for bed in g.objects:
    if bed.kind=='sprout':assert(p.distance_to(bed.pos)>=53)
 print('PASS paths avoid beds and use cached world meshes')
 g.begin_task('rake:0',Vector2.ZERO,1);g.update_tasks(1.1);assert('0' in g.save_data.cleaned and '0' not in g.fertilized)
 g.begin_task('fertilize:0',Vector2.ZERO,1);assert('0' not in g.fertilized);g.update_tasks(1.1);assert('0' in g.fertilized)
 assert(g.sprites.has('bed_empty') and g.sprites.has('bed_fertilized') and g.sprites.has('seedling0') and g.sprites.has('flower_bud5'));print('PASS soil, powder, green plant and bud assets')
 g.build_level(4);g.weapon='rifle';g.enemies.append({'pos':g.player+Vector2(50,0),'hp':10,'type':0,'state':'chase','timer':0.,'cooldown':0.})
 g.damage_enemy(0,3,Vector2.ZERO);assert(g.damage_numbers.size()==1 and g.damage_numbers[0].value==3);print('PASS damage number and blood hit feedback')
 g.build_level(1);g.equip_tool('flashlight');g.direction=0;g.joy_vector=Vector2.ZERO
 for n in range(12):
  g.skull_clock=0;g.update_new_rooms(.001)
  for skull in g.skulls:
   var offset=skull.pos-(g.player+Vector2(14,-33));assert(offset.normalized().dot(Vector2.UP)>.96 and offset.length()<=145.1)
 print('PASS skulls restricted to flashlight cone')
 g.queue_free();await process_frame;quit()
