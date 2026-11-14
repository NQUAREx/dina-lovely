"""Forest variants and material-specific damage, preserving the garden palette."""
from PIL import Image,ImageDraw
from pathlib import Path
import json,random
A=Path(__file__).resolve().parents[1]/'assets';im=Image.open(A/'atlas.png').convert('RGBA');ids=json.loads((A/'atlas.json').read_text())
def get(n):
 i=ids[n];return im.crop((i%16*32,i//16*48,i%16*32+32,i//16*48+48))
def put(n,s):
 global im
 if n not in ids:ids[n]=max(ids.values())+1
 i=ids[n]
 if (i//16+1)*48>im.height:
  b=Image.new('RGBA',(512,(i//16+1)*48));b.paste(im,(0,0));im=b
 im.paste(s,(i%16*32,i//16*48))
for stage in range(1,7):
 s=get('quest_tree');d=ImageDraw.Draw(s);depth=min(4,1+stage//2)
 d.polygon([(12,33),(12+depth,35),(12,38)],fill=(0,0,0,0));d.line((12,32,13+depth,35,12,39),fill='#d6b58d');d.line((13,33,13+depth,35),fill='#6c584e');put('quest_tree_damage'+str(stage),s)
for stage in range(1,4):
 s=get('quest_rock');d=ImageDraw.Draw(s)
 for n in range(stage*3):
  x=5+(n*7)%21;y=20+(n*5)%19
  d.line((x,y,x+2,y+2,x+1,y+4),fill='#586c75');d.line((x+2,y+2,x+5,y+1),fill='#687a80')
 put('quest_rock_damage'+str(stage),s)
for base in ['tree','tree_apples']:
 for v in range(3):
  s=get(base);r=random.Random(827+v);d=ImageDraw.Draw(s)
  for n in range(36):
   x=r.randrange(4,28);y=r.randrange(7,29)
   if s.getpixel((x,y))[3] and s.getpixel((x,y))[1]>s.getpixel((x,y))[0]:d.line((x,y,x+1,y),fill=['#93af91','#6d9781','#a1b99a'][v])
  put(base+'_variant'+str(v),s)
for base in ['hedge_tree','hedge_tree_apples']:
 original=Image.open(A/(base+'.png')).convert('RGBA')
 for v in range(3):
  s=original.copy();d=ImageDraw.Draw(s);r=random.Random(v+771)
  for n in range(65):
   x=r.randrange(8,56);y=r.randrange(5,55)
   c=s.getpixel((x,y))
   if c[3]>220 and c[1]>c[0]:d.line((x,y,x+1,y),fill=['#8daa8b','#739983','#a0b79a'][v])
  s.save(A/(base+'_variant'+str(v)+'.png'))
im.save(A/'atlas.png');(A/'atlas.json').write_text(json.dumps(ids)+'\n')
# Double the exposed stone while retaining the existing foliage lip.
s=Image.open(A/'stone_peek.png').convert('RGBA');stone=s.crop((9,7,17,15)).resize((13,13),Image.Resampling.NEAREST);s.alpha_composite(stone,(4,2));s.save(A/'stone_peek.png')
