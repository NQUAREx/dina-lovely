"""Original top-down tree crowns. Fruit/trunks stay separate from outline masks."""
from pathlib import Path
from PIL import Image,ImageDraw
import random,json,math
A=Path(__file__).resolve().parents[1]/'assets'
PALETTES=[('#29453e','#3b604b','#527e5b','#6d9565','#94ac78'),('#29473e','#3e644c','#557f5c','#73976a','#95ad7c'),('#29463f','#3c6250','#507c62','#6c946e','#8ca982'),('#30483c','#45654b','#5c805a','#789867','#9aae7a'),('#2c483f','#416650','#568263','#71996f','#94ad80'),('#2f473b','#45634b','#5b7e59','#769367','#99aa79')]
def tree(variant,apples=False,damage=0):
 rng=random.Random(764+variant*31);p=PALETTES[variant%6]
 im=Image.new('RGBA',(32,48));d=ImageDraw.Draw(im)
 d.ellipse((8,39,24,45),fill=(30,63,56,125))
 # Only a short glimpse of trunk below a broad, nearly horizontal crown.
 d.rectangle((14,34,18,41),fill='#6f625a');d.rectangle((14,35,15,40),fill='#95816c');d.line((18,36,18,41),fill='#514c49')
 mask=Image.new('L',(32,48));m=ImageDraw.Draw(mask)
 lobes=[(4,20,20,35),(12,18,28,35),(5,12,20,28),(13,11,27,27),(2,24,16,37),(16,23,29,37),(9,25,24,39)]
 if variant%3==1:lobes[2]=(3,14,19,29);lobes[3]=(13,10,27,27)
 if variant%3==2:lobes[0]=(2,18,19,34);lobes[-1]=(7,25,24,38)
 for b in lobes:m.ellipse(b,fill=255)
 crown=Image.new('RGBA',(32,48));c=ImageDraw.Draw(crown)
 # Rounded clusters viewed from above, dark skirt only at lower rim.
 for y in range(48):
  for x in range(32):
   if not mask.getpixel((x,y)):continue
   edge=any(not (0<=x+dx<32 and 0<=y+dy<48) or not mask.getpixel((x+dx,y+dy)) for dx,dy in [(1,0),(-1,0),(0,1),(0,-1)])
   shade=0 if edge else (1 if y>33 else 2)
   crown.putpixel((x,y),(*ImageColor(p[shade]),255))
 # Shallow overlapping leaf domes, highlight arcs follow the top plane.
 for n,b in enumerate(lobes):
  x0,y0,x1,y1=b;cx=(x0+x1)/2;cy=(y0+y1)/2
  for y in range(y0+2,y1-2):
   for x in range(x0+2,x1-2):
    rr=((x-cx)/(max(1,(x1-x0)/2-1)))**2+((y-cy)/(max(1,(y1-y0)/2-1)))**2
    if rr<.60 and mask.getpixel((x,y)):
     shade=3 if y<cy else 2
     if rr<.22 and y<cy and n in [2,3]:shade=4
     crown.putpixel((x,y),(*ImageColor(p[shade]),255))
  c.line((x0+4,y0+3,x1-4,y0+3),fill=p[3])
 for _ in range(60):
  x=rng.randrange(4,28);y=rng.randrange(13,37)
  if mask.getpixel((x,y)):
   col=p[3] if rng.random()<.65 else p[1];c.line((x,y,min(29,x+1),y),fill=col)
 if apples:
  for x,y in [(8+variant%3,25),(19,18+variant%2),(23-variant%2,32)]:
   c.rectangle((x,y,x+2,y+2),fill='#be8897');c.point((x,y),fill='#e0b1b0');c.point((x+1,y-1),fill=p[0])
 if damage:
  for n in range(damage):
   x=8+n*3;y=30+(n%2)*2;c.line((x,y,x+2,y+3),fill=p[0]);c.point((x+1,y),fill=p[4])
 im.alpha_composite(crown)
 return im,crown

def ImageColor(s):return tuple(bytes.fromhex(s[1:]))
def generate():
 ids=json.loads((A/'atlas.json').read_text());atlas=Image.open(A/'atlas.png').convert('RGBA');masks=Image.new('RGBA',atlas.size)
 for name,i in ids.items():
  if name not in ['tree','tree_apples','hedge_tree','hedge_tree_apples','quest_tree','quest_tree_outline'] and not name.startswith(('tree_variant','tree_apples_variant','quest_tree_damage')):continue
  v=int(name[-1]) if name[-1].isdigit() else 0
  damage=int(name[len('quest_tree_damage')]) if name.startswith('quest_tree_damage') else 0
  im,crown=tree(v%6,'apples' in name,damage)
  atlas.paste(im,(i%16*32,i//16*48));masks.paste(crown,(i%16*32,i//16*48))
 atlas.save(A/'atlas.png');masks.save(A/'tree_crowns.png')
 for fruit in [False,True]:
  stem='hedge_tree_apples' if fruit else 'hedge_tree'
  for v in range(6):
   im,crown=tree(v,fruit)
   im.resize((64,96),Image.Resampling.NEAREST).save(A/f'{stem}_variant{v}.png')
   crown.resize((64,96),Image.Resampling.NEAREST).save(A/f'{stem}_variant{v}_crown.png')
  im,crown=tree(0,fruit);im.resize((64,96),Image.Resampling.NEAREST).save(A/f'{stem}.png')
 print('Generated broad top-down tree crowns, short trunks and independent canopy masks')
if __name__=='__main__':generate()
