extends SceneTree
func _initialize():call_deferred('run')
func run():
 var g=load('res://main.tscn').instantiate();root.add_child(g);await process_frame
 g.new_game();g.clear_modal();g.set_process(false);g.set_physics_process(false);g.hide();g.sound_on=false
 g.playing=true;g.paused=false;g.save_data.open_gates.append(0)
 g.activate_cached_room(1)
 var anchor:=Vector2(14.1,g.grid.size()-2.5)*48
 for offset in [Vector2.UP,Vector2(1,-1).normalized(),Vector2.RIGHT,Vector2(1,1).normalized(),Vector2.DOWN,Vector2(-1,1).normalized(),Vector2.LEFT,Vector2(-1,-1).normalized()]:
  g.held_item='';g.sync_hands()
  g.save_data.flashlight_location={"room":1,"pos":[anchor.x,anchor.y],"ground":false}
  g.torch.install();g.player=anchor+offset*28;g.walk_facing=-offset;g.joy_active=false;g.joy_vector=Vector2.ZERO
  g.nearest=g.objects.find(g.objects.filter(func(o):return o.id=='flashlight')[0])
  assert(g.interaction_reachable(g.objects[g.nearest]))
  g.interact();assert(g.held_item=='flashlight')
  for frame in range(3):g._physics_process(.001)
  assert(g.held_item=='flashlight','stationary corridor pickup was immediately dropped')
 # Returning to the room, then actually crossing the open exit, still releases.
 g.player=Vector2(14.1*48,(g.grid.size()-5.3)*48+1);g.walk_facing=Vector2.DOWN
 g.release_at_gate(g.player-Vector2(0,2));assert(g.held_item.is_empty())
 g.activate_cached_room(3);g.save_data.finished=true
 var point:=Vector2(13.5,10)*48
 for tool in ['can','rake','fertilizer','shovel','quest_axe','pickaxe','axe','shears','drill']:
  for offset in [Vector2.UP,Vector2(1,-1).normalized(),Vector2.RIGHT,Vector2(1,1).normalized(),Vector2.DOWN,Vector2(-1,1).normalized(),Vector2.LEFT,Vector2(-1,-1).normalized()]:
   g.held_item='';g.sync_hands();g.save_data.world_kit.erase(tool)
   g.objects.assign(g.objects.filter(func(o):return o.id!=tool))
   g.objects.append({"kind":tool,"id":tool,"pos":point,"solid":false})
   g.player=point+offset*28;g.walk_facing=-offset;g.nearest=g.objects.size()-1
   assert(g.interaction_reachable(g.objects[g.nearest]))
   g.interact();assert(g.held_item==tool,tool+' pickup failed')
   g._physics_process(.001);assert(g.held_item==tool)
 print('PASS flashlight pedestal and nine tools pickup from all eight sides; only actual outward gate crossing releases')
 quit()
