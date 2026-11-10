extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame
 g.new_game();g.clear_modal();g.sound_on=false;g.set_process(false);g.set_physics_process(false)
 assert(not g.content.ui.has("intro_darkness") and g.content.ui.has("start_intro"))
 g.build_level(1);g.held_item="";g.sync_hands();g.update_fog();assert(not g.fog.material.get_shader_parameter("enabled"))
 var light=g.objects.filter(func(o):return o.id=="flashlight")[0];assert(light.pos.y>(g.grid.size()-5)*48 and light.pos.y<g.grid.size()*48)
 g.build_level(4);g.wave=0
 for wave in range(1,11):
  g.enemies.clear();g.spawn_wave()
  assert(g.enemies.filter(func(e):return e.type==5).size()==(4 if wave==10 else 2+wave/3))
  if wave==10:assert(g.enemies.filter(func(e):return e.get("boss",false))[0].hp==1000)
 var gunner=g.enemies.filter(func(e):return e.type==5)[0]
 g.enemies.assign([gunner]);gunner.state="chase";gunner.cooldown=0;g.player=gunner.pos+Vector2(100,200);g.combat_done=false
 g.shots.clear();g.update_combat(.01);assert(gunner.state=="chase")
 assert(g.shots.filter(func(s):return s.kind=="enemy_bullet").size()==1)
 g.shots.clear();g.shots.append({"pos":g.player+Vector2(-120,-26),"vel":Vector2(600,0),"age":0.0,"life":3.0,"kind":"enemy_bullet"});g.health=8;g.invincible=0;g.update_shots(.4);assert(g.health==7 and g.shots.is_empty())
 g.save_data.finished=true;g.save_data.letters.append("courage");g.build_level(5);g.held_item="rifle";g.weapon="rifle";g.attack_cd=0;g.reload_time=0;g.magazine=30;g.walk_facing=Vector2.RIGHT;g.player=Vector2(650,650)
 g.objects.assign(g.objects.filter(func(o):return not o.solid))
 g.shake=0;var before=g.player;g.attack();assert(g.shots.size()==1 and absf(g.player.distance_to(before)-4.6)<.001 and is_equal_approx(g.rifle_kick,4.025) and is_equal_approx(g.shake,3.68))
 assert(absf(g.shots[0].vel.angle())<=.0361 and g.magazine==29)
 g.cache_current_room();var shift=Vector2(13.5*48,-2)-g.player;g.player+=shift
 for s in g.shots:s.pos+=shift
 g.camera=g.player;g.save_data.open_gates.append(5);g.travel(6);assert(g.held_item=="rifle" and g.weapon=="rifle" and g.magazine==29 and g.shots.size()==1)
 g.return_held_tool();var drops=g.objects.filter(func(o):return o.id.begins_with("drop_"));assert(drops.size()==1)
 g.build_level(6);assert(g.objects.filter(func(o):return o.id==drops[0].id).size()==1)
 g.build_level(4);assert(not g.objects.any(func(o):return o.id==drops[0].id))
 g.weapon="rpg";g.held_item="rpg";g.rpg_reload=0;g.attack_cd=0;g.reload_time=0;g.walk_facing=Vector2.RIGHT;g.shots.clear();g.attack();assert(is_equal_approx(g.rpg_windup,.20));g.attack(true);assert(g.shots.size()==1 and g.shots[0].kind=="rpg")
 assert(g.rpg_textures.loaded.get_width()==64 and g.rpg_textures.empty.get_width()==64)
 g.build_level(3);g.held_item="shovel";g.save_data.dig_target=[750,600];g.save_data.buried_exposed=false;g.world_tools.excavate(Vector2(540,600));assert(g.toast.text==g.tx("buried_note_near"))
 var bank=load("res://scripts/audio_bank.gd").STREAMS;assert(bank.gate_open.get_length()>.8 and g.rocket_voice.stream.get_length()>.25)
 print("PASS one intro, corridor torch, ten-wave gunners, swept enemy damage, stronger AK/camera, post-game carry/fire/drop, RPG textures/audio and dig hint")
 quit()
