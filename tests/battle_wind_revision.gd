extends SceneTree
func _initialize():call_deferred("run")
func run():
 var f=load("res://scripts/hedge_field.gd").new();var map:Array[String]=["#####","#####","#####","#####","#####"]
 f.build(map,71,{},{});f.wind_clock=100;var leaf=f.crowns[f.crowns.size()/2];var base:Vector2=leaf.base
 # A lower approach may release the visual crown; moving upward must immediately re-engage it.
 f.update(.016,base+Vector2(20,25));f.update(.016,base+Vector2(20,0));assert(not leaf.released and leaf.press>0 and f.crown_in_contact(f.crowns.find(leaf),base+Vector2(20,0)))
 var tail:=0.0
 for i in range(1080):
  f.update(1.0/60,Vector2(-1000,-1000))
  if i>60 and i<120:tail=maxf(tail,absf(leaf.sway))
 assert(tail>.2 and leaf.sway==0)
 f.wind_clock=.001;f.update(.016,base);assert(f.wind_clock>=4 and not f.active.is_empty())
 var clock:float=f.wind_clock;f.update(.016,base);assert(f.wind_clock<clock)
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame
 g.new_game();g.clear_modal();g.sound_on=false;g.set_process(false);g.set_physics_process(false);g.build_level(4);g.wave=0;g.health=8
 for wave in range(1,11):
  g.enemies.clear();g.spawn_wave();assert(g.wave==wave)
  var shooters=g.enemies.filter(func(e):return e.type in [5,6,7]);assert(shooters.size()>=1)
  for shooter in shooters:
   shooter.state="chase";shooter.cooldown=0;g.player=shooter.pos+Vector2(100,100);var count=g.shots.size();g.update_gunner(shooter,.016);assert(g.shots.size()==count+1 and shooter.state=="chase" and g.shots.back().vel.length()>=270)
  if wave==10:
   assert(shooters.filter(func(e):return e.type==5).size()==4 and shooters.filter(func(e):return e.type==6).size()==4 and shooters.filter(func(e):return e.type==7).size()==1)
   var boss=g.enemies.filter(func(e):return e.boss)[0];assert(boss.hp>100);boss.state="chase";boss.slime_cd=0;g.battle.boss(boss,.016);assert(g.poison_zones.size()==1)
   g.player=g.poison_zones[0].pos;g.invincible=0;g.battle.update_poison(1);assert(g.health==7)
 g.enemies.clear();g.wave_timer=0;g.update_combat(.016);assert(g.combat_done and g.poison_zones.is_empty())
 g.build_level(0);g.held_item="rifle";g.weapon="rifle";g.save_data.finished=true;g.player=Vector2(15.5,10.5)*48;g.aim=Vector2.UP;g.attack_cd=0;g.reload_time=0;g.magazine=30;g.attack();assert(is_equal_approx(g.rifle_kick,4.025) and g.shake>=3.68)
 print("PASS upward hedge contact, doubled inertia, wind interval, ten waves, instant shooters, final lineup, poison damage and rifle recoil")
 quit()
