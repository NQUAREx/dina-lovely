extends RefCounted
var g:Node2D
var textures:Dictionary={}
func _init(game:Node2D):g=game
func stamp(owner:int,point:Vector2)->void:
 if not g.get_viewport_rect().grow(110).has_point(point):return
 var key:="wall_room%d_exposed"%owner
 if not textures.has(key):textures[key]=load("res://assets/"+key+".png")
 var texture:Texture2D=textures[key]
 var foundation:=Color("203b31") if owner in [0,1] else Color("493127") if owner==3 else Color("57412b") if owner==5 else Color("453d50")
 g.draw_rect(Rect2(point-Vector2(24,24),Vector2(48,48)),foundation)
 var tint:=Color(.65,.65,.65,1)
 g.draw_texture_rect_region(texture,Rect2(point+Vector2(-32,-70),Vector2(64,68)),Rect2(0,0,32,34),tint)
 g.draw_texture_rect_region(texture,Rect2(point+Vector2(-32,-2),Vector2(64,36)),Rect2(0,34,32,30),tint)
func draw()->void:
 var width:int=g.grid[0].length()
 var height:int=g.grid.size()
 for ring in [1,2]:
  for y in range(5-ring,height-5+ring):
   for x in range(-ring,width+ring):
    if x>=0 and x<width and y>=5 and y<height-5:continue
    var center:=15 if g.level==0 and y<5 else 13
    if (y<5 and g.level<6 or y>=height-5 and g.level>0) and absi(x-center)<=2:continue
    var p:Vector2=g.screen(Vector2(x+.5,y+.5)*48)
    # Junction aprons exist in both cached rooms; their material follows
    # the same upper-room owner as the shared corridor, never active level.
    stamp(g.boundary_room(y) if g.corridor_row(y) else g.level,p)
 # Corridor texture must continue beyond its actual outer wall too. Otherwise
 # the transparent edge ends before the72px fog reaches full opacity.
 if g.drawing_neighbor:return
 var first:=maxi(-5,floori((g.camera.y-g.get_viewport_rect().size.y/2)/48)-3)
 var last:=mini(height+5,ceili((g.camera.y+g.get_viewport_rect().size.y/2)/48)+3)
 for y in range(first,last):
  if not g.corridor_row(y):continue
  var center:=15 if g.level==0 and y<5 else 13
  var owner:int=g.boundary_room(y)
  for side in [-1,1]:
   for ring in [3,4]:stamp(owner,g.screen(Vector2(center+side*ring+.5,y+.5)*48))
