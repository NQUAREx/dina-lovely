extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame
 g.new_game();g.clear_modal();g.set_process(false);g.set_physics_process(false);g.sound_on=false;g.save_data.finished=true
 g.build_level(6)
 for tool in ["axe","shears","drill"]:g.world_tools.pickup(tool)
 g.held_item="rifle";g.sync_hands();var drops:int=g.save_data.loose_weapons.size()
 var seen:Array=[]
 for i in range(4):
  g.world_tools.cycle();seen.append(g.held_item)
  assert(g.weapon==(g.held_item if g.held_item=="rifle" else ""))
 assert(seen.has("rifle") and seen.has("drill") and seen.has("axe") and seen.has("shears"))
 assert(g.save_data.loose_weapons.size()==drops)
 g.held_item="rpg";g.sync_hands();g.rpg_windup=.2;g.world_tools.cycle();assert(g.rpg_windup<0 and "rpg" in g.save_data.world_kit)
 g.activate_cached_room(3);g.player=Vector2(648,600);g.walk_facing=Vector2.RIGHT;g.held_item="drill";g.sync_hands();g.nearest=-1
 var count:int=g.world_tools.state().excavations.size()
 g.action_button.button_down.emit();assert(g.world_tools.drilling and g.task_time==0 and g.world_tools.state().excavations.size()>count)
 g.player+=Vector2(36,0);g.world_tools.update(.2);assert(g.world_tools.drilling and g.world_tools.state().excavations.size()>count+1)
 g.action_button.button_up.emit();count=g.world_tools.state().excavations.size();g.world_tools.update(.4)
 assert(not g.world_tools.drilling and not g.world_tools.drill_voice.playing and g.world_tools.state().excavations.size()==count)
 g.world_tools.start_drill();g.paused=true;g.world_tools.update(.1);g.paused=false;g.world_tools.update(.1);assert(not g.world_tools.drilling)
 g.leave_footprint(Vector2.RIGHT);assert(g.footprints[-1].life==6.75)
 g.activate_cached_room(1);g.equip_tool("flashlight");g.torch.drop(g.player+Vector2(0,-80));g.update_fog()
 assert(g.fog.material.get_shader_parameter("enabled") and g.fog.material.get_shader_parameter("ground_light"))
 g.equip_tool("flashlight");g.update_fog();assert(g.fog.material.get_shader_parameter("enabled") and not g.fog.material.get_shader_parameter("ground_light"))
 print("PASS weapon/tool storage and cycling, cancelled pending launch, immediate continuous hold drilling, release/pause stop, shorter prints, ground/held flashlight")
 quit()
