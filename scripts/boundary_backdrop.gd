extends RefCounted
var g:Node2D
var textures:Dictionary={}
func _init(game:Node2D):g=game
func stamp(owner:int,point:Vector2)->void:
 if not g.get_viewport_rect().grow(110).has_point(point):return
 var cell:=Vector2i(floori((point+g.camera-g.get_viewport_rect().size/2).x/48),floori((point+g.camera-g.get_viewport_rect().size/2).y/48))
 var layout:Dictionary=g.boundary_layout(cell,owner)
 var key:="wall_room%d_%s"%[owner,"exposed" if owner in [0,1] else "stacked"]
 if layout.variant>0:key+=str(layout.variant)
 if owner==1:point+=Vector2(layout.jitter)
 if layout.mirror and owner==1:g.draw_set_transform(point,0,Vector2(-1,1));point=Vector2.ZERO
 if not textures.has(key):textures[key]=load("res://assets/"+key+".png")
 var texture:Texture2D=textures[key]
 var tint:=Color.WHITE
 g.draw_texture_rect_region(texture,Rect2(point+Vector2(-32,-70),Vector2(64,68)),Rect2(0,0,32,34),tint)
 g.draw_texture_rect_region(texture,Rect2(point+Vector2(-32,-2),Vector2(64,36)),Rect2(0,34,32,30),tint)
 if layout.mirror and owner==1:g.draw_set_transform(Vector2.ZERO)
func draw_shared_corridors()->void:
 # Always use the upper room's coordinates, and render after both room floors.
 # These are visual wall cells only: keep the playable corridor floor untouched.
 var old_level:int=g.level
 var old_grid:Array=g.grid
 var old_camera:Vector2=g.camera
 for owner in [old_level,old_level+1]:
  if owner<1 or owner>6 or not g.room_cache.has(owner):continue
  var map:Array=old_grid if owner==old_level else g.room_cache[owner].grid
  var height:int=map.size()
  var offset:=Vector2.ZERO if owner==old_level else Vector2(-96 if old_level==0 else 0,height*48)
  g.level=owner;g.grid=map;g.camera=old_camera+offset
  # Reset the shared floor under wall chamfers, including extended grass.
  for y in range(height-5,height+5):
   for x in [11,15]:
    var p:Vector2=g.screen(Vector2(x,y)*48)
    g.draw_ground_region(g.ground,Rect2(p,Vector2(48,48)),Rect2(24,0,24,24))
  for y in range(height-5,height+5):
   for x in [11,15]:
    stamp(owner,g.screen(Vector2(x+.5,y+.5)*48))
  # Lower room front row covers the final corridor block face at the corner.
  if owner>1 and g.room_cache.has(owner-1):
   var lower:Array=g.room_cache[owner-1].grid
   g.level=owner-1;g.grid=lower
   g.camera=old_camera+offset-Vector2(-96 if owner==1 else 0,height*48)
   var cx:=15 if owner==1 else 13
   for x in [cx-4,cx-3,cx-2,cx+2,cx+3,cx+4]:
    if lower[5][x]=="#":g.draw_sprite("stone",g.screen(Vector2(x+.5,5.5)*48))
 g.level=old_level;g.grid=old_grid;g.camera=old_camera

func draw_tree_shadows()->void:
 # Floor pass only, before actors. The same upper-room coordinates describe
 # both corridor halves, so entering room1 cannot reroll the tree silhouettes.
 if g.level not in [0,1] or not g.room_cache.has(1):return
 var old_level:int=g.level
 var old_grid:Array=g.grid
 var old_camera:Vector2=g.camera
 var map:Array=g.grid if g.level==1 else g.room_cache[1].grid
 var height:int=map.size()
 var offset:=Vector2.ZERO if g.level==1 else Vector2(-96,height*48)
 g.level=1;g.grid=map;g.camera=old_camera+offset
 var floor_box:=Rect2(g.screen(Vector2(12*48,(height-5)*48)),Vector2(144,10*48))
 for y in range(height-5,height+5):
  for x in [11,15]:
   var cell:=Vector2i(x,y)
   var layout:Dictionary=g.boundary_layout(cell,1)
   var centre:Vector2=g.screen(Vector2(x+.5,y+.5)*48)+Vector2(layout.jitter)
   var inward:=1. if x==11 else -1.
   # Three low broad silhouettes merge under the thicket, avoiding a rigid
   # rectangular edge strip and keeping the far side outside the floor clear.
   for layer in range(3):
    var polygon:=PackedVector2Array()
    var radius:=Vector2(37-layer*5,19-layer*3)
    var anchor:=centre+Vector2(inward*(8+layer*3),-5+layer*2)
    for n in range(16):
     var angle:=float(n)*TAU/16
     polygon.append(anchor+Vector2(cos(angle)*radius.x,sin(angle)*radius.y))
    var floor_polygon:=PackedVector2Array([floor_box.position,Vector2(floor_box.end.x,floor_box.position.y),floor_box.end,Vector2(floor_box.position.x,floor_box.end.y)])
    for clipped in Geometry2D.intersect_polygons(polygon,floor_polygon):
     if clipped.size()>2:g.draw_colored_polygon(clipped,Color(.035,.055,.065,.12 if layer<2 else .18))
 g.level=old_level;g.grid=old_grid;g.camera=old_camera
