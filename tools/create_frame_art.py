"""Original pixel artwork for the pause control and page/game seam garlands."""
from PIL import Image, ImageDraw
from pathlib import Path
import random
root = Path(__file__).resolve().parents[1] / 'assets'
icon = Image.new('RGBA', (32, 32))
d = ImageDraw.Draw(icon)
for x in (6, 20):
 d.rectangle((x,5,x+6,27),fill='#171e30');d.rectangle((x-1,3,x+5,24),fill='#d19aab');d.rectangle((x,3,x+5,22),fill='#ffead0');d.line((x,3,x+4,3),fill='#fff9e9');d.line((x+5,5,x+5,23),fill='#d6b0b1')
icon.save(root/'pause_icon.png')
for bottom in (False,True):
 rng=random.Random(241+bottom);im=Image.new('RGBA',(270,40));d=ImageDraw.Draw(im)
 for x in range(-10,280,3):
  y=18+int(3*__import__('math').sin(x*.065));y=39-y if bottom else y
  d.ellipse((x-6,y-4,x+7,y+8),fill='#172f38');d.ellipse((x-5,y-6,x+6,y+4),fill='#345848')
 for x in range(-4,278,7):
  y=18+rng.randrange(-4,5);y=39-y if bottom else y
  for side in (-1,1):
   yy=y+side*rng.randrange(3,8);xx=x+rng.randrange(-2,3)
   d.polygon([(xx-5,yy),(xx-2,yy-4),(xx+5,yy-3),(xx+6,yy+1),(xx+2,yy+4),(xx-4,yy+3)],fill=rng.choice(['#527653','#65865b','#416b51']))
   d.line((xx-3,yy+1,xx+3,yy-1),fill='#92a771')
 for x in range(12,270,27):
  y=17+rng.randrange(-3,4);y=39-y if bottom else y
  if (x//27)%2==0:
   points=[(x-5,y-3),(x-2,y-3),(x,y-1),(x+2,y-3),(x+5,y-3),(x+6,y),(x+5,y+3),(x,y+8),(x-5,y+3),(x-6,y)]
   d.polygon([(a,b+2) for a,b in points],fill='#533d50');d.polygon(points,fill='#d37a95');d.line((x-4,y-2,x-2,y-2,x,y),fill='#ffd3c6',width=1)
  else:
   for dx,dy in [(0,-4),(4,0),(0,4),(-4,0)]:
    d.rectangle((x+dx-2,y+dy-2,x+dx+2,y+dy+2),fill='#79546c');d.rectangle((x+dx-2,y+dy-3,x+dx+1,y+dy),fill='#edb8c2')
   d.rectangle((x-1,y-2,x+1,y+1),fill='#f9d99a')
 im.save(root/('frame_bottom.png' if bottom else 'frame_top.png'))
