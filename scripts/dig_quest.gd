extends RefCounted
## A saved, room-local gathering and crafting chain. Positions use final room coordinates.
var g:Node2D
func _init(game:Node2D):g=game
func state()->Dictionary:
 if not g.save_data.has("dig_quest") or g.save_data.dig_quest.is_empty():
  g.save_data.dig_quest={"layout":{},"hits":0,"tree_hits":randi_range(5,7),"tree_down":false,"branches":0,"pebbles":0,"gathered":[],"pickaxe":false,"rock_hits":0,"rock_broken":false,"rock_taken":false,"shovel":false,"broken":false,"uses":0,"durability":randi_range(3,6)}
 return g.save_data.dig_quest
func owns(obj:Dictionary)->bool:return obj.kind.begins_with("quest_") or obj.kind=="pickaxe" or (g.level==3 and obj.id=="shovel")
func point(id:String)->Vector2:
 var a:Array=state().layout[id];return Vector2(a[0],a[1])
func install()->void:
 if g.level!=3:return
 var d:=state()
 if g.held_item=="shovel" and not d.shovel:g.held_item="";g.sync_hands()
 if d.layout.is_empty():
  var rng:=RandomNumberGenerator.new();rng.seed=int(g.save_data.seed)^912321
  d.layout.tree=[13.5*48,11.5*48]
  var choices:Array[Vector2]=[]
  for y in range(8,15):
   for x in range(3,24):
    var p:=Vector2(x+.5,y+.5)*48
    if p.distance_to(point("tree"))>135 and not g.objects.any(func(o):return o.pos.distance_to(p)<95):choices.append(p)
  for id in ["bench","axe","rock"]:
   var p:Vector2=choices[rng.randi_range(0,choices.size()-1)];d.layout[id]=[p.x,p.y]
   choices=choices.filter(func(q):return q.distance_to(p)>120)
 g.objects.assign(g.objects.filter(func(o):return not owns(o)))
 add("quest_bench","bench",point("bench"),true)
 add("quest_stump" if d.tree_down else "quest_tree","tree",point("tree"),true)
 if not d.rock_taken:add("quest_rock_fragments" if d.rock_broken else "quest_rock","rock",point("rock"),not d.rock_broken)
 for n in range(3):
  if d.tree_down and "branch"+str(n) not in d.gathered:add("quest_branch","branch"+str(n),scatter("tree",n))
  if "pebble"+str(n) not in d.gathered:add("quest_pebble","pebble"+str(n),scatter("rock",n))
 for tool in ["quest_axe","pickaxe","shovel"]:
  if tool=="pickaxe" and not d.pickaxe:continue
  if tool=="shovel" and not d.shovel:continue
  var key:String="3:"+str(tool)
  var a:Array=g.save_data.tool_positions.get(key,d.layout.axe if tool=="quest_axe" else [point("bench").x+40,point("bench").y+30])
  add(tool,tool,Vector2(a[0],a[1]))
func scatter(origin:String,n:int)->Vector2:
 var rng:=RandomNumberGenerator.new();rng.seed=int(g.save_data.seed)^hash(origin)^((n+1)*7169)
 var angle:=rng.randf_range(0,TAU)
 return point(origin)+Vector2(cos(angle),sin(angle))*rng.randf_range(48,78)
func toss(tool:String)->void:
 var p:Vector2=g.item_drop_spot(point("bench")+Vector2.from_angle(randf_range(0,TAU))*randf_range(40,65))
 g.save_data.tool_positions["3:"+tool]=[p.x,p.y]
 install()
 for obj in g.objects:
  if obj.id==tool:obj.flight_start=g.time;obj.flight_duration=.65;obj.flight_from=point("bench")
func add(kind:String,id:String,pos:Vector2,solid:bool=false)->void:g.objects.append({"kind":kind,"id":id,"pos":pos,"solid":solid})
func available(obj:Dictionary)->bool:
 if obj.kind in ["quest_axe","pickaxe","shovel"]:return g.held_item!=obj.id
 match obj.kind:
  "quest_tree":return g.held_item=="quest_axe" or g.held_item=="axe"
  "quest_rock":return g.held_item=="pickaxe"
  "quest_stump","quest_falling":return false
 return true
func name_for(obj:Dictionary)->String:
 if obj.kind=="shovel":return g.tx("item_broken_shovel" if state().broken else "item_shovel")
 match obj.kind:
  "quest_axe":return g.tx("item_axe")
  "pickaxe":return g.tx("item_pickaxe")
  "quest_tree":return g.tx("item_tree")
  "quest_bench":return g.tx("item_workbench")
  "quest_branch":return g.tx("item_branch")
  "quest_pebble":return g.tx("item_pebble")
  "quest_rock":return g.tx("item_large_rock")
  "quest_rock_fragments":return g.tx("item_rock_material")
 return ""

