extends ColorRect
var g:Node2D
var fades:=PackedFloat32Array()
func _ready()->void:
 g=get_parent();mouse_filter=Control.MOUSE_FILTER_IGNORE
 material=ShaderMaterial.new();material.shader=preload("res://shaders/boundary_depth.gdshader")
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
 material.set_shader_parameter("view_size",size)
