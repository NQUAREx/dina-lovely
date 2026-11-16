extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);g.hide();await process_frame
 g.new_game();g.clear_modal();g.set_process(false);g.set_physics_process(false);g.sound_on=false
 g.build_level(4);g.objects.assign(g.objects.filter(func(o):return not o.solid));g.pending_spawns.clear()
 g.combat_done=false;g.wave=1;g.playing=true;g.paused=false;g.invincible=1000;g.wave_timer=100
 var north:float=6*48+10;var south:float=(g.grid.size()-6)*48-10
 for y in [north,south]:
  for x in [2*48.0,7*48.0,(g.grid[0].length()-2)*48.0]:
   g.player=Vector2(x,y);g.enemies.clear();g.shots.clear()
   var pos:Vector2=g.player+Vector2(0,145 if y==north else -145)
   assert(not g.blocked(g.player),"Test player must be able to stand at wall")
   assert(not g.inside_main_room(),"Regression must exercise the formerly frozen strip")
   assert(g.battle.player_in_arena())
   g.battle.enemy(0,pos,100);var enemy:Dictionary=g.enemies[0];enemy.state="patrol";enemy.sense=0
   assert(g.battle.sight(enemy.pos,g.player))
   g._process(.04)
   assert(enemy.aggro and enemy.state=="chase", "Wall must not disable detection")
   for step in range(20):g._process(.04)
   assert(enemy.pos.distance_to(g.player)<pos.distance_to(g.player)-10,"Enemy must pursue at both walls and corners")
 # Genuine blockers still occlude sight; corridor safety remains separate.
 g.player=Vector2(500,600)
 g.objects.append({"kind":"crate","id":"test_occluder","pos":Vector2(500,700),"solid":true})
 assert(not g.battle.sight(Vector2(500,800),g.player))
 g.player=Vector2(13.5*48,4*48);assert(not g.battle.player_in_arena())
 g.player=Vector2(13.5*48,(g.grid.size()-4)*48);assert(not g.battle.player_in_arena())
 print("PASS arena AI detects and pursues along both horizontal walls and four corners; solid obstacles occlude, corridors remain excluded")
 quit()
