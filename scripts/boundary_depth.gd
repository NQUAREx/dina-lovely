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
 # Original layered pixel cumulus: many shaded puffs, no dark outline.
 var atlas:=Image.create(128*8,128,false,Image.FORMAT_RGBA8)
 var palette:Array[Color]=[Color("655474"),Color("786187"),Color("8b709d"),Color("9c80ae"),Color("ad90bd"),Color("bea1cc"),Color("d0b3da"),Color("e2c9e5"),Color("eedbea")]
 for variant in range(8):
  var rng:=RandomNumberGenerator.new();rng.seed=78191+variant*173
  var lobes:Array[Vector4]=[]
  # Broad lower shelf, taller asymmetric central towers and small satellites.
  for n in range(14):
   var x:float=16+n*7+rng.randf_range(-3,3)
   var rise:=sin(float(n)/13*PI)*rng.randf_range(16,29)
   lobes.append(Vector4(x,83-rise,rng.randf_range(12,19),rng.randf_range(10,18)))
  for n in range(36):
   lobes.append(Vector4(rng.randf_range(19,111),rng.randf_range(65,91),rng.randf_range(5,13),rng.randf_range(5,10)))
  lobes.sort_custom(func(a,b):return a.y<b.y)
  for y in range(128):
   for x in range(128):
    var colour:=Color.TRANSPARENT
    for lobe in lobes:
     var q:Vector2=(Vector2(x,y)-Vector2(lobe.x,lobe.y))/Vector2(lobe.z,lobe.w)
     var rr:=q.length_squared()
     if rr>=1.:continue
     var z:=sqrt(1.-rr)
     var illumination:=clampf(z*.67-q.x*.17-q.y*.35,0.,1.)
     # Local flecks follow the rounded surface, never white random noise.
     var fleck:=sin(x*1.7+y*.83+variant)*sin(y*1.13-x*.61)*.055
     var shade:=clampi(int((illumination+fleck)*7),0,8)
     if q.y< -.4 and z>.5:shade=mini(8,shade+1)
     colour=palette[shade]
    if colour.a>0:atlas.set_pixel(variant*128+x,y,colour)
 return ImageTexture.create_from_image(atlas)
