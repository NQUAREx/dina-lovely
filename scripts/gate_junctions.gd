extends RefCounted
## A solid wall cell supports each tall pillar; neighbouring walls remain behind it.
const POSTS := [
 preload("res://assets/junction_stone_stone_top_left.png"),
 preload("res://assets/junction_stone_stone_top_right.png"),
]

var g:Node2D
func _init(game:Node2D):g=game
func prepare()->void:
 for door in g.objects:
  if door.kind!="doorway":continue
  var cell:=Vector2i(door.pos/48);var inside:=1 if door.id=="exit" else -1
  for side in [-2,2]:
   g.set_cell(cell.x+side,cell.y,"#")
   g.set_cell(cell.x+side,cell.y-inside,"#")
func pillar_cell(cell:Vector2i)->bool:
 for door in g.objects:
  if door.kind!="doorway":continue
  var centre:=Vector2i(door.pos/48)
  if cell.y==centre.y and absi(cell.x-centre.x)==2:return true
 return false
func skip_wall(cell:Vector2i)->bool:
 # The composite supplies this single wall block, not the neighbouring walls.
 return pillar_cell(cell)
func draw(_door:Dictionary,pos:Vector2)->void:
 for index in range(POSTS.size()):
  var x:=-96.0 if index==0 else 96.0
  g.draw_texture_rect(POSTS[index],Rect2(pos+Vector2(x-48,-160),Vector2(96,224)),false)

func draw_hinges(pos:Vector2,amount:float)->void:
 for side in [-1,1]:
  for y in [-54,-13]:
   var origin:=pos+Vector2(side*72,y)
   g.draw_rect(Rect2(origin+Vector2(-4,-3),Vector2(8,8)),Color("373943"))
   g.draw_rect(Rect2(origin+Vector2(-2,-2),Vector2(4,6)),Color("939099"))
   var length:=9.0 if side<0 or amount<=.25 else 4.0
   var start:=origin+Vector2(4 if side<0 else -length-4,-2)
   g.draw_rect(Rect2(start,Vector2(length,5)),Color("474853"))
   g.draw_line(start,start+Vector2(length,0),Color("898692"),2)
   g.draw_rect(Rect2(start+Vector2(length*.5,2),Vector2(2,2)),Color("b5a5aa"))

var lamps:Dictionary={}
var lamp_texture:Texture2D
# The beam texture and every gate's two lamps are made behind the loading
# screen; creating them when a gate first scrolled into view hitched.
func warm_up()->void:
 lamp_beam()
 for room_id in g.room_cache:
  for door in g.room_cache[room_id].objects:
   if door.kind!="doorway":continue
   for side in [-1,1]:lamp(str(room_id)+":"+str(door.id)+":"+str(side))
func lamp_beam()->Texture2D:
 if lamp_texture==null:
  var image:=Image.create(96,96,false,Image.FORMAT_RGBA8)
  for y in range(96):
   for x in range(96):
    var down:=float(y-48)
    var across:=absf(float(x-48))
    var value:=0.0
    if down>=0:
     var width:=9.0+down*.30
     value=pow(maxf(0,1.0-across/width),2)*pow(maxf(0,1.0-down/44.0),1.6)
    image.set_pixel(x,y,Color(1,1,1,value))
  lamp_texture=ImageTexture.create_from_image(image)
 return lamp_texture
func lamp(key:String)->PointLight2D:
 if not lamps.has(key):
  var light:=PointLight2D.new()
  light.texture=lamp_beam()
  light.texture_scale=1.0
  light.color=Color(1,.70,.38)
  light.visible=false
  g.add_child(light);lamps[key]=light
 return lamps[key]
func update_lights()->void:
 for light in lamps.values():light.visible=false
 update_room_lights(g.level,g.objects,Vector2.ZERO)
 # Both halves of a shared corridor show the same two gates. Their lights
 # must follow the canonical room offset just like the neighbour's sprites.
 for room_id in [g.level-1,g.level+1]:
  if not g.room_cache.has(room_id):continue
  var state:Dictionary=g.room_cache[room_id]
  var north:bool=room_id>g.level
  var center:float=(15.5 if g.level==0 else 13.5)*48 if north else 13.5*48
  var other:float=13.5*48 if north else (15.5 if room_id==0 else 13.5)*48
  var offset:=Vector2(center-other,-state.grid.size()*48-2*g.HALL_SEAM if north else g.grid.size()*48+2*g.HALL_SEAM)
  update_room_lights(room_id,state.objects,offset)

func update_room_lights(room_id:int,room_objects:Array,offset:Vector2)->void:
 for door in room_objects:
  if door.kind!="doorway":continue
  var position:Vector2=g.screen(door.pos+offset)
  if not g.get_viewport_rect().grow(180).has_point(position):continue
  for side in [-1,1]:
   var light:=lamp(str(room_id)+":"+str(door.id)+":"+str(side))
   light.visible=true
   light.position=position+Vector2(side*99,-47)
   light.energy=.055 if room_id==1 else .32
