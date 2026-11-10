extends RefCounted
## A delayed breadcrumb follower; room seams translate its entire route together.
var g:Node2D
var position:=Vector2.ZERO
var trail:Array[Dictionary]=[]
var prints:Array[Dictionary]=[]
var clock:=0.0
var seed_value:=-1
var direction:=2
var moving:=false
var stride:=0.0
var anim:=0.0
var last_player:=Vector2.INF
var autosave:=0.0
var repath_wait:=0.0
var target_ref:Dictionary={}
func _init(game:Node2D):g=game
func place(rng:RandomNumberGenerator)->void:
 if g.level!=0:return
 var choices:Array[Vector2i]=[]
 for y in range(8,g.grid.size()-8):
  for x in range(2,g.grid[0].length()-2):
   if g.grid[y][x]!="." or g.grid[y+1][x]!=".":continue
   if g.grid[y-1][x]=="." or g.grid[y][x-1]=="." or g.grid[y][x+1]==".":continue
   var p:Vector2=(Vector2(x,y)+Vector2(.5,.5))*48
   if not g.objects.any(func(o):return o.pos.distance_to(p)<100):choices.append(Vector2i(x,y))
 if choices.is_empty():
  for y in range(8,g.grid.size()-8):
   for x in range(2,g.grid[0].length()-2):
    if g.grid[y][x]=="#" and g.grid[y+1][x]=="." and g.grid[y-1][x]=="#" and g.grid[y][x-1]=="#" and g.grid[y][x+1]=="#":choices.append(Vector2i(x,y))
 if choices.is_empty():return
 var cell:Vector2i=choices[rng.randi_range(0,choices.size()-1)];g.set_cell(cell.x,cell.y,".")
 g.put_object("cat_hut",cell,"cat_hut",true)
 var fish:Array[Vector2i]=[]
 for y in range(8,g.grid.size()-7):
  for x in range(2,g.grid[0].length()-2):
   var p:Vector2=(Vector2(x,y)+Vector2(.5,.5))*48
   if g.grid[y][x]=="." and p.distance_to((Vector2(cell)+Vector2(.5,.5))*48)>180 and not g.objects.any(func(o):return o.pos.distance_to(p)<65):fish.append(Vector2i(x,y))
 if not fish.is_empty():g.put_object("cat_fish",fish[rng.randi_range(0,fish.size()-1)],"cat_fish")
func install()->void:
 g.objects.assign(g.objects.filter(func(o):return o.kind!="pet_cat"));target_ref={}
 if seed_value!=int(g.save_data.seed):
  seed_value=int(g.save_data.seed);trail.clear();prints.clear();clock=0;autosave=0;last_player=Vector2.INF
  if g.save_data.cat_tamed and int(g.save_data.cat_room)==g.level and g.save_data.cat_position.size()==2:position=Vector2(g.save_data.cat_position[0],g.save_data.cat_position[1])
  else:position=g.player
 if g.save_data.cat_tamed and g.playing and not g.transition and last_player!=Vector2.INF and last_player.distance_to(g.player)>160:restore()
 if g.save_data.cat_tamed and trail.is_empty():trail.append({"pos":g.player,"time":clock-.55})
func restore()->void:
 if not g.save_data.cat_tamed:return
 trail.clear();prints.clear();last_player=g.player
 position=g.accessory_drop_position(g.player-g.walk_facing*28)
 if g.blocked(position) or not clear_segment(position,g.player):position=g.player
 if int(g.save_data.cat_room)==g.level and g.save_data.cat_position.size()==2:
  var saved:=Vector2(g.save_data.cat_position[0],g.save_data.cat_position[1])
  if saved.distance_to(g.player)<100 and not g.blocked(saved) and clear_segment(saved,g.player):position=saved
 trail.append({"pos":g.player,"time":clock})
func record()->void:
 if not g.save_data.cat_tamed:return
 if last_player==Vector2.INF or last_player.distance_to(g.player)>3:
  trail.append({"pos":g.player,"time":clock});last_player=g.player
