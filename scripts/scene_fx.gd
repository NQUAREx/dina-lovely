extends RefCounted
## Textured pixel particles. All states live in the room's existing particle array.
const BITS:Texture2D=preload("res://assets/physical_particles.png")
const BLAST:Texture2D=preload("res://assets/rocket_blast.png")
var g:Node2D
func _init(game:Node2D):g=game
func add(kind:String,point:Vector2,velocity:Vector2,life:float,size:float)->Dictionary:
 var p:={"physical_fx":true,"fx_kind":kind,"pos":point,"vel":velocity,"life":life,"duration":life,"age":0.0,"size":size,"angle":randf_range(-PI,PI),"spin":randf_range(-5,5),"phase":randf_range(0,TAU),"height":0.0,"vz":0.0,"drag":randf_range(2.5,5),"variant":0,"color":Color.WHITE,"heart":false}
 g.particles.append(p)
 return p
func soil(point:Vector2,amount:int)->void:
 for n in range(amount):
  if g.particles.size()>=950:break
  var p:=add("dirt",point+Vector2(randf_range(-8,8),randf_range(-4,4)),Vector2.from_angle(randf()*TAU)*randf_range(45,170),randf_range(1.05,1.9),randf_range(.45,1.25))
  p.variant=randi_range(0,5);p.height=randf_range(1,7);p.vz=randf_range(62,135);p.gravity=randf_range(180,290)
  p.drag=randf_range(2.6,5.4);p.landed=false
func plume(point:Vector2,direction:Vector2,smoke:int,fire:int,power:float=1.0)->void:
 for n in range(smoke+fire):
  if g.particles.size()>=950:break
  var hot:=n>=smoke
  var velocity:=direction.rotated(randf_range(-.65,.65))*randf_range(30,140)*power+Vector2(randf_range(-9,9),randf_range(-12,8))
  var p:=add("fire" if hot else "smoke",point+Vector2(randf_range(-4,4),randf_range(-4,4)),velocity,randf_range(.18,.48) if hot else randf_range(.65,1.35),randf_range(.7,1.5) if hot else randf_range(.8,1.7))
  p.variant=randi_range(6,9) if hot else randi_range(10,15);p.drag=randf_range(3,6);p.alpha=randf_range(.5,.85) if hot else randf_range(.27,.5)
func launch(muzzle:Vector2,rear:Vector2,direction:Vector2,player_owned:bool=true)->void:
 plume(rear,-direction,22,14,1.45);plume(muzzle,direction,9,7,.7)
 if player_owned:
  var p:=add("muzzle",muzzle,Vector2.ZERO,.4,1)
  p.clock=0.0;p.direction=direction
func trail(shot:Dictionary,start:Vector2,end:Vector2,delta:float)->void:
 shot.fx_clock=float(shot.get("fx_clock",0))+delta
 var count:=mini(4,int(float(shot.fx_clock)/.035))
 if count<=0:return
 shot.fx_clock=fmod(float(shot.fx_clock),.035)
 var backwards:Vector2=-Vector2(shot.vel).normalized()
 for n in range(count):
  var point:=start.lerp(end,float(n+1)/count)+backwards*14
  plume(point,backwards,3,2,.65)
func explosion(point:Vector2)->void:
 add("blast",point,Vector2.ZERO,.64,randf_range(2.7,3.1))
 for n in range(65):
  if g.particles.size()>=1000:break
  var hot:=n>=30
  var p:=add("spark" if hot else "smoke",point+Vector2(randf_range(-9,9),randf_range(-8,8)),Vector2.from_angle(randf()*TAU)*randf_range(45,215),randf_range(.24,.75) if hot else randf_range(.85,1.65),randf_range(.45,1.1) if hot else randf_range(1.2,2.7))
  p.variant=randi_range(6,9) if hot else randi_range(10,15);p.drag=randf_range(2,5);p.alpha=randf_range(.5,1) if hot else randf_range(.3,.55)
func step(p:Dictionary,delta:float)->void:
 p.age+=delta
 if p.fx_kind=="blast":return
 if p.fx_kind=="muzzle":
  if g.held_item!="rpg":p.life=0;return
  p.pos=g.rpg_muzzle();p.clock-=delta
  if p.clock<=0:
   p.clock=.035;plume(p.pos,p.direction,2,1 if p.age<.12 else 0,.25)
  return
 var count:=clampi(ceili(delta*90),1,12);var dt:=delta/count
 for n in range(count):
  if p.fx_kind=="dirt":
   if p.landed:p.vel*=exp(-dt*12);p.pos+=p.vel*dt;p.spin*=exp(-dt*9);continue
   var wind:=Vector2(sin(p.age*6+p.phase)*8,cos(p.age*4+p.phase)*5)
   p.vel=Vector2(p.vel)*exp(-p.drag*dt)+wind*dt;p.pos+=p.vel*dt
   p.height+=p.vz*dt-float(p.gravity)*dt*dt*.5;p.vz-=p.gravity*dt
   if p.height<=0:p.height=0.0;p.landed=true;p.vel*=.16
  else:
   var drift:=Vector2(sin(p.age*5+p.phase)*10,-15 if p.fx_kind=="smoke" else 20)
   p.vel=Vector2(p.vel)*exp(-p.drag*dt)+drift*dt;p.pos+=p.vel*dt
  p.angle+=p.spin*dt
func draw(ground:bool)->void:
 for p in g.particles:
  if not p.get("physical_fx",false) or (p.fx_kind=="dirt")!=ground or p.fx_kind=="muzzle":continue
  var point:Vector2=g.screen(Vector2(p.pos)-Vector2(0,float(p.height))).round()
  if not g.get_viewport_rect().grow(140).has_point(point):continue
  var ratio:float=clampf(maxf(float(p.age),float(p.duration)-float(p.life))/maxf(.01,float(p.duration)),0,1)
  if p.fx_kind=="blast":
   var frame:=mini(7,int(ratio*8));var size:=Vector2.ONE*48*float(p.size)
   g.draw_texture_rect_region(BLAST,Rect2(point-size/2,size),Rect2(frame*48,0,48,48),Color(1,1,1,1-smoothstep(.7,1,ratio)))
   continue
  var scale:float=p.size
  if p.fx_kind=="smoke":scale*=1+ratio*1.5
  elif p.fx_kind!="dirt":scale*=1-ratio*.55
  var alpha:float=(1-smoothstep(.55,1,ratio))*float(p.get("alpha",1))
  g.draw_set_transform(point,float(p.angle))
  g.draw_texture_rect_region(BITS,Rect2(Vector2(-6,-6)*scale,Vector2(12,12)*scale),Rect2(int(p.variant)*12,0,12,12),Color(1,1,1,alpha))
  g.draw_set_transform(Vector2.ZERO)
func draw_jet(point:Vector2,direction:Vector2,age:float)->void:
 var frame:=6+posmod(int(age*30),4)
 g.draw_set_transform((point-direction*16).round(),direction.angle()-PI/2)
 g.draw_texture_rect_region(BITS,Rect2(Vector2(-8,-29),Vector2(16,39)),Rect2(frame*12,0,12,12))
 g.draw_set_transform(Vector2.ZERO)
