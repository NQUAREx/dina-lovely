extends SceneTree
func _initialize():call_deferred("run")
func area(points:PackedVector2Array)->float:
 var sum:=0.0
 for i in range(points.size()):sum+=points[i].cross(points[(i+1)%points.size()])
 return absf(sum)*.5
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame;g.new_game();g.clear_modal();g.sound_on=false;g.set_process(false);g.set_physics_process(false);g.save_data.seed=723;g.prepare_room_cache(0)
 assert(g.hud.get_child(0).position==Vector2(16,36) and g.hud.get_node("MenuButton").position==Vector2(440,52))
 g.save_data.cat_tamed=true;g.held_item="";g.player=Vector2(744,900);g.companion.position=g.player+Vector2(35,0);g.find_nearest()
 assert(not g.objects.any(func(o):return o.kind=="pet_cat"))
 assert(not g.available({"kind":"pet_cat","pos":g.player,"id":"pet_cat"}))
 g.player=Vector2(744,-40);g.companion.position=g.player+Vector2(35,0);g.find_nearest();assert(g.objects.any(func(o):return o.kind=="pet_cat"))
 var field=g.hedge_field;var node=field.crowns[field.crowns.size()/2];g.player=node.base+Vector2(60,30);g.camera=node.base
 var visible=field.visible_ids(Rect2(node.base-Vector2(200,200),Vector2(400,400)));field.prepare_draw(visible,g.player)
 var saw_clipping:=false
 for offset in [Vector2(20,15),Vector2(-20,15),Vector2(0,28)]:
  g.companion.position=node.base+offset;var p:Vector2=g.screen(g.companion.position);var name="cat_idle2_0"
  var polygons=g.companion.ground_regions(name,p);var clipped_area:=0.0
  for polygon in polygons:clipped_area+=area(polygon)
  var source:Rect2=g.companion.cat_bounds[name];var full_area:float=source.get_area()*1.6*1.6
  assert(clipped_area<=full_area+.5)
  if clipped_area<full_area-1:saw_clipping=true
 assert(saw_clipping)
 var shader=FileAccess.get_file_as_string("res://shaders/flashlight.gdshader");assert(not "near_light" in shader and "reflected" in shader and "lens_spill" in shader)
 print("PASS HUD inset below wreath, strict corridor-only cat labels, ground-clipped cat geometry and lens-origin reflected light")
 quit()
