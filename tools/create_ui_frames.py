"""Original pixel UI geometry. Decorative art is separate from stretchable rails."""
from pathlib import Path
from PIL import Image, ImageDraw,ImageOps
A=Path(__file__).resolve().parents[1]/'assets'/'ui'
def generate():
 A.mkdir(exist_ok=True)
 for state,base,edge,hi in [('normal','#4f3855','#bd829d','#f0bdba'),('hover','#65455f','#e1a9a9','#ffe1b4'),('pressed','#3b2d46','#a67590','#d6a0ad'),('disabled','#443a4a','#7d697f','#a78a9e'),('panel','#403147','#bc87a0','#ecc0bd'),('paper','#fff4df','#ba879a','#f4d8bd'),('focus','#4f3855','#dfb88d','#ffe2b4')]:
  im=Image.new('RGBA',(64,64));d=ImageDraw.Draw(im)
  # All sides are straight rails; the 12px corner patches never stretch.
  def shape(inset,cut,fill):
   a=inset;b=63-inset;c=cut
   d.polygon([(a+c,a),(b-c,a),(b,a+c),(b,b-c),(b-c,b),(a+c,b),(a,b-c),(a,a+c)],fill=fill)
  shape(0,7,'#302638');shape(1,6,edge);shape(3,5,hi);shape(4,5,'#78546e');shape(6,4,base)
  # Fine inset bevel, restrained enough for small controls and large panels.
  d.line([(9,6),(54,6),(57,9)],fill=hi)
  d.line([(6,10),(6,53)],fill='#a67b96' if state!='paper' else '#e3b9bc')
  d.line([(10,58),(53,58),(58,53)],fill='#2f2739' if state!='paper' else '#cda0ad')
  d.line([(58,10),(58,52)],fill='#65445f' if state!='paper' else '#d8b1b9')
  for x,y in [(5,7),(57,55)]:d.point((x,y),fill=hi)
  im.save(A/f'frame_{state}.png')
 # One branch cluster, copied at native size in UI drawing, never nine-sliced.
 im=Image.new('RGBA',(36,30));d=ImageDraw.Draw(im)
 d.line([(3,26),(6,16),(15,9),(30,7)],fill='#465039',width=3)
 d.line([(4,25),(7,16),(16,9),(30,7)],fill='#8d9e60',width=1)
 for x,y,dx in [(5,23,1),(8,15,-1),(17,9,1),(26,7,1),(30,10,-1)]:
  d.polygon([(x,y),(x+dx*5,y-5),(x+dx*7,y-4),(x+dx*6,y-1)],fill='#617747')
  d.line((x+dx,y-1,x+dx*5,y-4),fill='#b5bc78')
 for x,y,r in [(8,10,4),(17,5,3),(26,10,3)]:
  for dx,dy in [(-r,0),(r,0),(0,-r),(0,r)]:
   d.rectangle((x+dx-2,y+dy-2,x+dx+2,y+dy+2),fill='#704b67')
   d.rectangle((x+dx-1,y+dy-1,x+dx+1,y+dy+1),fill='#e7adb9')
   d.point((x+dx-1,y+dy-1),fill='#ffe0d2')
  d.rectangle((x-1,y-1,x+1,y+1),fill='#f5d29a');d.point((x,y+1),fill='#bc8d68')
 im.save(A/'flower_corner.png')
 # Center badges: transparent around the heart, no captured image background.
 for name,w,h in [('button',36,16),('panel',84,22)]:
  im=Image.new('RGBA',(w,h));d=ImageDraw.Draw(im);cx=w//2
  if name=='panel':
   p=[(0,6),(8,1),(w-9,1),(w-1,6),(w-9,h-2),(8,h-2)]
   d.polygon(p,fill='#b9839d');d.polygon([(3,6),(10,3),(w-11,3),(w-4,6),(w-11,h-4),(10,h-4)],fill='#60415d')
   d.line((11,4,w-12,4),fill='#efc1be');d.point((10,10),fill='#dfabaf');d.point((w-11,10),fill='#dfabaf')
  y=3 if name=='button' else 5
  pts=[(cx-7,y+1),(cx-4,y-1),(cx,y+2),(cx+4,y-1),(cx+7,y+1),(cx+7,y+5),(cx,y+12),(cx-7,y+5)]
  d.polygon(pts,fill='#704b67');d.polygon([(x,yy-1) for x,yy in pts],fill='#e9a9b7');d.line([(cx-6,y+1),(cx-4,y),(cx-1,y+3)],fill='#ffe0c7',width=1)
  im.save(A/f'crest_{name}.png')
 print('Generated clean original UI rails, fixed-size floral corners and heart badges')
if __name__=='__main__':generate()