func interact(obj:Dictionary)->bool:
 if obj.kind=="cat_fish":g.save_data.cat_fish=true;g.persist();g.sfx("chime");g.notify(g.tx("cat_fish_found"));return true
 if obj.kind=="cat_hut":
  if not can_feed(obj):return true
  if not g.save_data.cat_fish:g.notify(g.tx("cat_needs_fish"));return true
  g.save_data.cat_fish=false;g.save_data.cat_tamed=true;position=obj.pos+Vector2(0,48);trail=[{"pos":g.player,"time":clock}];last_player=g.player
  g.save_data.cat_room=g.level;g.save_data.cat_position=[position.x,position.y];g.food_heart_burst();g.persist();g.sfx("chime");g.notify(g.tx("cat_tamed"));return true
 if obj.kind=="pet_cat":
  if g.inside_main_room():return true
  g.stats.add(g,"pets");g.burst(position,5,Color("eba3b9"));g.sfx("ui");g.persist();return true
 return false
func refresh_target()->void:
 if not g.save_data.cat_tamed or g.inside_main_room():
  if not target_ref.is_empty():g.objects.erase(target_ref);target_ref={}
  return
 if target_ref.is_empty():
  target_ref={"kind":"pet_cat","id":"pet_cat","pos":position,"solid":false};g.objects.append(target_ref)
 else:target_ref.pos=position

func handoff(offset:Vector2)->void:
 if not g.save_data.cat_tamed:return
 position+=offset
 for point in trail:point.pos+=offset
 for mark in prints:mark.pos+=offset
 if last_player!=Vector2.INF:last_player+=offset
func save()->void:
 if not g.save_data.cat_tamed:return
 g.save_data.cat_room=g.level;g.save_data.cat_position=[position.x,position.y]
func update(delta:float)->void:
 if not g.playing or g.paused or g.transition:moving=false;return
 clock+=delta;autosave+=delta;repath_wait=maxf(0,repath_wait-delta)
 if autosave>8:autosave=0;save();g.persist()
 for n in range(prints.size()-1,-1,-1):
  prints[n].life-=delta
  if prints[n].life<=0:prints.remove_at(n)
 if not g.save_data.cat_tamed:return
 if last_player==Vector2.INF or last_player.distance_to(g.player)>3:
  trail.append({"pos":g.player,"time":clock});last_player=g.player
 if g.blocked(position):
  var safe:=bridge_start(position)
  if safe!=Vector2.INF:position=safe
 var before:=position;var budget:float=g.SPEED*1.18*delta
 while not trail.is_empty() and trail[0].time<=clock-.55 and budget>0:
  var point:Vector2=trail[0].pos;var distance:=position.distance_to(point)
  if distance<.1:trail.pop_front();continue
  var amount:=minf(budget,distance)
  var route_left:=distance
  if route_left<96:
   for i in range(1,trail.size()):
    route_left+=Vector2(trail[i-1].pos).distance_to(trail[i].pos)
    if route_left>=96:break
  amount=minf(amount,maxf(0,route_left-80))
  if amount<=.001:break
  var next:=position.move_toward(point,amount)
  if not clear_segment(position,next):
   if repath_wait<=0:
    repath_wait=.4
    var detour:=bridge(position,point)
    if not detour.is_empty():
     for i in range(detour.size()-1,-1,-1):trail.push_front({"pos":detour[i],"time":clock-.55})
   break
  position=next;budget-=amount
  if position.distance_to(point)<1:position=point;trail.pop_front()
 moving=position.distance_to(before)>.05
 if moving:
  var v:=position-before;direction=(1 if v.x<0 else 3) if absf(v.x)>absf(v.y) else (0 if v.y<0 else 2)
  anim+=delta;stride+=v.length()
  if stride>=16:
   stride=fmod(stride,16);prints.append({"pos":position-v.normalized()*9,"angle":v.angle()+PI/2,"life":13.0,"stone":g.stone_surface(position)})
   if prints.size()>120:prints.pop_front()
