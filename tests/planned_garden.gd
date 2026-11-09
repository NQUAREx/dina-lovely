extends SceneTree
var g
func _initialize():call_deferred('run')
func run():
 g=load('res://main.tscn').instantiate();root.add_child(g);await process_frame;g.new_game();g.clear_modal();g.sound_on=false
 assert(not g.pushing_hedge(g.player,Vector2.ZERO))
 g.grid.clear()
 for y in range(25):g.grid.append('#'+'.'.repeat(23)+'#')
 for y in range(7,18):g.set_cell(10,y,'#')
 assert(not g.pushing_hedge(Vector2(10*48-18,10.5*48),Vector2.RIGHT));assert(g.pushing_hedge(Vector2(10*48+4,10.5*48),Vector2.RIGHT));print('PASS rustle requires inward pressure, not proximity')
 g.build_level(5);assert(g.path_targets.size()>=12)
 for target in g.path_targets:
  var path=g.paths[target.path];assert(path[-1].distance_to(target.end)<.1)
  assert((path[-1]-path[-2]).length()>0)
  for point in path:assert(g.path_point_safe(point))
 for mesh in g.path_meshes:
  for layer in mesh.layers:
   var colors=layer.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
   for color in colors:assert(color.a==1)
 assert(g.sprites.has('path_end'));print('PASS organic object approaches with opaque pixel caps')
 assert(g.grass_texture!=null and g.grass_details.size()>50);var first=g.grass_details.duplicate(true);g.build_level(5);assert(first==g.grass_details);print('PASS seeded ground details')
 var count=g.particles.size();g.leave_footprint(Vector2.UP);assert(g.particles.size()-count==8);print('PASS increased walking particles')
 assert(g.content.loading_phrases.size()>=20);print('PASS loading phrases from JSON')
 g.queue_free();await process_frame;quit()
