extends SceneTree
func _initialize():call_deferred("run")
func run():
 var field=load("res://scripts/hedge_field.gd").new()
 var map:Array[String]=[]
 for y in range(11):map.append(".....#.....")
 field.build(map,71,{},{});field.wind_clock=100
 var strong:=approach(field,Vector2(210,264),Vector2.RIGHT,1)
 assert(strong.x<=246.01 and strong.x>245,"original collision maximum changed")
 # A brief push is shallower than sustained pressure, without secondary walls.
 field.push_charge=0;field.push_anchor=Vector2.INF
 var first:Vector2=field.resist_motion(Vector2(240,264),Vector2(.6,0),Vector2.RIGHT,.016)
 for n in range(35):field.resist_motion(Vector2(240,264),Vector2(.6,0),Vector2.RIGHT,.016)
 var sustained:Vector2=field.resist_motion(Vector2(240,264),Vector2(.6,0),Vector2.RIGHT,.016)
 assert(sustained.x>first.x and sustained.x<.6)
 var point:=Vector2(245,170)
 for n in range(300):
  var next:Vector2=point+field.resist_motion(point,Vector2(0,.5),Vector2.DOWN,.016)
  assert(not field.blocks(next),"longitudinal movement caught on segment seam")
  point=next
 assert(point.y>280)
 # Both sides of a wall use the same normal-based resistance.
 var other:=approach(field,Vector2(318,264),Vector2.LEFT,1)
 assert(other.x>=281.99 and other.x<283)
 var tangential:Vector2=field.resist_motion(Vector2(240,264),Vector2(0,3))
 assert(tangential.y>2 and tangential.y<3 and tangential.x==0)
 var inward:Vector2=field.resist_motion(Vector2(240,264),Vector2(3,0))
 assert(inward.x>0 and inward.x<3)
 # Horizontal wall: same pressure law, original vertical core remains 15 pixels.
 var horizontal:Array[String]=[]
 for y in range(11):horizontal.append("###########" if y==5 else "...........")
 field.build(horizontal,71,{},{});field.wind_clock=100
 var above:=approach(field,Vector2(264,210),Vector2.DOWN,1)
 var below:=approach(field,Vector2(264,318),Vector2.UP,1)
 assert(above.y<=249.01 and above.y>248)
 assert(below.y>=278.99 and below.y<280)
 # An arbitrarily moving hero cannot pull a routing crown along with her.
 var index:int=field.crowns.size()/2
 var base:Vector2=field.crowns[index].base
 var anchor:=base.round()-Vector2(0,16)
 for frame in range(1200):
  var player:=base+Vector2(sin(frame*.07)*50,cos(frame*.09)*40)
  var pose:Vector3=field.crown_pose(index,player)
  var result:Vector3=field.route_pose(index,pose,frame%40<20,player,1.0/60)
  var centre:=Vector2(result.x,result.y)
  assert(absf(centre.x-anchor.x)<=26.1 and centre.y-anchor.y<=32.1 and centre.y-anchor.y>=-10.1,"anchor limit exceeded")
 print("PASS time-dependent viscosity, seam-free sliding, four wall sides, original hard limit, free retreat/tangent and 1200 tether frames")
 quit()
func approach(field,start:Vector2,direction:Vector2,strength:float)->Vector2:
 var point:=start
 for n in range(400):
  var next:Vector2=point+field.resist_motion(point,direction*.6*strength,direction*strength,.016)
  if not field.blocks(next):point=next
 return point
