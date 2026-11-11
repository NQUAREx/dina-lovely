extends SceneTree
func _initialize():call_deferred("run")
func run():
 var field=load("res://scripts/hedge_field.gd").new()
 var map:Array[String]=["#####","#####","#####","#####","#####"]
 field.build(map,71,{},{});field.wind_clock=100;var node=field.crowns[field.crowns.size()/2];var base:Vector2=node.base
 field.update(1.0/60,base+Vector2(35,0))
 var tail:=0.0;var peak:=absf(node.sway);var settle_frame:=-1
 for n in range(1080):
  field.update(1.0/60,Vector2(-1000,-1000))
  peak=maxf(peak,absf(node.sway))
  if n>=60 and n<180:tail=maxf(tail,absf(node.sway))
  if settle_frame<0 and node.sway==0 and node.sway_velocity==0:settle_frame=n
 assert(peak>6.0 and tail>.5 and settle_frame>=180 and settle_frame<=720)
 print("PASS original touch impulse, wide sustained sways and controlled settling")
 quit()
