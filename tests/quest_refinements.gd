extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame
 g.new_game();g.clear_modal();g.set_process(false);g.set_physics_process(false);g.sound_on=false
 # A bench must never become a breadcrumb; old blocked crumbs cannot stall pursuit.
 g.build_level(5);g.objects.assign([{"kind":"bench","id":"seat","pos":Vector2(600,600),"solid":true}])
 g.player=Vector2(600,646);g.save_data.cat_tamed=true;g.companion.position=Vector2(550,646)
 g.companion.trail.clear();g.companion.clock=0;g.companion.last_player=Vector2.INF;g.companion.record()
 var count:int=g.companion.trail.size()
 g.resting="seat";g.rest_anchor=Vector2(600,600);g.player=Vector2(600,608);g.companion.record()
 assert(g.companion.trail.size()==count)
 g.companion.trail.append({"pos":g.player,"time":0.0});g.stand_up()
 assert(g.companion.trail.all(func(p):return not g.blocked(p.pos)))
 var before:Vector2=g.companion.position
 for n in range(160):g.move_player(.016,Vector2.RIGHT);g.companion.update(.016)
 assert(g.companion.position.distance_to(before)>100 and g.companion.position.distance_to(g.player)<90)
 print("PASS cat resumes after bench and discards obstructed breadcrumbs")
 # Flashlight lives on the darkness side, including old/corrupted saves.
 g.prepare_room_cache(1);g.equip_tool("flashlight");assert(g.held_item=="flashlight")
 g.player=Vector2(13.5*48,g.grid.size()*48+1);g.camera=g.player;g.travel(0)
 assert(g.held_item!="flashlight" and not g.save_data.flashlight)
 assert(int(g.save_data.flashlight_location.room)==1 and not g.objects.any(func(o):return o.id=="flashlight"))
 g.equip_tool("flashlight");assert(g.held_item!="flashlight")
 g.travel(1);assert(g.objects.any(func(o):return o.kind=="flashlight_pedestal"))
 assert(g.objects.any(func(o):return o.id=="flashlight"))
 print("PASS flashlight stays outside maze and pedestal persists")
 # Visible targets take precedence over the home leash; shooters close their blind band.
 g.build_level(4);g.grid.clear()
 for y in range(30):g.grid.append("#"+".".repeat(28)+"#")
 g.objects.clear();g.enemies.clear();g.player=Vector2(900,700);g.wave=5
 g.battle.enemy(0,Vector2(800,700),100);var e:Dictionary=g.enemies[0]
 e.state="chase";e.home=Vector2(0,700)
 assert(g.battle.brain(e,.2))
 g.enemies.clear();g.shots.clear();g.player=Vector2(670,600)
 g.battle.enemy(5,Vector2(500,600),100);e=g.enemies[0];e.state="chase";e.cooldown=0;e.sense=0
 var old_x:float=e.pos.x;g.battle.gunner(e,.1);assert(e.pos.x>old_x)
 for n in range(35):g.time+=.016;g.battle.gunner(e,.016)
 assert(not g.shots.is_empty() and is_equal_approx(Vector2(g.shots[0].vel).length(),570))
 # Genuine navigation around a solid column, not teleporting or ignoring collision.
 g.objects.assign([{"kind":"column","id":"test_column","pos":Vector2(600,600),"solid":true}])
 e.pos=Vector2(500,600);g.player=Vector2(700,600);g.battle.navigation=null
 for n in range(280):
  g.time+=.016;g.battle.navigate(e,g.player,85,.016);assert(not g.blocked(e.pos))
 assert(Vector2(e.pos).distance_to(g.player)<20)
 print("PASS home leash, ranged dead band, player-speed bullets and obstacle navigation")
 g.build_level(0)
 var marker:int=g.rune_stones.marker_index;assert(marker>=0 and g.hedge_field.crowns[marker].stone_marker)
 var hidden=g.objects.filter(func(o):return o.kind=="riddle_stone")[0]
 g.rune_stones.collect(hidden);assert(not g.hedge_field.crowns[marker].get("stone_marker",false))
 var cell:=Vector2i(-1,-1)
 for y in range(8,g.grid.size()-8):
  for x in range(2,g.grid[0].length()-2):
   if g.grid[y][x]=="#":cell=Vector2i(x,y);break
  if cell.x>=0:break
 var count_before:int=g.particles.size()
 g.world_tools.complete("snip_hedge:%d:%d"%[cell.x,cell.y],(Vector2(cell)+Vector2(.5,.5))*48)
 assert([cell.x,cell.y] in g.world_tools.state().hedges and g.particles.size()-count_before>=28)
 g.build_level(3);var p:Array=g.save_data.riddle_stone_positions["3"]
 g.rune_stones.excavate(Vector2(p[0],p[1])+Vector2(50,0));assert(g.save_data.riddle_stone_exposed)
 for level in range(7):g.level=level;g.update_hud();assert(g.status.text.is_empty() and g.hint.text.is_empty())
 print("PASS stone foliage cue, cut stems/particles, wider stone excavation and hint-free HUD")
 quit()
