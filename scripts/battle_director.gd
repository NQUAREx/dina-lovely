extends RefCounted
const BALANCE_VERSION := 5
const WAVE_COUNT := 7
const MEDKIT_WAVE := 4
const BULLET_RANGE := 196.0
const ROCKET_RANGE := 280.0
const WAVES := [
 [0,0,1,1,2,2,4,4],
 [0,1,1,2,2,2,3,4,4,4],
 [0,1,1,2,2,2,3,3,4,4,4,4],
 [0,1,2,2,3,3,4,4,4,4,4,4,5,5],
 [0,1,2,2,3,3,3,4,4,4,4,4,5,5,6,6],
 [0,1,2,2,3,3,3,4,4,4,4,4,5,5,5,6,6,7],
 [-1,5,5,6,6,7,7]]

const GUNS := {
 5:{"clip":3,"interval":Vector2(1.05,1.4),"reload":Vector2(2.5,3.1),"range":168.0,"travel":175.0,"speed":275.0,"damage":1.0,"keep":140.0,"move":30.0,"aggro":285.0,"minimum":85.0},
 6:{"clip":4,"interval":Vector2(.36,.5),"reload":Vector2(3.1,3.8),"range":189.0,"travel":196.0,"speed":330.0,"damage":1.5,"keep":160.0,"move":28.0,"aggro":315.0,"minimum":100.0},
 7:{"clip":1,"interval":Vector2(1.0,1.3),"reload":Vector2(5.0,6.0),"range":280.0,"travel":280.0,"speed":235.0,"damage":2.0,"keep":235.0,"move":24.0,"aggro":440.0,"minimum":170.0}}
var g:Node2D
func _init(game:Node2D):g=game
func enemy(kind:int,pos:Vector2,hp:int,boss:bool=false)->void:
 var serial:int=g.enemies.size()+1
 g.enemies.append({"pos":pos,"home":pos,"hp":hp,"max_hp":hp,"boss":boss,"type":kind,"serial":serial,"state":"spawn","timer":1.3+serial*.15,"target":g.player,"cooldown":randf_range(.8,1.5),"slime_cd":4.5,"aggro":false,"alert":0.0,"sense":0.0,"wander":0.0,"patrol":pos,"reload_left":0.0,"reload_duration":1.0,"ammo":int(GUNS[kind].clip) if GUNS.has(kind) else 0})
func spawn(medkits:bool=true,announce:bool=true)->void:
 var plan:Array=WAVES[clampi(g.wave-1,0,WAVE_COUNT-1)]
 var points:Array[Vector2]=[]
 for y in range(7,g.grid.size()-5):
  for x in range(3,g.grid[0].length()-3):
   var point:=Vector2(x+.5,y+.5)*48+Vector2(randf_range(-9,9),randf_range(-9,9))
   if point.distance_to(g.player)<190 or not spawn_clear(point):continue
   points.append(point)
 points.shuffle()
 for kind in plan:
  var chosen:Vector2=Vector2.ZERO;var best:=-1.0
  for point in points:
   var gap:=INF
   for existing in g.enemies:gap=minf(gap,point.distance_to(existing.pos))
   if gap>best:best=gap;chosen=point
   if gap>=88:break
  if best<0:push_error("No valid arena spawn point");return
  points.erase(chosen)
  enemy(2 if kind<0 else kind,chosen,roundi(base_hp(kind)),kind<0)
 if medkits and g.wave==MEDKIT_WAVE:spawn_medkit()
 elif announce:g.notify(g.tx("boss_announcement") if g.wave==WAVE_COUNT else g.tx("wave_announcement")%g.wave)
func base_hp(kind:int)->float:
 return 1100.0 if kind<0 else 32+g.wave*4+(kind-5)*4 if kind>=5 else 26+g.wave*4 if kind==4 else 16+g.wave*3+kind*2
func spawn_clear(point:Vector2)->bool:
 if g.blocked(point):return false
 for n in range(8):
  if g.blocked(point+Vector2.from_angle(n*TAU/8)*38):return false
 return true
func ensure(e:Dictionary)->void:
 if int(e.get("brain_version",0))==BALANCE_VERSION:return
 var defaults={"home":e.pos,"serial":maxi(1,g.enemies.find(e)+1),"aggro":false,"alert":0.0,"sense":0.0,"wander":0.0,"patrol":e.pos,"reload_left":0.0,"reload_duration":1.0,"ammo":int(GUNS[int(e.type)].clip) if GUNS.has(int(e.type)) else 0}
 for key in defaults:
  if not e.has(key):e[key]=defaults[key]
 e.brain_version=BALANCE_VERSION
