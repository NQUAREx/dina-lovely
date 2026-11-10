extends SceneTree
func _initialize():call_deferred("run")
func route(g,start:Vector2i,finish:Vector2i)->Array:
 var queue=[start];var parents={start:start}
 while not queue.is_empty():
  var cell=queue.pop_front()
  if cell==finish:break
  for v in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
   var next:Vector2i=cell+v
   if parents.has(next) or not g.valid_ground((Vector2(next)+Vector2(.5,.5))*48) or g.blocked((Vector2(next)+Vector2(.5,.5))*48):continue
   parents[next]=cell;queue.append(next)
 assert(parents.has(finish))
 var path=[];var current=finish
 while current!=start:path.push_front((Vector2(current)+Vector2(.5,.5))*48);current=parents[current]
 return path
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame
 g.new_game();g.clear_modal();g.sound_on=false;g.set_process(false);g.set_physics_process(false)
 for seed in [17,113,723]:
  g.save_data.seed=seed;g.build_level(5)
  var beds=g.objects.filter(func(o):return o.kind=="sprout")
  assert(beds.size()==6)
  for bed in beds:assert(g.garden_bed_clear(bed.pos,false))
  var well=g.objects.filter(func(o):return o.kind=="well")[0]
  assert(not g.garden_bed_clear(well.pos+Vector2(0,-50)))
 var well=g.objects.filter(func(o):return o.kind=="well")[0]
 var paths=g.paths.duplicate(true)
 g.world_tools.state().beds.append({"id":"991","pos":[well.pos.x,well.pos.y]});g.plants["991"]={"stage":1,"remaining":0}
 g.world_tools.install();var repaired=g.objects.filter(func(o):return o.id=="991")[0]
 assert(repaired.pos!=well.pos and g.garden_bed_clear(repaired.pos,false) and g.plants["991"].stage==1 and g.paths==paths)
 g.build_level(0);var spawn=g.player
 var hut=g.objects.filter(func(o):return o.kind=="cat_hut")[0];var fish=g.objects.filter(func(o):return o.kind=="cat_fish")[0]
 assert(route(g,Vector2i(spawn/48),Vector2i(fish.pos/48)).size()>0)
 g.player=fish.pos;g.nearest=g.objects.find(fish);g.interact();assert(g.save_data.cat_fish)
 g.player=hut.pos+Vector2(0,48);g.nearest=g.objects.find(hut);g.interact();assert(g.save_data.cat_tamed and not g.save_data.cat_fish)
 var initial=g.companion.position;g.companion.update(.1);assert(g.companion.position==initial)
 var path=route(g,Vector2i(g.player/48),Vector2i(spawn/48))
 for point in path.slice(0,mini(30,path.size())):
  for n in range(80):
   if g.player.distance_to(point)<1:break
   g.move_player(.016,(point-g.player).normalized()*minf(1,g.player.distance_to(point)/(g.SPEED*.016)));g.companion.update(.016)
   assert(not g.blocked(g.companion.position))
 for n in range(100):g.companion.update(.016)
 assert(g.companion.position.distance_to(g.player)<50 and not g.companion.prints.is_empty())
 assert(g.save_data.stats.steps>0 and g.save_data.stats.distance>0)
 g.held_item="rake";g.find_nearest();assert(g.nearest<0 or g.objects[g.nearest].kind!="pet_cat")
 g.prepare_room_cache(0)
 g.held_item="";g.player=Vector2(15.5*48,-2);g.companion.position=g.player+Vector2(0,65);g.companion.trail.clear();g.companion.trail.append({"pos":g.player,"time":g.companion.clock});g.companion.last_player=g.player;g.camera=g.player
 var before=g.screen(g.companion.position);g.travel(1);assert(g.screen(g.companion.position).is_equal_approx(before))
 g.stats.add(g,"kills");g.stats.add(g,"waterings");g.persist();var steps=int(g.save_data.stats.steps);g.load_save();assert(g.save_data.cat_tamed and int(g.save_data.stats.steps)==steps and int(g.save_data.stats.kills)==1)
 g.build_level(6);var stone=g.objects.filter(func(o):return o.kind=="stats_stone")[0];var book=g.objects.filter(func(o):return o.kind=="secret_book")[0]
 assert(is_equal_approx(stone.pos.x+book.pos.x,g.grid[0].length()*48) and stone.pos.y==book.pos.y)
 g.player=stone.pos+Vector2(-55,0);g.nearest=g.objects.find(stone);g.interact();assert(g.paused and g.modal!=null)
 print("PASS well/bed clearance, legacy-bed repair, fish/taming, delayed wall-safe route, paw prints, seam carry, stats persistence and symmetric tablet")
 quit()
