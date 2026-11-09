extends SceneTree
var g
func _initialize():call_deferred('run')
func pickup(id):
 for i in range(g.objects.size()):
  if g.objects[i].id==id:g.player=g.objects[i].pos;g.nearest=i;g.interact();return
 assert(false,'missing '+id)
func run():
 g=load('res://main.tscn').instantiate();root.add_child(g);await process_frame;g.new_game();g.clear_modal();g.build_level(5)
 pickup('rake');assert(g.held_item=='rake' and g.save_data.rake)
 var at=g.player;pickup('can');assert(g.held_item=='can' and not g.save_data.rake and g.garden_can);assert(g.objects.any(func(o):return o.id=='rake' and o.pos.distance_to(g.player+Vector2(0,25))<1))
 pickup('fertilizer');assert(g.has_fertilizer and not g.garden_can);g.persist();g.build_level(5);assert(g.held_item=='fertilizer' and not g.garden_can);print('PASS one hand, drops, persistence')
 var beds=g.objects.filter(func(o):return o.kind=='sprout');assert(beds.size()==6)
 var positions=beds.map(func(o):return o.pos);g.build_level(5);assert(positions==g.objects.filter(func(o):return o.kind=='sprout').map(func(o):return o.pos));print('PASS stable random garden')
 g.begin_task('rake:0',Vector2(200,200),1.0);g.update_tasks(1.1);assert('0' in g.save_data.cleaned)
 pickup('seat');assert(g.resting=='seat');g.interact();assert(g.resting.is_empty() and not g.blocked(g.player));pickup('swing');assert(g.resting=='swing');g.interact();print('PASS seat, swing and stand up')
 g.return_held_tool();g.build_level(4);pickup('rifle');g.enemies.clear();g.magazine=30;g.reload_time=0
 for n in range(30):g.attack_cd=0;g.attack()
 assert(g.magazine==0 and g.reload_time>0 and g.shots.size()==30);g.attack_cd=0;g.attack();assert(g.shots.size()==30);g._physics_process(2.0);assert(g.magazine==30 and g.reload_time==0);print('PASS 30-round magazine and reload')
 g.aim=Vector2.LEFT;assert(g.rifle_muzzle().x<g.player.x+14);g.aim=Vector2.RIGHT;assert(g.rifle_muzzle().x>g.player.x+14)
 g.return_held_tool();assert(g.held_item.is_empty() and g.weapon.is_empty() and g.save_data.loose_weapons.size()>0);print('PASS muzzle directions and weapon drop')
 g.build_level(0);var note=g.objects.filter(func(o):return o.kind=='note')[0];g.player=note.pos;g.collect(note.id);assert(note.id in g.save_data.letters);assert(g.objects.any(func(o):return o.id==note.id));await create_timer(1.7).timeout;assert(is_instance_valid(g.modal));g.clear_modal();print('PASS physical letter and persistent envelope')
 quit()
