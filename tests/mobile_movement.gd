extends SceneTree
func _initialize():call_deferred('run')
func run():
 var g=load('res://main.tscn').instantiate();root.add_child(g);await process_frame;g.new_game();g.clear_modal()
 assert(not g.blocked(g.player));assert(abs(g.player.x/48.0-15.5)<.01)
 var e=InputEventScreenTouch.new();e.index=4;e.pressed=true;e.position=Vector2(100,800);g._input(e)
 var d=InputEventScreenDrag.new();d.index=4;d.position=Vector2(100,748);g._input(d)
 assert(g.joy_vector.y<-.9);var before=g.player;await physics_frame;await physics_frame;assert(g.player.distance_to(before)>0)
 e.pressed=false;g._input(e);assert(g.joy_id==-1);print('PASS centered spawn, touch drag, physics movement, release')
 for room in range(7):
  g.build_level(room);assert(not g.blocked(g.player),'blocked spawn room '+str(room))
  var found=false
  for v in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
   if not g.blocked(g.player+v*12):found=true
  assert(found,'trapped spawn '+str(room))
 print('PASS all seven room spawns unblocked');quit()
