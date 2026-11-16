extends SceneTree
func _initialize():call_deferred('run')
func run():
 var g=load('res://main.tscn').instantiate();root.add_child(g);await process_frame
 g.new_game();g.clear_modal();g.set_process(false);g.set_physics_process(false);g.hide()
 for facing in [Vector2(1,-1),Vector2(1,1)]:
  g.walk_facing=facing;g.moving=false
  for tool in ['can','rake','fertilizer','shovel','flashlight','axe','shears','drill','quest_axe','pickaxe']:
   g.held_item=tool
   if facing.y>0:assert(not g.hand_is_behind())
   var pose=g.held_tool_pose()
   assert(pose.hand.x>g.player.x if facing.y<0 else pose.hand.x<g.player.x)
  if facing.y>0:assert(not g.hand_is_behind())
 print('PASS ten tools retain right-hand grips; southeast tools render in front of body')
 quit()
