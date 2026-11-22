extends RefCounted
var g:Node2D
var textures:Dictionary={}
var tree_shadow_textures:Array[Texture2D]=[]
func _init(game:Node2D):g=game
func stamp(owner:int,point:Vector2)->void:
 if not g.get_viewport_rect().grow(110).has_point(point):return
 var cell:=Vector2i(floori((point+g.camera-g.get_viewport_rect().size/2).x/48),floori((point+g.camera-g.get_viewport_rect().size/2).y/48))
 var layout:Dictionary=g.boundary_layout(cell,owner)
 var key:="wall_room%d_exposed"%owner
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
  # Floors are drawn exclusively in _draw_world, before actors. Repainting
  # the wall underlay here used to cover the heroine near the tree trunks.
  for y in range(height-5,height+5):
   for x in [11,15]:
    stamp(owner,g.screen(Vector2(x+.5,y+.5)*48))
  # The room's first wall row and gate posts are drawn in the world depth pass.
 g.level=old_level;g.grid=old_grid;g.camera=old_camera

func warm_up()->void:
 # Loaded behind the loading screen instead of on the first corridor frame.
 for owner in range(1,7):
  for variant in range(16 if owner==1 else 4):
   var key:="wall_room%d_exposed"%owner
   if variant>0:key+=str(variant)
   if not textures.has(key):textures[key]=load("res://assets/"+key+".png")
 prepare_tree_shadows()
func prepare_tree_shadows()->void:
 if not tree_shadow_textures.is_empty():return
 # One continuous soft penumbra, sampled at world-pixel resolution so the
 # edge does not break into the old twelve-pixel staircase.
 var image:=Image.create(80,480,false,Image.FORMAT_RGBA8)
 for y in range(image.get_height()):
  var end_fade:=smoothstep(0.0,18.0,float(y))*smoothstep(0.0,18.0,float(image.get_height()-1-y))
  var ripple:=sin(float(y)*.040)*2.0+sin(float(y)*.075)*1.4
  for x in range(image.get_width()):
   var distance:=float(x)-24.0-ripple
   var alpha:=.31*(1.0-smoothstep(8.0,34.0,distance))*end_fade
   image.set_pixel(x,y,Color(1,1,1,alpha))
 tree_shadow_textures.append(ImageTexture.create_from_image(image))
 image.flip_x()
 tree_shadow_textures.append(ImageTexture.create_from_image(image))

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
 # Keep the shadow in the upper room's coordinates in either corridor half.
 prepare_tree_shadows()
 var top:float=(height-5)*48
 # Keep the feathered ends inside the shared corridor: otherwise the later
 # neighbour floor pass covers a few pixels on only one side of the seam.
 var cast_offset:=Vector2(g.SHADOW_DIRECTION.x*10.0,0)
 for side in [-1,1]:
  var edge:float=12*48 if side==-1 else 15*48
  var left:float=edge-24 if side==-1 else edge-56
  var texture:Texture2D=tree_shadow_textures[0 if side==-1 else 1]
  g.draw_texture_rect(texture,Rect2(g.screen(Vector2(left,top)+cast_offset),Vector2(80,480)),false,g.SHADOW_TINT)
 g.level=old_level;g.grid=old_grid;g.camera=old_camera
