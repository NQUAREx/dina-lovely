"""Original carved keepsake stones and matching sockets, in the existing atlas palette."""
from PIL import Image, ImageDraw, ImageFilter
from pathlib import Path
import json, math
R=Path(__file__).resolve().parents[1]; A=R/'assets'
symbols=['sun','flower','star','moon','heart','leaf','drop']
colors=['#f2cc83','#e6a4c9','#dbce9e','#bdc4ec','#eea5b8','#a6c99c','#9acddd']
def glyph(d,name,x,y,c):
 if name=='sun':
  d.ellipse((x-3,y-3,x+3,y+3),fill=c)
  for n in range(8):
   dx,dy=math.cos(n*math.pi/4),math.sin(n*math.pi/4);d.line((x+dx*5,y+dy*5,x+dx*6,y+dy*6),fill=c)
 elif name=='flower':
  for n in range(5):
   dx,dy=round(math.cos(n*math.tau/5)*4),round(math.sin(n*math.tau/5)*4);d.rectangle((x+dx-2,y+dy-2,x+dx+2,y+dy+2),fill=c)
  d.rectangle((x-1,y-1,x+1,y+1),fill='#fff0bb')
 elif name=='star':d.polygon([(x+math.cos(n*math.pi/5-math.pi/2)*(7 if n%2==0 else 3),y+math.sin(n*math.pi/5-math.pi/2)*(7 if n%2==0 else 3)) for n in range(10)],fill=c)
 elif name=='moon':
  d.ellipse((x-5,y-6,x+5,y+6),fill=c);d.polygon([(x+1,y-6),(x-2,y-3),(x-2,y+2),(x+1,y+5),(x+5,y+5),(x+6,y-6)],fill='#464353')
 elif name=='heart':d.polygon([(x-6,y-3),(x-4,y-5),(x-2,y-5),(x,y-3),(x+2,y-5),(x+4,y-5),(x+6,y-3),(x+6,y),(x,y+6),(x-6,y)],fill=c)
 elif name=='leaf':
  d.polygon([(x-6,y+5),(x-5,y-2),(x+1,y-6),(x+6,y-6),(x+5,y+1),(x,y+5)],fill=c);d.line((x-4,y+3,x+3,y-4),fill='#4e6757')
 elif name=='drop':d.polygon([(x,y-7),(x+5,y),(x+5,y+4),(x+2,y+6),(x-2,y+6),(x-5,y+4),(x-5,y)],fill=c)
