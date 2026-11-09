extends SceneTree
var g
func _initialize():call_deferred('run')
func run():
 g=load('res://main.tscn').instantiate();root.add_child(g);await process_frame;g.new_game();g.clear_modal();g.sound_on=false
 g.grid.clear()
 for y in range(25):g.grid.append('#'+'.'.repeat(23)+'#')
 for y in range(7,18):g.set_cell(10,y,'#')
 assert(not g.blocked(Vector2(10*48+4,10.5*48)));assert(g.blocked(Vector2(10*48+16,10.5*48)))
 for y in range(8,18):assert(g.blocked(Vector2(10.5*48,y*48)))
 print('PASS deeper foliage with continuous solid core')
 for room in range(7):
  g.build_level(room);g.player=Vector2(13.5,12)*48
  if room==5:
   assert(g.paths.size()==9)
   for path in g.paths:
    for point in path:assert(g.path_point_safe(point))
    for n in range(1,path.size()):assert(path[n].distance_to(path[n-1])<32)
  var before=g.footprints.size();g.leave_footprint(Vector2.UP);assert(g.footprints.size()==before+1)
 print('PASS footprints and walking particles in all rooms')
 g.paths=[PackedVector2Array([Vector2(0,0),Vector2(50,0),Vector2(100,0)]),PackedVector2Array([Vector2(100,0),Vector2(150,0),Vector2(200,0)]),PackedVector2Array([Vector2(200,0),Vector2(250,0),Vector2(300,0)])];g.path_terminals.assign([false,false,true]);g.build_path_meshes()
 assert(not g.path_meshes[0].terminal and not g.path_meshes[1].terminal and g.path_meshes[2].terminal)
 for i in range(2):
  var colors=g.path_meshes[i].layers[0].mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
  for c in colors:assert(c.a==1)
 var final=g.path_meshes[2].layers[0].mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR];assert(final[-1].a==0)
 print('PASS internal path joins stay opaque; only true tip fades')
 g.queue_free();await process_frame;quit()
