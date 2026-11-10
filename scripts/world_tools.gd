extends RefCounted
const PIT_WALL := [Color("76543c"),Color("674832"),Color("5c3f2e"),Color("51382b"),Color("473229"),Color("402e28"),Color("382b27"),Color("332925"),Color("2e2724"),Color("2b2523")]
## Optional world editing. Only the current room runs; other rooms keep saved data.
const TOOLS := ["axe","shears","drill"]
var g:Node2D
var images:Dictionary={}
var masks:Dictionary={}
var textures:Dictionary={}
var sample_indices:Dictionary={}
var seed_value:=-1
var drill_clock:=0.0
var drill_voice:AudioStreamPlayer
var drilling:=false
var falling:Array[Dictionary]=[]
func _init(game:Node2D):g=game
func state() -> Dictionary:
 var key:=str(g.level)
 if not g.save_data.world_edits.has(key):g.save_data.world_edits[key]={"trees":[],"flowers":[],"hedges":[],"excavations":[],"beds":[]}
 return g.save_data.world_edits[key]
func key_for(obj:Dictionary)->String:return "%s_%d_%d"%["tree" if obj.kind in ["tree","tree_apples","fallen_tree"] else "flower",roundi(obj.pos.x),roundi(obj.pos.y)]
func variant(id:String)->int:return posmod(int(id),6)
func install()->void:
 if seed_value!=int(g.save_data.seed):images.clear();masks.clear();textures.clear();sample_indices.clear();falling.clear();seed_value=int(g.save_data.seed)
 var data:=state()
 # One-time migration from the old isolated-pit save format.
 if g.level==3:
  for old in g.save_data.dug:
   var parts:=str(old).split(":")
   if parts.size()==2:
    var point:=[float(parts[0]),float(parts[1])]
    if point not in data.excavations:data.excavations.append(point)
 g.objects.assign(g.objects.filter(func(obj):return obj.kind!="dug" and not (obj.kind in ["flowers","blueflowers"] and key_for(obj) in data.flowers)))
 for obj in g.objects:
  if obj.kind in ["tree","tree_apples"] and key_for(obj) in data.trees:obj.kind="fallen_tree";obj.solid=false;obj.erase("integrated_hedge")
 if g.hedge_field!=null:
  for cut in data.hedges:apply_hedge(Vector2i(int(cut[0]),int(cut[1])))
 if g.level==5:
  for bed in data.beds:
   var existing=g.objects.filter(func(obj):return obj.kind=="sprout" and obj.id==bed.id)
   if existing.is_empty():g.objects.append({"kind":"sprout","id":bed.id,"pos":Vector2(bed.pos[0],bed.pos[1]),"solid":false,"extra_bed":true})
   else:existing[0].pos=Vector2(bed.pos[0],bed.pos[1])
  repair_beds()
 restore_tools()
 if not data.excavations.is_empty():ensure_dirt()
func restore_tools()->void:
 g.objects.assign(g.objects.filter(func(obj):return obj.kind not in TOOLS))
 for tool in TOOLS:
  if g.held_item==tool:continue
  var info:Dictionary=g.save_data.world_tool_locations.get(tool,{"room":6,"pos":[22.5*48.0,(12.5+TOOLS.find(tool)*2)*48.0],"rack":true})
  if int(info.room)==g.level:g.objects.append({"kind":tool,"id":tool,"pos":Vector2(info.pos[0],info.pos[1]),"solid":false,"ground_tool":not info.get("rack",false)})
func drop_held()->void:
 var tool:String=g.held_item
 if tool not in TOOLS:return
 var pos:Vector2=g.accessory_drop_position(g.player+Vector2(0,30))
 g.save_data.world_tool_locations[tool]={"room":g.level,"pos":[pos.x,pos.y],"rack":false}
 g.held_item="";g.sync_hands();restore_tools()
func pickup(tool:String)->void:
 if not g.save_data.finished:return
 g.return_held_tool();g.held_item=tool;g.sync_hands();g.save_data.world_tool_locations[tool]={"room":-1,"pos":[]};restore_tools();g.persist();g.sfx("ui")
