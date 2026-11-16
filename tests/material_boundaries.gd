extends SceneTree
func _initialize():call_deferred('run')
func run():
 var g=load('res://main.tscn').instantiate();root.add_child(g);await process_frame
 g.new_game();g.clear_modal();g.set_process(false);g.set_physics_process(false)
 for lower in range(6):
  g.build_level(lower)
  var owner:int=g.boundary_room(0)
  assert(owner==lower+1)
  var left:Image=load('res://assets/wall_room%d_exposed.png'%owner).get_image()
  g.build_level(lower+1)
  assert(g.boundary_room(g.grid.size()-1)==owner)
  var right:Image=load('res://assets/wall_room%d_exposed.png'%g.boundary_room(g.grid.size()-1)).get_image()
  assert(left.get_data()==right.get_data())
 for stage in range(7):
  var name='quest_tree'+('' if stage==0 else '_damage'+str(stage))
  var mask:Image=load('res://assets/'+name+'_trunk.png').get_image()
  var count=0
  for y in range(48):
   for x in range(32):
    if mask.get_pixel(x,y).a>.1:
     assert(y>=25 and y<44);count+=1
  assert(count>20)
 print('PASS six shared corridors retain upper-room material, seven trunk-only masks')
 quit()
