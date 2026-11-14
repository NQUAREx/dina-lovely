extends RefCounted
var g:Node2D
var textures:Dictionary={}
func _init(game:Node2D):g=game
func tex(name:String)->Texture2D:
 if not textures.has(name):textures[name]=load("res://assets/reference_"+name+".png")
 return textures[name]
func wall_cell(x:int,y:int)->bool:
 if g.grid[y][x]!="#":return false
 return g.level in [1,2,4] or g.corridor_row(y) or x==0 or x==g.grid[0].length()-1 or y in [5,g.grid.size()-6]
func draw_wall(item:Dictionary,p:Vector2)->void:
 var vertical:=true
 if item.has("cell"):
  var c:Vector2i=item.cell
  vertical=c.x in [0,g.grid[0].length()-1] or g.corridor_row(c.y)
 var cell:Vector2i=item.get("cell",Vector2i((item.pos/48).floor()))
 if not vertical and g.level not in [1,2,4]:p.y-=24
 var name:="wall_h"+str(posmod(cell.x,3))
 if vertical:
  var row:int=cell.y
  for room in range(1,g.level+1):
   if g.room_cache.has(room):row-=g.room_cache[room].grid.size()
  name="wall_v"+str(posmod(row,2))
  var side:float=-1 if cell.x<g.grid[0].length()/2 else 1
  g.draw_colored_polygon(PackedVector2Array([p+Vector2(side*24,-104),p+Vector2(side*40,-120),p+Vector2(side*40,-8),p+Vector2(side*24,8)]),Color("393447"))
 g.draw_rect(Rect2(p+Vector2(-24,6),Vector2(48,6)),Color(0.08,0.07,0.12,.22))
 g.draw_texture_rect(tex(name),Rect2(p+Vector2(-24,-104),Vector2(48,112)),false)
func pillars(door:Dictionary,p:Vector2)->void:
 for side in [-96,96]:g.draw_texture_rect(tex("pillar"),Rect2(p+Vector2(side-32,-150),Vector2(64,160)),false)
func lintel(p:Vector2)->void:g.draw_texture_rect(tex("gate_top"),Rect2(p+Vector2(-128,-150),Vector2(256,64)),false)
