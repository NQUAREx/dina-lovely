extends SceneTree
func _initialize():call_deferred('run')
func run():
 var g=load('res://main.tscn').instantiate();root.add_child(g);await process_frame
 g.new_game();g.clear_modal();g.set_process(false);g.set_physics_process(false);g.hide()
 for kind in ['axe','quest_axe','pickaxe','shovel','can','rake','fertilizer','flashlight','shears','drill']:
  g.objects.assign([{'kind':kind,'id':kind,'pos':g.player}]);g.nearest=0
  g.action_button.text=g.tx('pickup_material');g.update_action_icon()
  var icon=g.action_button.icon
  assert(icon is AtlasTexture and icon.atlas==g.atlas)
  var name='axe' if kind=='quest_axe' else kind
  var id:int=g.sprites[name]
  assert(icon.region.position.x>=id%16*32 and icon.region.position.x<(id%16+1)*32)
  assert(icon.region.position.y>=int(id/16)*48 and icon.region.position.y<(int(id/16)+1)*48)
 print('PASS ten tool pickup actions use their own atlas sprite even with shared label')
 quit()