func sight(a:Vector2,b:Vector2)->bool:
 var count:=maxi(1,ceili(a.distance_to(b)/18))
 for i in range(1,count):
  if g.blocked(a.lerp(b,float(i)/count)):return false
 return true
func brain(e:Dictionary,delta:float)->bool:
 ensure(e)
 if e.state=="spawn":return false
 e.alert=maxf(0,float(e.alert)-delta);e.sense-=delta
 if e.sense<=0:
  e.sense=.18+fmod(float(e.serial),4)*.02
  var radius:float=360 if e.get("boss",false) else GUNS[int(e.type)].aggro if GUNS.has(int(e.type)) else 270 if e.type==3 else 245
  radius*=1.05 if GUNS.has(int(e.type)) else 1.5
  var distance:float=e.pos.distance_to(g.player)
  if e.pos.distance_to(e.home)>540 and not e.get("boss",false):e.aggro=false;e.alert=0.0
  elif distance<=radius and sight(e.pos,g.player):e.aggro=true
  elif distance>radius+110 and e.alert<=0:e.aggro=false
 return bool(e.aggro) or e.alert>0
func move(e:Dictionary,velocity:Vector2,delta:float)->void:
 if velocity.length_squared()<.01:return
 var motion:=velocity*delta
 for candidate in [e.pos+motion,e.pos+Vector2(motion.x,0),e.pos+Vector2(0,motion.y),e.pos+motion.rotated(.7),e.pos+motion.rotated(-.7)]:
  if candidate.distance_squared_to(e.pos)<.00001:continue
  if not g.blocked(candidate):e.pos=candidate;return
func patrol(e:Dictionary,delta:float)->void:
 e.state="patrol";e.wander-=delta
 if e.pos.distance_to(e.home)>105:e.patrol=e.home
 elif e.wander<=0 or e.pos.distance_to(e.patrol)<8:
  e.wander=randf_range(2,4);var angle:=randf()*TAU
  var point:Vector2=e.home+Vector2.from_angle(angle)*randf_range(28,80)
  e.patrol=point if not g.blocked(point) else e.home
 move(e,(Vector2(e.patrol)-Vector2(e.pos)).normalized()*(18 if e.type>=5 else 26),delta)
func tick(delta:float)->void:
 for e in g.enemies:
  ensure(e);e.timer-=delta;e.cooldown=maxf(0,float(e.cooldown)-delta)
  if e.state=="spawn":
   if e.timer<=0:e.state="patrol"
   continue
  if e.type in [5,6,7]:gunner(e,delta)
  else:melee(e,delta)
 separate()
func melee(e:Dictionary,delta:float)->void:
 if not brain(e,delta):patrol(e,delta);return
 if e.get("boss",false):boss(e,delta)
 var distance:float=e.pos.distance_to(g.player)
 if e.state=="warn":
  if e.timer<=0:
   if distance<(125 if e.get("boss",false) else 70):g.hurt(1.5 if e.get("boss",false) else 1.0)
   g.burst(e.pos,5,Color("bc96c7"));e.state="rest";e.timer=1.15 if e.type==3 or e.get("boss",false) else .85
  return
 if e.state=="rest" and e.timer>0:return
 if distance<(110 if e.get("boss",false) else 67):
  e.state="warn";e.timer=1.05 if e.get("boss",false) else .8 if e.type==3 else .9;return
 e.state="chase"
 var direction:Vector2=(Vector2(e.home)-g.player).normalized().rotated(sin(float(e.serial)*2.3)*.25)
 var goal:Vector2=g.player+direction*(95 if e.get("boss",false) else 58)
 var speed:float=55 if e.get("boss",false) else 55+int(e.type)*6+min(g.wave,9)*2
 if e.type==3:speed=185.0 if fposmod(g.time+float(e.serial)*.41,2.2)<.7 else 70.0
 if e.type==4:speed=58
 move(e,(goal-Vector2(e.pos)).normalized()*speed*1.25,delta)
