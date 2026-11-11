extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame
 g.set_process(false);g.set_physics_process(false);g.sound_on=false;g.clear_modal();g.save_data=g.default_save();g.ensure_riddle();g.build_level(6);g.playing=true;g.invincible=0
 g.save_data.letters=g.content.letters.slice(0,g.content.letters.size()-1).map(func(n):return n.id)
 var collected=g.save_data.letters.duplicate();var boxes=g.objects.filter(func(o):return o.kind=="letter_box");assert(boxes.size()==1 and boxes[0].solid)
 var box=boxes[0];assert(not g.blocked(box.pos+Vector2(0,50)));var reachable:=false
 for n in range(16):
  g.player=box.pos+Vector2.from_angle(n*TAU/16)*65
  if not g.blocked(g.player) and g.interaction_reachable(box):reachable=true;break
 assert(reachable)
 g.nearest=g.objects.find(box);g.interact();var stack=g.modal;assert(stack.box_object==box and box.archive_open and g.paused)
 assert(stack.letters.size()==collected.size() and stack.letters.all(func(n):return n.id in collected))
 stack.age=1.3;stack._process(0);stack.begin_drag(Vector2(270,320));stack.continue_drag(Vector2(270,180));stack.end_drag(Vector2(270,180));assert(stack.target_cursor>0)
 stack.step(100);stack._process(2);assert(stack.cursor==stack.max_cursor())
 var index=stack.letters.size()-1;var id=stack.letters[index].id;var point=stack.card_rect(index).position+Vector2(100,25)
 var touch=InputEventScreenTouch.new();touch.position=point;touch.pressed=true;stack._gui_input(touch)
 touch=InputEventScreenTouch.new();touch.position=point;touch.pressed=false;stack._gui_input(touch)
 var view=g.modal;assert(view!=stack and view.letter.id==id and view.stack_view==stack and not stack.active)
 view._process(.8);assert(view.paper.scale.is_equal_approx(Vector2.ONE) and not view.close_button.disabled)
 view.close();view._process(.6);await process_frame;assert(g.modal==stack and stack.active and stack.selected_id.is_empty() and stack.cursor==stack.max_cursor())
 assert(g.save_data.letters==collected)
 g.clear_modal();await process_frame;assert(not box.archive_open and not g.paused and g.hud.visible)
 g.show_letter(id);var normal=g.modal;normal._process(1.6);assert(not normal.close_button.disabled and not is_instance_valid(normal.stack_view));normal.close();await process_frame
 g.show_letter_stack(box);stack=g.modal;stack.age=1.3;stack._process(0);stack.begin_drag(stack.card_rect(0).position+Vector2(100,25));stack.end_drag(stack.card_rect(0).position+Vector2(100,25));assert(g.modal!=stack)
 g.show_menu();await process_frame;await process_frame;assert(not is_instance_valid(stack) and not box.archive_open and g.paused)
 g.clear_modal();g.save_data.letters=[];g.show_letter_stack(box);stack=g.modal;stack.age=1.3;stack._process(0);assert(stack.letters.is_empty() and stack.previous_button.disabled and stack.next_button.disabled and not stack.exit_button.disabled)
 g.clear_modal();g.queue_free();await process_frame
 print("PASS archive interaction, saved-only letters, swipe/page/tap, pull-out and return, exit cleanup, empty pile and normal letter opening")
 quit()
