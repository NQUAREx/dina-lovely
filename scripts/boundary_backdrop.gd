extends RefCounted
var g:Node2D
var textures:Dictionary={}
func _init(game:Node2D):g=game
func stamp(owner:int,point:Vector2)->void:
 if not g.get_viewport_rect().grow(110).has_point(point):return
 var cell:=Vector2i(floori((point+g.camera-g.get_viewport_rect().size/2).x/48),floori((point+g.camera-g.get_viewport_rect().size/2).y/48))
 var layout:Dictionary=g.boundary_layout(cell,owner)
 var key:="wall_room%d_%s"%[owner,"exposed" if owner in [0,1,3] else "stacked"]
 if layout.variant>0:key+=str(layout.variant)
 if owner in [1,3]:point+=Vector2(layout.jitter)
 if layout.mirror and owner in [1,3]:g.draw_set_transform(point,0,Vector2(-1,1));point=Vector2.ZERO
 if not textures.has(key):textures[key]=load("res://assets/"+key+".png")
 var texture:Texture2D=textures[key]
 var foundation:=Color("203b31") if owner in [0,1] else Color("493127") if owner==3 else Color("57412b") if owner==5 else Color("453d50")
 g.draw_rect(Rect2(point-Vector2(24,24),Vector2(48,48)),foundation)
 var tint:=Color.WHITE
 g.draw_texture_rect_region(texture,Rect2(point+Vector2(-32,-70),Vector2(64,68)),Rect2(0,0,32,34),tint)
 g.draw_texture_rect_region(texture,Rect2(point+Vector2(-32,-2),Vector2(64,36)),Rect2(0,34,32,30),tint)
 if layout.mirror and owner in [1,3]:g.draw_set_transform(Vector2.ZERO)
func draw()->void:
 if g.level==0:draw_outer_hedge()
 var width:int=g.grid[0].length()
 var height:int=g.grid.size()
 if g.level in [2,4,5,6]:
  var left:int=8 if g.level==2 else 0
  var right:int=18 if g.level==2 else width-1
  for y in range(4,height-4):
   for x in range(left-1,right+2):
    if x>=left and x<=right and y>=5 and y<height-5:continue
    if (y<5 or y>=height-5) and absi(x-13)<=2:continue
    stamp(g.level,g.screen(Vector2(x+.5,y+.5)*48))
 # One outer band: nested rings used to stamp the same cells twice.
 for ring in [2]:
  for y in range(5-ring,height-5+ring):
   for x in range(-ring,width+ring):
    if x>=0 and x<width and y>=5 and y<height-5:continue
    var center:=15 if g.level==0 and y<5 else 13
    if (y<5 and g.level<6 or y>=height-5 and g.level>0) and absi(x-center)<=4:continue
    var p:Vector2=g.screen(Vector2(x+.5,y+.5)*48)
    # Junction aprons exist in both cached rooms; their material follows
    # the same upper-room owner as the shared corridor, never active level.
    var owner:int=g.boundary_room(y) if g.corridor_row(y) else g.level
    if not g.corridor_row(y) and owner!=1:continue
    stamp(owner,p)
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

func draw_outer_hedge()->void:
 if g.hedge_field==null:return
 var width:float=g.grid[0].length()*48
 var height:float=g.grid.size()*48
 for crown in g.hedge_field.crowns:
  var base:Vector2=crown.base
  var offsets:Array[Vector2]=[]
  if base.x<48:offsets.append(Vector2(-48,0))
  if base.x>width-48:offsets.append(Vector2(48,0))
  if base.y<6*48 and absf(base.x-15.5*48)>120:offsets.append(Vector2(0,-48))
  if base.y>height-6*48:offsets.append(Vector2(0,48))
  for offset in offsets:
   var centre:Vector2=g.screen((base+offset).round()-Vector2(0,16))
   if not g.get_viewport_rect().grow(48).has_point(centre):continue
   var id:int=g.sprites["crown_leaf_"+str(crown.variant)]
   var radius:float=roundf(crown.radius*1.48)
   g.draw_texture_rect_region(g.atlas,Rect2(centre-Vector2.ONE*radius,Vector2.ONE*radius*2),Rect2(Vector2(id%16*32+8,id/16*48+24),Vector2(17,17)))
