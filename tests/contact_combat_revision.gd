extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame
 g.sound_on=false;g.new_game();g.clear_modal();g.set_process(false);g.set_physics_process(false)
 var bank=load("res://scripts/audio_bank.gd").STREAMS
 assert(bank.has("gate_open") and bank.has("gate_unlock"))
 g.activate_cached_room(1)
 var door=g.objects.filter(func(o):return o.kind=="house_door")[0]
 assert(g.item_name(door)==g.tx("item_house_door"))
 g.player=door.pos+Vector2(0,65);g.nearest=g.objects.find(door);g.interact();assert(door.opened)
 var positions={}
 for room in [1,5]:
  g.build_level(room);positions[room]=g.objects.filter(func(o):return o.kind in ["house","pond","well","bench","can"]).map(func(o):return o.pos)
 g.save_data.seed+=1003
 for room in [1,5]:
  g.build_level(room);var next=g.objects.filter(func(o):return o.kind in ["house","pond","well","bench","can"]).map(func(o):return o.pos)
  assert(next!=positions[room])
 g.build_level(0)
 var field=g.hedge_field;var index=field.draw_order[field.draw_order.size()/2];var base=field.crowns[index].base
 for n in range(100):field.update(1.0/60,base+Vector2(0,28+n*.12))
 for node in field.crowns:assert(node.depression<=22.01)
 for n in range(240):field.update(1.0/60,Vector2(-1000,-1000))
 for node in field.crowns:assert(absf(node.depression)<.05 and node.offset.length()<.1)
 g.build_level(4);g.weapon="rifle";g.held_item="rifle";g.paused=false;g.playing=true;g.combat_done=false;g.player=Vector2(13.5,14)*48;g.aim=Vector2.RIGHT
 var before=g.player;g.attack();assert(g.player.distance_to(before)>0 and g.player.distance_to(before)<=3.01)
 assert(g.rifle_kick>0 and g.shots.size()==1)
 assert(absf(g.shots[0].vel.angle())<=.0281)
 print("PASS house interaction, recorded gate sounds, seed-driven props, bounded/released/settled crowns, AK recoil and spread")
 quit()
