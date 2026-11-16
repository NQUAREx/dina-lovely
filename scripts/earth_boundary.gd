extends RefCounted
## Continuous packed-earth relief baked at the game's two-world-pixel grid.
## A connected base closes every wall cell. Overlapping height masses merge
## before shading, so they read as an embankment rather than isolated piles.
const PIXEL:=2.0
const PAD:=64
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
 if y<3 or y>=g.grid.size()-3 or x< -2 or x>=g.grid[0].length()+2:return false
 var cy:=clampi(y,5,g.grid.size()-6)
 var cx:=clampi(x,0,g.grid[0].length()-1)
 if y!=cy and absi(x-13)<=2:return false
 return g.grid[cy][cx]=="#" and not g.gate_junctions.skip_wall(Vector2i(cx,cy))

func polygon(image:Image,points:PackedVector2Array,colour:Color)->void:
 var bounds:=Rect2(points[0],Vector2.ZERO)
 for point in points:bounds=bounds.expand(point)
 for y in range(maxi(0,int(bounds.position.y)),mini(image.get_height(),ceili(bounds.end.y)+1)):
  for x in range(maxi(0,int(bounds.position.x)),mini(image.get_width(),ceili(bounds.end.x)+1)):
   if Geometry2D.is_point_in_polygon(Vector2(x,y),points):image.set_pixel(x,y,colour)
func edge_depth(p:Vector2)->float:
 var right:float=(g.grid[0].length()-1)*24
 var bottom:float=(g.grid.size()-6)*24
 return maxf(maxf(24-p.x,p.x-right),maxf(6*24-p.y,p.y-bottom))

func bake()->ImageTexture:
 var width:int=g.grid[0].length()*24+PAD*2
 var height:int=g.grid.size()*24+PAD*2
 var image:=Image.create(width,height,false,Image.FORMAT_RGBA8)
 var rng:=RandomNumberGenerator.new();rng.seed=int(g.save_data.seed)+350147
 var hills:Array=[]
 for y in range(3,g.grid.size()-3):
  for x in range(-2,g.grid[0].length()+2):
   if not wall(x,y):continue
   image.fill_rect(Rect2i(x*24+PAD-1,y*24+PAD-1,26,26),Color("493127"))
   var depth:=clampf(edge_depth(Vector2(x*24+12,y*24+12))/48.,0.,1.)
   # Three staggered rows interlock; spacing is smaller than every mound.
   # Full foundations remain hidden beneath overlap, even at concave corners.
   for n in range(3):
    var hx:=3+(n%3)*8+rng.randi_range(-2,2)
    var hy:=7+(n%2)*12+rng.randi_range(-2,2)
    hills.append({"pos":Vector2(x*24+PAD+hx,y*24+PAD+hy),"w":rng.randi_range(6,9),"h":rng.randi_range(5,9),"light":rng.randf()<.12,"seed":rng.randi()})
   # Taller sparse masses remain legible above the close-packed small clods.
   # Their full width never exceeds one48px world block.
   if rng.randf()<.92:
    hills.append({"pos":Vector2(x*24+PAD+12+rng.randi_range(-2,2),y*24+PAD+24),"w":rng.randi_range(11,12),"h":rng.randi_range(10,14)+int(depth*5),"light":rng.randf()<.20,"seed":rng.randi()})
   for m in range(2):
    hills.append({"pos":Vector2(x*24+PAD+rng.randi_range(5,19),y*24+PAD+12+m*13),"w":rng.randi_range(9,12),"h":rng.randi_range(7,11),"light":rng.randf()<.12,"seed":rng.randi()})
 # Sparse loose earth merges into a dense apron before the grass texture ends.
 # This is on the same 2-world-pixel grid as the bank, never a separate decal.
 for y in range(6*24,(g.grid.size()-6)*24,3):
  for x in range(24,(g.grid[0].length()-1)*24,3):
   var p:=Vector2(x,y)
   var depth:=edge_depth(p)
   if depth< -40 or depth>=0:continue
   if absf(x-13.5*24)<62 and (y<7*24 or y>(g.grid.size()-7)*24):continue
   var fullness:=smoothstep(-40.,0.,depth)
   if rng.randf()<fullness*.72:
    var shade:=Color("4c4630") if rng.randf()<.6 else Color("654b33")
    var dot:=Vector2i(x+PAD+rng.randi_range(-1,1),y+PAD+rng.randi_range(-1,1))
    image.fill_rect(Rect2i(dot,Vector2i(rng.randi_range(1,3),1)),shade)
   if rng.randf()<pow(fullness,2)*.12:
    var radius:=rng.randi_range(2,4)+int(fullness*3)
    hills.append({"pos":p+Vector2(PAD,PAD),"w":radius,"h":maxi(2,int(radius*.65)),"light":rng.randf()<.12,"seed":rng.randi()})
 # Close-set mid-size shoulders conceal the grass cut beneath a ragged edge.
 for y in range(6*24,(g.grid.size()-6)*24,8):
  for x in range(24,(g.grid[0].length()-1)*24,8):
   var depth:=edge_depth(Vector2(x,y))
   if depth< -10 or depth>=0:continue
   if absf(x-13.5*24)<62 and (y<7*24 or y>(g.grid.size()-7)*24):continue
   hills.append({"pos":Vector2(x+PAD+rng.randi_range(-2,2),y+PAD+rng.randi_range(-1,2)),"w":rng.randi_range(6,9),"h":rng.randi_range(4,7),"light":rng.randf()<.12,"seed":rng.randi()})
 hills.sort_custom(func(a,b):return a.pos.y<b.pos.y)
 for hill in hills:
  var p:Vector2=hill.pos;var w:int=hill.w;var h:int=hill.h
  var r:=RandomNumberGenerator.new();r.seed=hill.seed
  var peak:=r.randi_range(-2,2)
  var body:=Color("76543c") if hill.light else Color("5c3f2e")
  var top:=Color("a88255") if hill.light else Color("79553a")
  # Broad broken shoulders and a flat irregular crest: loose earth heaps.
  var outline:=PackedVector2Array([p+Vector2(-w,0),p+Vector2(-w+1,-h*.35),p+Vector2(-w*.65,-h*.7),p+Vector2(peak-3,-h),p+Vector2(peak+2,-h+1),p+Vector2(w*.65,-h*.65),p+Vector2(w-1,-h*.3),p+Vector2(w,1),p+Vector2(w*.5,3),p+Vector2(-w*.6,2)])
  polygon(image,outline,Color("38281f"))
  for i in range(outline.size()):outline[i]=p+(outline[i]-p)*.88
  polygon(image,outline,body)
  polygon(image,PackedVector2Array([p+Vector2(-w*.7,-h*.6),p+Vector2(peak-3,-h+1),p+Vector2(peak+2,-h+2),p+Vector2(w*.5,-h*.55),p+Vector2(1,-h*.35),p+Vector2(-w*.5,-h*.3)]),top)
  for n in range(5 if w>=6 else 1):
   var dot:=Vector2i(p)+Vector2i(r.randi_range(-maxi(1,w-3),maxi(1,w-3)),r.randi_range(-h/2,0))
   image.fill_rect(Rect2i(dot,Vector2i(2,1)),Color("674832") if n%2 else Color("8a6848"))
  if r.randf()<.45:
   var stone:=Vector2i(p)+Vector2i(r.randi_range(-w+2,w-2),-1)
   image.fill_rect(Rect2i(stone,Vector2i(3,2)),Color("777363"))
   image.set_pixelv(stone,Color("aba28a"))
 return ImageTexture.create_from_image(image)
