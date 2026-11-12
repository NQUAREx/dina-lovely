extends Control
## Screen-space decoration, independent of world particles and room simulation.
var motes:Array[Dictionary]=[]
var bursts:=0
func _ready()->void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func emit_at(point:Vector2)->void:
 bursts+=1
 for i in range(14):
  if motes.size()>=140:motes.pop_front()
  var angle:=randf_range(-PI,0)
  motes.append({"pos":point,"vel":Vector2.from_angle(angle)*randf_range(65,160),"age":0.0,"life":randf_range(.55,.85),"size":randf_range(1.1,2.1),"color":[Color("e4a0b7"),Color("efb5c7"),Color("d889a8")][i%3]})
 queue_redraw()
func _process(delta:float)->void:
 if motes.is_empty():return
 delta=minf(delta,.05)
 for i in range(motes.size()-1,-1,-1):
  var p:Dictionary=motes[i];p.age+=delta
  if p.age>=p.life:motes.remove_at(i);continue
  p.vel*=exp(-delta*1.5);p.vel.y+=190*delta;p.pos+=p.vel*delta
 queue_redraw()
func _draw()->void:
 for p in motes:
  var shape:=PackedVector2Array([Vector2(-4,-2),Vector2(-4,-4),Vector2(-2,-5),Vector2(0,-3),Vector2(2,-5),Vector2(4,-4),Vector2(4,-2),Vector2(0,3)])
  for i in range(shape.size()):shape[i]=(p.pos+shape[i]*p.size).round()
  var color:Color=p.color;color.a=1-smoothstep(.3,1.0,p.age/p.life)
  draw_colored_polygon(shape,color)
