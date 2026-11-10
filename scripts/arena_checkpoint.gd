extends RefCounted
## JSON-safe, seed-bound arena state. Inactive rooms stay frozen in the room cache.
const FIELDS:=["objects","enemies","shots","poison_zones","health","invincible","wave","wave_timer","combat_done","player","magazine","reload_time","rpg_reload","attack_cd"]
var g:Node2D
var clock:=0.0
var resetting:=false
func _init(game:Node2D):g=game
func pack(value:Variant)->Variant:
 if value is Vector2:return {"$v2":[value.x,value.y]}
 if value is Vector2i:return {"$i2":[value.x,value.y]}
 if value is Color:return {"$color":[value.r,value.g,value.b,value.a]}
 if value is Array:
  var result=[]
  for entry in value:result.append(pack(entry))
  return result
 if value is Dictionary:
  var result={}
  for key in value:result[key]=pack(value[key])
  return result
 return value
func unpack(value:Variant)->Variant:
 if value is Array:
  var result=[]
  for entry in value:result.append(unpack(entry))
  return result
 if value is Dictionary:
  if value.has("$v2"):return Vector2(value["$v2"][0],value["$v2"][1])
  if value.has("$i2"):return Vector2i(int(value["$i2"][0]),int(value["$i2"][1]))
  if value.has("$color"):return Color(value["$color"][0],value["$color"][1],value["$color"][2],value["$color"][3])
  var result={}
  for key in value:result[key]=unpack(value[key])
  return result
 return value
func valid()->bool:
 var state:Dictionary=g.save_data.arena_checkpoint
 return not state.is_empty() and not state.get("dead",false) and int(state.get("seed",-1))==int(g.save_data.seed) and state.get("fields") is Dictionary and int(state.fields.get("health",0))>0
func capture()->void:
 if resetting or not g.playing or g.level!=4 or g.health<=0:return
 var fields={}
 for field in FIELDS:fields[field]=pack(g.get(field))
 g.save_data.arena_checkpoint={"schema":1,"seed":g.save_data.seed,"fields":fields,"held_item":g.held_item,"time":g.time,"remains":pack(g.room_remains.get(4,[]))}
 clock=0
func restore_room()->void:
 if resetting or g.level!=4 or not valid():return
 var state:Dictionary=g.save_data.arena_checkpoint
 for field in FIELDS:
  if not state.fields.has(field):continue
  var value:Variant=unpack(state.fields[field])
  if g.get(field) is Array:g.get(field).assign(value)
  elif field in ["health","wave","magazine"]:g.set(field,int(value))
  else:g.set(field,value)
 g.time=maxf(g.time,float(state.get("time",0)))
 g.room_remains[4]=unpack(state.get("remains",[]))
func restore_hands()->void:
 if g.level!=4 or not valid():return
 g.held_item=str(g.save_data.arena_checkpoint.get("held_item",""));g.weapon=g.held_item if g.held_item in ["rifle","rpg","sword"] else "";g.sync_hands()
func mark_dead()->void:
 if g.level==4:g.save_data.arena_checkpoint={"dead":true,"seed":g.save_data.seed}
func reset_saved()->void:
 g.save_data.arena_checkpoint={}
 g.save_data.weapons_taken=[]
 for drop in g.save_data.loose_accessories:
  if int(drop.room)==4:drop.room=g.accessory_origin(str(drop.accessory));drop.pos=[]
 g.save_data.loose_weapons=g.save_data.loose_weapons.filter(func(o):return int(o.get("room",4))!=4)
 if g.held_item in ["rifle","rpg","sword"]:g.held_item="";g.weapon=""
 if str(g.save_data.held_item) in ["rifle","rpg","sword"]:g.save_data.held_item="";g.save_data.weapon=""
 if not g.save_data.finished:g.save_data.open_gates.erase(4)
func sanitize_dead_save()->void:
 if g.save_data.arena_checkpoint.get("dead",false):reset_saved()
func restart()->void:
 resetting=true;reset_saved();g.room_remains.erase(4)
 g.attack_held=false;g.attack_cd=0;g.attack_flash=0;g.rpg_reload=0;g.reload_time=0;g.magazine=30;g.rifle_kick=0;g.shake=0;g.food_hearts_left=0
 g.build_level(4);g.sync_hands();g.cache_current_room();resetting=false;g.clear_modal();g.persist()
func update(delta:float)->void:
 if resetting or not g.playing or g.paused or g.level!=4 or g.health<=0:return
 clock+=delta
 if clock>=5:g.persist()
