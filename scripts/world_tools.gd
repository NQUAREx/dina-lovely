extends RefCounted
const PIT_WALL := [Color("76543c"),Color("674832"),Color("5c3f2e"),Color("51382b"),Color("473229"),Color("402e28"),Color("382b27"),Color("332925"),Color("2e2724"),Color("2b2523")]
## Optional world editing. Only the current room runs; other rooms keep saved data.
const TOOLS := ["axe","shears","drill"]
var dig_shapes:Image=preload("res://assets/dig_shapes.png").get_image()
var soil_fx_clock:=0.0
var stubble:Texture2D=preload("res://assets/hedge_stubble.png")
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
 if not g.save_data.has("world_kit"):g.save_data.world_kit=[]
 if g.held_item in TOOLS and g.save_data.finished and g.held_item not in g.save_data.world_kit:g.save_data.world_kit.append(g.held_item)
 restore_tools()
 if not data.excavations.is_empty():ensure_dirt()
func restore_tools()->void:
 g.objects.assign(g.objects.filter(func(obj):return obj.kind not in TOOLS))
 for tool in TOOLS:
  if g.held_item==tool or tool in g.save_data.get("world_kit",[]):continue
  var info:Dictionary=g.save_data.world_tool_locations.get(tool,{"room":6,"pos":[22.5*48.0,(13.5+TOOLS.find(tool)*1.25)*48.0],"rack":true})
  if int(info.room)==g.level:g.objects.append({"kind":tool,"id":tool,"pos":Vector2(info.pos[0],info.pos[1]),"solid":false,"ground_tool":not info.get("rack",false),"on_table":info.get("rack",false)})
func drop_held(force:bool=false,point:Vector2=Vector2.INF)->void:
 var tool:String=g.held_item
 if tool not in TOOLS:return
 if not force and tool in g.save_data.get("world_kit",[]):
  g.held_item="";g.sync_hands();return
 g.save_data.world_kit.erase(tool)
 var pos:Vector2=g.accessory_drop_position(g.player+Vector2(0,30)) if point==Vector2.INF else point
 g.save_data.world_tool_locations[tool]={"room":g.level,"pos":[pos.x,pos.y],"rack":false}
 g.held_item="";g.sync_hands();restore_tools()
func pickup(tool:String)->void:
 if not g.save_data.finished:return
 g.return_held_tool();
 if tool not in g.save_data.world_kit:g.save_data.world_kit.append(tool)
 g.held_item=tool;g.sync_hands();g.save_data.world_tool_locations[tool]={"room":-1,"pos":[]};restore_tools();g.persist();g.sfx("ui");g.find_nearest();g.update_hud()
func cycle()->void:
 if g.paused or g.transition or not g.playing or g.task_time>0:return
 var kit:Array=g.save_data.get("world_kit",[])
 if kit.is_empty():return
 var next:String=kit[(kit.find(g.held_item)+1)%kit.size()]
 g.return_held_tool();g.held_item=next;g.sync_hands();g.persist();g.sfx("ui");g.find_nearest();g.update_hud()
func start_drill()->void:
 if g.held_item=="drill" and soil(ground_point()):g.begin_task("drill",ground_point(),.65)
func is_excavated(point:Vector2)->bool:
 var key:=str(g.level)
 if not masks.has(key):return false
 var mask:Image=masks[key];var pixel:=Vector2i((point/2).floor())
 return pixel.x>=0 and pixel.y>=0 and pixel.x<mask.get_width() and pixel.y<mask.get_height() and mask.get_pixelv(pixel).r>.5
func print_clear(point:Vector2,rotation:float=0)->bool:
 for offset in [Vector2.ZERO,Vector2(-4,-7),Vector2(4,-7),Vector2(-4,7),Vector2(4,7)]:
  if is_excavated(point+offset.rotated(rotation)):return false
 return true

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
  var parts:=kind.split(":");var cell:=Vector2i(int(parts[1]),int(parts[2]));data.hedges.append([cell.x,cell.y]);apply_hedge(cell);cut_particles(pos);return true
 if kind.begins_with("snip_decor:"):
  data.flowers.append(kind.trim_prefix("snip_decor:"));g.objects.assign(g.objects.filter(func(obj):return obj.kind not in ["flowers","blueflowers"] or key_for(obj)!=kind.trim_prefix("snip_decor:")));g.burst(pos,30,Color("e9a3c6"));return true
 if kind.begins_with("uproot:") or kind.begins_with("snip:"):
  var id:=kind.split(":")[1];var texture:="bloom"+str(variant(id))+"_plant"
  if kind.begins_with("uproot:"):falling.append({"room":g.level,"pos":pos,"texture":texture,"age":0.0})
  else:g.burst(pos,30,Color("e9a3c6"))
  g.plants.erase(id);g.watered.erase(id);g.save_data.watered=g.watered.duplicate();g.fertilized.erase(id);g.bloom_times.erase(id);return true
 return false
