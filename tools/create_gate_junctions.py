"""Standalone orthogonal material junctions; pillar and walls share one RGBA image."""
from PIL import Image,ImageDraw,ImageOps
from pathlib import Path
import json,random
A=Path(__file__).resolve().parents[1]/'assets';atlas=Image.open(A/'atlas.png').convert('RGBA');ids=json.loads((A/'atlas.json').read_text())
def sprite(name):
 i=ids[name];return atlas.crop((i%16*32,i//16*48,i%16*32+32,i//16*48+48))
def wall(material,size,vertical=False):
 im=Image.new('RGBA',size);d=ImageDraw.Draw(im);r=random.Random(717+size[0]*19+size[1])
 if material=='stone':
  tile=sprite('stone').crop((3,20,29,44)).resize((24,24),Image.Resampling.NEAREST)
  for y in range(0,size[1],24):
   for x in range(0,size[0],24):im.alpha_composite(tile,(x,y))
 elif material=='hedge':
  d.rectangle((0,3,size[0]-1,size[1]-1),fill='#305c50')
  for y in range(3,size[1]+5,7):
   for x in range(-2,size[0]+5,8):
    xx=x+r.randrange(-1,2);yy=y+r.randrange(-1,2);d.ellipse((xx-5,yy-4,xx+5,yy+4),fill='#527f60',outline='#3e6a54');d.line((xx-2,yy-2,xx,yy-3,xx+2,yy-2),fill='#8ba67b')
 else:
  for y in range(-9,size[1],22):
   tree=sprite('tree_variant'+str((y//22)%6));tree=tree.resize((24,36),Image.Resampling.NEAREST);im.alpha_composite(tree,((size[0]-24)//2,y))
 return im
for room in ['hedge','stone']:
 for corridor in ['stone','tree']:
  for end in ['top','bottom']:
   im=Image.new('RGBA',(48,112))
   # Room wall reaches the outer edge of the pillar's plinth, at right angles.
   im.alpha_composite(wall(room,(12,14)),(0,69))
   if end=='top':im.alpha_composite(wall(corridor,(24,31),True),(12,8))
   else:im.alpha_composite(wall(corridor,(24,25),True),(12,82))
   # The visible pillar is integrated after clipping both material arms to its edge.
   post=sprite('gate_post');im.alpha_composite(post,(8,37))
   for side,s in [('left',im),('right',ImageOps.mirror(im))]:s.save(A/f'junction_{room}_{corridor}_{end}_{side}.png')
print('Generated 16 material-aware gate junction sprites')
