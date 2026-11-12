extends SceneTree
func _initialize():call_deferred("run")
func visible_text(node:Node)->Array:
 var result:Array=[]
 if (node is Label or node is Button) and not node.text.is_empty():result.append(node.text)
 for child in node.get_children():result.append_array(visible_text(child))
 return result
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame
 g.clear_modal();g.set_process(false);g.set_physics_process(false)
 g.content.game_title="JSON_ONLY_TITLE"
 var expected:Array=[g.content.game_title]
 for key in ["start_intro","gate_key_intro","controls_help","begin_room"]:
  g.content.ui[key].text="JSON_ONLY_"+key;expected.append(g.content.ui[key].text)
 g.new_game()
 var actual:Array=visible_text(g.modal)
 assert(actual==expected,JSON.stringify(actual))
 g.content.ui.start_intro.text="JSON_CHANGED_INTRO";g.show_intro()
 assert("JSON_CHANGED_INTRO" in visible_text(g.modal))
 print("PASS actual New Game screen uses only current JSON title, paragraphs and button; live value change reflected")
 quit()
