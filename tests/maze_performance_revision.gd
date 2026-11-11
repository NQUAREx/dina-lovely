extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame;g.new_game();g.clear_modal();g.set_process(false);g.set_physics_process(false);g.sound_on=false
 g.save_data.seed=723;g.prepare_room_cache(0);g.save_data.cat_tamed=true;g.held_item="";g.nearest=-1
 var pet={"kind":"pet_cat","id":"pet_cat","pos":g.player,"solid":false}
 g.player=Vector2(744,900);assert(not g.available(pet));g.player=Vector2(744,-40);assert(g.available(pet))
 var field=g.hedge_field;var base:Vector2=field.crowns[field.crowns.size()/2].base
 for facing in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
  for frame in range(12):
   var pos:Vector2=base+facing*(34-frame*.8);field.update(.016,pos)
   var visible=field.visible_ids(Rect2(pos-Vector2(95,95),Vector2(190,190)));field.prepare_draw(visible,pos)
   for a in range(visible.size()):
    var first:int=visible[a]
    if not field.front_crowns.has(first):continue
    var p:Vector3=field.draw_poses[first]
    for b in range(a+1,visible.size()):
     var second:int=visible[b]
     if field.front_crowns.has(second):continue
     var q:Vector3=field.draw_poses[second]
     assert(Vector2(p.x,p.y).distance_squared_to(Vector2(q.x,q.y))>=pow(p.z+q.z,2))
 g.activate_cached_room(4);g.objects.assign(g.objects.filter(func(o):return not o.solid));g.player=Vector2(600,800);g.companion.position=g.player+Vector2(0,140);g.companion.trail.clear();g.companion.last_player=g.player
 for n in range(13,-1,-1):g.companion.trail.append({"pos":g.player+Vector2(0,n*10),"time":g.companion.clock-1})
 for n in range(60):g.companion.update(.016)
 assert(g.companion.position.distance_to(g.player)>78 and g.companion.position.distance_to(g.player)<82)
 g.companion.position=g.player;g.companion.trail.clear();g.companion.trail.append({"pos":g.player,"time":g.companion.clock-1});g.moving=false
 for n in range(80):g.companion.update(.016)
 assert(g.companion.position.distance_to(g.player)>45)
 g.activate_cached_room(1);var pedestal=g.objects.filter(func(o):return o.kind=="flashlight_pedestal")[0];var anchor:Vector2=pedestal.pos
 g.held_item="flashlight";g.sync_hands();g.player=Vector2(13.5*48,g.grid.size()*48+1);g.camera=g.player;g.travel(0)
 assert(g.held_item=="" and int(g.save_data.flashlight_location.room)==1)
 assert(not g.objects.any(func(o):return o.id=="flashlight"))
 assert(g.room_cache[1].objects.any(func(o):return o.kind=="flashlight_pedestal" and o.pos==anchor))
 g.equip_tool("flashlight");assert(g.held_item=="")
 g.travel(1);assert(g.objects.filter(func(o):return o.kind=="flashlight_pedestal").size()==1)
 g.equip_tool("flashlight");assert(g.held_item=="flashlight")
 g.return_held_tool();assert(int(g.save_data.flashlight_location.room)==1 and g.objects.filter(func(o):return o.kind=="flashlight_pedestal").size()==1)
 g.persist();g.load_save();assert(int(g.save_data.flashlight_location.room)==1)
 var shader=FileAccess.get_file_as_string("res://shaders/flashlight.gdshader");assert(not "scattered" in shader and "158.0" in shader and "hero_pos" in shader)
 print("PASS four-side stable crown ordering, corridor-only petting, dark-room-only torch return/pickup, permanent pedestal, saved torch location and two-source light shader")
 quit()
