extends SceneTree
func _initialize():call_deferred("run")
func run():
 var field=load("res://scripts/hedge_field.gd").new()
 var map:Array[String]=["#####","#####","#####","#####","#####"]
 field.build(map,71,{},{});var node=field.crowns[field.crowns.size()/2];var base:Vector2=node.base
 field.update(1.0/60,base+Vector2(35,0))
 var tail:=0.0
 for n in range(480):
  field.update(1.0/60,Vector2(-1000,-1000))
  if n>=60 and n<180:tail=maxf(tail,absf(node.sway))
 assert(tail>.3 and node.sway==0 and node.sway_velocity==0)
 print("PASS light-touch inertia persists beyond one second, then settles without drift")
 quit()
