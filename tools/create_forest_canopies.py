"""Six distinct pixel canopies, transparent gate ironwork and a joined tall jamb."""
from pathlib import Path
from PIL import Image,ImageDraw
import json,random
A=Path(__file__).resolve().parents[1]/'assets';atlas=Image.open(A/'atlas.png').convert('RGBA');ids=json.loads((A/'atlas.json').read_text())
def get(n):
 i=ids[n];return atlas.crop((i%16*32,i//16*48,i%16*32+32,i//16*48+48))
def put(n,s):
 global atlas
 if n not in ids:ids[n]=max(ids.values())+1
 i=ids[n]
 if (i//16+1)*48>atlas.height:
  b=Image.new('RGBA',(512,(i//16+1)*48));b.paste(atlas,(0,0));atlas=b
 atlas.paste(s,(i%16*32,i//16*48))
shapes=[[(16,13,10,12),(9,20,8,9),(23,21,8,9),(16,26,10,8)],[(16,10,7,9),(14,19,10,11),(17,27,9,8)],[(10,15,9,10),(23,14,8,10),(16,25,12,9)],[(7,22,7,8),(15,16,10,10),(25,22,7,9),(17,28,9,7)],[(16,8,6,7),(10,16,8,9),(23,18,7,10),(16,27,10,8)],[(10,12,7,8),(21,11,8,9),(8,23,8,9),(23,25,9,9),(16,23,10,10)]]
for v,parts in enumerate(shapes):
 s=Image.new('RGBA',(32,48));d=ImageDraw.Draw(s);r=random.Random(913+v)
 d.ellipse((8,39,25,45),fill=(36,60,56,90));d.polygon([(13,42),(13,25),(18,25),(20,42)],fill='#80645b');d.line((15,40,15,29),fill='#b29274',width=2)
 d.line((15,32,8,25),fill='#80645b',width=2);d.line((17,32,24,25),fill='#80645b',width=2)
 for x,y,rx,ry in parts:
  d.ellipse((x-rx,y-ry,x+rx,y+ry),fill='#244d4c');d.ellipse((x-rx+1,y-ry,x+rx-1,y+ry-3),fill=['#548568','#568573','#59816c','#507f70','#5b8872','#56836c'][v])
  d.arc((x-rx+2,y-ry+1,x+rx-2,y+ry-4),190,290,fill='#83aa73')
  for n in range(9):
   px=x+r.randrange(-rx//2,rx//2+1);py=y+r.randrange(-ry//2,ry//2+1)
   d.line((px,py,px+1,py),fill=r.choice(['#6c987b','#789e80','#91ad82','#456e61']))
 put('tree_variant'+str(v),s)
 apple=s.copy();ad=ImageDraw.Draw(apple)
 for x,y in [(8,21),(23,24),(17,12)]:
  if apple.getpixel((x,y))[3]:ad.rectangle((x,y,x+2,y+2),fill='#c38391');ad.point((x,y),fill='#efb8ab');ad.point((x+1,y-1),fill='#9aac81')
 put('tree_apples_variant'+str(v),apple)
 for base,img in [('hedge_tree',s),('hedge_tree_apples',apple)]:
  # Identical atlas and integrated variants; the special tree pass uses the same ID.
  img.resize((64,96),Image.Resampling.NEAREST).save(A/(base+'_variant'+str(v)+'.png'))
# Clear the formerly solid dark plane between the open bars.
s=get('gate_ajar')
for y in range(48):
 for x in range(32):
  if s.getpixel((x,y))[:3]==(80,62,86):s.putpixel((x,y),(0,0,0,0))
put('gate_ajar',s)
# Same foot and width; extend the shaft/cap upward to meet the preceding wall.
s=get('doorpost');post=Image.new('RGBA',(32,48));post.paste(s.crop((0,14,32,48)),(0,14));post.paste(s.crop((0,7,32,14)),(0,0))
for y in range(7,14):post.paste(s.crop((0,14,32,15)),(0,y))
d=ImageDraw.Draw(post)
d.polygon([(9,38),(24,38),(29,41),(31,43),(31,45),(0,45),(0,43),(3,41)],fill='#958294')
d.line((3,41,28,41),fill='#b6a0ad');d.line((0,45,31,45),fill='#716476')
put('gate_post',post)
atlas.save(A/'atlas.png');(A/'atlas.json').write_text(json.dumps(ids)+'\n')
# A native-scale comparison for review.
preview=Image.new('RGBA',(6*80,120),(48,73,68,255))
for v in range(6):preview.alpha_composite(get('tree_variant'+str(v)).resize((64,96),Image.Resampling.NEAREST),(v*80+8,12))
preview.save('/tmp/forest-canopy-variants.png')
