extends SceneTree
func _initialize():call_deferred('run')
func run():
 var g=load('res://main.tscn').instantiate();root.add_child(g);await process_frame
 g.new_game();g.clear_modal();g.set_process(false);g.set_physics_process(false);g.hide();g.activate_cached_room(4)
 var chest:Dictionary=g.objects.filter(func(o):return o.id=='courage')[0]
 assert(g.arena_chest_clear(chest.pos,chest))
 # The old point-only check accepted the edge of a wide weapon crate.
 var crate:Dictionary=g.objects.filter(func(o):return o.kind=='weapon_crate')[0]
 assert(not g.arena_chest_clear(crate.pos+Vector2(60,0),chest))
 chest.pos=crate.pos;g.ensure_arena_chest_clearance()
 assert(g.arena_chest_clear(chest.pos,chest))
 var stable:Vector2=chest.pos;g.ensure_arena_chest_clearance();assert(chest.pos==stable)
 var rng:=RandomNumberGenerator.new()
 for seed_value in range(50):
  rng.seed=seed_value
  g.finish_room_layout(rng)
  chest=g.objects.filter(func(o):return o.id=='courage')[0]
  assert(g.arena_chest_clear(chest.pos,chest))
 var stream=load('res://scripts/audio_bank.gd').STREAMS.shovel_break
 assert(stream.get_length()>.3 and stream.get_length()<.8)
 print('PASS reward chest visual clearance across50 layout shuffles; dedicated break audio')
 quit()
