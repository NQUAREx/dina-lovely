extends SceneTree
func _initialize():call_deferred("run")
func run():
 var scene=load("res://main.tscn");var g=scene.instantiate();root.add_child(g);await process_frame;g.set_process(false);g.set_physics_process(false)
 var path:String=g.SAVE_PATH;var previous:=FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()
 assert(g.level==(int(g.save_data.level) if g.save_data.started else 0))
 assert(g.body_font.get_font_name().contains("Garden Pixel") and g.title_font.get_font_name().contains("Garden Pixel"))
 for node in g.modal.find_children("*", "Button", true, false):
  if node.text.is_empty():continue
  assert(node.get_theme_font_size("font_size")==30)
 g.action_button.size=Vector2(180,76)
 for key in ["fill_water","insert_rune","pickup_flashlight","open_gate"]:
  var text:String=g.tx(key)
  if text.is_empty():continue
  g.action_button.text=text;g.fit_button_text(g.action_button)
  var width:float=g.action_button.get_theme_font("font").get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,g.action_button.get_theme_font_size("font_size")).x
  assert(width<=g.action_button.size.x-g.action_button.get_theme_stylebox("normal").get_minimum_size().x-4)
 assert(g.objective.autowrap_mode==TextServer.AUTOWRAP_OFF and g.status.autowrap_mode==TextServer.AUTOWRAP_OFF)
 assert(g.objective.get_theme_font_size("font_size")==24 and g.status.get_theme_font_size("font_size")==20)
 var data:Dictionary=g.default_save();data.started=true;data.level=2;data.seed=7322
 var f=FileAccess.open(path,FileAccess.WRITE);f.store_string(JSON.stringify(data));f.close();g.queue_free();await process_frame
 var saved=scene.instantiate();root.add_child(saved);await process_frame;saved.set_process(false);saved.set_physics_process(false)
 assert(saved.level==2 and not saved.playing and saved.paused and saved.save_data.level==2)
 assert(saved.camera==saved.camera_target())
 saved.queue_free();await process_frame;data.started=false;data.level=5
 f=FileAccess.open(path,FileAccess.WRITE);f.store_string(JSON.stringify(data));f.close()
 var fresh=scene.instantiate();root.add_child(fresh);await process_frame;fresh.set_process(false);fresh.set_physics_process(false)
 assert(fresh.level==0 and not fresh.playing)
 fresh.queue_free();await process_frame
 if previous.is_empty():DirAccess.remove_absolute(path)
 else:
  f=FileAccess.open(path,FileAccess.WRITE);f.store_buffer(previous);f.close()
 print("PASS saved menu room, fresh maze background, camera, paused state and Garden Pixel fonts")
 quit()
