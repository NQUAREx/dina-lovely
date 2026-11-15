"""Original coarse pixel UI: draw on a 2px game grid, then nearest upscale."""
from pathlib import Path
from PIL import Image, ImageDraw
A=Path(__file__).resolve().parents[1]/'assets'/'ui'
def save(im,name):im.resize((im.width*2,im.height*2),Image.Resampling.NEAREST).save(A/name)
def generate():
 A.mkdir(exist_ok=True)
 for state,base,edge,hi in [('normal','#523f58','#ac7e96','#e2b4b2'),('hover','#654b65','#c897a8','#f2cdb5'),('pressed','#3e3449','#8e708a','#c29ca8'),('disabled','#443e4c','#716779','#938396'),('panel','#44384e','#a77d95','#dbb3b3'),('paper','#f5e7cf','#b2899d','#edd0bb'),('focus','#523f58','#d4b28b','#f1d3ab')]:
  im=Image.new('RGBA',(32,32));d=ImageDraw.Draw(im)
  def box(i,c,col):
   a=i;b=31-i
   # Explicit steps rather than fine diagonal lines.
   d.polygon([(a+c,a),(b-c,a),(b-c,a+1),(b-1,a+1),(b-1,a+c),(b,a+c),(b,b-c),(b-1,b-c),(b-1,b-1),(b-c,b-1),(b-c,b),(a+c,b),(a+c,b-1),(a+1,b-1),(a+1,b-c),(a,b-c),(a,a+c),(a+1,a+c),(a+1,a+1),(a+c,a+1)],fill=col)
  box(0,4,'#2d293b');box(1,3,edge);box(2,2,hi);box(3,2,'#76596f');box(4,1,base)
  d.rectangle((4,3,27,3),fill='#b68c9f' if state!='paper' else '#d4b0ae')
  d.rectangle((3,5,3,26),fill=edge);d.rectangle((28,5,28,26),fill='#675068');d.rectangle((5,28,26,28),fill='#332b40' if state!='paper' else '#bc97a3')
  # Broad inset corner clusters read as carved pixel bevels.
  for x,y in [(3,3),(27,27)]:
   d.rectangle((x,y,x+1,y),fill=hi);d.point((x,y+1),fill=hi)
  save(im,f'frame_{state}.png')
 # 24x18 source means final 48x36; all petals/leaves are deliberate clusters.
 im=Image.new('RGBA',(24,18));d=ImageDraw.Draw(im)
 d.line([(1,17),(2,12),(5,8),(10,5),(17,5),(22,8)],fill='#354b3d',width=2)
 d.line([(2,16),(3,12),(6,9),(11,6),(17,6),(22,9)],fill='#8d9b63',width=1)
 for x,y,sgn in [(2,14,1),(4,10,-1),(9,7,1),(15,5,1),(20,8,1),(19,11,-1)]:
  d.polygon([(x,y),(x+sgn*2,y-3),(x+sgn*4,y-3),(x+sgn*3,y-1)],fill='#526f49')
  d.line((x+sgn,y-1,x+sgn*3,y-2),fill='#a2ad70')
 for x,y in [(6,7),(12,3),(17,8)]:
  # Cross petals with stepped square corners, shaded undersides.
  d.rectangle((x-1,y-3,x+1,y+3),fill='#8d657f');d.rectangle((x-3,y-1,x+3,y+1),fill='#8d657f')
  d.rectangle((x-1,y-3,x+1,y-1),fill='#e0a4b4');d.rectangle((x-3,y-1,x-1,y+1),fill='#d295aa');d.rectangle((x+1,y-1,x+3,y+1),fill='#e6b5bc');d.rectangle((x-1,y+1,x+1,y+2),fill='#c78fa7')
  d.line((x-1,y-3,x+1,y-3),fill='#f3d3c7');d.point((x-3,y-1),fill='#edc1c4')
  d.rectangle((x-1,y-1,x+1,y+1),fill='#d1af78');d.point((x,y-1),fill='#f2d6a0');d.point((x+1,y+1),fill='#89734f')
 save(im,'flower_corner.png')
 for name,w,h in [('button',22,12),('panel',48,16)]:
  im=Image.new('RGBA',(w,h));d=ImageDraw.Draw(im);cx=w//2
  if name=='panel':
   d.polygon([(1,3),(5,0),(w-6,0),(w-2,3),(w-2,10),(w-7,15),(6,15),(1,10)],fill='#302a3c')
   d.polygon([(2,3),(6,1),(w-7,1),(w-3,3),(w-3,9),(w-8,13),(7,13),(2,9)],fill='#c094a5')
   d.polygon([(4,4),(7,3),(w-8,3),(w-5,4),(w-5,8),(w-9,11),(8,11),(4,8)],fill='#634c65');d.line((8,2,w-9,2),fill='#e8c1b7')
   for x in [7,w-8]:d.rectangle((x,6,x+1,7),fill='#b78e9f')
  y=1 if name=='button' else 3
  d.polygon([(cx-5,y+1),(cx-3,y),(cx-1,y),(cx,y+2),(cx+1,y),(cx+3,y),(cx+5,y+1),(cx+5,y+4),(cx+3,y+6),(cx,y+9),(cx-3,y+6),(cx-5,y+4)],fill='#b78199')
  d.rectangle((cx-4,y+1,cx-2,y+3),fill='#e2afba');d.point((cx-3,y+1),fill='#f4cfc2');d.rectangle((cx+1,y+1,cx+3,y+2),fill='#dba4b3');d.line((cx-1,y+7,cx,y+8),fill='#926f89')
  save(im,f'crest_{name}.png')
 print('Generated coarse 2px-grid UI rails, clustered flowers and stepped crests')
if __name__=='__main__':generate()
