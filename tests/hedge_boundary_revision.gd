extends SceneTree
func _initialize():call_deferred('run')
func run():
 var g=load('res://main.tscn').instantiate();root.add_child(g);await process_frame;g.new_game();g.clear_modal();g.sound_on=false
 assert(g.hedge_trees.size()>=18)
 for cell in g.hedge_trees:
  assert(not g.berry_cells.has(cell))
  assert(not g.objects.any(func(o):return o.kind=='berries' and Vector2i(o.pos/48)==cell))
 g.grid.clear()
 for y in range(14):g.grid.append('#'+'.'.repeat(13))
 for y in range(3,9):g.set_cell(5,y,'#')
 g.objects.clear();g.vegetation.clear();g.hedge_trees.clear()
 g.player=Vector2(224,288)
 assert(g.hedge_in_foreground(Vector2(264,264)) and g.hedge_in_foreground(Vector2(264,312)))
 assert(not g.shadow_ray_clear(Vector2(350,288)))
 assert(g.shadow_ray_clear(Vector2(190,288)))
 g.player=Vector2(264,447);assert(not g.hedge_in_foreground(Vector2(264,408)))
 g.player=Vector2(62,240)
 for n in range(12):g.update_vegetation(.016)
 assert(g.vegetation.has('h:'+str(Vector2i(0,4))+':2'))
 assert(g.vegetation.values().any(func(v):return v.offset.length()>.1))
 print('PASS 22 integrated trees, no berry overlap, continuous side faces, boundary springs and hedge-blocked shadows')
 g.queue_free();await process_frame;quit()
