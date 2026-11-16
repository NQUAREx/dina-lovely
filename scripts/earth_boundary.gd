extends RefCounted
## Continuous packed-earth relief baked at the game's two-world-pixel grid.
## A connected base closes every wall cell. Overlapping height masses merge
## before shading, so they read as an embankment rather than isolated piles.
const PIXEL:=2.0
const PAD:=32
var g:Node2D
var cache:Dictionary={}
func _init(game:Node2D):g=game
func draw()->void:
 if g.level!=3:return
 var key:=str(g.save_data.seed)+":"+str(hash(g.grid))
 if not cache.has(key):cache[key]=bake()
 var texture:Texture2D=cache[key]
 g.draw_texture_rect(texture,Rect2(g.screen(Vector2(-PAD,-PAD)*PIXEL),Vector2(texture.get_size())*PIXEL),false)
func wall(x:int,y:int)->bool:
 if y<5 or y>=g.grid.size()-5 or x<0 or x>=g.grid[0].length():return false
 return g.grid[y][x]=="#" and not g.gate_junctions.skip_wall(Vector2i(x,y))
func polygon(image:Image,points:PackedVector2Array,colour:Color)->void:
 var bounds:=Rect2(points[0],Vector2.ZERO)
 for point in points:bounds=bounds.expand(point)
 for y in range(maxi(0,int(bounds.position.y)),mini(image.get_height(),ceili(bounds.end.y)+1)):
  for x in range(maxi(0,int(bounds.position.x)),mini(image.get_width(),ceili(bounds.end.x)+1)):
   if Geometry2D.is_point_in_polygon(Vector2(x,y),points):image.set_pixel(x,y,colour)
func bake()->ImageTexture:
 var width:int=g.grid[0].length()*24+PAD*2
 var height:int=g.grid.size()*24+PAD*2
 var image:=Image.create(width,height,false,Image.FORMAT_RGBA8)
 var rng:=RandomNumberGenerator.new();rng.seed=int(g.save_data.seed)+350147
 var hills:Array=[]
 for y in range(5,g.grid.size()-5):
  for x in range(g.grid[0].length()):
   if not wall(x,y):continue
   image.fill_rect(Rect2i(x*24+PAD-1,y*24+PAD-1,26,26),Color("493127"))
   # Three staggered rows interlock; spacing is smaller than every mound.
   # Full foundations remain hidden beneath overlap, even at concave corners.
   for n in range(3):
    var hx:=3+(n%3)*8+rng.randi_range(-2,2)
    var hy:=7+(n%2)*12+rng.randi_range(-2,2)
    hills.append({"pos":Vector2(x*24+PAD+hx,y*24+PAD+hy),"w":rng.randi_range(6,9),"h":rng.randi_range(5,9),"light":rng.randf()<.12,"seed":rng.randi()})
   # Taller sparse masses remain legible above the close-packed small clods.
   # Their full width never exceeds one48px world block.
   if rng.randf()<.92:
    hills.append({"pos":Vector2(x*24+PAD+12+rng.randi_range(-2,2),y*24+PAD+24),"w":rng.randi_range(11,12),"h":rng.randi_range(17,22),"light":rng.randf()<.20,"seed":rng.randi()})
   for m in range(2):
    hills.append({"pos":Vector2(x*24+PAD+rng.randi_range(5,19),y*24+PAD+12+m*13),"w":rng.randi_range(9,12),"h":rng.randi_range(11,15),"light":rng.randf()<.12,"seed":rng.randi()})
 hills.sort_custom(func(a,b):return a.pos.y<b.pos.y)
 for hill in hills:
  var p:Vector2=hill.pos;var w:int=hill.w;var h:int=hill.h
  var r:=RandomNumberGenerator.new();r.seed=hill.seed
  var peak:=r.randi_range(-2,2)
  var body:=Color("76543c") if hill.light else Color("5c3f2e")
  var top:=Color("a88255") if hill.light else Color("79553a")
  polygon(image,PackedVector2Array([p+Vector2(-w,0),p+Vector2(-w+2,-h/2),p+Vector2(peak,-h),p+Vector2(w-2,-h/2),p+Vector2(w,0),p+Vector2(w-2,4),p+Vector2(-w+2,4)]),Color("38281f"))
  polygon(image,PackedVector2Array([p+Vector2(-w+1,-1),p+Vector2(-w+3,-h/2),p+Vector2(peak,-h+1),p+Vector2(w-3,-h/2),p+Vector2(w-1,0),p+Vector2(w-3,2),p+Vector2(-w+3,2)]),body)
  polygon(image,PackedVector2Array([p+Vector2(-w+3,-h/2),p+Vector2(peak,-h+1),p+Vector2(peak+2,-h/2),p+Vector2(-2,-2),p+Vector2(-w+2,-1)]),top)
  for n in range(5):
   var dot:=Vector2i(p)+Vector2i(r.randi_range(-w+3,w-3),r.randi_range(-h/2,0))
   image.fill_rect(Rect2i(dot,Vector2i(2,1)),Color("674832") if n%2 else Color("8a6848"))
  if r.randf()<.45:
   var stone:=Vector2i(p)+Vector2i(r.randi_range(-w+2,w-2),-1)
   image.fill_rect(Rect2i(stone,Vector2i(3,2)),Color("777363"))
   image.set_pixelv(stone,Color("aba28a"))
 return ImageTexture.create_from_image(image)
