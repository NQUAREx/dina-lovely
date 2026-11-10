extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame;g.new_game();g.clear_modal();g.set_process(false);g.set_physics_process(false);g.sound_on=false;g.activate_cached_room(4);g.save_data.level=4;g.health=3
 for wave in range(1,8):
  g.enemies.clear();g.spawn_wave();assert(g.health==3)
 assert(g.objects.filter(func(o):return o.kind=="medkit").map(func(o):return o.id).size()==2)
 assert(g.objects.any(func(o):return o.id=="wave3_medkit") and g.objects.any(func(o):return o.id=="wave6_medkit"))
 assert(not g.objects.any(func(o):return o.id=="wave5_medkit"))
 g.held_item="rifle";g.weapon="rifle";g.save_data.weapons_taken=["rifle"];g.player=Vector2(600,800);g.magazine=11;g.reload_time=.4;g.rpg_reload=1.2
 g.save_data.accessories.append("white_scarf");g.save_data.loose_accessories.append({"id":"accessory_drop_white_scarf","accessory":"white_scarf","room":4,"pos":[600,700]})
 g.enemies[0].state="chase";g.enemies[0].hp=9.5;g.enemies[0].pos=Vector2(700,600);g.room_remains[4]=[{"kind":"blood_pool","pos":Vector2(700,600),"scale":1.0}];g.persist()
 var count=g.enemies.size();var seed=int(g.save_data.seed)
 var h=load("res://main.tscn").instantiate();root.add_child(h);await process_frame;h.set_process(false);h.set_physics_process(false);h.sound_on=false;h.resume_game()
 assert(h.level==4 and h.wave==7 and h.health==3 and h.enemies.size()==count and int(h.save_data.seed)==seed)
 assert(h.enemies[0].pos==Vector2(700,600) and is_equal_approx(h.enemies[0].hp,9.5) and h.player==Vector2(600,800))
 assert(h.magazine==11 and is_equal_approx(h.reload_time,.4) and h.held_item=="rifle" and h.room_remains[4].size()==1)
 assert(h.objects.filter(func(o):return o.kind=="medkit").size()==2)
 h.health=0;h.arena_save.mark_dead();h.persist();h.arena_save.restart()
 assert(h.health==8 and h.wave==0 and h.enemies.is_empty() and h.shots.is_empty() and h.poison_zones.is_empty() and h.room_remains.get(4,[]).is_empty())
 assert(h.save_data.loose_accessories[0].room==1 and h.save_data.loose_accessories[0].pos.is_empty())
 assert(h.held_item=="" and h.save_data.weapons_taken.is_empty() and h.magazine==30 and h.reload_time==0 and h.rpg_reload==0)
 for id in ["sword","rifle","rpg"]:assert(h.objects.any(func(o):return o.id==id and h.available(o)))
 h.objects.assign(h.objects.filter(func(o):return not o.solid));h.player=Vector2(950,700);h.health=8
 h.shots.append({"kind":"enemy_bullet","pos":Vector2(400,700),"vel":Vector2(1000,0),"life":3.0,"age":0.0,"range_left":100.0});h.update_shots(.5);assert(h.shots.is_empty() and h.health==8)
 var e={"pos":Vector2(600,700),"hp":30.0,"max_hp":30.0,"type":7,"boss":false,"state":"chase","timer":0.0,"cooldown":0.0,"target":h.player}
 for n in range(8):
  e.cooldown=0;var toward:Vector2=(h.player-e.pos).normalized();h.update_gunner(e,.01);assert(h.shots.back().vel.normalized().is_equal_approx(toward) and h.shots.back().range_left==600)
 h.shots.clear();h.enemies.assign([{"pos":Vector2(650,700),"hp":10.0,"max_hp":10.0,"type":0,"boss":false,"state":"chase","timer":0.0,"cooldown":1.0}]);h.weapon="rifle";h.player=Vector2(400,700)
 h.shots.append({"kind":"rifle","pos":Vector2(550,684),"vel":Vector2(570,0),"life":1.4,"age":0.0});h.update_shots(.2);assert(is_equal_approx(h.enemies[0].hp,7.5))
 h.health=0;h.arena_save.mark_dead();h.persist();h.load_save();assert(h.save_data.arena_checkpoint.is_empty() and h.save_data.weapons_taken.is_empty())
 print("PASS fresh-instance wave/HP/enemy/ammo/medkit restore, clean retry racks, dead-save reset, bounded swept bullets, straight enemy RPG and 2.5 HP AK hit")
 quit()
