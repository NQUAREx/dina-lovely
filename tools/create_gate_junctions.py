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
   # Same 24x24 ground footprint as the wall, raised 40 source pixels.
   d=ImageDraw.Draw(im)
   d.polygon([(12,48),(35,48),(35,88),(32,91),(15,91),(12,88)],fill='#51475f')
   d.rectangle((14,51,32,87),fill='#7c6a87')
   d.line((13,51,13,87),fill='#a18a9f')
   d.line((33,51,33,88),fill='#62536f')
   # Recessed face panel is below the roof, never painted across its top plane.
   d.rectangle((17,58,29,81),fill='#51485f')
   d.line((17,58,29,58),fill='#b096a9');d.line((17,58,17,81),fill='#a088a0')
   d.rectangle((19,60,28,79),fill='#665771')
   d.line((19,79,28,79),fill='#8c7690')
   d.rectangle((20,61,27,64),fill='#d2ae79');d.line((20,61,27,61),fill='#ecd1a4')
   d.polygon([(15,28),(32,28),(35,31),(35,48),(32,51),(15,51),(12,48),(12,31)],fill='#95819a')
   d.polygon([(12,31),(15,28),(15,47),(17,51),(15,51),(12,48)],fill='#b499ac')
   d.polygon([(32,28),(35,31),(35,48),(32,51),(30,51),(32,47)],fill='#695a76')
   d.line([(12,31),(15,28),(32,28)],fill='#d0b0c0')
   d.line((16,30,31,30),fill='#b99db1');d.line((15,49,31,49),fill='#7a6582')
   # Quiet inset on the cap, with small flecks in the stone.
   d.rectangle((18,34,29,44),fill='#8a748e')
   d.line((18,34,29,34),fill='#79647f');d.line((18,44,29,44),fill='#b295a9')
   for x,y in [(16,32),(30,38),(17,46),(25,32),(15,55),(31,72),(15,84)]:d.point((x,y),fill='#bea0b2')
   d.line((14,85,32,85),fill='#a0869d');d.line((15,89,32,89),fill='#443c55')
   for dx,dy in [(0,0),(3,0),(-1,1),(1,1),(2,1),(4,1),(0,2),(1,2),(2,2),(3,2),(1,3),(2,3)]:d.point((22+dx,70+dy),fill='#c49aaa')
   for side,s in [('left',im),('right',ImageOps.mirror(im))]:s.save(A/f'junction_{room}_{corridor}_{end}_{side}.png')
print('Generated 16 material-aware gate junction sprites')
