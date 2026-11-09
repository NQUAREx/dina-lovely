extends SceneTree
var g
func _initialize():call_deferred('run')
func run():
 g=load('res://main.tscn').instantiate();root.add_child(g);await process_frame;g.new_game();g.clear_modal();g.sound_on=false
 var berries=g.objects.filter(func(o):return o.kind=='berries');assert(berries.size()>0)
 for b in berries:assert(g.grid[int(b.pos.y/48)][int(b.pos.x/48)]=='#')
 var secret=g.objects.filter(func(o):return o.id=='secret_moon')[0];assert(g.grid[int(secret.pos.y/48)][int(secret.pos.x/48)]=='#');g.player=Vector2.ZERO;assert(not g.available(secret));g.player=secret.pos+Vector2(30,0);assert(g.available(secret));print('PASS berry hedges and hidden secrets')
 g.player=secret.pos+Vector2(35,0);g.update_vegetation(.04);assert(g.vegetation.size()>0);print('PASS hedge spring response')
 var tested=false
 for b in berries:
  var c=Vector2i(b.pos/48)
  if g.grid[c.y][c.x-1]=='.':
   assert(not g.blocked(Vector2(c.x*48-4,b.pos.y)));assert(g.blocked(Vector2(c.x*48+8,b.pos.y)));tested=true;break
 assert(tested);print('PASS soft hedge edge with solid core')
 var flower={'kind':'flowers','id':'','pos':g.player+Vector2(10,0),'solid':false};g.objects.append(flower);g.update_vegetation(.04);assert(flower.bend.length()>0);print('PASS flower parting')
 g.build_level(2);assert(g.grid.size()==39);assert(abs(g.obstacle_rect(1).get_center().y-g.obstacle_rect(0).get_center().y-4.4*48)<.1)
 var specs=g.obstacle_specs.duplicate(true);g.new_game();g.clear_modal();g.sound_on=false;g.build_level(2);assert(specs!=g.obstacle_specs);print('PASS doubled spacing and seeded random beams')
 g.build_level(5);assert(g.paths.size()>=8);assert(g.sprites.has('bud0_0') and g.sprites.has('bud5_1'));print('PASS garden paths and distinct growth sprites')
 g.build_level(4);g.weapon='rifle';g.enemies.clear();g.player=Vector2(13,16)*48
 g.enemies.append({'pos':Vector2(600,550),'hp':10,'type':0,'state':'chase','timer':0.,'cooldown':0.})
 g.shots.append({'pos':Vector2(450,534),'vel':Vector2(2000,0),'life':2.,'kind':'rifle','age':0.})
 g.update_shots(.15);assert(g.enemies[0].hp==9 and g.shots.is_empty());print('PASS swept rifle hit across low-FPS frame')
 g.attack_flash=0;g.move_player(.01,Vector2.LEFT);assert(g.aim.x<0 and g.direction==1);g.attack_cd=0;g.attack();assert(g.direction in [0,3]);print('PASS movement aim and attack facing')
 g.queue_free();await process_frame;quit()
