extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame
 g.new_game();g.clear_modal();g.set_process(false);g.set_physics_process(false);g.sound_on=false
 g.activate_cached_room(3);g.equip_tool("shovel");g.walk_facing=Vector2.UP
 var center:=13.5*48;var gate=g.objects.filter(func(o):return o.kind=="doorway" and o.id=="exit")[0]
 g.player=Vector2(center+40,6.9*48);g.save_data.open_gates.erase(3);gate.gate_amount=0;g.release_at_gate();assert(g.held_item=="shovel")
 g.save_data.open_gates.append(3);gate.gate_amount=1
 for x in [90.0,center-40,1200.0]:
  g.player=Vector2(x,6.9*48);g.release_at_gate();assert(g.held_item=="shovel")
 g.player=Vector2(center+40,6.9*48);g.release_at_gate();assert(g.held_item.is_empty())
 g.equip_tool("shovel");g.walk_facing=Vector2.DOWN;g.player=Vector2(90,(g.grid.size()-6.9)*48);g.release_at_gate();assert(g.held_item=="shovel")
 g.player.x=center;g.release_at_gate();assert(g.held_item=="shovel")
 g.save_data.open_gates.append(2);g.release_at_gate();assert(g.held_item.is_empty())
 g.activate_cached_room(4);g.wave=3;g.combat_done=false;g.held_item="rifle";g.sync_hands();g.walk_facing=Vector2.DOWN
 var boundary:float=(g.grid.size()-7)*48
 g.player=Vector2(center+40,boundary+6);g.release_at_gate();assert(g.held_item=="rifle" and g.blocked(g.player))
 assert(g.blocked(Vector2(center-40,boundary+6)))
 g.combat_done=true;assert(not g.arena_exit_sealed() and not g.blocked(g.player))
 var before:int=g.ui_hearts.bursts
 var b=g.button("",func():pass);g.root.add_child(b);b.position=Vector2(200,300);b.size=Vector2(80,60);b.pressed.emit()
 var click:Vector2=b.get_global_rect().position+Vector2(11,9)
 g.last_ui_pointer_position=click;g.last_ui_pointer_time=Time.get_ticks_msec();b.pressed.emit()
 assert(g.ui_hearts.bursts==before+2 and g.ui_hearts.motes.size()==28)
 for i in range(14,28):assert(g.ui_hearts.motes[i].pos==click)
 g.ui_button_hearts(g.action_button);assert(g.ui_hearts.bursts==before+2)
 g.ui_hearts._process(.1);assert(not g.ui_hearts.motes.is_empty())
 print("PASS gate-open and passage-only tool drops, no drops on room edges/closed leaf, sealed arena return during waves, UI hearts excluding action")
 quit()
