extends RefCounted
## Seven room-bound stones. Inventory and socket states survive every room rebuild.
var seed_value:=-1
var flights:Array[Dictionary]=[]
var g:Node2D
func _init(game:Node2D):g=game
func ensure()->void:
 if seed_value!=int(g.save_data.seed):flights.clear();seed_value=int(g.save_data.seed)
 for key in ["riddle_stones","riddle_inserted","riddle_stone_order"]:
  if not g.save_data.has(key):g.save_data[key]=[]
 if not g.save_data.has("riddle_stone_positions"):g.save_data.riddle_stone_positions={}
 if not g.save_data.has("riddle_stone_exposed"):g.save_data.riddle_stone_exposed=false
 if g.save_data.riddle_stone_order.size()!=7:
  var order:Array=g.content.puzzle.symbols.duplicate();var rng:=RandomNumberGenerator.new();rng.seed=int(g.save_data.seed)^0x53544f4e
  for i in range(6,0,-1):
   var j:=rng.randi_range(0,i);var swap=order[i];order[i]=order[j];order[j]=swap
  g.save_data.riddle_stone_order=order
  if not g.save_data.finished:g.save_data.riddle_input=[]
func install()->void:
 ensure()
 g.objects.assign(g.objects.filter(func(o):return o.kind!="riddle_stone"))
 var id:String=g.save_data.riddle_stone_order[g.level]
 if id in g.save_data.riddle_stones:return
 var room:=str(g.level);var pos:Vector2
 if g.save_data.riddle_stone_positions.has(room):
  var p:Array=g.save_data.riddle_stone_positions[room];pos=Vector2(p[0],p[1])
 else:
  var choices:Array[Vector2]=[];var rng:=RandomNumberGenerator.new();rng.seed=int(g.save_data.seed)+g.level*13477+71993
  var width:int=g.grid[0].length();var height:int=g.grid.size()
  for y in range(7,height-7):
   for x in range(1,width-1):
    var point:=Vector2(x+.5,y+.5)*48
    if g.level==0:
     if g.grid[y][x]!="#":continue
     if not [g.grid[y][x-1],g.grid[y][x+1],g.grid[y-1][x],g.grid[y+1][x]].has("."):continue
     if g.objects.any(func(o):return o.pos.distance_to(point)<65):continue
    else:
     if not g.valid_ground(point) or g.blocked(point):continue
     if mini(x,width-1-x)>3 and mini(y-5,height-6-y)>3:continue
     if g.objects.any(func(o):return o.pos.distance_to(point)<80):continue
     if g.level==3 and point.distance_to(Vector2(g.save_data.dig_target[0],g.save_data.dig_target[1]))<130:continue
    choices.append(point)
  if choices.is_empty():push_error("No reachable edge position for riddle stone in room %d"%g.level);return
  pos=choices[rng.randi_range(0,choices.size()-1)]
  g.save_data.riddle_stone_positions[room]=[pos.x,pos.y]
 var obj:={"kind":"riddle_stone","id":id,"pos":pos,"solid":false,"hidden_hedge":g.level==0,"buried_stone":g.level==3}
 if g.level==3 and not g.save_data.riddle_stone_exposed:return
 g.objects.append(obj)
func excavate(pos:Vector2)->void:
 if g.level!=3:return
 ensure()
 var id:String=g.save_data.riddle_stone_order[3]
 if id in g.save_data.riddle_stones or g.save_data.riddle_stone_exposed:return
 var point:Array=g.save_data.riddle_stone_positions.get("3",[])
 if point.size()!=2:return
 var hidden:=Vector2(point[0],point[1]);var distance:=pos.distance_to(hidden)
 if distance<38:
  g.save_data.riddle_stone_exposed=true;g.save_data.riddle_stone_positions["3"]=[pos.x,pos.y];install()
  g.burst(pos,12,Color("e6c592"));g.notify(g.tx("stone_unearthed"))
 elif distance<170:g.notify(g.tx("stone_dig_near"))
func texture(obj:Dictionary)->String:
 if obj.kind=="riddle_stone":return "rune_"+str(obj.id)
 if obj.id=="puzzle_reset":return "rune_reset"
 var id:String=obj.id
 if flights.any(func(f):return f.id==id and g.time-float(f.start)<.75):return "socket_"+id+"_empty"
 return "socket_"+id+"_pressed" if activated(id) else "socket_"+id+"_full" if id in g.save_data.riddle_inserted else "socket_"+id+"_empty"
func name_for(obj:Dictionary)->String:
 return g.tx("rune_stone_name").format({"symbol":g.tx("symbol_"+str(obj.id))}) if obj.kind=="riddle_stone" else g.tx("rune_socket_name").format({"symbol":g.tx("symbol_"+str(obj.id))})
func collect(obj:Dictionary)->void:
 if obj.id in g.save_data.riddle_stones:return
 g.save_data.riddle_stones.append(str(obj.id));g.objects.erase(obj)
 g.sfx("chime");g.burst(obj.pos,16,Color("f4ce96"));g.notify(g.tx("rune_found").format({"count":g.save_data.riddle_stones.size()}));g.persist();g.find_nearest()
func use_socket(id:String,pos:Vector2)->void:
 if flights.any(func(f):return g.time-float(f.start)<.75):return
 if id=="puzzle_reset":g.press_riddle_symbol(id,pos);return
 if id not in g.save_data.riddle_inserted:
  if id not in g.save_data.riddle_stones:g.notify(g.tx("rune_not_found"));return
  flights.assign(flights.filter(func(f):return g.time-float(f.start)<.75))
  flights.append({"id":id,"room":g.level,"start":g.time,"origin":g.player+Vector2(14,-22),"target":pos+Vector2(0,-32)})
  g.save_data.riddle_inserted.append(id);g.persist()
  g.notify(g.tx("rune_all_inserted") if ready() else g.tx("rune_inserted").format({"count":g.save_data.riddle_inserted.size()}));return
 if not ready():g.notify(g.tx("rune_need_all"));return
 g.press_riddle_symbol(id,pos)
func activated(id:String)->bool:
 return id in g.save_data.riddle_inserted and id in g.puzzle
func ready()->bool:
 return g.content.puzzle.symbols.all(func(id):return id in g.save_data.riddle_inserted)
func update()->void:
 for flight in flights:
  if not flight.get("landed",false) and g.time-float(flight.start)>=.72:
   flight.landed=true
   if int(flight.room)==g.level:g.sfx("stone_insert");g.burst(Vector2(flight.target)+Vector2(0,-24),6,Color("ddc29b"))
func draw_insertions()->void:
 for flight in flights:
  if int(flight.room)!=g.level:continue
  var age:=maxf(0,g.time-float(flight.start))
  if age>=.75:continue
  var t:=clampf(age/.5,0,1)
  var target:Vector2=Vector2(flight.target)
  var point:Vector2=Vector2(flight.origin).lerp(target+Vector2(0,-14),smoothstep(0,1,t))+Vector2(0,-sin(t*PI)*35)
  if age>.5:point=target+Vector2(0,-14*(1-smoothstep(0,1,(age-.5)/.25)))
  g.draw_sprite("rune_"+str(flight.id),g.screen(point),Color.WHITE,1-.15*t)
