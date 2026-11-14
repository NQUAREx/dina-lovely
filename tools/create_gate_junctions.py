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
   # A full-cell tall masonry pier, with the same base plane as wall tiles.
   d=ImageDraw.Draw(im)
   d.polygon([(12,39),(15,35),(33,35),(36,39),(36,80),(12,80)],fill='#514b65')
   d.rectangle((13,40,34,79),fill='#756780')
   d.polygon([(12,39),(15,35),(33,35),(36,39)],fill='#aa91a6')
   d.line((13,40,13,78),fill='#95819b')
   d.line((35,40,35,79),fill='#48465e')
   for y in [48,59,70]:
    d.line((14,y,34,y),fill='#514b65')
    d.line((14,y+1,33,y+1),fill='#88758e')
   for x,y in [(24,41),(20,49),(28,60),(22,71)]:
    d.line((x,y,x,y+8),fill='#5d526e')
   d.rectangle((20,52,27,56),fill='#d9b77f')
   d.line((20,52,27,52),fill='#efcfa1')
   for side,s in [('left',im),('right',ImageOps.mirror(im))]:s.save(A/f'junction_{room}_{corridor}_{end}_{side}.png')
print('Generated 16 material-aware gate junction sprites')