func tree_target(obj:Dictionary)->bool:return g.held_item=="axe" and obj.kind in ["tree","tree_apples","hedge_tree","hedge_tree_apples"]
func flower_target(obj:Dictionary)->bool:return g.held_item=="shears" and (obj.kind in ["flowers","blueflowers"] or (obj.kind=="sprout" and int(g.plants.get(obj.id,{}).get("stage",0))>0))
func refresh_targets()->void:
 g.objects.assign(g.objects.filter(func(obj):return obj.kind!="hedge_target"))
 if g.held_item!="shears" or g.level!=0:return
 var cell:=Vector2i(g.player/48)
 var best:Dictionary={};var distance:=79.0
 for y in range(cell.y-1,cell.y+2):
  for x in range(cell.x-1,cell.x+2):
   if x<1 or y<6 or x>=g.grid[0].length()-1 or y>=g.grid.size()-6:continue
   if g.grid[y][x]!="#":continue
   var pos:Vector2=(Vector2(x,y)+Vector2(.5,.5))*48
   if g.objects.any(func(obj):return obj.kind in ["tree","tree_apples"] and obj.pos.distance_to(pos)<28):continue
   var obj:={"kind":"hedge_target","id":"hedge_%d_%d"%[x,y],"pos":pos,"solid":false,"cell":Vector2i(x,y)}
   if pos.distance_to(g.player)<distance and g.interaction_reachable(obj):best=obj;distance=pos.distance_to(g.player)
 if not best.is_empty():g.objects.append(best)

func use_object(obj:Dictionary)->bool:
 if tree_target(obj):g.begin_task("axe:"+key_for(obj),obj.pos,.65);return true
 if obj.kind=="hedge_target" and g.held_item=="shears":g.begin_task("snip_hedge:"+str(obj.cell.x)+":"+str(obj.cell.y),obj.pos,.35);return true
 if flower_target(obj):g.begin_task("snip:"+str(obj.id) if obj.kind=="sprout" else "snip_decor:"+key_for(obj),obj.pos,.35);return true
 if obj.kind=="sprout" and g.held_item=="rake" and int(g.plants.get(obj.id,{}).get("stage",0))>=2:g.begin_task("uproot:"+str(obj.id),obj.pos,.65);return true
 return false
func ground_point()->Vector2:return (g.player+g.walk_facing.normalized()*34).snapped(Vector2(12,12))
func soil(pos:Vector2)->bool:
 if g.level in [4,6] or not g.valid_ground(pos) or g.corridor_row(floori(pos.y/48)) or pos.y<7*48 or pos.y>(g.grid.size()-7)*48:return false
 return not g.blocked(pos) and not g.objects.any(func(obj):return (obj.solid or obj.kind=="doorway") and obj.pos.distance_to(pos)<38)
func can_bed()->bool:
 var pos:=ground_point()
 return g.level==5 and g.held_item=="rake" and soil(pos) and g.garden_bed_clear(pos)
func make_bed()->void:
 if can_bed():g.begin_task("new_bed",ground_point(),.65)
