extends RefCounted
## Reversible, screen-culled 2D shadow study. Cached silhouettes, no ray tracing.
var g:Node2D
var cache:Dictionary={}
func _init(game:Node2D):g=game
func textures(name:String)->Array:
 if cache.has(name):return cache[name]
 var texture:Texture2D
 var rect:=Rect2(-32,-86,64,96)
 if name=="stone":
  texture=load("res://assets/wall_exposed.png");rect=Rect2(-32,-70,64,104)
 elif name=="post":
  texture=load("res://assets/junction_stone_stone_top_left.png");rect=Rect2(-48,-160,96,224)
 elif name.begins_with("hedge_tree"):
  texture=load("res://assets/"+name+".png");rect=Rect2(-32,-96,64,96)
 elif g.sprites.has(name):
  var id:int=g.sprites[name]
  var image:Image=g.atlas.get_image().get_region(Rect2i(id%16*32,id/16*48,32,48))
  texture=ImageTexture.create_from_image(image)
 else:return []
 var soft:Image=texture.get_image()
 soft.resize(maxi(4,soft.get_width()/4),maxi(4,soft.get_height()/4),Image.INTERPOLATE_BILINEAR)
 soft.resize(texture.get_width(),texture.get_height(),Image.INTERPOLATE_BILINEAR)
 cache[name]=[texture,ImageTexture.create_from_image(soft),rect]
 return cache[name]
func stamp(name:String,world:Vector2,scale_factor:float=1.0)->void:
 var p:Vector2=g.screen(world)
 if not g.get_viewport_rect().grow(190).has_point(p):return
 var data:=textures(name)
 if data.is_empty():return
 var reach:=.48
 var direction:=Vector2(.48,.38)
 # Tall forms throw longer shadows; small pickups stay near the ground.
 if name in ["stone","post"]:reach=.65
 var transform:=Transform2D(Vector2(1,0),Vector2(-direction.x,-reach),p)
 var rect:Rect2=data[2]
 rect.position*=scale_factor;rect.size*=scale_factor
 project(data[1],rect.grow(3),transform,Color(.035,.045,.075,.16))
 project(data[0],rect,transform,Color(.035,.045,.075,.23))
 # Layered contact occlusion connects the silhouette to the floor.
 for i in range(3):
  var radius:float=(24.0-i*5)*scale_factor
  g.draw_set_transform(p+Vector2(0,3),0,Vector2(1,.25))
  g.draw_circle(Vector2.ZERO,radius,Color(.025,.035,.055,.07+i*.035))
 g.draw_set_transform(Vector2.ZERO)
func project(texture:Texture2D,rect:Rect2,transform:Transform2D,color:Color)->void:
 var quad:=PackedVector2Array()
 for point in [rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]:quad.append(transform*point)
 var bounds:=Rect2(quad[0],Vector2.ZERO)
 for point in quad:bounds=bounds.expand(point)
 var offset:Vector2=g.screen(Vector2.ZERO)
 var first:=Vector2i((bounds.position-offset)/48)-Vector2i.ONE
 var last:=Vector2i((bounds.end-offset)/48)+Vector2i.ONE
 var inverse:=transform.affine_inverse()
 for y in range(maxi(0,first.y),mini(g.grid.size(),last.y+1)):
  for x in range(maxi(0,first.x),mini(g.grid[0].length(),last.x+1)):
   if not g.shadow_floor_cell(Vector2i(x,y)):continue
   var p:=offset+Vector2(x,y)*48
   var floor_quad:=PackedVector2Array([p,p+Vector2(48,0),p+Vector2(48,48),p+Vector2(0,48)])
   for clipped in Geometry2D.intersect_polygons(quad,floor_quad):
    var uv:=PackedVector2Array()
    for point in clipped:uv.append((inverse*point-rect.position)/rect.size)
    g.draw_polygon(clipped,PackedColorArray([color]),uv,texture)

func draw(items:Array)->void:
 for item in items:
  var kind:String=item.kind
  if kind in ["player","dug","pond","path","sprout"]:continue
  if kind=="doorway":
   for side in [-1,1]:stamp("post",item.pos+Vector2(side*96,0))
   continue
  if kind=="accessory":kind="accessory_"+str(item.accessory)
  if kind=="stand_flashlight":kind="flashlight_rest"
  if kind=="weapon_crate":kind="crate"
  if kind in ["tree","tree_apples","hedge_tree","hedge_tree_apples"]:
   var v:=posmod(floori(item.pos.x/48)*17+floori(item.pos.y/48)*7,6)
   kind+="_variant"+str(v)
  stamp(kind,item.pos,.65 if item.get("on_table",false) or item.get("ground_tool",false) else 1.0)