def top_glyph(im,name,cx,cy,color,flat=.62):
 mark=Image.new('RGBA',(32,32));glyph(ImageDraw.Draw(mark),name,16,16,color)
 height=round(32*flat);mark=mark.resize((32,height),Image.Resampling.NEAREST)
 rim=Image.new('RGBA',mark.size,'#4a3d56');rim.putalpha(mark.getchannel('A').filter(ImageFilter.MaxFilter(3)))
 im.alpha_composite(rim,(cx-16,cy-height//2));im.alpha_composite(mark,(cx-16,cy-height//2))
def pebble(im,name,cx,cy,color,pressed=False,flat=False):
 d=ImageDraw.Draw(im)
 # A small irregular stone with a lit upper face and a shaded front edge.
 dy=1 if pressed else 0
 outline=[(cx-10,cy-3+dy),(cx-7,cy-7+dy),(cx+3,cy-8+dy),(cx+9,cy-4+dy),(cx+11,cy+1+dy),(cx+7,cy+6+dy),(cx-4,cy+7+dy),(cx-10,cy+3+dy)]
 d.polygon(outline,fill='#51485d')
 d.polygon([(x,y-2) for x,y in outline],fill='#8d8298' if pressed else '#aa93a7')
 d.line([(cx-10,cy-5+dy),(cx-7,cy-9+dy),(cx+3,cy-10+dy),(cx+8,cy-6+dy)],fill='#e2c7c5')
 d.line((cx-8,cy+3+dy,cx-3,cy+5+dy,cx+6,cy+4+dy,cx+9,cy+1+dy),fill='#756178')
 d.point((cx-7,cy-3+dy),fill='#f4dbcd');d.point((cx+7,cy+1+dy),fill='#9b889e')
 top_glyph(im,name,cx,cy-3+dy,color,.62 if flat else .75)
art={}
for i,name in enumerate(symbols):
 item=Image.new('RGBA',(32,48));pebble(item,name,16,35,colors[i]);art['rune_'+name]=item
 for state in ['empty','full','pressed']:
  im=Image.new('RGBA',(32,48));d=ImageDraw.Draw(im)
  # The original lavender block pedestal, with a horizontal bevelled top.
  # The front retains the old inset panel; the socket is only on the upper plane.
  d.polygon([(3,22),(29,22),(29,40),(27,44),(5,44),(3,41)],fill='#57516d')
  d.rectangle((5,28,26,40),fill='#93839b');d.line((6,29,25,29),fill='#c6abba')
  d.line((5,40,26,40),fill='#71617d');d.rectangle((9,33,22,35),fill='#b59aaa')
  d.line((4,28,4,40),fill='#776582');d.line((28,26,28,39),fill='#413e56')
  d.polygon([(3,21),(7,15),(24,15),(29,21),(27,28),(5,28)],fill='#a390a6')
  d.line((4,21,8,16,23,16,28,21),fill='#dfbfc4')
  d.line((5,27,26,27,28,23),fill='#6d5a77')
  # Oval opening sits in perspective on the top, with a deep inner back wall.
  d.polygon([(6,20),(10,17),(22,17),(26,20),(25,24),(21,26),(11,26),(7,24)],fill='#4c445d')
  d.line((8,20,11,18,21,18,24,20),fill='#38364d')
  d.line((8,24,11,25,21,25,24,23),fill='#c6a5af')
  if state=='empty':top_glyph(im,name,16,21,'#82758f',.5)
  else:
   # A separately drawn shallow stone, inset from above. Its complete glyph lies
   # on its top face; no upright plaque or symbol on the front of the pedestal.
   pressed=state=='pressed';cy=21 if pressed else 18
   # Thick plug: bright top, seven-pixel front wall, dark right facet and
   # a narrow lower foot hidden inside the socket. It protrudes above the rim.
   top=[(7,cy-3),(11,cy-7),(21,cy-7),(26,cy-3),(24,cy+2),(20,cy+4),(11,cy+4),(7,cy+1)]
   d.polygon([(7,cy-1),(26,cy-1),(25,cy+6),(21,cy+9),(11,cy+9),(7,cy+5)],fill='#58465e')
   d.polygon([(7,cy),(12,cy+3),(21,cy+3),(21,cy+8),(12,cy+8),(7,cy+5)],fill='#9b7d95')
   d.polygon([(21,cy+2),(26,cy-2),(25,cy+5),(21,cy+8)],fill='#6f5775')
   d.line((12,cy+5,12,cy+7),fill='#c4a0b2');d.line((14,cy+7,19,cy+7),fill='#b090a7')
   d.polygon(top,fill='#ae94ac' if pressed else '#bda2b7')
   d.line((7,cy-3,11,cy-7,21,cy-7,25,cy-3),fill='#f0d1cf')
   d.line((8,cy,12,cy+3,20,cy+3,23,cy+1),fill='#d7b2c1')
   top_glyph(im,name,16,cy-1,colors[i],.65)
   # Foreground lip occludes the buried foot; the visible side remains thick.
   d.line((8,27,11,28,22,28,26,25),fill='#b99aaa')
   d.line((9,29,24,29),fill='#7c657f')
   if pressed:
    d.point((6,25),fill=colors[i]);d.point((26,25),fill=colors[i]);d.line((10,34,21,34),fill=colors[i])
  art['socket_'+name+'_'+state]=im
im=Image.new('RGBA',(32,48));d=ImageDraw.Draw(im)
d.polygon([(4,29),(8,25),(24,25),(28,29),(28,42),(4,42)],fill='#64546c');d.line((7,27,24,27,26,29),fill='#be9baa');d.arc((10,28,23,39),35,325,fill='#e6b6bd',width=2);d.polygon([(10,28),(9,33),(14,30)],fill='#e6b6bd');art['rune_reset']=im
atlas=Image.open(A/'atlas.png').convert('RGBA');ids=json.loads((A/'atlas.json').read_text())
for name,im in art.items():
 if name not in ids:ids[name]=max(ids.values())+1
 n=ids[name];need=(n//16+1)*48
 if need>atlas.height:
  grown=Image.new('RGBA',(512,need));grown.paste(atlas,(0,0));atlas=grown
 atlas.paste(im,((n%16)*32,(n//16)*48))
atlas.save(A/'atlas.png');(A/'atlas.json').write_text(json.dumps(ids))
preview=Image.new('RGBA',(32*7,48*4),'#292737')
for row,state in enumerate(['item','empty','full','pressed']):
 for col,name in enumerate(symbols):preview.alpha_composite(art['rune_'+name if state=='item' else 'socket_'+name+'_'+state],(col*32,row*48))
preview.resize((672,576),Image.Resampling.NEAREST).save('/tmp/rune-art.png')
