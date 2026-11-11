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
 var press_field=load("res://scripts/hedge_field.gd").new()
 press_field.build(map,72,{},{});press_field.wind_clock=100
 var press_index:int=press_field.crowns.size()/2;var press_node=press_field.crowns[press_index]
 var press_player:Vector2=press_node.base+Vector2(0,15)
 press_field.update(1.0/60,press_player)
 var unsoftened:=maxf(0,ceilf(press_player.y-28+roundf(press_node.radius*1.48))-((press_node.base+press_node.offset).round().y-16))
 assert(not press_node.released and press_node.depression>0 and press_node.depression<unsoftened)
 var ids:=PackedInt32Array([index]);node.layer_initialized=false
 field.prepare_draw(ids,base+Vector2(0,50),1.0/60)
 field.prepare_draw(ids,base-Vector2(0,50),1.0/60)
 var start_x:float=field.draw_poses[index].x
 assert(absf(start_x-base.round().x)>1 and absf(start_x-base.round().x)<10)
 for n in range(8):field.prepare_draw(ids,base-Vector2(0,50),1.0/60)
 assert(field.front_crowns.has(index))
 for n in range(10):field.prepare_draw(ids,base-Vector2(0,50),1.0/60)
 assert(absf(field.draw_poses[index].x-base.round().x)<1)
 var crowded=load("res://scripts/hedge_field.gd").new();crowded.build(map,71,{},{});crowded.wind_clock=100
 var centre:Vector2=crowded.crowns[crowded.crowns.size()/2].base
 var all_ids:=PackedInt32Array();for i in range(crowded.crowns.size()):all_ids.append(i)
 var above:=centre-Vector2(0,50);crowded.prepare_draw(all_ids,centre+Vector2(0,50),1.0/60);crowded.prepare_draw(all_ids,above,1.0/60)
 var local_motion:=0.0;var remote_motion:=0.0
 for i in all_ids:
  var pose:Vector3=crowded.draw_poses[i];var rest:Vector3=crowded.crown_pose(i,above)
  var amount:=Vector2(pose.x-rest.x,pose.y-rest.y).length()
  if crowded.crowns[i].base.distance_to(above)<64:local_motion=maxf(local_motion,amount)
  else:remote_motion=maxf(remote_motion,amount)
 assert(local_motion>1 and remote_motion<.1)
 print("PASS original touch impulse, wide sustained sways and controlled settling")
 quit()
