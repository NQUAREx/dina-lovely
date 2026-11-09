extends SceneTree
var g
func _initialize():call_deferred('run')
func run():
 g=load('res://main.tscn').instantiate();root.add_child(g);await process_frame;var previous_save=FileAccess.get_file_as_string(g.SAVE_PATH) if FileAccess.file_exists(g.SAVE_PATH) else '';g.new_game();g.clear_modal();g.sound_on=false;g.save_data.seed=541
 for room in range(7):
  g.build_level(room);var items=g.objects.filter(func(o):return o.kind=='accessory' and not o.get('dropped_accessory',false));assert(items.size()==2)
  for item in items:assert(not g.blocked(item.pos));g.collect_accessory(item.accessory);assert(not g.available(item))
 assert(g.save_data.accessories.size()==14);assert(g.save_data.wearing.filter(func(item):return g.ACCESSORY_SLOTS[item]=='head').size()==1);assert(g.save_data.loose_accessories.size()==9)
 for item in g.ACCESSORIES:
  for direction in range(4):
   for frame in range(4):assert(g.sprites.has('wear_'+item+'_'+str(direction)+'_'+str(frame)))
 g.build_level(5);g.held_item='fertilizer';g.sync_hands();g.direction=3;g.walk_facing=Vector2.RIGHT
 var bed=g.objects.filter(func(o):return o.kind=='sprout')[0];g.player=bed.pos+Vector2(50,30);g.begin_task('fertilize:'+bed.id,bed.pos,1.6)
 var pose=g.held_tool_pose();assert((pose.tip-pose.hand).normalized().dot((bed.pos+Vector2(0,-10)-pose.hand).normalized())>.95)
 assert(g.direction==1);g.update_tasks(2.0);assert(g.direction==3 and g.walk_facing==Vector2.RIGHT)
 g.held_item='can';g.sync_hands();g.walk_facing=Vector2.RIGHT;var right=g.held_tool_pose();g.walk_facing=Vector2.LEFT;var left=g.held_tool_pose();assert(right.tip.x>right.hand.x and left.tip.x<left.hand.x)
 g.save_data.letters.append('garden');g.save_data.open_gates.append(5);var door=g.objects.filter(func(o):return o.id=='exit')[0];door.gate_amount=.1;g.player=door.pos;assert(g.blocked(g.player));g.resolve_gate_overlap(door);assert(not g.blocked(g.player))
 g.particles.clear();g.leave_footprint(Vector2.DOWN);assert(g.particles.all(func(p):return p.get('ground',false)));assert(g.footprints.size()>0)
 g.build_level(0);g.objects.append({'kind':'berries','id':'gift_food','pos':g.player,'solid':false});g.nearest=g.objects.size()-1;g.interact();assert(g.food_hearts_left==10 and g.food_heart_clock==.2);assert(g.particles.filter(func(p):return p.heart and p.color==Color('ef436b')).size()==18)
 g.particles.clear();g.update_food_hearts(.19);assert(g.particles.is_empty());g.update_food_hearts(.011);assert(g.particles.size()==1)
 for n in range(9):g.update_food_hearts(.2)
 assert(g.food_hearts_left==0 and g.particles.size()==10);g.update_food_hearts(5);assert(g.particles.size()==10)
 g.build_level(6);assert(g.objects.filter(func(o):return o.kind=='heart_stand').size()==4);assert(g.objects.any(func(o):return o.kind=='column_wreath'));assert(g.objects.all(func(o):return o.kind!='candle'))
 g.persist();g.load_save();assert(g.save_data.accessories.size()==14 and g.save_data.loose_accessories.size()==9)
 var drop_room=int(g.save_data.loose_accessories.filter(func(d):return d.accessory=='wreath')[0].room);g.build_level(drop_room);var old_wreath=g.objects.filter(func(o):return o.kind=='accessory' and o.accessory=='wreath' and o.get('dropped_accessory',false))[0];assert(g.available(old_wreath));g.collect_accessory('wreath');assert('wreath' in g.save_data.wearing);assert(g.save_data.loose_accessories.any(func(d):return d.accessory=='heart_tiara' and int(d.room)==drop_room));assert(g.save_data.loose_accessories.size()==9)
 g.save_data=g.default_save();g.save_data.accessories=['wreath','crown','brooch'];g.save_data.wearing=['crown','brooch'];g.repair_accessory_save(true);assert(g.save_data.wearing==['crown']);assert(g.save_data.loose_accessories.size()==1 and g.save_data.loose_accessories[0].accessory=='wreath');assert('brooch' not in g.save_data.accessories)
 print('PASS 14 accessories / 2 per room, slot swaps/drop/re-pick/save/migration, 18 burst + 10 timed hearts, aligned frames and existing garden/gate controls')
 var path=g.SAVE_PATH;g.queue_free();await process_frame
 if previous_save.is_empty():DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
 else:var file=FileAccess.open(path,FileAccess.WRITE);file.store_string(previous_save);file.close()
 quit()
