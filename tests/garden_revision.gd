extends SceneTree
func _initialize():call_deferred('run')
func run():
 var g=load('res://main.tscn').instantiate();root.add_child(g);await process_frame;g.new_game();g.clear_modal();g.build_level(5)
 assert(g.objects.any(func(o):return o.id=='rake'));g.save_data.rake=true;g.begin_task('rake:0',Vector2.ZERO,1.0);g.update_tasks(1.1);assert('0' in g.save_data.cleaned)
 g.plants['0']={'stage':0,'remaining':.1}
 for stage in [1,2,3]:
  g.plants['0'].remaining=.1
  g.update_plants(.2)
  assert(g.plants['0'].stage==stage and ('0' in g.watered)==(stage==3))
 g.plants['1']={'stage':1,'remaining':0.0}
 g.plants['2']={'stage':2,'remaining':0.0}
 g.plants['3']={'stage':0,'remaining':0.0}
 g.update_plants(8.9)
 assert(g.plants['1'].stage==1 and g.plants['2'].stage==2)
 g.update_plants(.11)
 for id in ['1','2']:assert(g.plants[id].stage==0 and g.plants[id].withered)
 assert(g.plants['0'].stage==3 and not g.plants['3'].has('withered'))
 print('PASS three waterings, nine-second drying for intermediate stages only')
 g.content.ui.new_game.text='LIVE TEST';assert(g.tx('new_game')=='LIVE TEST');print('PASS editable UI lookup');quit()