func cut_particles(pos:Vector2)->void:
 for n in range(randi_range(28,38)):
  var part:Dictionary=g.leaf_debris.spawn(pos+Vector2(randf_range(-21,21),randf_range(-15,15)),false)
  part.size=randf_range(.8,1.5) if n%3==0 else randf_range(1.7,3.2)
  part.vel*=randf_range(.7,1.4);part.leaf_height=randf_range(10,30);part.leaf_vz=randf_range(20,48)
  g.particles.append(part)

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
 var key:=str(g.level);var mask:Image=masks[key];var image:Image=images[key];var centre:=Vector2i(pos/2)
 var shape_rng:=RandomNumberGenerator.new()
 shape_rng.seed=int(g.save_data.seed)^(int(pos.x)*73856093)^(int(pos.y)*19349663)^(g.level*4177)
 var variant:=shape_rng.randi_range(0,7);var mirror:=shape_rng.randf()>.5
 for y in range(28):
  for x in range(40):
   var target:=centre+Vector2i(x-20,y-14)
   if target.x<1 or target.y<1 or target.x>=mask.get_width()-1 or target.y>=mask.get_height()-1:continue
   if dig_shapes.get_pixel(variant*40+(39-x if mirror else x),y).a>.5:mask.set_pixelv(target,Color.WHITE)
 # The union mask owns the rim. Running depth down each column avoids the old
 # twenty-pixel upward search at every pixel and leaves no seams between stamps.
 var first_y:=maxi(1,centre.y-16);var last_y:=mini(mask.get_height()-1,centre.y+36)
 for x in range(maxi(1,centre.x-23),mini(mask.get_width()-1,centre.x+24)):
  var depth:=0
  for y in range(maxi(0,first_y-20),last_y):
   if mask.get_pixel(x,y).r<.5:depth=0;continue
   depth=mini(20,depth+1)
   if y<first_y:continue
   var side_edge:=mask.get_pixel(x-1,y).r<.5 or mask.get_pixel(x+1,y).r<.5
   var color:=Color("a88255") if depth==1 else Color("49362d") if side_edge else Color("2b2523")
   if depth>1:
    color=PIT_WALL[mini(9,depth-2)]
    if depth in [3,6] and posmod(x*13+y*7,17)<4:color=color.lightened(.035)
    elif depth>9 and posmod(x*31+y*17,23)<2:color=Color("3a3029")
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
 g.scene_fx.soil(pos,10)
 if g.held_item=="drill":g.sfx_at("dig",pos)
 g.persist()
func update(delta:float)->void:
 drilling=g.held_item=="drill" and g.task_time>0 and g.task_kind=="drill" and g.playing and not g.paused and not g.transition and soil(ground_point())
 soil_fx_clock-=delta
 var shoveling:bool=g.playing and not g.paused and not g.transition and g.held_item=="shovel" and g.task_time>0 and g.task_kind.begins_with("dig:")
 if (drilling or shoveling) and soil_fx_clock<=0:
  soil_fx_clock=.075 if shoveling else .085
  g.scene_fx.soil(g.task_target if shoveling else ground_point(),10 if shoveling else 7)
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
 for cut in state().hedges:
  var cell:=Vector2i(int(cut[0]),int(cut[1]));var point:=Vector2(cell)*48
  if not g.get_viewport_rect().grow(48).has_point(g.screen(point)):continue
  var variant:=posmod(cell.x*13+cell.y*7,3)
  g.draw_texture_rect_region(stubble,Rect2(g.screen(point),Vector2(48,48)),Rect2(variant*24,0,24,24))
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
