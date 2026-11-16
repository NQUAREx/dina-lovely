extends RefCounted
var g:Node2D
var textures:Dictionary={}
func _init(game:Node2D):g=game
func draw()->void:
 var key:="wall_room%d_exposed"%g.level
 if not textures.has(key):textures[key]=load("res://assets/"+key+".png")
 var texture:Texture2D=textures[key]
 var width:int=g.grid[0].length()
 var height:int=g.grid.size()
 for ring in [1,2]:
  for y in range(5-ring,height-5+ring):
   for x in range(-ring,width+ring):
    if x>=0 and x<width and y>=5 and y<height-5:continue
    var center:=15 if g.level==0 and y<5 else 13
    if (y<5 and g.level<6 or y>=height-5 and g.level>0) and absi(x-center)<=2:continue
    var p:Vector2=g.screen(Vector2(x+.5,y+.5)*48)
    if not g.get_viewport_rect().grow(110).has_point(p):continue
    var tint:=Color(.65,.65,.65,1)
    g.draw_texture_rect_region(texture,Rect2(p+Vector2(-32,-70),Vector2(64,68)),Rect2(0,0,32,34),tint)
    g.draw_texture_rect_region(texture,Rect2(p+Vector2(-32,-2),Vector2(64,36)),Rect2(0,34,32,30),tint)
