extends ColorRect
var g:Node2D
var masks:Dictionary={}
func _ready()->void:
 g=get_parent();mouse_filter=Control.MOUSE_FILTER_IGNORE
 material=ShaderMaterial.new();material.shader=preload("res://shaders/boundary_depth.gdshader")
 z_index=100
func area(origin:Vector2,w:float,h:float,rects:Array[Vector4])->void:
 var p:Vector2=g.screen(origin)
 rects.append(Vector4(p.x,p.y,p.x+w,p.y+h))
func floor_mask(grid:Array)->Texture2D:
 var key:=str(hash(grid))
 if not masks.has(key):
  var image:=Image.create(grid[0].length(),grid.size(),false,Image.FORMAT_RGBA8)
  for y in range(grid.size()):
   for x in range(grid[0].length()):
    image.set_pixel(x,y,Color.WHITE if grid[y][x]=="." else Color.BLACK)
  masks[key]=ImageTexture.create_from_image(image)
 return masks[key]
func protect(grid:Array,origin:Vector2,index:int)->void:
 material.set_shader_parameter("floor_mask"+str(index),floor_mask(grid))
 var p:Vector2=g.screen(origin)
 material.set_shader_parameter("floor_rect"+str(index),Vector4(p.x,p.y,grid[0].length()*48,grid.size()*48))
func _process(_delta:float)->void:
 visible=not g.grid.is_empty()
 if not visible:return
 size=g.get_viewport_rect().size
 var rects:Array[Vector4]=[]
 var halls:Array[Vector4]=[]
 var floor_count:=1
 protect(g.grid,Vector2.ZERO,0)
 var width:float=g.grid[0].length()*48
 var height:float=g.grid.size()*48
 area(Vector2(-24,5*48-24),width+48,height-10*48+48,rects)
 for next in [g.level-1,g.level+1]:
  if next<0 or next>6 or not g.room_cache.has(next):continue
  var grid:Array=g.room_cache[next].grid
  var nw:float=grid[0].length()*48;var nh:float=grid.size()*48
  var north:bool=next>g.level
  var current_center:float=(15.5 if g.level==0 else 13.5)*48 if north else 13.5*48
  var other_center:float=13.5*48 if north else (15.5 if next==0 else 13.5)*48
  var origin:=Vector2(current_center-other_center,-nh if north else height)
  protect(grid,origin,floor_count);floor_count+=1
  area(origin+Vector2(-24,5*48-24),nw+48,nh-10*48+48,rects)
  # One shared corridor, including both room-coordinate halves.
  var hp:Vector2=g.screen(Vector2(current_center-72,-5*48 if north else height-5*48))
  halls.append(Vector4(hp.x,hp.y,hp.x+144,hp.y+10*48))
  area(Vector2(current_center-144,-5*48 if north else height-5*48),288,10*48,rects)
 material.set_shader_parameter("floor_count",floor_count)
 material.set_shader_parameter("hall_count",halls.size())
 while halls.size()<2:halls.append(Vector4(-10000,-10000,-10000,-10000))
 material.set_shader_parameter("protected_halls",halls)
 material.set_shader_parameter("area_count",rects.size())
 while rects.size()<7:rects.append(Vector4(-10000,-10000,-10000,-10000))
 material.set_shader_parameter("areas",rects)
 material.set_shader_parameter("view_size",size)