func action_for(obj:Dictionary)->String:
 if obj.kind=="quest_tree":return g.tx("chop_tree")
 if obj.kind=="quest_rock":return g.tx("mine_rock")
 if obj.kind=="quest_bench":return g.tx("repair_shovel" if state().broken else "craft_shovel" if state().pickaxe else "craft_pickaxe")
 return g.tx("pickup_material")
func use(obj:Dictionary)->bool:
 if not owns(obj):return false
 var d:=state()
 match obj.kind:
  "quest_tree":g.begin_task("quest_chop",obj.pos,.48)
  "quest_rock":g.begin_task("quest_mine",obj.pos,.55)
  "quest_branch":d.branches+=1;d.gathered.append(obj.id);g.objects.erase(obj);g.sfx("ui")
  "quest_pebble":d.pebbles+=1;d.gathered.append(obj.id);g.objects.erase(obj);g.sfx("ui")
  "quest_rock_fragments":d.rock_taken=true;g.objects.erase(obj);g.sfx("ui")
  "quest_bench":
   if d.broken:g.begin_task("quest_repair",obj.pos,1.0)
   elif not d.pickaxe:
    if d.branches<3 or d.pebbles<3:g.notify(g.tx("craft_pickaxe_requirements"));return true
    g.begin_task("quest_pickaxe",obj.pos,1.0)
   elif not d.shovel:
    if not d.rock_taken:g.notify(g.tx("craft_shovel_requirements"));return true
    g.begin_task("quest_shovel",obj.pos,1.0)
   else:g.notify(g.tx("workbench_ready"))
  "quest_axe","pickaxe","shovel":g.equip_tool(obj.id)
  _:return true
 g.persist();g.find_nearest();return true
func complete(kind:String,pos:Vector2)->bool:
 if not kind.begins_with("quest_"):return false
 var d:=state()
 match kind:
  "quest_chop":
   d.hits+=1;g.burst(pos,8,Color("b7a282"))
   if d.hits>=d.tree_hits:
    d.tree_down=true;install();add("quest_falling","falling",pos);g.objects[-1].age=0.0
  "quest_mine":
   d.rock_hits+=1;g.burst(pos,12,Color("a8a7a6"))
   if d.rock_hits>=4:d.rock_broken=true;install()
  "quest_pickaxe":d.pickaxe=true;toss("pickaxe")
  "quest_shovel":d.shovel=true;toss("shovel")
  "quest_repair":d.broken=false;d.uses=0;d.durability=randi_range(3,6);equip("shovel")
 return true
func equip(tool:String)->void:
 g.equip_tool(tool);g.persist()
func wear_shovel()->void:
 if g.level!=3 or g.held_item!="shovel":return
 var d:=state();d.uses+=1
 if d.uses>=d.durability:d.broken=true;g.notify(g.tx("shovel_needs_repair"));g.sfx("axe")
func blocks(pos:Vector2)->bool:
 if g.level!=3:return false
 for obj in g.objects:
  if obj.kind=="quest_stump" and (pos-obj.pos).length()<22:return true
  if obj.kind=="quest_tree" and (pos-obj.pos).length()<35:return true
  if obj.kind=="quest_bench" and Rect2(obj.pos-Vector2(39,23),Vector2(78,40)).has_point(pos):return true
 return false
func update(delta:float)->void:
 if g.level!=3 or g.paused:return
 for obj in g.objects:
  if obj.kind=="quest_falling":obj.age+=delta
 g.objects.assign(g.objects.filter(func(o):return o.kind!="quest_falling" or o.age<1.8))
func draw_falling(obj:Dictionary,p:Vector2)->void:
 var t:=clampf(float(obj.age)/1.8,0,1)
 g.draw_set_transform(p,t*t*1.35)
 g.draw_sprite("quest_tree",Vector2.ZERO,Color(1,1,1,1-smoothstep(.45,1.0,t)))
 g.draw_set_transform(Vector2.ZERO)

func damage_texture(name:String)->String:
 if g.level!=3:return name
 if name=="quest_tree" and state().hits>0:return "quest_tree_damage"+str(clampi(int(state().hits),1,6))
 if name=="quest_rock" and state().rock_hits>0:return "quest_rock_damage"+str(clampi(int(state().rock_hits),1,3))
 return name
