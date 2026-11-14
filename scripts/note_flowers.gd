extends RefCounted
## Ground-only flowers. Growth is sampled at 20 Hz, independent of rendering FPS.
var g:Node2D
var plots:Dictionary={}
var grounds:Dictionary={}
var flowers:Dictionary={}
var seed_value:=-1
var clock:=0.0
func _init(game:Node2D):g=game
func update(delta:float)->void:
 if g.save_data.is_empty() or g.grid.is_empty():return
 if seed_value!=int(g.save_data.seed):plots.clear();grounds.clear();seed_value=int(g.save_data.seed)
 if g.level in [4,6]:return
 clock+=delta
 if clock<.05:return
 var elapsed:=clock
 clock=0.0
 for obj in g.objects:
  if obj.kind!="note" or obj.id not in g.save_data.letters:continue
  var key:=str(g.level)+":"+str(obj.id)
  if not plots.has(key):
   plots[key]=make_plot(obj)
   if key in g.save_data.flower_notes:plots[key].age=3.0
  var plot:Dictionary=plots[key]
  plot.age=minf(3,float(plot.age)+elapsed) if g.playing else plot.age
  if plot.age>=3 and key not in g.save_data.flower_notes:g.save_data.flower_notes.append(key);g.persist()
 bake()
func make_plot(note:Dictionary)->Dictionary:
 var rng:=RandomNumberGenerator.new();rng.seed=seed_value^hash(str(note.id))
 var points:Array[Dictionary]=[]
 for n in range(52):
  var angle:=n*2.399963+ rng.randf_range(-.2,.2)
  var radius:=24+sqrt((n+.5)/52.0)*70
  var p:Vector2=(note.pos+Vector2(cos(angle),sin(angle))*radius).snapped(Vector2(2,2))
  var cell:=Vector2i(p/48)
  if not g.valid_ground(p) or g.corridor_row(cell.y) or g.grid[cell.y][cell.x]!="." or g.blocked(p):continue
  if g.objects.any(func(o):return o!=note and o.kind!="dug" and o.pos.distance_to(p)<(95 if o.kind in ["house","pond","quest_tree"] else 58 if o.kind in ["well","sprout"] else 32)):continue
  points.append({"pos":p,"variant":rng.randi_range(0,5)})
 return {"room":g.level,"age":0.0,"points":points}
func bake()->void:
 if g.grass_texture==null:return
 var room:=str(g.level)
 if not grounds.has(room) or grounds[room].texture!=g.grass_texture:
  grounds[room]={"texture":g.grass_texture,"image":g.grass_texture.get_image(),"counts":{}}
 var ground:Dictionary=grounds[room]
 var changed:=false
 for key in plots:
  var plot:Dictionary=plots[key]
  if plot.room!=g.level:continue
  var count:=mini(plot.points.size(),ceili(float(plot.age)/3*plot.points.size()))
  for n in range(int(ground.counts.get(key,0)),count):
   var flower:Dictionary=plot.points[n]
   var variant:int=flower.variant
   if not flowers.has(variant):
    var id:int=g.sprites["note_flower"+str(variant)]
    flowers[variant]=g.label_atlas_pixels.get_region(Rect2i(id%16*32+13,id/16*48+36,7,9))
   var image:Image=flowers[variant]
   ground.image.blit_rect_mask(image,image,Rect2i(0,0,7,9),Vector2i(flower.pos/2)+Vector2i(-3,-7))
   changed=true
  ground.counts[key]=count
 if changed:ground.texture.update(ground.image)
