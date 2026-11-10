extends RefCounted
var g:Node2D
func _init(game:Node2D):g=game
func enemy(kind:int,pos:Vector2,hp:int,boss:bool=false)->void:
 g.enemies.append({"pos":pos,"hp":hp,"max_hp":hp,"boss":boss,"type":kind,"state":"spawn","timer":1.3+g.enemies.size()*.08,"target":g.player,"cooldown":randf_range(.5,1.2),"slime_cd":3.0})
func spawn()->void:
 var count:int=1 if g.wave==10 else 3+g.wave
 for i in range(count):
  var angle:float=TAU*i/count
  var pos:=Vector2(13.5,14.5)*48+Vector2(cos(angle)*390,sin(angle)*235)
  enemy(2 if g.wave==10 else i%mini(g.wave+1,5),pos,1000 if g.wave==10 else 7+g.wave*3+(i%3)*3,g.wave==10)
 var pistols:int=4 if g.wave==10 else 2+g.wave/3
 var rifles:int=4 if g.wave==10 else 1+maxi(0,(g.wave-2)/3)
 for i in range(pistols+rifles+(1 if g.wave==10 else 0)):
  var kind:=5 if i<pistols else 6 if i<pistols+rifles else 7
  var angle:float=TAU*i/(pistols+rifles+(1 if g.wave==10 else 0))+.3
  var pos:=Vector2(13.5,14.5)*48+Vector2(cos(angle)*350,sin(angle)*250)
  enemy(kind,g.accessory_drop_position(pos),12+g.wave*3)
 if g.wave in [3,6,9]:spawn_medkit()
 else:g.notify(g.tx("boss_announcement") if g.wave==10 else g.tx("wave_announcement")%g.wave)
func gunner(e:Dictionary,delta:float)->void:
 if e.state=="spawn":
  if e.timer<=0:e.state="chase"
  return
 # All shooters fire directly; no targeting beam or stationary aim phase.
 e.state="chase"
 var toward:Vector2=g.player-e.pos
 var firing_range:=620.0 if e.type==7 else 435.0
 if toward.length()<firing_range and e.cooldown<=0:
  var rocket:bool=e.type==7
  var direction:=toward.normalized()
  if not rocket:direction=direction.rotated(randf_range(-.095,.095) if e.type==5 else randf_range(-.045,.045))
  g.shots.append({"pos":e.pos+Vector2(0,-24)+direction*28,"vel":direction*(270 if rocket else 410 if e.type==6 else 340),"life":3.0,"kind":"enemy_rocket" if rocket else "enemy_bullet","age":0.0,"range_left":600.0 if rocket else 420.0})
  e.fired_at=g.time;e.cooldown=randf_range(4.5,6.7) if rocket else randf_range(.18,.48) if e.type==6 else randf_range(.5,1.15);e.target=g.player
  g.sfx_at("rpg_launch" if rocket else "rifle" if e.type==6 else "pistol",e.pos)
 var preferred:=470.0 if e.type==7 else 320.0
 var motion:=toward.normalized()*(65 if toward.length()>preferred else -55 if toward.length()<180 else 0)*delta
 if not g.blocked(e.pos+motion):e.pos+=motion
func boss(e:Dictionary,delta:float)->void:
 e.slime_cd=float(e.get("slime_cd",3.0))-delta
 if e.slime_cd>0 or e.state=="spawn":return
 e.slime_cd=3.8
 var target:Vector2=g.player+g.walk_facing*randf_range(12,50)
 if g.blocked(target):target=g.player
 g.poison_zones.append({"pos":target,"origin":e.pos+Vector2(0,-65),"age":0.0,"life":7.0,"radius":90.0,"tick":0.0})
 g.sfx_at("attack",e.pos)
