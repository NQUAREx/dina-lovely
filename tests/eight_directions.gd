extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame
 g.clear_modal();g.set_process(false);g.set_physics_process(false)
 var seen:Array=[]
 for i in range(8):
  var v:=Vector2.from_angle(i*PI/4);var facing:int=g.facing_octant(v);seen.append(facing)
  g.walk_facing=v;g.weapon="";assert(g.visual_facing()==facing)
  for frame in range(4):
   assert(g.sprites.has("hero%d_%d"%[facing,frame]) and g.sprites.has("cat_walk%d_%d"%[facing,frame]))
   for accessory in g.OUTFIT_ORDER:assert(g.sprites.has("wear_%s_%d_%d"%[accessory,facing,frame]))
  for frame in range(3):assert(g.sprites.has("cat_idle%d_%d"%[facing,frame]))
 assert(seen.size()==8 and seen.all(func(d):return seen.count(d)==1))
 g.weapon="rifle";g.attack_flash=.1;g.aim=Vector2(-1,-1);assert(g.visual_facing()==4)
 print("PASS eight distinct facings, all walking/idle sprites, complete accessory layers and aimed diagonal pose")
 quit()