func gunner(e:Dictionary,delta:float)->void:
 ensure(e)
 if e.state=="spawn":return
 var active:=brain(e,delta);var profile:Dictionary=GUNS[int(e.type)]
 e.reload_left=maxf(0,float(e.reload_left)-delta)
 if e.reload_left==0 and int(e.ammo)<=0:e.ammo=int(profile.clip)
 if not active:patrol(e,delta);return
 e.state="chase"
 var toward:Vector2=g.player-e.pos;var distance:=toward.length()
 if e.reload_left<=0 and e.cooldown<=0 and distance>=profile.minimum and distance<profile.range and sight(e.pos,g.player):
  var rocket:bool=e.type==7;var direction:=toward.normalized()
  if not rocket:direction=direction.rotated(randf_range(-.085,.085) if e.type==5 else randf_range(-.04,.04))
  g.shots.append({"pos":e.pos+Vector2(0,-24)+direction*28,"vel":direction*float(profile.speed),"life":3.0,"kind":"enemy_rocket" if rocket else "enemy_bullet","age":0.0,"range_left":profile.travel,"max_range":profile.travel,"shooter_type":int(e.type),"damage":profile.damage})
  e.fired_at=g.time;e.cooldown=randf_range(profile.interval.x,profile.interval.y);e.target=g.player;e.ammo-=1
  g.sfx_at("rpg_launch" if rocket else "rifle" if e.type==6 else "pistol",e.pos)
  if e.ammo<=0:
   e.reload_duration=randf_range(profile.reload.x,profile.reload.y);e.reload_left=e.reload_duration;g.sfx_at("reload",e.pos)
 var velocity:=Vector2.ZERO
 if distance<float(profile.keep)-30:velocity=-toward.normalized()*float(profile.move)
 elif distance>float(profile.keep)+35:velocity=toward.normalized()*float(profile.move)
 elif e.reload_left>0:velocity=toward.orthogonal().normalized()*sin(float(e.serial)*2.4)*12
 move(e,velocity*1.3,delta)
func radius(e:Dictionary)->float:
 return 37 if e.get("boss",false) else 14 if e.type==5 else 20
func separate()->void:
 for pass_index in range(2):
  for i in range(g.enemies.size()):
   var a:Dictionary=g.enemies[i]
   for j in range(i+1,g.enemies.size()):
    var b:Dictionary=g.enemies[j];var away:Vector2=a.pos-b.pos;var distance:=away.length();var wanted:=radius(a)+radius(b)+8
    if distance>=wanted:continue
    var normal:=away/distance if distance>.01 else Vector2.from_angle((i*7+j*3)*.7)
    var correction:=normal*minf(12,(wanted-distance)*.52)
    if not g.blocked(a.pos+correction):a.pos+=correction
    if not g.blocked(b.pos-correction):b.pos-=correction
   var away:Vector2=a.pos-g.player;var distance:=away.length();var wanted:=26+radius(a)*.4
   if distance<wanted:
    var point:Vector2=g.player+(away.normalized() if distance>.01 else Vector2.from_angle(i*2.4))*wanted
    if not g.blocked(point):a.pos=point
func boss(e:Dictionary,delta:float)->void:
 e.slime_cd=float(e.get("slime_cd",4.5))-delta
 if e.slime_cd>0:return
 e.slime_cd=5.5
 var target:Vector2=g.player+g.walk_facing*randf_range(12,35)
 if g.blocked(target):target=g.player
 g.poison_zones.append({"pos":target,"origin":e.pos+Vector2(0,-65),"age":0.0,"life":5.5,"radius":64.0,"tick":0.0})
 g.sfx_at("attack",e.pos)
func update_poison(delta:float)->void:
 for i in range(g.poison_zones.size()-1,-1,-1):
  var zone:Dictionary=g.poison_zones[i];zone.age+=delta;zone.life-=delta;zone.tick-=delta
  if zone.age>.8 and zone.tick<=0 and ((g.player-Vector2(zone.pos))/Vector2(64,30)).length()<1:
   g.hurt(.5);zone.tick=1.0
  if zone.life<=0:g.poison_zones.remove_at(i)
func draw_poison()->void:
 for zone in g.poison_zones:
  var p:Vector2=g.screen(zone.pos)
  if zone.age<.8:
   g.draw_set_transform(p,0,Vector2(1,30.0/64.0));g.draw_arc(Vector2.ZERO,zone.radius,0,TAU,28,Color(.62,.85,.34,.5),2);g.draw_set_transform(Vector2.ZERO)
   var t:float=zone.age/.8
   var blob:Vector2=g.screen(Vector2(zone.origin).lerp(zone.pos,t))+Vector2(0,-sin(t*PI)*110)
   g.draw_sprite("poison_glob",blob,Color.WHITE,.7+sin(t*PI)*.3)
  else:
   var alpha:float=minf(1,zone.life/.8)
   g.draw_sprite("poison_pool",p,Color(1,1,1,alpha),2.3)
   for n in range(5):
    var phase:float=fposmod(g.time*.7+n*.21,1)
    var bp:Vector2=p+Vector2(sin(n*4.1)*31,cos(n*5.7)*17-phase*12)
    g.draw_arc(bp,2+phase*3,0,TAU,8,Color(.7,.9,.35,(1-phase)*alpha),1)
