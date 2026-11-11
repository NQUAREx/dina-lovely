extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame
 g.new_game();g.clear_modal();g.set_process(false);g.set_physics_process(false);g.sound_on=false;g.save_data.finished=true
 g.build_level(3);g.player=Vector2(13.5,12.5)*48;g.objects.clear();g.held_item="drill";g.sync_hands()
 g.world_tools.drop_held();g.objects.append({"kind":"shovel","id":"shovel","pos":g.player+Vector2(25,0),"solid":false})
 g.nearest=g.objects.find(g.objects.filter(func(o):return o.id=="shovel")[0]);g.interact();assert(g.held_item=="shovel")
 g.find_nearest();assert(g.nearest>=0 and g.objects[g.nearest].kind=="drill")
 g.update_hud();assert(g.action_button.text==g.tx("pickup_drill"))
 g.interact();assert(g.held_item=="drill" and g.task_time==0,"shovel swallowed drill pickup")
 for tool in ["axe","shears","drill"]:
  g.world_tools.pickup(tool);assert(g.held_item==tool)
  g.equip_tool("shovel");assert(g.held_item=="shovel")
  var dropped=g.objects.filter(func(o):return o.kind==tool)
  assert(dropped.is_empty() and tool in g.save_data.world_kit)
  g.world_tools.cycle();assert(g.held_item in g.world_tools.TOOLS)
 print("PASS drill/shovel round trip and repeated tool swaps through real interaction")
 # Stencil artwork is distinct and a joined mask replays identically in either order.
 var forms:Dictionary={}
 for n in range(8):forms[hash(g.world_tools.dig_shapes.get_region(Rect2i(n*40,0,40,28)).get_data())]=true
 assert(forms.size()==8)
 g.world_tools.ensure_dirt();var key:=str(g.level);var mask:Image=g.world_tools.masks[key];var image:Image=g.world_tools.images[key]
 var a:=Vector2(500,600);var b:=Vector2(524,612)
 mask.fill(Color.BLACK);image.fill(Color.TRANSPARENT);g.world_tools.stamp(a);g.world_tools.stamp(b)
 var joined:=image.get_data();var joined_mask:=mask.get_data()
 mask.fill(Color.BLACK);image.fill(Color.TRANSPARENT);g.world_tools.stamp(b);g.world_tools.stamp(a)
 assert(joined==image.get_data() and joined_mask==mask.get_data(),"joined pit depends on stamp order")
 assert(mask.get_pixelv(Vector2i((a+b)/4)).r>.5)
 print("PASS eight irregular forms, connected pit union and seam-free replay")
 g.particles.clear();g.scene_fx.soil(Vector2(500,600),30)
 assert(g.particles.size()==30)
 var sizes:Dictionary={};var drift:=0.0
 for p in g.particles:
  var origin:Vector2=p.pos;var initial_speed:float=Vector2(p.vel).length()
  sizes[roundf(float(p.size)*10)]=true
  for n in range(130):g.scene_fx.step(p,.016)
  assert(p.landed and p.height==0 and Vector2(p.vel).length()<initial_speed)
  drift=maxf(drift,origin.distance_to(p.pos))
 assert(sizes.size()>3 and drift>12)
 g.particles.clear();g.held_item="drill";g.player=Vector2(13.5,12.5)*48;g.walk_facing=Vector2.RIGHT;g.sync_hands();g.world_tools.soil_fx_clock=0
 g.world_tools.start_drill();g.world_tools.update(.016);assert(g.particles.any(func(p):return p.get("fx_kind","")=="dirt"))
 g.held_item="shovel";g.sync_hands();g.particles.clear();g.begin_task("dig:test",g.player+Vector2(25,0),.25);g.world_tools.update(.08)
 assert(g.particles.size()>=22)
 print("PASS varied physical earth clods, abrupt non-linear flight, drill and shovel emission")
 var hidden:Array=g.save_data.riddle_stone_positions["3"]
 g.rune_stones.excavate(Vector2(hidden[0],hidden[1])+Vector2(45,0));assert(not g.save_data.riddle_stone_exposed)
 g.rune_stones.excavate(Vector2(hidden[0],hidden[1])+Vector2(36,0));assert(g.save_data.riddle_stone_exposed)
 g.leave_footprint(Vector2.RIGHT);assert(g.footprints[-1].life==6.75)
 # A missile keeps its direct-hit damage; its visual blast never damages neighbours.
 g.build_level(4);g.objects.clear();g.enemies.clear();g.shots.clear();g.particles.clear();g.player=Vector2(700,700)
 g.held_item="rpg";g.weapon="rpg";g.aim=Vector2.RIGHT;g.rpg_aim=Vector2.RIGHT;g.attack_cd=0;g.rpg_reload=0;g.task_time=0
 g.attack(true);assert(g.shots.size()==1 and g.particles.size()>40)
 var muzzle:Vector2=g.shots[0].pos
 g.battle.enemy(0,muzzle+Vector2(145,16),200);g.battle.enemy(0,muzzle+Vector2(145,100),200)
 for e in g.enemies:e.state="chase"
 var initial:int=g.particles.size()
 for n in range(100):
  if g.shots.is_empty():break
  g.update_shots(.016)
 assert(g.shots.is_empty() and g.enemies[0].hp==101 and g.enemies[1].hp==200)
 assert(g.particles.size()>initial and g.particles.filter(func(p):return p.get("fx_kind","")=="blast").size()==1)
 var blast=g.particles.filter(func(p):return p.get("fx_kind","")=="blast")[0]
 assert(Vector2(blast.pos).distance_to(muzzle+Vector2(115,0))<5)
 print("PASS shorter footprint lifetime, original digging radius, rocket launch/trail/contact blast and no area damage")
 quit()
