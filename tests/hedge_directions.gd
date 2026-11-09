extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame;g.new_game();g.clear_modal();g.sound_on=false
 g.grid.clear()
 for y in range(22):g.grid.append(".".repeat(22))
 g.set_cell(10,10,"#")
 g.hedge_field=load("res://scripts/hedge_field.gd").new();g.hedge_field.build(g.grid,541,{}, {})
 var bush=Vector2(10.5,10.5)*48
 for offset in [Vector2(0,-30),Vector2(-30,0),Vector2(30,0),Vector2(-30,15),Vector2(30,15),Vector2(10,-30)]:
  g.player=bush+offset;assert(g.hedge_field.foreground(g.player))
 for offset in [Vector2(0,30),Vector2(-10,30),Vector2(10,30)]:
  g.player=bush+offset;assert(not g.hedge_field.foreground(g.player))
 print("PASS upper and both side canopies overlap; southern canopy stays behind")
 g.queue_free();await process_frame;quit()
