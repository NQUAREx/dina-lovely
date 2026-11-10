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

# Seven authored page fabrics: dusk ivy, night sky, mechanisms, excavation,
# courage, seed garden and the final celebration. No maze-green background.
from PIL import ImageColor
palettes = [
 ('#302a43','#564666','#987694','#df9db3'),
 ('#131d35','#293755','#7588a4','#b5cbd4'),
 ('#342d38','#5c4652','#af8879','#e0b68b'),
 ('#403139','#705247','#b18c6b','#ecd0a1'),
 ('#352735','#654253','#b97c89','#e9b69d'),
 ('#3b2e46','#68536b','#bca49c','#f4c7cc'),
 ('#493744','#8b6975','#d3ae8a','#fff0cf')]
def heart(draw,x,y,c):
 draw.polygon([(x-4,y-2),(x-1,y-2),(x,y),(x+1,y-2),(x+4,y-2),(x+5,y),(x+4,y+3),(x,y+7),(x-4,y+3),(x-5,y)],fill=c)
def motif(draw,room,x,y,p):
 base,shadow,accent,light=p
 if room==0:
  draw.arc((x-12,y-9,x+12,y+13),190,355,fill=accent,width=2)
  for side in [-1,1]:
   for n in range(3):draw.polygon([(x+side*(5+n*3),y+5-n*3),(x+side*(11+n*2),y+2-n*3),(x+side*(9+n*3),y+8-n*3)],fill=accent)
  heart(draw,x,y-5,light)
 elif room==1:
  draw.ellipse((x-8,y-11,x+8,y+5),fill=light);draw.ellipse((x-3,y-13,x+11,y+1),fill=base)
  for dx,dy in [(-12,8),(9,12),(15,-7)]:draw.line((x+dx-2,y+dy,x+dx+2,y+dy),fill=accent);draw.line((x+dx,y+dy-2,x+dx,y+dy+2),fill=accent)
 elif room==2:
  for dx,dy in [(0,-10),(10,0),(0,10),(-10,0),(-7,-7),(7,7),(-7,7),(7,-7)]:draw.rectangle((x+dx-2,y+dy-2,x+dx+2,y+dy+2),fill=accent)
  draw.ellipse((x-9,y-9,x+9,y+9),fill=accent);draw.ellipse((x-5,y-5,x+5,y+5),fill=shadow);draw.rectangle((x-2,y-2,x+2,y+2),fill=light)
 elif room==3:
  draw.line((x-9,y+12,x+6,y-10),fill=light,width=3);draw.polygon([(x-12,y+9),(x-5,y+14),(x-14,y+19),(x-17,y+14)],fill=accent)
  draw.line((x+4,y-12,x+11,y-7),fill=accent,width=2)
  for dx,dy in [(10,9),(17,13),(8,17)]:draw.polygon([(x+dx-2,y+dy),(x+dx,y+dy-2),(x+dx+3,y+dy),(x+dx+1,y+dy+2)],fill=shadow)
 elif room==4:
  draw.polygon([(x-10,y-10),(x+10,y-10),(x+9,y+3),(x,y+13),(x-9,y+3)],fill=accent);draw.polygon([(x-7,y-7),(x+7,y-7),(x+6,y+2),(x,y+9),(x-6,y+2)],fill=shadow);heart(draw,x,y-3,light)
 elif room==5:
  draw.rectangle((x-1,y-2,x+1,y+11),fill=accent);draw.polygon([(x,y+7),(x-10,y+1),(x-9,y+8),(x,y+10)],fill=accent)
  for dx,dy in [(0,-7),(6,-2),(3,5),(-3,5),(-6,-2)]:draw.ellipse((x+dx-3,y+dy-3,x+dx+3,y+dy+3),fill=light)
  draw.rectangle((x-2,y-3,x+2,y+1),fill=accent);draw.polygon([(x-8,y+12),(x+8,y+12),(x+5,y+21),(x-5,y+21)],fill=shadow)
 else:
  draw.rectangle((x-9,y+5,x+9,y+8),fill=accent);draw.rectangle((x-2,y-9,x+2,y+5),fill=light);draw.ellipse((x-2,y-16,x+2,y-11),fill=accent);heart(draw,x-11,y-7,light);heart(draw,x+11,y-7,light)
for room,palette in enumerate(palettes):
 rng=random.Random(521+room);base,shadow,accent,light=palette
 fabric=Image.new('RGBA',(96,96),base);fd=ImageDraw.Draw(fabric)
 # Quiet textile/pixel detail, not another playable grass texture.
 for n in range(190):
  x=rng.randrange(96);y=rng.randrange(96)
  fd.line((x,y,x+1,y),fill=shadow)
 for x,y in [(24,23),(72,71)]:motif(fd,room,x,y,palette)
 for x,y in [(70,18),(18,70)]:
  fd.line((x-3,y,x+3,y),fill=accent);fd.line((x,y-3,x,y+3),fill=accent);fd.point((x,y),fill=light)
 fabric.save(root/f'frame_field_{room}.png')
 for edge in ('top','bottom'):
  border=Image.open(root/f'frame_{edge}.png').convert('RGBA');pix=border.load()
  for y in range(40):
   for x in range(270):
    r,g,b,a=pix[x,y]
    if a:
     if g>r*.95 and g>b*.9:
      if g>150:
       ca=ImageColor.getrgb(accent);cl=ImageColor.getrgb(light);target=tuple((ca[i]+cl[i])//2 for i in range(3))
      elif g>115:target=ImageColor.getrgb(accent)
      elif g>90:
       ca=ImageColor.getrgb(accent);cs=ImageColor.getrgb(shadow);target=tuple((ca[i]+cs[i])//2 for i in range(3))
      else:target=ImageColor.getrgb(shadow)
      pix[x,y]=(*target,a)
     elif r>g*1.12:pix[x,y]=(*ImageColor.getrgb(light if r>220 else accent),a)
  bd=ImageDraw.Draw(border)
  # Room-specific marks repeat in the dense border as well as the page fabric.
  for x in range(34,270,68):
   if room==1:
    bd.line((x-2,17,x+2,17),fill=light);bd.line((x,15,x,19),fill=light)
   elif room==2:bd.ellipse((x-3,15,x+3,21),outline=light);bd.point((x,18),fill=light)
   elif room==3:bd.polygon([(x-3,18),(x,14),(x+4,18),(x,21)],fill=light)
   elif room==4:bd.polygon([(x-3,14),(x+3,14),(x+3,18),(x,22),(x-3,18)],outline=light)
   elif room==5:
    for dx,dy in [(0,-2),(2,0),(0,2),(-2,0)]:bd.rectangle((x+dx-1,18+dy-1,x+dx+1,18+dy+1),fill=light)
   elif room==6:bd.line((x-3,20,x-3,15,x,18,x+3,15,x+3,20,x-3,20),fill=light)
  border.save(root/f'frame_{edge}_{room}.png')