func draw_gun(e:Dictionary,p:Vector2)->void:
 var direction:Vector2=(g.player-e.pos).normalized();var origin:=p+Vector2(0,-19 if e.type==5 else -24)
 var recoil:float=maxf(0,1-(g.time-float(e.get("fired_at",-10)))/.12)
 origin-=direction*recoil*(6 if e.type==7 else 3)
 g.draw_set_transform(origin,direction.angle(),Vector2(1,-1 if direction.x<0 else 1))
 if e.type==7:g.draw_texture_rect(g.rpg_textures["loaded" if e.get("reload_left",0)<=0 else "empty"],Rect2(Vector2(-30,-12),Vector2(64,32)),false)
 else:g.draw_sprite("enemy_pistol" if e.type==5 else "weapon_rifle",Vector2(0,18),Color.WHITE,.45 if e.type==5 else .65)
 g.draw_set_transform(Vector2.ZERO)

 if recoil>0:g.draw_texture_rect(g.glow,Rect2(origin+direction*28-Vector2(14,14),Vector2(28,28)),false,Color(1,.8,.4,recoil))

func spawn_medkit()->void:
 var id:="arena_medkit"
 if g.save_data.arena_medkit_claimed or g.objects.any(func(o):return o.kind=="medkit"):return
 var origin:=Vector2(13.5,21.0)*48
 var point:Vector2=g.accessory_drop_position(origin)
 for offset in [Vector2.ZERO,Vector2(-144,0),Vector2(144,0),Vector2(-288,0),Vector2(288,0),Vector2(0,-96),Vector2(-144,-96),Vector2(144,-96)]:
  var candidate:Vector2=origin+offset;var bounds:=Rect2(candidate-Vector2(30,44),Vector2(60,52))
  if not g.valid_ground(candidate) or g.blocked(candidate):continue
  if g.objects.any(func(o):return o.kind not in ["doorway","arch","pet_cat"] and g.item_visual_bounds(o).grow(12).intersects(bounds)):continue
  point=candidate;break
 g.objects.append({"kind":"medkit","id":id,"pos":point,"solid":false})
 g.notify(g.tx("medkit_spawned").format({"wave":g.wave}))
func bullet_length(shot:Dictionary)->float:
 return 5.0 if int(shot.get("shooter_type",6))==5 else 10.0
func draw_bullet(shot:Dictionary,p:Vector2)->void:
 # The player and enemy AK use this exact same tracer, colour and width.
 g.draw_line(p,p-Vector2(shot.vel).normalized()*bullet_length(shot),Color("ffe3a7"),3)
func normalize_projectile(shot:Dictionary)->void:
 var cap:float=ROCKET_RANGE if shot.kind=="enemy_rocket" else float(GUNS[int(shot.get("shooter_type",6))].travel) if GUNS.has(int(shot.get("shooter_type",6))) else BULLET_RANGE
 if not shot.has("max_range"):
  # Upgrade saved bullets from the previous 420/600px range, including tiny residues.
  var previous:=600.0 if shot.kind=="enemy_rocket" else 420.0
  var travelled:=maxf(0,previous-float(shot.range_left)) if shot.has("range_left") else Vector2(shot.vel).length()*float(shot.get("age",0))
  shot.max_range=cap;shot.range_left=maxf(0,cap-travelled)
 elif float(shot.max_range)>cap:
  var travelled:=maxf(0,float(shot.max_range)-float(shot.range_left))
  shot.max_range=cap;shot.range_left=maxf(0,cap-travelled)

func restore_medkit_limit(legacy:bool)->void:
 var medkits:Array=g.objects.filter(func(obj):return obj.kind=="medkit")
 if legacy and g.wave>=3 and medkits.is_empty():g.save_data.arena_medkit_claimed=true
 if g.save_data.arena_medkit_claimed:
  g.objects.assign(g.objects.filter(func(obj):return obj.kind!="medkit"))
 elif not medkits.is_empty():
  var keep:Dictionary=medkits[0]
  keep.id="arena_medkit"
  g.objects.assign(g.objects.filter(func(obj):return obj.kind!="medkit" or obj==keep))