func complete(kind:String,pos:Vector2)->bool:
 var data:=state()
 if kind=="new_bed":
  g.stats.add(g,"beds")
  var id:=str(100+int(g.save_data.bed_serial));g.save_data.bed_serial+=1
  data.beds.append({"id":id,"pos":[pos.x,pos.y]});g.objects.append({"kind":"sprout","id":id,"pos":pos,"solid":false,"extra_bed":true})
  g.save_data.cleaned.append(id);g.burst(pos,10,Color("987858"));return true
 if kind.begins_with("axe:"):
  for obj in g.objects:
   if obj.kind in ["tree","tree_apples"] and key_for(obj)==kind.trim_prefix("axe:"):
    data.trees.append(key_for(obj));obj.kind="fallen_tree";obj.solid=false;obj.erase("integrated_hedge");g.burst(pos,20,Color("ac916d"));break
  return true
 if kind.begins_with("snip_hedge:"):
  var parts:=kind.split(":");var cell:=Vector2i(int(parts[1]),int(parts[2]));data.hedges.append([cell.x,cell.y]);apply_hedge(cell);g.burst(pos,42,Color("719c65"));return true
 if kind.begins_with("snip_decor:"):
  data.flowers.append(kind.trim_prefix("snip_decor:"));g.objects.assign(g.objects.filter(func(obj):return obj.kind not in ["flowers","blueflowers"] or key_for(obj)!=kind.trim_prefix("snip_decor:")));g.burst(pos,30,Color("e9a3c6"));return true
 if kind.begins_with("uproot:") or kind.begins_with("snip:"):
  var id:=kind.split(":")[1];var texture:="bloom"+str(variant(id))+"_plant"
  if kind.begins_with("uproot:"):falling.append({"room":g.level,"pos":pos,"texture":texture,"age":0.0})
  else:g.burst(pos,30,Color("e9a3c6"))
  g.plants.erase(id);g.watered.erase(id);g.save_data.watered=g.watered.duplicate();g.fertilized.erase(id);g.bloom_times.erase(id);return true
 return false
func apply_hedge(cell:Vector2i)->void:
 if cell.x<1 or cell.y<6 or cell.x>=g.grid[0].length()-1 or cell.y>=g.grid.size()-6:return
 g.set_cell(cell.x,cell.y,".")
 if g.hedge_field!=null:g.hedge_field.remove_cell(cell)
 for obj in g.objects:
  if obj.get("hidden_hedge",false) and Vector2i(obj.pos/48)==cell:obj.hidden_hedge=false
func ensure_dirt()->void:
 var key:=str(g.level)
 if images.has(key):return
 var size:=Vector2i(g.grid[0].length()*24,g.grid.size()*24)
 masks[key]=Image.create(size.x,size.y,false,Image.FORMAT_L8);images[key]=Image.create(size.x,size.y,false,Image.FORMAT_RGBA8)
 for point in state().excavations:stamp(Vector2(point[0],point[1]))
 textures[key]=ImageTexture.create_from_image(images[key])
func stamp(pos:Vector2)->void:
 var key:=str(g.level);var mask:Image=masks[key];var image:Image=images[key];var centre:=pos/2
 for y in range(maxi(1,int(centre.y)-10),mini(mask.get_height()-1,int(centre.y)+11)):
  for x in range(maxi(1,int(centre.x)-16),mini(mask.get_width()-1,int(centre.x)+17)):
   var noise:float=sin(x*17.31+y*7.91)*.07
   if ((Vector2(x+.5,y+.5)-centre)/Vector2(15.5,9.5)).length()<1+noise:mask.set_pixel(x,y,Color.WHITE)
 for y in range(maxi(1,int(centre.y)-12),mini(mask.get_height()-1,int(centre.y)+33)):
  for x in range(maxi(1,int(centre.x)-18),mini(mask.get_width()-1,int(centre.x)+19)):
   if mask.get_pixel(x,y).r<.5:continue
   var top_depth:=20
   for depth in range(1,21):
    if y-depth<0 or mask.get_pixel(x,y-depth).r<.5:top_depth=depth;break
   var upper_edge:=mask.get_pixel(x,y-1).r<.5
   var side_edge:=mask.get_pixel(x-1,y).r<.5 or mask.get_pixel(x+1,y).r<.5
   var color:=Color("a88255") if upper_edge else Color("49362d") if side_edge else Color("2b2523")
   if top_depth>1:
    color=PIT_WALL[mini(9,top_depth-2)]
    if top_depth in [3,6] and posmod(x*13+y*7,17)<4:color=color.lightened(.035)
    elif top_depth>9 and posmod(x*31+y*17,23)<2:color=Color("3a3029")

   image.set_pixel(x,y,color)
func has_sample(pos:Vector2)->bool:
 var room:=str(g.level)
 if not sample_indices.has(room):
  sample_indices[room]={}
  for point in state().excavations:sample_indices[room]["%d:%d"%[point[0],point[1]]]=true
 return sample_indices[room].has("%d:%d"%[pos.x,pos.y])
