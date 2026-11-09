extends SceneTree
const Field=preload('res://scripts/hedge_field.gd')
func _initialize():call_deferred('run')
func check_packing(field, moving=false):
 for i in range(field.crowns.size()):
  var a=field.crowns[i];var ra=float(a.radius)*(1-float(a.press)*.07 if moving else 1)
  for j in field.near_ids(a.base,38):
   if j<=i:continue
   var b=field.crowns[j];var rb=float(b.radius)*(1-float(b.press)*.07 if moving else 1)
   assert((a.base+a.offset).distance_to(b.base+b.offset)>=ra+rb-.001)
func run():
 var map:Array[String]=[]
 for y in range(16):map.append('.'.repeat(18))
 for y in range(2,14):map[y]='...#'+'.'.repeat(14)
 for x in range(3,15):map[8]=map[8].substr(0,x)+'#'+map[8].substr(x+1)
 var field=Field.new();field.build(map,541,{},{});check_packing(field)
 var fingerprint=field.crowns.map(func(n):return [n.base,n.radius])
 assert(field.chains.size()>=3 and field.crowns.size()>100)
 var player=Vector2(3.5*48-18.5,6*48)
 assert(not field.blocks(player));assert(field.blocks(player+Vector2(3,0)));assert(field.foreground(player))
 assert(not field.foreground(Vector2(3.5*48,13.5*48+16)))
 for n in range(40):field.update(.016,player)
 assert(field.crowns.any(func(node):return node.offset.length()>.1));check_packing(field,true)
 for n in range(180):field.update(.016,Vector2(800,800))
 check_packing(field,true)
 field.build(map,541,{},{});assert(field.crowns.map(func(n):return [n.base,n.radius])==fingerprint)
 field.build(map,542,{},{});assert(field.crowns.map(func(n):return [n.base,n.radius])!=fingerprint)
 print('PASS continuous graph, non-overlapping rest/moving crowns, deterministic packing, side/south layering and sealed core')
 quit()
