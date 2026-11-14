"""One-cell masonry with a shared 24px footprint and 12px vertical rise."""
from PIL import Image, ImageDraw
from pathlib import Path
import random
A=Path(__file__).resolve().parents[1]/'assets'
for variant in range(4):
 for joined in (False,True):
  im=Image.new('RGBA',(32,64));d=ImageDraw.Draw(im);r=random.Random(914+variant)
  top=['#8e7b94','#877b94','#957d95','#8b8099'][variant]
  # Ground footprint is x4..27,y31..54; roof rises twelve source pixels.
  if not joined:
   d.polygon([(4,39),(27,39),(27,51),(24,54),(7,54),(4,51)],fill='#51475f')
   d.polygon([(5,40),(25,40),(25,50),(23,52),(7,52),(5,50)],fill='#75617d')
   d.line((6,46,25,46),fill='#584a64');d.line((7,47,24,47),fill='#8c7189')
   d.line((16,47,16,51),fill='#63516c')
   d.line((8,50,11,50),fill='#a08399');d.point((22,49),fill='#b08c9e')
  shape=[(7,19),(24,19),(27,22),(27,39),(24,42),(7,42),(4,39),(4,22)]
  d.polygon(shape,fill=top)
  # Broad bevels and shaded outer shoulders establish height along vertical runs.
  d.polygon([(4,22),(7,19),(7,39),(9,42),(7,42),(4,39)],fill='#a68ba2')
  d.polygon([(24,19),(27,22),(27,39),(24,42),(22,42),(24,39)],fill='#62536f')
  d.line([(4,22),(7,19),(24,19)],fill='#c2a5b6')
  d.line([(8,21),(23,21)],fill='#ad92a8')
  d.line([(7,40),(23,40),(25,38)],fill='#78617f')
  for n in range(17):
   x=r.randrange(8,24);y=r.randrange(23,39)
   d.point((x,y),fill=r.choice(['#a990a6','#9e849d','#7d708a','#b39aaa']))
  x=11+variant%2*4;y=28
  for dx,dy in [(0,0),(2,0),(-1,1),(1,1),(3,1),(0,2),(2,2),(1,3)]:d.point((x+dx,y+dy),fill='#baa0af')
  im.save(A/('wall_stacked' if joined else 'wall_exposed').__add__(('' if variant==0 else str(variant))+'.png'))
