extends SceneTree
func _initialize():call_deferred("run")
func run():
 var field=load("res://scripts/hedge_field.gd").new()
 var map:Array[String]=["#####","#.#.#","#####","#...#","#####"]
 field.build(map,71,{},{});field.wind_clock=100
 var index:int=field.crowns.size()/2
 var base:Vector2=field.crowns[index].base
 for n in range(8):
  field.layer_routes.clear()
  var player:Vector2=base+Vector2.from_angle(n*TAU/8)*12
  var pose:=Vector3(base.x,player.y-14,14)
  var previous:Vector3=field.route_pose(index,pose,false,player,1.0/60)
  var switched:=false
  for frame in range(100):
   var result:Vector3=field.route_pose(index,pose,true,player,1.0/60)
   assert(Vector2(result.x,result.y).distance_to(Vector2(previous.x,previous.y))<4.1,"crown jumped")
   assert(Vector2(result.x,result.y).distance_to(Vector2(pose.x,pose.y))<=9,"crown escaped its tether")
   if field.layer_routes[index].front and not switched:
    assert(absf(result.x-player.x)>=32 or result.y-result.z>=player.y-28.1,"layer changed above waist")
    switched=true
   previous=result
  assert(switched and Vector2(previous.x,previous.y).distance_to(Vector2(pose.x,pose.y))<1.5)
  for frame in range(100):field.route_pose(index,pose,false,player,1.0/60)
  assert(not field.layer_routes[index].front)
 # Rest-pose cache must retain exactly the original pixel positions and sizes.
 for id in range(field.crowns.size()):
  assert(field.crowns[id].rest_pose==field.crown_pose(id,Vector2(-1000,-1000)))
 var visible:PackedInt32Array=field.visible_ids(Rect2(0,0,240,240))
 var player:Vector2=base+Vector2(12,0)
 field.prepare_draw(visible,player)
 for id in visible:
  if field.crowns[id].base.distance_squared_to(player)>=64*64:
   assert(field.draw_poses[id]==field.crowns[id].rest_pose,"unrelated row moved")
 var far_pose:=Vector3(base.x,base.y-16,14)
 assert(field.route_pose(index,far_pose,true,base+Vector2(500,0),.016)==far_pose)
 assert(not field.layer_routes.has(index))
 # Compare cached collision candidates against the original exact query.
 var rng:=RandomNumberGenerator.new();rng.seed=72
 for n in range(2500):
  var point:=Vector2(rng.randf_range(-20,260),rng.randf_range(-20,260))
  assert(field.blocks(point)==original_blocks(field,point))
 field.remove_cell(Vector2i(2,2))
 for n in range(500):
  var point:=Vector2(rng.randf_range(60,180),rng.randf_range(60,180))
  assert(field.blocks(point)==original_blocks(field,point))
 print("PASS eight approach directions, whole-crown detours, local state, collision equivalence before/after cutting")
 quit()
func original_blocks(field,point:Vector2)->bool:
 var cell:=Vector2i(point/48)
 for y in range(cell.y-1,cell.y+2):
  for x in range(cell.x-1,cell.x+2):
   for index in field.segment_cells.get(Vector2i(x,y),[]):
    var closest:Vector2=field.closest_on_segment(point,field.segments[index])
    if not field.wall(Vector2i(closest/48)):continue
    if ((point-closest)/Vector2(18,15)).length_squared()<1:return true
 return false
