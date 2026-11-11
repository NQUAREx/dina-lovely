extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame
 g.set_process(false);g.set_physics_process(false);g.sound_on=false;g.clear_modal();g.save_data=g.default_save();g.ensure_riddle();g.build_level(4);g.playing=true;g.hud.show();g.health=4;g.wave=1
 g.battle.spawn(false,false);g.update_hud();assert(g.enemy_wave_bar.visible and g.enemy_count_progress.max_value==8 and g.enemy_count_progress.value==8)
 g.enemies.pop_back();g.enemies.pop_back();g.update_hud();assert(g.enemy_count_progress.value==6 and "6" in g.enemy_count_label.text)
 g.enemies.clear();g.update_hud();assert(not g.enemy_wave_bar.visible)
 var total_medkits=0
 for wave in range(1,8):
  g.wave=wave;g.enemies.clear();g.battle.spawn(true,false)
  var medkits=g.objects.filter(func(o):return o.kind=="medkit")
  assert(medkits.size()==(0 if wave<4 else 1));total_medkits=maxi(total_medkits,medkits.size())
 assert(total_medkits==1)
 var medkit=g.objects.filter(func(o):return o.kind=="medkit")[0];g.player=medkit.pos+Vector2(0,50);g.nearest=g.objects.find(medkit);g.interact()
 assert(g.health==8 and g.save_data.arena_medkit_claimed and not g.objects.any(func(o):return o.kind=="medkit"))
 g.battle.spawn_medkit();assert(not g.objects.any(func(o):return o.kind=="medkit"))
 g.save_data.arena_medkit_claimed=false;g.wave=4
 for n in range(2):g.objects.append({"kind":"medkit","id":"old_medkit"+str(n),"pos":Vector2(500+n*100,900),"solid":false})
 g.battle.restore_medkit_limit(true);assert(g.objects.filter(func(o):return o.kind=="medkit").size()==1)
 g.objects.assign(g.objects.filter(func(o):return o.kind!="medkit"));g.battle.restore_medkit_limit(true);assert(g.save_data.arena_medkit_claimed)
 g.arena_save.reset_saved();assert(not g.save_data.arena_medkit_claimed)
 g.wave=4;g.combat_done=false;g.update_hud();assert(g.enemy_wave_bar.visible and g.toast.position.y==198)
 g.level=5;g.update_hud();assert(not g.enemy_wave_bar.visible and g.toast.position.y==146)
 g.rocket_voice.volume_db=-10;g.rocket_audio.event("rpg_launch",g.player);assert(g.rocket_audio.duck_left>=.35 and g.rocket_voice.volume_db<=-58)
 g.rocket_audio.event("rpg_explosion",g.player);assert(g.rocket_audio.duck_left>=1.2 and g.rocket_audio.launch_voices.size()==4 and g.rocket_audio.impact_voices.size()==4)
 g.rocket_audio.update(.1);assert(g.rocket_audio.duck_left>1 and not g.rocket_voice.playing)
 print("PASS enemy counts/visibility, one fourth-wave medkit, claim/retry/legacy migration, HUD spacing and immediate rocket flight ducking")
 g.queue_free();await process_frame;quit()
