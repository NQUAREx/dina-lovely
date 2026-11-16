extends ColorRect
var g:Node2D
func _ready()->void:
 g=get_parent();mouse_filter=Control.MOUSE_FILTER_IGNORE
 material=ShaderMaterial.new();material.shader=preload("res://shaders/boundary_depth.gdshader")
 z_index=100
func area(origin:Vector2,w:float,h:float,rects:Array[Vector4])->void:
 var p:Vector2=g.screen(origin)
 rects.append(Vector4(p.x,p.y,p.x+w,p.y+h))
func room(origin:Vector2,width:float,height:float,rects:Array[Vector4])->void:
 area(origin+Vector2(48,6*48),width-96,height-12*48,rects)
func _process(_delta:float)->void:
 visible=not g.grid.is_empty()
 if not visible:return
 size=g.get_viewport_rect().size
 var rects:Array[Vector4]=[]
 var width:float=g.grid[0].length()*48
 var height:float=g.grid.size()*48
 room(Vector2.ZERO,width,height,rects)
 for next in [g.level-1,g.level+1]:
  if next<0 or next>6 or not g.room_cache.has(next):continue
  var grid:Array=g.room_cache[next].grid
  var nw:float=grid[0].length()*48;var nh:float=grid.size()*48
  var north:bool=next>g.level
  var current_center:float=(15.5 if g.level==0 else 13.5)*48 if north else 13.5*48
  var other_center:float=13.5*48 if north else (15.5 if next==0 else 13.5)*48
  var origin:=Vector2(current_center-other_center,-nh if north else height)
  room(origin,nw,nh,rects)
  area(Vector2(current_center-72,-6*48 if north else height-6*48),144,12*48,rects)
 material.set_shader_parameter("area_count",rects.size())
 while rects.size()<20:rects.append(Vector4(-10000,-10000,-10000,-10000))
 material.set_shader_parameter("visible_areas",rects)
 material.set_shader_parameter("view_size",size)
