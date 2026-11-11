extends SceneTree
func _initialize():call_deferred("run")
func run():
 var path=ProjectSettings.globalize_path(load("res://scripts/game.gd").SAVE_PATH)
 var previous=FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.set_physics_process(false);g.sound_on=false;g.clear_modal();g.save_data=g.default_save();g.ensure_riddle();g.playing=true;g.build_level(6)
 g.save_data.riddle_stones=g.content.puzzle.symbols.duplicate();g.save_data.riddle_inserted=g.content.puzzle.symbols.duplicate()
 var first:String=g.content.puzzle.symbols[0]
 g.press_riddle_symbol(first,g.player);g.press_riddle_symbol(first,g.player);assert(g.puzzle.size()==1)
 assert(not g.available({"kind":"stone","id":first,"pos":g.player,"solid":false}))
 for id in g.content.puzzle.symbols:g.press_riddle_symbol(id,g.player)
 assert(g.puzzle.size()==7);g.press_riddle_symbol("puzzle_reset",g.player);assert(g.puzzle.is_empty())
 g.save_data.riddle_input=[first,first,g.content.puzzle.symbols[1]];g.ensure_riddle();assert(g.save_data.riddle_input.size()==2)
 g.build_level(5);assert(g.corridor_wall_kind(-2)=="tree" and g.corridor_wall_kind(4)=="tree" and g.corridor_wall_kind(g.grid.size()+2)=="stone")
 g.build_level(6);assert(g.corridor_wall_kind(g.grid.size()-4)=="tree" and g.corridor_wall_kind(g.grid.size()+2)=="tree" and g.corridor_wall_kind(2)=="stone")
 var id:String=g.save_data.riddle_letters[0];g.show_letter(id);var sheet=g.modal
 var ruling:Control
 for node in sheet.paper.get_children():
  if node.get_script()!=null and node.get_script().resource_path.ends_with("letter_ruling.gd"):ruling=node
 assert(is_instance_valid(ruling) and ruling.scroll==sheet.text_scroll and ruling.clip_contents)
 var body:RichTextLabel=sheet.text_scroll.get_child(0).get_child(0)
 assert(not body.get_parsed_text().contains("«") and not body.get_parsed_text().contains("»"))
 g.clear_modal();g.build_level(0);g.particles.clear();g.hedge_field=null;g.objects.clear();g.player=Vector2(500,500);g.moving=true;g.joy_active=true;g.joy_vector=Vector2.RIGHT;g.vegetation_fx_cooldown=0;g.vegetation_was_touched=false
 g.objects.append({"kind":"flowers","id":"","pos":g.player,"solid":false});g.update_vegetation(.04)
 assert(g.particles.size()==2 and g.particles.all(func(p):return p.get("foliage",false)))
 g.update_vegetation(.01);assert(g.particles.size()==2)
 print("PASS throttled flower foliage particles")
 print("PASS unique presses/reset/old-input migration, shared tree corridor material, scroll-bound ruling and unquoted icons")
 g.clear_modal();g.queue_free();await process_frame
 if previous.is_empty():DirAccess.remove_absolute(path)
 else:
  var file=FileAccess.open(path,FileAccess.WRITE);file.store_buffer(previous);file.close()
 quit()
