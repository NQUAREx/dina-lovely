extends SceneTree
func _initialize():call_deferred('run')
func run():
 var g=load('res://main.tscn').instantiate();root.add_child(g);await process_frame;g.new_game();g.clear_modal();g.build_level(2)
 var widths=[]
 for i in range(5):widths.append(g.obstacle_rect(i).size.x)
 assert(widths.size()==5 and widths.min()!=widths.max());print('PASS five varied beams')
 g.build_level(4);g.wave=4;g.spawn_wave();assert(g.wave==5 and g.enemies.size()>1);g.enemies.clear();g.spawn_wave();assert(g.wave==6 and g.enemies.size()==1)
 g.enemies[0].state='chase';g.weapon='rpg';g.damage_enemy(0,99,Vector2.ZERO);assert(g.enemies.size()==1 and g.enemies[0].hp==501);print('PASS boss survives direct RPG')
 g.enemies.clear();g.wave=0;g.spawn_wave();assert(g.enemies[0].hp>3);print('PASS tougher waves');quit()
