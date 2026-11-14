"""Original crafting sprites, using the existing nearest-filtered atlas and palette."""
from pathlib import Path
from PIL import Image,ImageDraw
import json,random,math
root=Path(__file__).resolve().parents[1];a=root/'assets'
im=Image.open(a/'atlas.png').convert('RGBA');ids=json.loads((a/'atlas.json').read_text());rng=random.Random(71)
new={}
def sprite(name):
 s=Image.new('RGBA',(32,48));new[name]=s;return ImageDraw.Draw(s)
def rock(d,box):
 x,y,w,h=box
 d.polygon([(x,y+3),(x+3,y),(x+w-3,y+1),(x+w,y+h-3),(x+w-4,y+h),(x+1,y+h-1)],fill='#8e9395',outline='#606e78')
 d.line((x+2,y+3,x+4,y+1,x+w-4,y+2),fill='#c3c2b5',width=2)
 d.line((x+2,y+h-2,x+w-4,y+h-1,x+w-1,y+h-4),fill='#737e86',width=2)
d=sprite('quest_tree');d.ellipse((2,39,30,46),fill='#304f48');d.polygon([(12,42),(13,17),(19,17),(21,42)],fill='#8d7160');d.line((15,39,15,19),fill='#c09c79',width=2)
for x,y,r in [(9,17,8),(22,17,9),(15,8,8),(15,20,10),(7,25,6),(26,25,5)]:
 d.ellipse((x-r,y-r,x+r,y+r),fill='#456d61',outline='#365b56');d.arc((x-r+1,y-r+1,x+r-2,y+r-2),190,300,fill='#91ae85',width=2)
 for n in range(15):
  px=x+rng.randrange(-r//2,r//2+1);py=y+rng.randrange(-r//2,r//2+1)
  d.line((px,py,px+1,py),fill=rng.choice(['#78997b','#85a580','#527969','#9cb18b']))
 d.arc((x-r,y-r,x+r,y+r),15,145,fill='#385f55',width=2)
# Bark ridges, roots and branching keep the trunk volumetric at doubled scale.
d.line((14,38,14,31,16,28),fill='#6e6254');d.line((18,40,18,33,17,29),fill='#a98c6e')
d.line((12,42,15,39,19,41,22,42),fill='#6b6253',width=2)
d.line((16,32,21,28),fill='#8d7160',width=2)
d=sprite('quest_stump');d.ellipse((8,36,25,45),fill='#456050');d.rectangle((10,35,23,42),fill='#8d7160');d.ellipse((9,31,24,38),fill='#d2b58f',outline='#92775d');d.arc((12,33,21,37),0,320,fill='#b79973');d.point((14,33),fill='#be7d86');d.point((16,33),fill='#be7d86');d.line((13,34,15,36,17,34),fill='#be7d86');d.line((21,33,19,33,19,34,21,35,21,36,19,36),fill='#805f58')
d=sprite('quest_bench');d.rectangle((3,31,7,44),fill='#796657');d.rectangle((25,31,29,44),fill='#796657');d.rectangle((3,38,29,40),fill='#9b7f66');d.polygon([(1,23),(27,23),(31,28),(31,34),(1,34)],fill='#9d8066',outline='#5c5b53');d.rectangle((2,24,28,28),fill='#c2a380');d.line((3,26,26,26),fill='#aa8a6b');d.line((3,31,28,31),fill='#786554');d.rectangle((6,21,10,25),fill='#8b9290');d.line((9,21,16,17),fill='#9d8066',width=2);d.rectangle((19,22,26,24),fill='#b9b3a1')
d=sprite('quest_rock');rock(d,(3,17,26,26));d.line((17,21,14,27,20,30,16,36),fill='#748089');d.polygon([(8,22),(13,20),(11,24)],fill='#b3b7b0')
d.polygon([(7,25),(13,22),(19,24),(16,31),(7,33)],fill='#a0a6a1');d.polygon([(20,22),(26,26),(27,36),(21,40),(20,32),(16,30)],fill='#818e92')
for x,y in [(9,28),(22,32),(13,37),(19,26),(7,36)]:d.line((x,y,x+1,y),fill='#b4b9ad')
d=sprite('quest_rock_fragments')
for x,y,w,h in [(3,34,10,9),(16,29,11,10),(14,39,8,5)]:rock(d,(x,y,w,h))
d=sprite('quest_pebble');rock(d,(12,38,8,6))
d=sprite('quest_branch');d.line((8,43,24,34),fill='#675c50',width=4);d.line((8,41,24,33),fill='#b29677',width=2);d.line((16,38,16,32),fill='#998269',width=2);d.point((24,33),fill='#d1b795')
d=sprite('pickaxe');d.line((12,43,21,21),fill='#675c51',width=4);d.line((12,42,21,21),fill='#b89a78',width=2);d.polygon([(8,23),(13,18),(22,18),(29,25),(22,22),(14,21)],fill='#a4adae',outline='#637a82');d.line((12,20,22,19,27,23),fill='#d2d2c0')
id=ids['shovel'];old=im.crop((id%16*32,id//16*48,id%16*32+32,id//16*48+48));new['shovel_broken']=old.copy();d=ImageDraw.Draw(new['shovel_broken']);d.rectangle((0,0,31,24),fill=(0,0,0,0));d.line((14,25,17,27,15,29),fill='#d5bb91')
for n,c in enumerate(['#d6a0b6','#b7a8cf','#e8c99a','#e4bcb3','#c7cee5','#e0dfb4']):
 d=sprite('note_flower'+str(n));d.line((16,43,16,39),fill='#87a18b');d.point((14,42),fill='#9dad8d')
 for x,y in [(15,38),(17,38),(16,37),(16,39)]:d.point((x,y),fill=c)
 d.point((16,38),fill='#ebd59e')
for name,s in new.items():
 if name not in ids:ids[name]=max(ids.values())+1
 idx=ids[name];height=(idx//16+1)*48
 if height>im.height:
  bigger=Image.new('RGBA',(512,height));bigger.paste(im,(0,0));im=bigger
 im.paste(s,(idx%16*32,idx//16*48))
im.save(a/'atlas.png');(a/'atlas.json').write_text(json.dumps(ids)+'\n')
# Damage stages and a thicker carved stump, each a standalone atlas sprite.
im=Image.open(a/'atlas.png').convert('RGBA')
def get(name):
 i=ids[name];return im.crop((i%16*32,i//16*48,i%16*32+32,i//16*48+48))
def put(name,s):
 global im
 if name not in ids:ids[name]=max(ids.values())+1
 i=ids[name]
 if (i//16+1)*48>im.height:
  b=Image.new('RGBA',(512,(i//16+1)*48));b.paste(im,(0,0));im=b
 im.paste(s,(i%16*32,i//16*48))
s=get('quest_stump');d=ImageDraw.Draw(s);d.rectangle((8,35,25,43),fill='#98785e');d.ellipse((7,29,26,38),fill='#d6b994',outline='#896c58')
d.polygon([(11,31),(14,30),(17,32),(20,30),(23,31),(23,34),(17,38),(11,34)],fill='#c18d94');d.line((19,32,16,32,15,33,19,34,19,35,16,36),fill='#70565a');put('quest_stump',s)
for base,count in [('quest_tree',6),('quest_rock',3)]:
 for stage in range(1,count+1):
  s=get(base);d=ImageDraw.Draw(s)
  for n in range(stage):
   x=13+n%5;y=29+n*2 if base=='quest_tree' else 21+n*5
   d.line((x,y,x+3,y+2,x+1,y+4,x+4,y+5),fill='#655d59');d.point((x+1,y),fill='#c2ac8f')
  put(base+'_damage'+str(stage),s)
# Tree outline excludes the baked ground shadow.
s=get('quest_tree')
for y in range(48):
 for x in range(32):
  if s.getpixel((x,y))[:3]==(48,79,72):s.putpixel((x,y),(0,0,0,0))
put('quest_tree_outline',s)
im.save(a/'atlas.png');(a/'atlas.json').write_text(json.dumps(ids)+'\n')
