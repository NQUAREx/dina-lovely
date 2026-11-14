extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame
 g.new_game();g.clear_modal();g.set_process(false);g.set_physics_process(false);g.sound_on=false
 g.build_level(3)
 for gate in g.objects.filter(func(o):return o.kind=="doorway"):
  var row=floori(gate.pos.y/48);var x=floori(gate.pos.x/48)
  for side in [-2,2]:assert(g.grid[row][x+side]==".")
  assert(g.blocked(gate.pos+Vector2(84,0)),"gate post lost its collision")
 g.save_data.open_gates.append(3)
 var exit=g.objects.filter(func(o):return o.id=="exit")[0];exit.gate_amount=1.0
 g.held_item="shovel";g.sync_hands();g.objects.append({"kind":"shovel","id":"shovel","pos":g.player,"solid":false})
 g.player=exit.pos+Vector2(40,-12);g.walk_facing=Vector2.UP
 var foot:Vector2=g.player;g.release_at_gate();assert(g.held_item.is_empty())
 assert(g.objects.filter(func(o):return o.id=="shovel")[0].pos==foot)
 g.build_level(4);g.wave=1;g.combat_done=false
 var top=Vector2(13.5*48,6.85*48)
 assert(g.blocked(top) and not g.projectile_blocked(top))
 var bottom=Vector2(13.5*48,(g.grid.size()-6.85)*48)
 assert(g.blocked(bottom) and not g.projectile_blocked(bottom))
 g.objects.clear();g.enemies.clear();g.shots.clear()
 for point in [top,bottom]:
  g.shots.append({"pos":point,"vel":Vector2.RIGHT*570,"life":1.4,"kind":"rifle","age":0.0})
 g.update_shots(.02);assert(g.shots.size()==2)
 g.save_data.finished=true;g.playing=true;g.paused=false;g.moving=true
 for direction in [Vector2.UP,Vector2(-1,-1),Vector2.LEFT,Vector2(-1,1),Vector2.DOWN,Vector2(1,1),Vector2.RIGHT,Vector2(1,-1)]:
  g.walk_facing=direction.normalized();g.aim=g.walk_facing
  for tool in ["can","rake","fertilizer","shovel","flashlight","quest_axe","pickaxe","shears","drill","sword","rifle","rpg"]:
   g.held_item=tool;g.weapon=tool if tool in ["sword","rifle","rpg"] else ""
   for frame in range(8):
    g.time=frame/16.0;var pose=g.held_tool_pose()
    assert(pose.hand==g.right_hand_position())
   if direction==Vector2(-1,1):assert(not g.hand_is_behind())
 print("PASS gate jambs, exact-foot drops, arena-edge projectiles and eight-direction grips")
 quit()
