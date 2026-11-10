extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame
 g.new_game();g.clear_modal();g.set_process(false);g.set_physics_process(false);g.sound_on=false;g.health=3.5
 g.activate_cached_room(4)
 for wave in range(1,8):
  g.enemies.clear();g.wave=wave;g.battle.spawn();assert(g.enemies.size()==g.battle.WAVES[wave-1].size())
  var guns=g.enemies.filter(func(e):return e.type in [5,6,7])
  if wave<=3:assert(guns.is_empty())
  var rockets=g.enemies.filter(func(e):return e.type==7)
  assert(rockets.size()==(2 if wave==7 else 1 if wave==6 else 0))
  if wave==7:
   assert(g.enemies.size()==7 and g.enemies.filter(func(e):return e.boss).size()==1)
   for kind in [5,6,7]:assert(g.enemies.filter(func(e):return e.type==kind).size()==2)
  for e in g.enemies:assert(g.battle.spawn_clear(e.pos) and e.pos.distance_to(g.player)>=190)
  assert(g.objects.filter(func(o):return o.kind=="medkit").size()==(1 if wave in [3,5] else 0))
  g.objects.assign(g.objects.filter(func(o):return o.kind!="medkit"))
 assert(g.battle.GUNS[5].travel==175 and g.battle.GUNS[6].travel==196 and g.battle.GUNS[7].travel==280)
 # Saved wave 10 must become the new final wave, never a dead end.
 g.wave=10;g.health=3.5;g.playing=true;g.arena_save.capture();g.save_data.arena_checkpoint.balance=4;g.arena_save.restore_room();assert(g.wave==7 and g.enemies.size()==7 and g.health==3.5)
 print("PASS seven waves, gradual shooters, exact finale, two medkits, range and old wave migration")
 var positions:Dictionary={}
 for room in range(7):
  g.activate_cached_room(room);g.rune_stones.install()
  var id:String=g.save_data.riddle_stone_order[room];assert(g.save_data.riddle_stone_positions.has(str(room)))
  var p:Array=g.save_data.riddle_stone_positions[str(room)];positions[room]=p.duplicate()
  if room==3:
   assert(not g.objects.any(func(o):return o.kind=="riddle_stone"))
   var point:=Vector2(p[0],p[1]);g.rune_stones.excavate(point);assert(g.save_data.riddle_stone_exposed)
  var stones=g.objects.filter(func(o):return o.kind=="riddle_stone");assert(stones.size()==1 and stones[0].id==id)
  assert(stones[0].get("hidden_hedge",false)==(room==0))
  var reachable:=false
  for n in range(32):
   g.player=stones[0].pos+Vector2.from_angle(n*TAU/32)*50
   if not g.blocked(g.player) and g.available(stones[0]) and g.interaction_reachable(stones[0]):reachable=true;break
  assert(reachable,"Stone must be reachable in room %d"%room)
  g.rune_stones.collect(stones[0]);g.rune_stones.install();assert(not g.objects.any(func(o):return o.kind=="riddle_stone"))
 assert(g.save_data.riddle_stones.size()==7 and not g.rune_stones.ready())
 g.activate_cached_room(6);var order:Array=g.save_data.riddle_order.duplicate();g.puzzle.clear()
 g.press_riddle_symbol(order[0],Vector2.ZERO);assert(g.puzzle.is_empty())
 for id in g.content.puzzle.symbols:
  g.time+=.8;g.rune_stones.use_socket(id,Vector2.ZERO)
 assert(g.rune_stones.ready() and g.puzzle.is_empty())
 g.time+=.8
 for id in order:g.rune_stones.use_socket(id,Vector2.ZERO)
 assert(g.puzzle==order);g.save_data.letters=g.save_data.riddle_letters.duplicate();g.check_riddle_chest();assert(g.save_data.finished)
 g.persist();g.load_save();g.rune_stones.ensure();assert(g.rune_stones.ready() and g.save_data.riddle_stone_positions.size()==7)
 print("PASS one saved random stone per room, buried discovery, collection, sockets, locked inputs, correct final sequence and reload")
 quit()
