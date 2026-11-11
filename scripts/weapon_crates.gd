extends RefCounted
## One durable crate per weapon. Progress, floor drops and one-time openings persist.
const ART:Texture2D=preload("res://assets/iron_weapon_crates.png")
const WEAPONS:=["rpg","rifle","sword"]
var g:Node2D
func _init(game:Node2D):g=game
func unlock_wave(weapon:String)->int:
 if weapon=="sword":return 2
 var shooter:=6 if weapon=="rifle" else 7
 for i in range(g.battle.WAVES.size()):
  if shooter in g.battle.WAVES[i] or (weapon=="rifle" and 5 in g.battle.WAVES[i]):return i+1
 return g.battle.WAVE_COUNT
func unlocked(weapon:String)->bool:
 return g.save_data.finished or g.combat_done or maxi(g.wave,g.prepared_wave)>=unlock_wave(weapon)
func install(animate:bool=false)->void:
 if g.level!=4:return
 if not g.save_data.has("weapon_crates_opened"):g.save_data.weapon_crates_opened=[]
 for obj in g.objects:
  if obj.kind.begins_with("rack_"):
   obj.weapon=str(obj.id);obj.id="crate_"+str(obj.weapon);obj.kind="weapon_crate";obj.solid=true
 for w in WEAPONS:
  var crates:Array=g.objects.filter(func(o):return o.kind=="weapon_crate" and o.weapon==w)
  if crates.is_empty():
   g.objects.append({"kind":"weapon_crate","id":"crate_"+w,"weapon":w,"pos":Vector2(9.5+WEAPONS.find(w)*4,17.5)*48,"solid":true})
   crates=g.objects.filter(func(o):return o.kind=="weapon_crate" and o.weapon==w)
  var crate:Dictionary=crates[0]
  if not unlocked(w):
   # Migrate older saves with an early weapon back into its locked crate.
   g.save_data.weapon_crates_opened.erase(w);g.save_data.weapons_taken.erase(w)
   g.save_data.loose_weapons=g.save_data.loose_weapons.filter(func(d):return not (int(d.get("room",4))==4 and d.weapon==w))
   g.objects.assign(g.objects.filter(func(o):return not (o.kind=="weapon_"+w)))
   if g.held_item==w:g.held_item="";g.weapon="";g.sync_hands()
   continue
  var existing:bool=g.held_item==w or g.save_data.loose_weapons.any(func(d):return d.weapon==w)
  var checkpoint:Dictionary=g.save_data.arena_checkpoint
  if int(checkpoint.get("seed",-1))==int(g.save_data.seed) and checkpoint.get("held_item","")==w:existing=true
  if existing and w not in g.save_data.weapon_crates_opened:g.save_data.weapon_crates_opened.append(w)
  if w in g.save_data.weapon_crates_opened:continue
  g.save_data.weapon_crates_opened.append(w);crate.opened_at=g.time if animate else g.time-1
  var target:=landing_point(crate.pos)
  var id:String="drop_crate_"+w
  var drop:={"kind":"weapon_"+w,"id":id,"weapon":w,"room":4,"pos":target,"solid":false}
  if animate:drop.flight_from=crate.pos+Vector2(0,6);drop.flight_start=g.time+.28;drop.flight_duration=.5;g.sfx_at("chest",crate.pos)
  g.objects.append(drop)
  g.save_data.loose_weapons.append({"kind":"weapon_"+w,"id":id,"weapon":w,"room":4,"pos":[target.x,target.y],"solid":false})
func landing_point(origin:Vector2)->Vector2:
 var start:=randf()*TAU
 for n in range(32):
  var point:=origin+Vector2.from_angle(start+n*2.39996)*randf_range(45,70)
  if g.valid_ground(point) and not g.blocked(point) and g.objects.all(func(o):return o.kind=="weapon_crate" or o.pos.distance_to(point)>38):return point
 return g.accessory_drop_position(origin+Vector2(0,56))
func draw(crate:Dictionary,point:Vector2)->void:
 var opened:bool=crate.weapon in g.save_data.weapon_crates_opened
 var age:float=g.time-float(crate.get("opened_at",g.time-1))
 var frame:=0 if not opened else mini(7,int(smoothstep(0,.65,age)*8))
 g.draw_texture_rect_region(ART,Rect2(point-Vector2(32,86),Vector2(64,96)),Rect2(frame*32,0,32,48))
func draw_fist()->void:
 if g.level!=4 or not g.weapon.is_empty() or g.attack_flash<=0 or g.combat_done:return
 var t:=clampf(1-g.attack_flash/.22,0,1)
 var angle:float=g.aim.angle()-1.0+t*1.8
 var origin:Vector2=g.screen(g.player)+Vector2(0,-20)
 g.draw_arc(origin,48,angle-.65,angle+.65,16,Color(.96,.88,.78,g.attack_flash/.22),4)
 g.draw_arc(origin,54,angle-.45,angle+.45,14,Color(.83,.71,.75,g.attack_flash/.22),2)
