extends RefCounted
var g:Node2D
func _init(game:Node2D):g=game
func install()->void:
 g.objects.assign(g.objects.filter(func(o):return o.kind!="stand_flashlight"))
 if g.level!=1 and g.playing and not g.transition and g.held_item=="flashlight":g.held_item="";g.sync_hands()
 if not g.save_data.get("flashlight_location",{}).is_empty() and int(g.save_data.flashlight_location.room)!=1:
  g.save_data.flashlight_location={}
 if g.level==1 and not g.objects.any(func(o):return o.kind=="flashlight_pedestal"):
  var anchor:Vector2=Vector2(14.1,g.grid.size()-2.5)*48
  g.objects.append({"kind":"flashlight_pedestal","id":"torch_pedestal","pos":anchor,"solid":false})
 if g.save_data.get("flashlight_location",{}).is_empty():
  if g.level==1:g.save_data.flashlight_location={"room":1,"pos":[14.1*48,(g.grid.size()-2.5)*48],"ground":false}
  else:return
 var saved:Dictionary=g.save_data.flashlight_location
 if int(saved.room)==g.level and g.held_item!="flashlight":g.objects.append({"kind":"stand_flashlight","id":"flashlight","pos":Vector2(saved.pos[0],saved.pos[1]),"ground_tool":bool(saved.ground),"solid":false})
 g.save_data.tool_positions.erase("1:flashlight")
func drop(pos:Vector2)->void:
 g.save_data.flashlight_location={"room":g.level,"pos":[pos.x,pos.y],"ground":true}
 g.held_item="";g.sync_hands();install()

func drop_at_exit()->void:
 if g.level==1:
  # Keep it on the dark-room side of the shared entrance corridor.
  drop(Vector2(clampf(g.player.x,12.6*48,14.4*48),clampf(g.player.y,1.5*48,(g.grid.size()-1.5)*48)))
 else:
  g.held_item="";g.sync_hands();g.save_data.flashlight_location={};install()
