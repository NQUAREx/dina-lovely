extends RefCounted
## A solid wall cell supports each tall pillar; neighbouring walls remain behind it.
var g:Node2D
var textures:Dictionary={}
func _init(game:Node2D):g=game
func room_material()->String:return "stone" if g.level in [1,2,4] else "hedge"
func corridor_material(door:Dictionary)->String:
 return "tree" if (g.level==5 and door.id=="exit") or (g.level==6 and door.id=="back") else "stone"
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
func draw(door:Dictionary,pos:Vector2)->void:
 var room:=room_material();var corridor:=corridor_material(door);var end:="top" if door.id=="exit" else "bottom"
 for side in ["left","right"]:
  var key:="junction_%s_%s_%s_%s"%[room,corridor,end,side]
  if not textures.has(key):textures[key]=load("res://assets/"+key+".png")
  var x:=-96.0 if side=="left" else 96.0
  g.draw_texture_rect(textures[key],Rect2(pos+Vector2(x-48,-160),Vector2(96,224)),false)

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
func update_lights()->void:
 for lamp in lamps.values():lamp.visible=false
 for door in g.objects:
  if door.kind!="doorway":continue
  for side in [-1,1]:
   var key:=str(door.id)+str(side)
   if not lamps.has(key):
    var lamp:=PointLight2D.new()
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
    lamp.texture=ImageTexture.create_from_image(image)
    lamp.texture_scale=1.0
    lamp.color=Color(1,.70,.38)
    g.add_child(lamp);lamps[key]=lamp
   var lamp:PointLight2D=lamps[key]
   lamp.visible=true
   lamp.position=g.screen(door.pos)+Vector2(side*99,-47)
   lamp.energy=.055 if g.level==1 else .32
