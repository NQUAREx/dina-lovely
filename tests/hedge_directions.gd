extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame;g.new_game();g.clear_modal();g.sound_on=false
 var bush=Vector2(500,500)
 for offset in [Vector2(0,-30),Vector2(-30,0),Vector2(30,0),Vector2(-30,15),Vector2(30,15),Vector2(10,-30)]:
  g.player=bush+offset;assert(g.hedge_in_foreground(bush))
 for offset in [Vector2(0,30),Vector2(-10,30),Vector2(10,30)]:
  g.player=bush+offset;assert(not g.hedge_in_foreground(bush))
 print("PASS upper and both side canopies overlap; southern canopy stays behind")
 g.queue_free();await process_frame;quit()
