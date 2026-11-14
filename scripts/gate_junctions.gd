extends RefCounted
## Junction art and the cell reservation use the same orthogonal wall footprint.
var g:Node2D
var textures:Dictionary={}
func _init(game:Node2D):g=game
func room_material()->String:return "stone" if g.level in [1,2,4] else "hedge"
func corridor_material(door:Dictionary)->String:
 return "tree" if (g.level==5 and door.id=="exit") or (g.level==6 and door.id=="back") else "stone"
func prepare()->void:
 for door in g.objects:
  if door.kind!="doorway":continue
  var cell:=Vector2i(door.pos/48);var inside:=1 if door.id=="exit" else -1
  for side in [-2,2]:
   g.set_cell(cell.x+side,cell.y,".")
   g.set_cell(cell.x+side,cell.y+inside,".")
   g.set_cell(cell.x+side,cell.y-inside,"#")
func skip_wall(cell:Vector2i)->bool:
 var north:=15 if g.level==0 else 13
 if g.level<6 and cell.y in [3,4] and absi(cell.x-north)==2:return true
 return g.level>0 and cell.y==g.grid.size()-5 and absi(cell.x-13)==2
func draw(door:Dictionary,pos:Vector2)->void:
 var room:=room_material();var corridor:=corridor_material(door);var end:="top" if door.id=="exit" else "bottom"
 for side in ["left","right"]:
  var key:="junction_%s_%s_%s_%s"%[room,corridor,end,side]
  if not textures.has(key):textures[key]=load("res://assets/"+key+".png")
  var x:=-96.0 if side=="left" else 96.0
  g.draw_texture_rect(textures[key],Rect2(pos+Vector2(x-48,-160),Vector2(96,224)),false)
