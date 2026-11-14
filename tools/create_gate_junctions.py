"""Standalone orthogonal material junctions; pillar and walls share one RGBA image."""
from PIL import Image,ImageOps
from pathlib import Path
import json
A=Path(__file__).resolve().parents[1]/'assets';atlas=Image.open(A/'atlas.png').convert('RGBA');ids=json.loads((A/'atlas.json').read_text())
def sprite(name):
 i=ids[name];return atlas.crop((i%16*32,i//16*48,i%16*32+32,i//16*48+48))
for room in ['hedge','stone']:
 for corridor in ['stone','tree']:
  for end in ['top','bottom']:
   im=Image.new('RGBA',(48,112))
   # Same ground footprint and perspective as the ordinary wall tile. The
   # taller post overlaps it, rather than replacing a hole in the wall.
   im.alpha_composite(sprite('stone'),(8,37))
   im.alpha_composite(sprite('gate_post'),(8,37))
   for side,s in [('left',im),('right',ImageOps.mirror(im))]:s.save(A/f'junction_{room}_{corridor}_{end}_{side}.png')
print('Generated 16 material-aware gate junction sprites')
