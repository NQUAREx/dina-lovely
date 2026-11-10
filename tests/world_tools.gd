extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame
 g.sound_on=false;g.new_game();g.clear_modal();g.set_process(false);g.set_physics_process(false)
 g.activate_cached_room(6)
 assert(g.objects.any(func(o):return o.kind=="secret_book"))
 var axe=g.objects.filter(func(o):return o.kind=="axe")[0];assert(not g.available(axe))
 g.save_data.finished=true;g.world_tools.pickup("axe");assert(g.held_item=="axe")
 var builds=g.room_build_count;g.player=Vector2(13.5*48,g.grid.size()*48+2);g.camera=g.player;g.travel(5)
 assert(g.held_item=="axe" and g.room_build_count==builds)
 var tree=g.objects.filter(func(o):return o.kind in ["tree","tree_apples"])[0]
 var tree_pos=tree.pos;assert(g.world_tools.tree_target(tree));g.world_tools.complete("axe:"+g.world_tools.key_for(tree),tree.pos)
 assert(tree.kind=="fallen_tree" and not tree.solid)
 g.world_tools.pickup("shears");assert(g.held_item=="shears" and g.objects.any(func(o):return o.kind=="axe"))
 g.build_level(5);assert(g.objects.any(func(o):return o.kind=="fallen_tree" and o.pos==tree_pos))
 g.equip_tool("rake")
 var beds=g.objects.filter(func(o):return o.kind=="sprout");var before_paths=g.paths.duplicate(true)
 var point=Vector2.ZERO
 for y in range(8,g.grid.size()-7):
  for x in range(2,g.grid[0].length()-2):
   g.player=Vector2(x+.5,y+.5)*48;g.walk_facing=Vector2.UP
   if g.world_tools.can_bed():point=g.world_tools.ground_point();break
  if point!=Vector2.ZERO:break
 assert(point!=Vector2.ZERO)
 g.world_tools.complete("new_bed",point)
 var extra=g.objects.filter(func(o):return o.kind=="sprout" and o.get("extra_bed",false))[0]
 assert(extra.id in g.save_data.cleaned and extra.id not in g.fertilized and g.paths==before_paths)
 g.plants[extra.id]={"stage":2,"remaining":0.0};g.watered=["0","1","2","3","4","5",extra.id]
 assert(g.required_flowers_ready() and g.required_flower_count()==6)
 g.world_tools.complete("uproot:"+extra.id,extra.pos);assert(not g.plants.has(extra.id) and extra.id not in g.watered and g.world_tools.falling.size()==1)
 g.build_level(3);g.held_item="shovel";g.sync_hands();g.save_data.dig_target=[600,600];g.save_data.buried_exposed=false
 g.world_tools.excavate(Vector2(600,600));g.world_tools.excavate(Vector2(624,600));g.world_tools.excavate(Vector2(648,600))
 assert(g.objects.filter(func(o):return o.id=="buried").size()==1)
 assert(g.world_tools.state().excavations.size()>=3)
 var mask:Image=g.world_tools.masks["3"]
 for x in range(300,325):assert(mask.get_pixel(x,300).r>.5)
 g.world_tools.pickup("drill");g.player=Vector2(13.5,12.5)*48;g.walk_facing=Vector2.RIGHT;g.world_tools.update(.2)
 assert(g.world_tools.drilling)
 g.build_level(4);assert(not g.world_tools.soil(Vector2(600,600)))
 g.build_level(0);g.held_item="shears";g.world_tools.refresh_targets()
 var cut=Vector2i.ZERO
 for y in range(7,g.grid.size()-7):
  for x in range(2,g.grid[0].length()-2):
   if g.grid[y][x]=="#":cut=Vector2i(x,y);break
  if cut!=Vector2i.ZERO:break
 var cell_point=(Vector2(cut)+Vector2(.5,.5))*48
 g.world_tools.complete("snip_hedge:%d:%d"%[cut.x,cut.y],cell_point)
 assert(g.grid[cut.y][cut.x]=="." and not g.hedge_field.blocks(cell_point))
 assert(g.hedge_field.crowns.any(func(o):return o.get("hidden",false)))
 g.persist();var edits=g.save_data.world_edits.duplicate(true);var tool=g.held_item;g.load_save()
 assert(g.save_data.world_edits.keys()==edits.keys() and g.save_data.held_item==tool)
 g.build_level(0);assert(g.grid[cut.y][cut.x]==".")
 g.build_level(5);assert(g.objects.any(func(o):return o.get("extra_bed",false)))
 g.build_level(3);assert(g.objects.filter(func(o):return o.id=="buried").size()==1)
 print("PASS gated portable tools, drop/swap, tree/crown edits, repeatable beds, six-flower quest, merged excavation, drill soil restrictions and save roundtrip")
 quit()
