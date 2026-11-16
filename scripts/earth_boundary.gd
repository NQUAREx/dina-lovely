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
func bake()->ImageTexture:
 var width:int=g.grid[0].length()*24+PAD*2
 var height:int=g.grid.size()*24+PAD*2
 var field:=PackedFloat32Array();field.resize(width*height);field.fill(0)
 var rng:=RandomNumberGenerator.new();rng.seed=int(g.save_data.seed)+350147
 for y in range(5,g.grid.size()-5):
  for x in range(g.grid[0].length()):
   if not wall(x,y):continue
   # Full joined foundation guarantees no visual grass gaps between cells.
   for py in range(y*24+PAD,(y+1)*24+PAD):
    for px in range(x*24+PAD,(x+1)*24+PAD):field[py*width+px]=maxf(field[py*width+px],4.0)
   # Different low shelves, long ridges, double peaks and steep clods merge.
   var count:=rng.randi_range(2,4)
   for n in range(count):
    var cx:=x*24+12+PAD+rng.randi_range(-9,9)
    var cy:=y*24+10+PAD+rng.randi_range(-7,7)
    var rx:=rng.randi_range(14,27)
    var ry:=rng.randi_range(12,20)
    var rise:=rng.randf_range(10,25)
    if n==0:
     # Long shelves bridge several anchors; small steep peaks sit on top.
     if wall(x-1,y) or wall(x+1,y):rx=rng.randi_range(26,40);ry=rng.randi_range(12,19)
     else:rx=rng.randi_range(13,20);ry=rng.randi_range(27,38)
     rise=rng.randf_range(12,32)
    for py in range(maxi(1,cy-ry),mini(height-1,cy+ry+1)):
     for px in range(maxi(1,cx-rx),mini(width-1,cx+rx+1)):
      var dist:=pow(float(px-cx)/rx,2)+pow(float(py-cy)/ry,2)
      if dist>=1:continue
      var value:=rise*pow(1.0-dist,.70)
      var index:=py*width+px
      # Soft maximum rounds the seams where individual banks meet.
      var old:=field[index]
      field[index]=maxf(old,value)+minf(old,value)*.06
 var image:=Image.create(width,height,false,Image.FORMAT_RGBA8)
 # Shadows and continuous side shell: same relief, projected before tops.
 for y in range(1,height-1):
  for x in range(1,width-1):
   var h:=field[y*width+x]
   if h<=1:continue
   image.set_pixel(x+1,mini(height-1,y+5),Color(.10,.075,.055,.22))
 for y in range(1,height-1):
  for x in range(1,width-1):
   var h:=field[y*width+x]
   if h<=1:continue
   var top:=maxi(0,y-roundi(h*.58))
   for sy in range(top,mini(height,y+2)):
    var strata:=posmod(sy+x/8,7)
    image.set_pixel(x,sy,Color("674832") if strata>1 else Color("51382b"))
 # Top slopes use their local normals; exposed ridges stay light and hollows
 # are cooler/darker, with broad coherent colour patches instead of noise.
 for y in range(1,height-1):
  for x in range(1,width-1):
   var index:=y*width+x;var h:=field[index]
   if h<=1:continue
   var dx:=field[index-1]-field[index+1]
   var dy:=field[index-width]-field[index+width]
   var light:=clampf(.48+dx*.055+dy*.07+sin(x*.055)*.09+sin(y*.071)*.08,.08,.95)
   var colour:=Color("674832").lerp(Color("a88255"),light)
   if posmod(x*13+y*29,37)==0:colour=colour.lightened(.08)
   var top_y:=maxi(0,y-roundi(h*.58))
   var next_y:=maxi(top_y+1,y+1-roundi(field[index+width]*.58))
   for py in range(top_y,mini(height,next_y)):image.set_pixel(x,py,colour)
 # Embedded stones belong to the bank surface, with lit upper edges and a
 # short contact shadow; size varies from tiny gravel to exposed rock chunks.
 for n in range((g.grid.size()+g.grid[0].length())*6):
  var x:=rng.randi_range(PAD,width-PAD-1)
  var y:=rng.randi_range(PAD,height-PAD-1)
  var h:=field[y*width+x]
  if h<5:continue
  var py:=maxi(2,y-roundi(h*.58));var size:=rng.randi_range(1,3)
  for dy in range(size):
   for dx in range(size+1):
    image.set_pixel(x+dx,py+dy,Color("776f61") if dy>0 else Color("a99a7c"))
  image.set_pixel(x,py+size,Color("51382b"))
 return ImageTexture.create_from_image(image)