func excavate(pos:Vector2)->void:
 pos=pos.snapped(Vector2(12,12))
 if not soil(pos) or has_sample(pos):return
 g.stats.add(g,"digs")
 ensure_dirt();state().excavations.append([pos.x,pos.y]);sample_indices[str(g.level)]["%d:%d"%[pos.x,pos.y]]=true;stamp(pos);textures[str(g.level)].update(images[str(g.level)])
 if g.level==3:
  var id:="%d:%d"%[pos.x,pos.y]
  if id not in g.save_data.dug:g.save_data.dug.append(id)
  var hidden:=Vector2(g.save_data.dig_target[0],g.save_data.dig_target[1])
  if not g.save_data.buried_exposed and pos.distance_to(hidden)<90 and "buried" not in g.save_data.letters:
   g.save_data.buried_exposed=true;g.save_data.dig_target=[pos.x,pos.y];g.objects.append({"kind":"note","id":"buried","solid":false,"pos":pos,"rise_start":g.time});g.notify(g.tx("buried_note_exposed"))
  elif not g.save_data.buried_exposed:g.notify(g.tx("buried_note_near") if pos.distance_to(hidden)<260 else g.tx("digging_empty"))
 g.rune_stones.excavate(pos)
 g.burst(pos,7,Color("aa8263"));g.persist()
func update(delta:float)->void:
 drilling=g.held_item=="drill" and g.playing and not g.paused and not g.transition and soil(ground_point())
 drill_clock-=delta
 if drilling and drill_clock<=0:drill_clock=.18;excavate(ground_point())
 if drill_voice==null:
  drill_voice=AudioStreamPlayer.new();var stream:=load("res://assets/drill_loop.wav").duplicate() as AudioStreamWAV;stream.loop_mode=AudioStreamWAV.LOOP_FORWARD;stream.loop_end=int(stream.get_length()*stream.mix_rate);drill_voice.stream=stream;drill_voice.volume_db=-80
  if OS.has_feature("web"):drill_voice.playback_type=AudioServer.PLAYBACK_TYPE_SAMPLE
  g.add_child(drill_voice)
 var gain:float=-22 if drilling and g.sound_on else -80
 drill_voice.volume_db=move_toward(drill_voice.volume_db,gain,delta*200)
 if gain>-80 and not drill_voice.playing:drill_voice.play()
 if drill_voice.volume_db<=-79 and drill_voice.playing:drill_voice.stop()
 for index in range(falling.size()-1,-1,-1):
  falling[index].age+=delta
  if falling[index].age>1.0:falling.remove_at(index)
func draw_ground()->void:
 if textures.has(str(g.level)):g.draw_texture_rect(textures[str(g.level)],Rect2(g.screen(Vector2.ZERO),Vector2(g.grid[0].length(),g.grid.size())*48),false)
func draw_falling()->void:
 for item in falling:
  if item.room!=g.level:continue
  var progress:float=item.age
  g.draw_set_transform(g.screen(item.pos)+Vector2(progress*12,0),progress*1.5)
  g.draw_sprite(item.texture,Vector2.ZERO,Color(1,1,1,1-smoothstep(.55,1,progress)));g.draw_set_transform(Vector2.ZERO)

func repair_beds()->void:
 for bed in g.objects:
  if bed.kind!="sprout" or not bed.get("extra_bed",false) or g.garden_bed_clear(bed.pos,true,bed.id):continue
  var best:=Vector2.INF;var distance:=INF
  for y in range(8,g.grid.size()-7):
   for x in range(2,g.grid[0].length()-2):
    var point:Vector2=Vector2(x+.5,y+.5)*48
    if point.distance_squared_to(bed.pos)<distance and g.garden_bed_clear(point,true,bed.id):best=point;distance=point.distance_squared_to(bed.pos)
  if best!=Vector2.INF:
   bed.pos=best
   for saved in state().beds:
    if saved.id==bed.id:saved.pos=[best.x,best.y]
