extends SceneTree
var g
func _initialize():call_deferred('run')
func run():
 g=load('res://main.tscn').instantiate();root.add_child(g);await process_frame;g.new_game();g.clear_modal();g.sound_on=false;g.save_data.seed=541
 for room in range(7):
  g.build_level(room);var items=g.objects.filter(func(o):return o.kind=='accessory');assert(items.size()==1);var item=items[0];assert(not g.blocked(item.pos));g.collect_accessory(item.accessory);assert(not g.available(item))
 assert(g.save_data.accessories.size()==7);assert(g.save_data.wearing.filter(func(item):return item in g.HEAD_ACCESSORIES).size()==1)
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
 g.build_level(0);g.objects.append({'kind':'berries','id':'gift_food','pos':g.player,'solid':false});g.nearest=g.objects.size()-1;g.interact();assert(g.food_hearts_left==10 and g.food_heart_clock==.3)
 g.particles.clear();g.update_food_hearts(.29);assert(g.particles.is_empty());g.update_food_hearts(.011);assert(g.particles.size()==1)
 for n in range(9):g.update_food_hearts(.3)
 assert(g.food_hearts_left==0 and g.particles.size()==10);g.update_food_hearts(5);assert(g.particles.size()==10)
 g.build_level(6);assert(g.objects.filter(func(o):return o.kind=='heart_stand').size()==4);assert(g.objects.any(func(o):return o.kind=='column_wreath'));assert(g.objects.all(func(o):return o.kind!='candle'))
 g.persist();g.load_save();assert(g.save_data.accessories.size()==7)
 print('PASS 7 auto-equipped saved accessories, aligned frames, fertilizer mouth, facing restore, item direction, gate recovery, ground steps and final romance')
 g.queue_free();await process_frame;quit()
