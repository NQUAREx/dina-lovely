extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame
 g.new_game();g.clear_modal();g.set_process(false);g.set_physics_process(false);g.sound_on=false
 g.build_level(4);g.player=Vector2(650,900)
 assert(g.objects.filter(func(o):return o.kind=="weapon_crate").size()==3)
 assert(g.objects.filter(func(o):return o.kind.begins_with("weapon_") and o.kind!="weapon_crate").is_empty())
 g.spawn_wave();assert(g.wave==1 and g.save_data.weapon_crates_opened.is_empty())
 g.enemies.clear();g.battle.enemy(0,g.player+Vector2(65,0),100);g.enemies[0].state="chase"
 g.weapon="";g.held_item="";g.attack_cd=0;g.attack();assert(g.enemies[0].hp==88)
 g.update_hud();assert(g.attack_button.visible)
 for wave in range(2,8):
  g.enemies.clear();g.spawn_wave();assert(g.wave==wave)
  for w in ["sword","rifle","rpg"]:
   var expected:bool=wave>={"sword":2,"rifle":4,"rpg":6}[w]
   assert((w in g.save_data.weapon_crates_opened)==expected)
  var count:int=g.save_data.loose_weapons.size()
  g.weapon_crates.install(true);assert(g.save_data.loose_weapons.size()==count,"crate released weapon twice")
 assert(g.save_data.loose_weapons.size()==3)
 var medkits=g.objects.filter(func(o):return o.kind=="medkit")
 assert(medkits.size()==1 and medkits[0].pos==Vector2(g.grid[0].length(),g.grid.size())*24)
 var drops=g.objects.filter(func(o):return str(o.id).begins_with("drop_crate_"))
 for drop in drops:
  assert(not g.blocked(drop.pos));assert(drop.pos.distance_to(drop.flight_from-Vector2(0,6))>=75)
 var flight:Dictionary=drops[-1]
 var before:Vector2=g.item_display_position(flight);g.time+=.45;var middle:Vector2=g.item_display_position(flight)
 assert(before.distance_to(middle)>10 and not g.available(flight))
 g.time+=1;assert(g.available(flight) and g.item_display_position(flight)==flight.pos)
 var bare:float=g.movement_speed();g.held_item="rifle";var rifle:float=g.movement_speed();g.held_item="rpg";var rpg:float=g.movement_speed()
 assert(bare==150 and rifle==135 and rpg==93)
 # An unlocked floor drop survives a room cache cycle, without a duplicate opening.
 g.held_item="";g.weapon="";g.cache_current_room();var floor_count:int=g.save_data.loose_weapons.size()
 g.activate_cached_room(5);g.activate_cached_room(4)
 assert(g.save_data.loose_weapons.size()==floor_count and g.save_data.weapon_crates_opened.size()==3)
 # Legacy early RPG ownership is returned to a locked crate even after hand restore.
 g.wave=1;g.held_item="rpg";g.weapon="rpg";g.weapon_crates.install()
 assert(g.held_item.is_empty() and not g.weapon_crates.unlocked("rpg"))
 g.save_data.arena_checkpoint={"seed":g.save_data.seed,"held_item":"rpg","fields":{"health":8},"dead":false}
 g.arena_save.restore_hands();assert(g.held_item.is_empty())
 g.arena_save.restart()
 assert(g.wave==0 and g.save_data.weapon_crates_opened.is_empty() and g.save_data.loose_weapons.is_empty())
 print("PASS fists, unlock waves 2/4/6, one-time crates, airborne drops, centered single medkit, weapon weight, room restore, legacy save and retry reset")
 quit()