func update_poison(delta:float)->void:
 for i in range(g.poison_zones.size()-1,-1,-1):
  var zone:Dictionary=g.poison_zones[i];zone.age+=delta;zone.life-=delta;zone.tick-=delta
  if zone.age>.8 and zone.tick<=0 and ((g.player-Vector2(zone.pos))/Vector2(90,42)).length()<1:
   g.hurt();zone.tick=.65
  if zone.life<=0:g.poison_zones.remove_at(i)
func draw_poison()->void:
 for zone in g.poison_zones:
  var p:Vector2=g.screen(zone.pos)
  if zone.age<.8:
   g.draw_set_transform(p,0,Vector2(1,42.0/90.0));g.draw_arc(Vector2.ZERO,zone.radius,0,TAU,28,Color(.62,.85,.34,.5),2);g.draw_set_transform(Vector2.ZERO)
   var t:float=zone.age/.8
   var blob:Vector2=g.screen(Vector2(zone.origin).lerp(zone.pos,t))+Vector2(0,-sin(t*PI)*110)
   g.draw_sprite("poison_glob",blob,Color.WHITE,.7+sin(t*PI)*.3)
  else:
   var alpha:float=minf(1,zone.life/.8)
   g.draw_sprite("poison_pool",p,Color(1,1,1,alpha),3.2)
   for n in range(5):
    var phase:float=fposmod(g.time*.7+n*.21,1)
    var bp:Vector2=p+Vector2(sin(n*4.1)*45,cos(n*5.7)*25-phase*12)
    g.draw_arc(bp,2+phase*3,0,TAU,8,Color(.7,.9,.35,(1-phase)*alpha),1)
func draw_gun(e:Dictionary,p:Vector2)->void:
 var direction:Vector2=(g.player-e.pos).normalized();var origin:=p+Vector2(0,-19 if e.type==5 else -24)
 var recoil:float=maxf(0,1-(g.time-float(e.get("fired_at",-10)))/.12)
 origin-=direction*recoil*(6 if e.type==7 else 3)
 g.draw_set_transform(origin,direction.angle(),Vector2(1,-1 if direction.x<0 else 1))
 if e.type==7:g.draw_texture_rect(g.rpg_textures["loaded" if e.cooldown<.4 else "empty"],Rect2(Vector2(-30,-12),Vector2(64,32)),false)
 else:g.draw_sprite("enemy_pistol" if e.type==5 else "weapon_rifle",Vector2(0,18),Color.WHITE,.45 if e.type==5 else .65)
 g.draw_set_transform(Vector2.ZERO)
 if recoil>0:g.draw_texture_rect(g.glow,Rect2(origin+direction*28-Vector2(14,14),Vector2(28,28)),false,Color(1,.8,.4,recoil))

func spawn_medkit()->void:
 var id:="wave"+str(g.wave)+"_medkit"
 if g.objects.any(func(o):return o.id==id):return
 var origin:=Vector2(13.5,21.0)*48
 var point:Vector2=g.accessory_drop_position(origin)
 for offset in [Vector2.ZERO,Vector2(-144,0),Vector2(144,0),Vector2(-288,0),Vector2(288,0),Vector2(0,-96),Vector2(-144,-96),Vector2(144,-96)]:
  var candidate:Vector2=origin+offset;var bounds:=Rect2(candidate-Vector2(30,44),Vector2(60,52))
  if not g.valid_ground(candidate) or g.blocked(candidate):continue
  if g.objects.any(func(o):return o.kind not in ["doorway","arch","pet_cat"] and g.item_visual_bounds(o).grow(12).intersects(bounds)):continue
  point=candidate;break
 g.objects.append({"kind":"medkit","id":id,"pos":point,"solid":false})
 g.notify(g.tx("medkit_spawned").format({"wave":g.wave}))
func draw_bullet(shot:Dictionary,p:Vector2)->void:
 var tail:Vector2=p-Vector2(shot.vel).normalized()*24
 g.draw_line(p,tail,Color("1b1727"),8)
 g.draw_line(p,tail,Color("ff995d"),4)
 g.draw_circle(p,4,Color("fff1bd"))
