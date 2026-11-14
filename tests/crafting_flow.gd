extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame
 g.new_game();g.clear_modal();g.set_process(false);g.set_physics_process(false);g.sound_on=false
 g.build_level(3)
 var q=g.dig_quest;var d=q.state()
 assert(g.objects.filter(func(o):return o.id=="shovel").is_empty())
 assert(q.point("tree")==Vector2(13.5,11.5)*48)
 var layout=d.layout.duplicate(true)
 q.install();assert(d.layout==layout)
 var axe=g.objects.filter(func(o):return o.kind=="quest_axe")[0]
 q.use(axe);assert(g.held_item=="quest_axe")
 for n in range(int(d.tree_hits)-1):q.complete("quest_chop",q.point("tree"));assert(not d.tree_down)
 q.complete("quest_chop",q.point("tree"));assert(d.tree_down)
 assert(g.objects.filter(func(o):return o.kind=="quest_branch").size()==3)
 # Collect in reverse order, reload, and verify no resources respawn.
 for kind in ["quest_branch","quest_pebble"]:
  var items=g.objects.filter(func(o):return o.kind==kind);items.reverse()
  for obj in items:q.use(obj);q.install()
 assert(d.branches==3 and d.pebbles==3)
 assert(g.objects.filter(func(o):return o.kind in ["quest_branch","quest_pebble"]).is_empty())
 q.complete("quest_pickaxe",q.point("bench"));g.equip_tool("pickaxe");assert(g.held_item=="pickaxe")
 assert(g.objects.any(func(o):return o.kind=="quest_axe"))
 g.equip_tool("quest_axe");g.equip_tool("pickaxe");assert(g.objects.any(func(o):return o.kind=="quest_axe"))
 for n in range(4):q.complete("quest_mine",q.point("rock"))
 assert(d.rock_broken)
 q.use(g.objects.filter(func(o):return o.kind=="quest_rock_fragments")[0]);assert(d.rock_taken)
 q.complete("quest_shovel",q.point("bench"));g.equip_tool("shovel");assert(g.held_item=="shovel")
 for n in range(int(d.durability)):q.wear_shovel()
 assert(d.broken)
 g.task_time=0;g.dig_here();assert(g.task_time==0)
 q.complete("quest_repair",q.point("bench"));assert(not d.broken and d.uses==0)
 var encoded=JSON.stringify(g.save_data);var decoded=JSON.parse_string(encoded)
 assert(decoded.dig_quest.shovel and decoded.dig_quest.tree_down)
 g.build_level(0);g.save_data.letters.append("dawn");g.note_flowers.closed["dawn"]=true;g.playing=true;g.paused=false
 for n in range(65):g.note_flowers.update(.05)
 assert(g.note_flowers.plots.has("0:dawn"))
 var plot=g.note_flowers.plots["0:dawn"];assert(plot.age==3 and plot.points.size()>5)
 for flower in plot.points:
  var cell=Vector2i(flower.pos/48);assert(g.grid[cell.y][cell.x]==".")
 g.build_level(3);assert(q.state().shovel and q.state().tree_down)
 g.player=Vector2(13.5,15.5)*48;g.camera=g.player;g.queue_redraw()
 await process_frame;await process_frame
 if DisplayServer.get_name()!="headless":root.get_texture().get_image().save_png("/tmp/crafting-room.png")
 var gates=g.objects.filter(func(o):return o.kind=="doorway")
 for gate in gates:assert(is_equal_approx(gate.pos.y,(5.5 if gate.id=="exit" else g.grid.size()-5.5)*48))
 g.build_level(1);g.held_item="flashlight";g.walk_facing=Vector2.LEFT;g.sync_hands();g.torch.drop(g.player)
 var lamp=g.objects.filter(func(o):return o.id=="flashlight")[0]
 assert(is_equal_approx(float(lamp.beam_angle),PI))
 assert(g.held_item.is_empty())
 print("PASS gate boundaries and saved flashlight orientation")
 print("PASS crafting chain, reverse-order resource persistence, break/repair, centered tree, ground flowers and room reentry")
 quit()
