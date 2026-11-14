extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scripts/game.gd").new()
 g.save_data=g.default_save();g.level=1
 for n in range(30):g.grid.append(".".repeat(27))
 # A lamp dropped just beyond either gate remains inside the main-room rows.
 # It belongs to the world pass and must never receive a second corridor draw.
 for y in [5.3,24.7]:
  var lamp={"kind":"stand_flashlight","pos":Vector2(13.5,y)*48,"ground_tool":true,"ground_angle":-PI/2}
  assert(not g.torch.neighbor_overlay(lamp))
 # A genuinely shared-corridor lamp/pedestal is excluded from the neighbouring
 # world pass, then drawn once by the foreground overlay using its stored pose.
 for y in [2.5,27.5]:
  var lamp={"kind":"stand_flashlight","pos":Vector2(13.5,y)*48,"ground_tool":true,"ground_angle":PI}
  assert(g.torch.neighbor_overlay(lamp))
  assert(g.torch.neighbor_overlay({"kind":"flashlight_pedestal","pos":lamp.pos}))
 assert(not g.torch.neighbor_overlay({"kind":"note","pos":Vector2(13.5,2.5)*48}))
 g.free();print("PASS unique flashlight draw ownership across both corridor halves")
 quit()
