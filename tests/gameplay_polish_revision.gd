extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame
 g.new_game();g.clear_modal();g.set_process(false);g.set_physics_process(false);g.sound_on=false;g.save_data.finished=true
 g.build_level(6)
 for tool in ["axe","shears","drill"]:
  var obj=g.objects.filter(func(o):return o.kind==tool)[0]
  assert(obj.on_table and g.item_visual_bounds(obj).size.y<65)
  g.player=obj.pos+Vector2(-58,16);g.nearest=g.objects.find(obj);g.interact();assert(g.held_item==tool)
 assert(g.save_data.world_kit.size()==3 and g.objects.filter(func(o):return o.kind in ["axe","shears","drill"]).is_empty())
 g.activate_cached_room(3);g.player=Vector2(648,600);g.walk_facing=Vector2.RIGHT;g.held_item="drill";g.sync_hands()
 var before:int=g.world_tools.state().excavations.size();g.world_tools.update(.3)
 assert(not g.world_tools.drilling and g.world_tools.state().excavations.size()==before)
 g.nearest=-1;g.interact();assert(g.task_kind=="drill" and g.task_time>0)
 g.world_tools.update(.2);assert(g.world_tools.drilling and g.world_tools.state().excavations.size()>before)
 g.update_tasks(.7);g.world_tools.update(.1);assert(not g.world_tools.drilling)
 var pit:Vector2=g.world_tools.ground_point();assert(g.world_tools.is_excavated(pit) and not g.world_tools.print_clear(pit))
 assert(g.world_tools.print_clear(pit+Vector2(70,0)))
 g.leave_footprint(Vector2.RIGHT);assert(g.footprints[-1].life==13.5)
 g.equip_tool("shovel");assert(g.held_item=="shovel" and g.save_data.world_kit.size()==3)
 g.world_tools.cycle();assert(g.held_item in g.world_tools.TOOLS and not g.save_data.shovel)
 var dropped:String=g.held_item;g.drop_current_item()
 assert(g.held_item.is_empty() and g.save_data.world_kit.size()==2)
 var loose=g.objects.filter(func(o):return o.kind==dropped);assert(loose.size()==1 and g.available(loose[0]))
 g.nearest=g.objects.find(loose[0]);g.interact();assert(g.save_data.world_kit.size()==3)
 g.update_hud();assert(g.drop_button.text.is_empty() and g.switch_button.text.is_empty() and g.drop_button.visible and g.switch_button.visible)
 print("PASS three-tool kit, normal-item swaps, drop/re-pick, icon controls, button-only drill and pit-safe shorter footprints")
 g.equip_tool("shovel");g.player=Vector2(648,(g.grid.size()-7)*48+4);g.walk_facing=Vector2.DOWN;g.release_at_gate()
 assert(g.held_item.is_empty() and g.save_data.tool_positions["3:shovel"][1]<(g.grid.size()-6.5)*48)
 g.activate_cached_room(5)
 for item in ["can","rake","fertilizer"]:
  g.equip_tool(item);g.player=Vector2(648,6.9*48);g.walk_facing=Vector2.UP;g.release_at_gate()
  assert(g.held_item.is_empty() and g.save_data.tool_positions["5:"+item][1]>6.5*48)
 var bench=g.objects.filter(func(o):return o.id=="seat")[0]
 g.player=bench.pos+Vector2(0,45);g.moving=true;g.attack_flash=.1;g.nearest=g.objects.find(bench);g.interact()
 assert(g.resting=="seat" and not g.moving and g.attack_flash==0)
 g.stand_up();assert(not g.available({"kind":"fallen_tree","id":"tree_test","pos":g.player,"solid":false}))
 g.activate_cached_room(1);g.equip_tool("flashlight");g.player=Vector2(648,(g.grid.size()-7)*48+4);g.walk_facing=Vector2.DOWN;g.release_at_gate()
 assert(g.held_item.is_empty() and int(g.save_data.flashlight_location.room)==1 and g.save_data.flashlight_location.pos[1]<(g.grid.size()-6.5)*48)
 print("PASS gate-side drops for shovel, garden tools and torch; bench animation reset and noninteractive fallen trees")
 g.save_data.finished=false;g.held_item="";g.sync_hands();g.build_level(4);g.player=Vector2(648,900);g.wave=1;g.wave_timer=1.2
 g.enemies.clear();g.pending_spawns.clear();g.update_combat(.01)
 assert(g.wave==1 and g.prepared_wave==2 and "sword" in g.save_data.weapon_crates_opened)
 var drop=g.objects.filter(func(o):return str(o.id)=="drop_crate_sword")[0]
 var crate=g.objects.filter(func(o):return o.kind=="weapon_crate" and o.weapon=="sword")[0]
 assert(drop.pos.distance_to(crate.pos)<=70.1 and drop.pos.distance_to(crate.pos)>=44.9)
 g.time+=.85;g.update_combat(.85);assert(g.wave==1)
 g.update_combat(.5);assert(g.wave==2 and g.enemies.is_empty() and g.pending_spawns.size()==g.battle.WAVES[1].size())
 for next in g.pending_spawns:assert(next.delay>=.1 and next.delay<=.7)
 for n in range(16):
  if not g.enemies.is_empty():break
  g.battle.emit_pending(.05)
 assert(g.enemies.size()==1)
 g.pending_spawns[0].delay=.65;var remaining:int=g.pending_spawns.size();g.battle.emit_pending(.1);assert(g.enemies.size()==1 and g.pending_spawns.size()==remaining)
 g.enemies.clear();g.wave_timer=.01;g.update_combat(.1);assert(g.wave==2 and not g.pending_spawns.is_empty())
 g.arena_save.capture();assert(g.save_data.arena_checkpoint.fields.has("pending_spawns") and g.save_data.arena_checkpoint.fields.has("prepared_wave"))
 assert(g.arena_save.unpack(g.arena_save.pack(g.pending_spawns))==g.pending_spawns)
 g.pending_spawns.clear();g.battle.enemy(0,g.player+Vector2(60,0),100);g.enemies[0].state="chase";g.enemies[0].sense=0;g.enemies[0].aggro=true
 g.battle.melee(g.enemies[0],.016);assert(g.enemies[0].state=="warn" and g.enemies[0].timer<.9)
 g.damage_enemy(0,5,Vector2.ZERO);assert(g.damage_numbers.is_empty())
 print("PASS pre-wave crate opening, shorter throw, staggered arrivals, pending-wave save/restore, shorter melee warning and no damage labels")
 g.save_data.finished=true;g.build_level(6);g.save_data.riddle_input=[];g.puzzle.assign(g.save_data.riddle_order);g.chest_open=true
 var order:Array=g.puzzle.duplicate();g.press_riddle_symbol("puzzle_reset",g.player);g.rune_stones.use_socket("puzzle_reset",g.player)
 assert(g.puzzle==order and not g.available({"kind":"stone","id":"puzzle_reset","pos":g.player}))
 g.cache_current_room();g.activate_cached_room(5);g.activate_cached_room(6);assert(g.puzzle==order)
 for name in ["dig","punch_swing","punch_hit","sword_swing"]:assert(g.get_script()!=null and load("res://scripts/audio_bank.gd").STREAMS[name].get_length()>0)
 print("PASS permanent solved symbols, room return and separate decoded digging/punch/sword recordings")
 quit()
