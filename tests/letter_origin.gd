extends SceneTree
func _initialize():call_deferred('run')
func run():
 var g=load('res://main.tscn').instantiate();root.add_child(g);await process_frame
 g.new_game();g.set_process(false);g.set_physics_process(false)
 for origin in [Vector2(75,240),Vector2(470,760),Vector2(270,480)]:
  var view=Control.new();view.set_script(load('res://scripts/letter_view.gd'))
  view.game=g;view.letter=g.letter_with_clue(g.content.letters[0]);view.start=origin
  g.root.add_child(view)
  assert(view.age==0.0)
  assert(view.paper.position.is_equal_approx(origin+Vector2(-15,-65)))
  assert(view.paper.scale.is_equal_approx(Vector2.ONE*.065))
  assert(view.paper.modulate.a==0.0)
  view.update_pose(0)
  assert(view.paper.position.is_equal_approx(origin+Vector2(-15,-65)))
  view.queue_free();await process_frame
 # Archive metadata may differ from the content dictionary; source selection
 # is by id, never a -1 card coordinate outside the stack.
 g.clear_modal();g.save_data.letters=[]
 for index in range(3):g.save_data.letters.append(g.content.letters[index].id)
 g.show_letter_stack({"archive_open":false,"pos":g.player})
 var stack=g.modal
 stack.letters[1]=stack.letters[1].duplicate(true)
 stack.letters[1].local_metadata=true
 var expected:Rect2=stack.card_rect(1)
 g.show_letter(str(stack.letters[1].id),false,stack)
 assert(g.modal.stack_rect==expected)
 g.clear_modal();await process_frame
 # Journals skip the world flight and are centered on their first draw.
 g.show_letter(str(g.content.letters[0].id),true)
 assert(g.modal.paper.position.is_equal_approx((g.get_viewport_rect().size-g.modal.paper.size)/2))
 assert(g.modal.paper.scale==Vector2.ONE)
 print('PASS letter first-frame origins, stable archive selection and immediate journal pose')
 quit()
