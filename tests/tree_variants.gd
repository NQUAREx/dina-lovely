extends SceneTree
## Native rendering regression; run with softpipe/Xvfb, like tools/qa/native_capture.sh.
## Screenshot stays in /tmp; no tracked save or content is modified.
func _initialize():call_deferred('run')
func run():
 var g=load('res://main.tscn').instantiate();root.add_child(g);await process_frame
 g.new_game();g.clear_modal();g.set_process(false);g.set_physics_process(false)
 for room in [0,1,2,3,5]:
  g.build_level(room)
  var trees=g.objects.filter(func(o):return o.kind in ['tree','tree_apples'])
  if trees.size()>1:
   assert(trees.any(func(o):return o.kind=='tree'))
   assert(trees.any(func(o):return o.kind=='tree_apples'))
  print('MIX ',room,' ',trees.filter(func(o):return o.kind=='tree').size(),'/',trees.filter(func(o):return o.kind=='tree_apples').size())
 g.build_level(0)
 var apples=g.objects.filter(func(o):return o.kind=='tree_apples' and o.get('integrated_hedge',false))
 assert(not apples.is_empty())
 var target=apples[0]
 var found=false
 for tree in apples:
  for offset in [Vector2(35,0),Vector2(-35,0),Vector2(0,35),Vector2(0,-35),Vector2(24,24),Vector2(-24,24),Vector2(12,0)]:
   g.player=tree.pos+offset
   var copy=tree.duplicate();copy.kind='hedge_tree_apples';copy.integrated_tree=true
   if g.interaction_reachable(copy):target=tree;found=true;break
  if found:break
 assert(found)
 g.camera=g.player;g.queue_redraw()
 await create_timer(.4).timeout;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png('/tmp/tree-outline-review.png')
 var variant=posmod(floori(target.pos.x/48)*17+floori(target.pos.y/48)*7,6)
 assert(g.outlines.has('hedge_tree_apples'+str(variant)))
 print('PASS mixed tree rooms and variant-specific apple proximity outline')
 quit()
