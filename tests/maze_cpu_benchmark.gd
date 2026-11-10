extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame;g.new_game();g.clear_modal();g.set_process(false);g.set_physics_process(false);g.sound_on=false;g.save_data.seed=723;g.build_level(0)
 var field=g.hedge_field;var pos:Vector2=field.crowns[field.crowns.size()/2].base+Vector2(25,0);field.wind_clock=.001
 var begin=Time.get_ticks_usec()
 for n in range(360):
  field.update(1.0/60,pos+Vector2(sin(n*.08)*5,cos(n*.1)*10))
  for y in range(-3,4):
   for x in range(-3,4):field.body_offset(pos+Vector2(x,y)*32)
 print("BENCH us=",Time.get_ticks_usec()-begin," crowns=",field.crowns.size()," active=",field.active.size())
 quit()
