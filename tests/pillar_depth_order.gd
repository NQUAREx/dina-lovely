extends SceneTree
func _initialize():call_deferred('run')
func run():
 var g=load('res://main.tscn').instantiate();root.add_child(g);await process_frame
 g.new_game();g.clear_modal();g.set_process(false);g.set_physics_process(false);g.hide()
 g.activate_cached_room(2)
 var overlay=g.get_children().filter(func(n):return n.get_script()!=null and n.get_script().resource_path=="res://scripts/pillar_overlay.gd")[0]
 var door=g.objects.filter(func(o):return o.kind=="doorway" and o.id=="exit")[0]
 g.camera=door.pos+Vector2(0,80)
 for offset in [-15,35]:
  g.player=door.pos+Vector2(-96,offset)
  overlay._process(0)
  var sprite=overlay.sprites["2:exit:-1"]
  assert(sprite.material.get_shader_parameter("player_in_front")== (offset>0))
  var mask:Image=sprite.material.get_shader_parameter("player_mask").get_image()
  assert(mask.get_pixel(0,0).a==0 and mask.get_pixel(16,20).a>.5)
 for tool in ["shovel","axe","flashlight","shears","drill","pickaxe"]:
  g.held_item=tool;g.weapon="";overlay._process(0)
  assert(overlay.sprites["2:exit:-1"].material.get_shader_parameter("held_enabled"))
 g.activate_cached_room(4)
 var arena_door=g.objects.filter(func(o):return o.kind=="doorway" and o.id=="exit")[0]
 g.camera=arena_door.pos+Vector2(0,80);g.player=arena_door.pos+Vector2(-96,35)
 for weapon in ["rifle","sword","rpg"]:
  g.weapon=weapon;overlay._process(0)
  assert(overlay.sprites["4:exit:-1"].material.get_shader_parameter("held_enabled"))
 print("PASS pillar overlay depth ordering, silhouette transparency and tool/weapon occlusion")
 quit()
