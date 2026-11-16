extends Node2D
## Pillars are foreground architecture, not holes cut out of the fog shape.
var g:Node2D
var textures:Dictionary={}
func _ready()->void:
 g=get_parent();z_index=101
func _process(_delta:float)->void:queue_redraw()
func posts(objects:Array,origin:Vector2)->void:
 for door in objects:
  if door.kind!="doorway":continue
  var pos:Vector2=g.screen(door.pos+origin)
  if not Rect2(pos-Vector2(144,160),Vector2(288,224)).intersects(g.get_viewport_rect()):continue
  for side in [-1,1]:
   var key:="junction_stone_stone_%s_%s"%["top" if door.id=="exit" else "bottom","left" if side<0 else "right"]
   if not textures.has(key):textures[key]=load("res://assets/"+key+".png")
   draw_texture_rect(textures[key],Rect2(pos+Vector2(side*96-48,-160),Vector2(96,224)),false)
func _draw()->void:
 if g==null or g.grid.is_empty():return
 posts(g.objects,Vector2.ZERO)
 for next in [g.level-1,g.level+1]:
  if next<0 or next>6 or not g.room_cache.has(next):continue
  var state:Dictionary=g.room_cache[next]
  var north:bool=next>g.level
  var center:float=(15.5 if g.level==0 else 13.5)*48 if north else 13.5*48
  var other:float=13.5*48 if north else (15.5 if next==0 else 13.5)*48
  posts(state.objects,Vector2(center-other,-state.grid.size()*48 if north else g.grid.size()*48))
