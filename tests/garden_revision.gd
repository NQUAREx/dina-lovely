extends SceneTree
func _initialize():call_deferred('run')
func run():
 var g=load('res://main.tscn').instantiate();root.add_child(g);await process_frame;g.new_game();g.clear_modal();g.build_level(5)
 assert(g.objects.any(func(o):return o.id=='rake'));g.save_data.rake=true;g.begin_task('rake:0',Vector2.ZERO,1.0);g.update_tasks(1.1);assert('0' in g.save_data.cleaned)
 g.plants['0']={'stage':0,'remaining':.1};g.update_plants(.2);assert(g.plants['0'].stage==1);g.plants['0'].remaining=.1;g.update_plants(.2);assert('0' in g.watered);print('PASS rake cleaning and two growth stages')
 g.content.ui.new_game.text='LIVE TEST';assert(g.tx('new_game')=='LIVE TEST');print('PASS editable UI lookup');quit()
