extends ColorRect
var g:Node2D
var fades:=PackedFloat32Array()
func _ready()->void:
 g=get_parent();mouse_filter=Control.MOUSE_FILTER_IGNORE
 material=ShaderMaterial.new();material.shader=preload("res://shaders/boundary_depth.gdshader")
 material.set_shader_parameter("cloud_atlas",make_cloud_atlas())
 z_index=100
func area(origin:Vector2,w:float,h:float,rects:Array[Vector4],owner:int)->void:
 # Fog follows the projected roof plane, not the block foot on the ground.
 if owner in [2,4,5,6]:
  origin+=Vector2(-2,-26);w+=4
 fades.append(72.)
 var p:Vector2=g.screen(origin)
 rects.append(Vector4(p.x,p.y,p.x+w,p.y+h))
func room(origin:Vector2,width:float,height:float,rects:Array[Vector4],owner:int)->void:
 # Room 2 occupies only columns 8..18; empty grid padding is not floor.
 var left:float=9*48 if owner==2 else 48
 var right:float=18*48 if owner==2 else width-48
 area(origin+Vector2(left,6*48),right-left,height-12*48,rects,owner)
func _process(_delta:float)->void:
 visible=not g.grid.is_empty()
 if not visible:return
 size=g.get_viewport_rect().size
 var rects:Array[Vector4]=[]
 fades=PackedFloat32Array()
 var width:float=g.grid[0].length()*48
 var height:float=g.grid.size()*48
 room(Vector2.ZERO,width,height,rects,g.level)
 for next in [g.level-1,g.level+1]:
  if next<0 or next>6 or not g.room_cache.has(next):continue
  var grid:Array=g.room_cache[next].grid
  var nw:float=grid[0].length()*48;var nh:float=grid.size()*48
  var north:bool=next>g.level
  var current_center:float=(15.5 if g.level==0 else 13.5)*48 if north else 13.5*48
  var other_center:float=13.5*48 if north else (15.5 if next==0 else 13.5)*48
  var origin:=Vector2(current_center-other_center,-nh if north else height)
  room(origin,nw,nh,rects,next)
  area(Vector2(current_center-72,-6*48 if north else height-6*48),144,12*48,rects,maxi(g.level,next))
 while fades.size()<20:fades.append(72.)
 material.set_shader_parameter("fade_widths",fades)
 material.set_shader_parameter("area_count",rects.size())
 while rects.size()<20:rects.append(Vector4(-10000,-10000,-10000,-10000))
 material.set_shader_parameter("visible_areas",rects)
 var origin:Vector2=g.camera-size/2
 for n in range(g.level):
  if g.room_cache.has(n+1):origin.y-=g.room_cache[n+1].grid.size()*48
 if g.level==0:origin.x-=96
 material.set_shader_parameter("world_origin",origin)
 material.set_shader_parameter("view_size",size)

func make_cloud_atlas()->ImageTexture:
 # Eight original pixel sprites, drawn at the same2px/world scale as foliage.
 var atlas:=Image.create(64*8,64,false,Image.FORMAT_RGBA8)
 for variant in range(8):
  var rng:=RandomNumberGenerator.new();rng.seed=99173+variant*71
  var shape:=Image.create(64,64,false,Image.FORMAT_RGBA8)
  var lobes:Array[Vector3]=[Vector3(20,36,14),Vector3(43,36,13),Vector3(32,27,17)]
  for n in range(5):lobes.append(Vector3(rng.randi_range(15,49),rng.randi_range(20,43),rng.randi_range(8,14)))
  for y in range(64):
   for x in range(64):
    var inside:=false
    for lobe in lobes:
     if Vector2(x-lobe.x,(y-lobe.y)*1.15).length()<=lobe.z:inside=true;break
    if inside:shape.set_pixel(x,y,Color.WHITE)
  for y in range(64):
   for x in range(64):
    if shape.get_pixel(x,y).a<.5:continue
    var rim:=false
    for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
     var q:Vector2i=Vector2i(x,y)+d*2
     if q.x<0 or q.y<0 or q.x>=64 or q.y>=64 or shape.get_pixelv(q).a<.5:rim=true
    var colour:=Color("9da6bc") if rim else Color("c6ccda") if y>37 else Color("e1e5ed")
    # Broad stepped highlights show individual puffs; no gradients/noise.
    for lobe in lobes:
     if Vector2(x-lobe.x+2,(y-lobe.y+4)*1.3).length()<lobe.z*.55 and y<lobe.y:colour=Color("f0f1f5")
    atlas.set_pixel(variant*64+x,y,colour)
 return ImageTexture.create_from_image(atlas)
