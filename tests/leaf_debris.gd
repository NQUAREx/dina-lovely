extends SceneTree
const Debris=preload("res://scripts/leaf_debris.gd")
func _initialize():
 seed(4281)
 var velocities=[]
 for variant in range(6):
  var initial=Debris.spawn(Vector2(100,100),variant%2==0)
  velocities.append(initial.vel)
  var fast=initial.duplicate(true);var slow=initial.duplicate(true)
  var origin:Vector2=initial.pos
  for frame in range(180):
   Debris.step(fast,1.0/60)
   assert(fast.leaf_height>=0)
  for frame in range(90):Debris.step(slow,1.0/30)
  assert(fast.landed and slow.landed and fast.leaf_height==0 and fast.leaf_vz==0)
  assert(fast.pos.distance_to(origin)<25 and fast.pos.distance_to(slow.pos)<.8)
  assert(fast.vel.length()<.1)
  var settled:Vector2=fast.pos
  for frame in range(60):Debris.step(fast,1.0/60)
  assert(fast.pos.distance_to(settled)<.1 and fast.leaf_height==0)
 assert(velocities[0]!=velocities[1] and velocities[2]!=velocities[3])
 print("PASS random drift, short travel, gravity/terminal speed, ground settling, 30/60 FPS agreement and stable resting leaves")
 quit()
