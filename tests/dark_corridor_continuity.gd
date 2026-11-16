extends SceneTree
func _initialize():call_deferred('run')
func run():
 var g=load('res://main.tscn').instantiate();root.add_child(g);await process_frame
 g.new_game();g.clear_modal();g.set_process(false);g.set_physics_process(false);g.hide();g.held_item=''
 g.activate_cached_room(0);g.player=Vector2(15.5*48,-48);g.camera=g.player;g.update_fog()
 var opacity=g.fog.material.get_shader_parameter('room_opacity')
 var band=g.fog.material.get_shader_parameter('room_band')
 g.activate_cached_room(1);g.player=Vector2(13.5*48,g.grid.size()*48-48);g.camera=g.player;g.update_fog()
 assert(is_equal_approx(opacity,g.fog.material.get_shader_parameter('room_opacity')))
 assert(band==g.fog.material.get_shader_parameter('room_band'))
 var first:float=opacity
 g.player.y-=3*48;g.camera=g.player;g.update_fog()
 assert(g.fog.material.get_shader_parameter('room_opacity')>first)
 print('PASS shared darkness is continuous across corridor midpoint and deepens over full viewport on entry')
 quit()