func draw_cat()->void:
 var name:="cat_walk"+str(direction)+"_"+str(int(anim*10)%4) if moving else "cat_idle"+str(direction)+"_"+str(2 if fposmod(g.time,4.7)>4.55 else int(g.time*1.5)%2)
 var p:Vector2=g.screen(position)
 var shadow:=PackedVector2Array()
 for n in range(16):shadow.append(p+Vector2(cos(n*TAU/16)*10,sin(n*TAU/16)*3))
 g.draw_floor_shadow(shadow,Color(.06,.09,.15,.25));g.draw_sprite(name,p,Color.WHITE,.8)

func draw_prints()->void:
 for mark in prints:
  if not g.shadow_floor_cell(Vector2i(mark.pos/48)):continue
  var color:=Color("a39180") if mark.stone else Color("223a2b");color.a=.68*minf(1,mark.life/2)
  g.draw_set_transform(g.screen(mark.pos),mark.angle);g.draw_sprite("cat_paw",Vector2.ZERO,color,.42);g.draw_set_transform(Vector2.ZERO)

func can_feed(obj:Dictionary)->bool:
 var relative:Vector2=g.player-obj.pos
 if relative.y<30 or absf(relative.x)>28:return false
 var front:Vector2=obj.pos+Vector2(0,36)
 for n in range(ceili(g.player.distance_to(front)/3)+1):
  var point:Vector2=g.player.lerp(front,float(n)/maxf(1,ceili(g.player.distance_to(front)/3)))
  for offset in [Vector2(-9,-6),Vector2(9,-6),Vector2(-9,6),Vector2(9,6)]:
   var cell:=Vector2i((point+offset)/48)
   if cell.x<0 or cell.y<0 or cell.y>=g.grid.size() or cell.x>=g.grid[0].length() or g.grid[cell.y][cell.x]!=".":return false
 return true
func clear_segment(a:Vector2,b:Vector2)->bool:
 var count:=maxi(1,ceili(a.distance_to(b)/3))
 for i in range(1,count+1):
  if g.blocked(a.lerp(b,float(i)/count)):return false
 return true
func bridge_start(point:Vector2)->Vector2:
 var best:=Vector2.INF;var distance:=INF
 for y in range(-3,4):
  for x in range(-3,4):
   var p:Vector2=(point/12).round()*12+Vector2(x,y)*12
   if not g.blocked(p) and p.distance_squared_to(point)<distance:best=p;distance=p.distance_squared_to(point)
 return best
func bridge(start:Vector2,goal:Vector2)->Array[Vector2]:
 # Small local grid only when a breadcrumb is obstructed; normal motion follows actual footsteps.
 var first:=Vector2i((start/12).round());var queue:Array[Vector2i]=[];var parents:Dictionary={}
 for y in range(-2,3):
  for x in range(-2,3):
   var cell:=first+Vector2i(x,y);var point:=Vector2(cell)*12
   if not g.blocked(point) and clear_segment(start,point):queue.append(cell);parents[cell]=cell
 var head:=0;var finish:=Vector2i(-99999,-99999)
 var bounds:=Rect2(start.min(goal)-Vector2(96,96),start.max(goal)-start.min(goal)+Vector2(192,192))
 while head<queue.size() and head<2500:
  var cell:=queue[head];head+=1;var point:=Vector2(cell)*12
  if point.distance_to(goal)<=24 and clear_segment(point,goal):finish=cell;break
  for offset in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
   var next:Vector2i=cell+offset;var target:=Vector2(next)*12
   if parents.has(next) or not bounds.has_point(target) or not clear_segment(point,target):continue
   parents[next]=cell;queue.append(next)
 var result:Array[Vector2]=[]
 if finish.x==-99999:return result
 while true:
  result.push_front(Vector2(finish)*12)
  if parents[finish]==finish:break
  finish=parents[finish]
 return result
