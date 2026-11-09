extends SceneTree
func _initialize():call_deferred('run')
func run():
 var g=load('res://main.tscn').instantiate();root.add_child(g);await process_frame;g.new_game();g.clear_modal();g.sound_on=false
 g.build_level(5);g.save_data.letters.append('garden');g.use_exit()
 var gate=g.objects.filter(func(o):return o.kind=='doorway' and o.id=='exit')[0];gate.gate_amount=1
 assert(g.blocked(gate.pos+Vector2(-35,0)));assert(g.blocked(gate.pos+Vector2(65,5)));assert(not g.blocked(gate.pos+Vector2(24,0)));assert(not g.available(gate))
 for y in range(-24,25,4):assert(not g.blocked(gate.pos+Vector2(24,y)))
 g.build_level(1);var pond=g.objects.filter(func(o):return o.kind=='pond')[0]
 assert(g.blocked(pond.pos+Vector2(0,-95)));assert(not g.blocked(pond.pos+Vector2(0,-120)))
 assert(g.objects.filter(func(o):return o.id=='back').all(func(o):return not g.available(o)))
 g.build_level(0);assert(not g.hedge_trees.is_empty())
 for tree in g.hedge_trees.values():assert(tree.integrated_hedge)
 g.build_level(4);assert(g.objects.filter(func(o):return o.kind in ['crate','column']).size()>=8)
 g.weapon='rpg';g.combat_done=false;g.attack_cd=0;g.rpg_reload=0;g.attack();assert(g.shots.is_empty() and g.rpg_windup>0)
 var before=g.player;g.rpg_windup=-1;g.attack(true);assert(g.shots.size()==1 and g.player.distance_to(before)>10)
 print('PASS gate leaf collision and walking gap, pond footprint, no corridor buttons, integrated hedges, extra props and RPG windup')
 g.queue_free();await process_frame;quit()
