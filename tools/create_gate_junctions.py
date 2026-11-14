"""Standalone orthogonal material junctions; pillar and walls share one RGBA image."""
from PIL import Image,ImageOps,ImageDraw
from pathlib import Path
import json
A=Path(__file__).resolve().parents[1]/'assets';atlas=Image.open(A/'atlas.png').convert('RGBA');ids=json.loads((A/'atlas.json').read_text())
def sprite(name):
 i=ids[name];return atlas.crop((i%16*32,i//16*48,i%16*32+32,i//16*48+48))
for room in ['hedge','stone']:
 for corridor in ['stone','tree']:
  for end in ['top','bottom']:
   im=Image.new('RGBA',(48,112))
   # One wall volume: the narrow shaft grows from its rear top plane.
   # There is no plinth, lower collar or separate block around the shaft.
   stone=sprite('stone')
   im.alpha_composite(stone.crop((4,24,28,44)),(12,61))
   d=ImageDraw.Draw(im)
   d.polygon([(12,61),(15,56),(32,56),(35,61)],fill='#82748f')
   d.line([(12,61),(35,61)],fill='#ac91a8',width=1)
   d.line([(15,56),(32,56)],fill='#a48ca4',width=1)
   # Contact shadow belongs to the wall's top, directly beneath the shaft.
   d.rectangle((18,56,30,58),fill='#514b65')
   shaft=sprite('gate_post').crop((0,0,32,21))
   im.alpha_composite(shaft,(8,37))
   for side,s in [('left',im),('right',ImageOps.mirror(im))]:s.save(A/f'junction_{room}_{corridor}_{end}_{side}.png')
print('Generated 16 material-aware gate junction sprites')
