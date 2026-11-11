extends SceneTree
func _initialize():call_deferred("run")
func run():
 var field=load("res://scripts/hedge_field.gd").new()
 var map:Array[String]=["#####","#####","#####","#####","#####"]
 field.build(map,71,{},{});field.wind_clock=100;var index:int=field.crowns.size()/2;var node=field.crowns[index];var base:Vector2=node.base
 field.update(1.0/60,base+Vector2(35,0))
 var tail:=0.0;var peak:=0.0;var settle_frame:=-1
 for n in range(1080):
  field.update(1.0/60,Vector2(-1000,-1000))
  var visible_sway:=absf(field.crown_pose(index,Vector2(-1000,-1000)).x-(base+node.offset).round().x)
  peak=maxf(peak,visible_sway)
  if n>=60 and n<180:tail=maxf(tail,visible_sway)
  if settle_frame<0 and node.sway==0 and node.sway_velocity==0:settle_frame=n
 assert(peak>=7.8 and tail>.5 and settle_frame>=180 and settle_frame<=720)
 print("PASS original touch impulse, wide sustained sways and controlled settling")
 quit()
