extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame
 g.new_game();g.clear_modal();g.sound_on=false;g.set_process(false);g.set_physics_process(false)
 g.activate_cached_room(6)
 var stand=g.objects.filter(func(o):return o.kind=="skull_stand")[0]
 assert(g.valid_ground(stand.pos))
 g.player=stand.pos+Vector2(0,50);g.nearest=g.objects.find(stand);g.interact()
 assert(not g.save_data.get("skull_inserted",false) and not g.paused)
 g.activate_cached_room(1)
 var door=g.objects.filter(func(o):return o.kind=="house_door")[0]
 var skull=g.objects.filter(func(o):return o.kind=="skull_relic")[0]
 assert(not g.available(skull))
 g.player=door.pos+Vector2(0,65);g.nearest=g.objects.find(door);g.interact();assert(g.available(skull))
 g.nearest=g.objects.find(skull);var held=g.held_item;g.interact()
 assert(g.save_data.skull_taken and g.held_item==held and not g.available(skull))
 g.activate_cached_room(6);stand=g.objects.filter(func(o):return o.kind=="skull_stand")[0]
 var puzzle=g.puzzle.duplicate();var finished=g.chest_open
 g.player=stand.pos+Vector2(0,50);g.nearest=g.objects.find(stand);g.interact()
 assert(g.save_data.skull_inserted and not g.save_data.skull_taken)
 assert(g.puzzle==puzzle and g.chest_open==finished and g.paused)
 g.clear_modal();g.activate_cached_room(1);assert(not g.available(g.objects.filter(func(o):return o.kind=="skull_relic")[0]))
 g.activate_cached_room(6);stand=g.objects.filter(func(o):return o.kind=="skull_stand")[0]
 g.player=stand.pos+Vector2(20,65);await g.deposit_reply()
 assert(g.save_data.reply_sent and not g.reply_deposit_active and not g.blocked(g.player))
 assert(g.player.distance_to(stand.pos+Vector2(0,50))<5)
 print("PASS optional skull pickup/insertion, invisible inventory, independent chest, reply modal and envelope deposit")
 quit()
