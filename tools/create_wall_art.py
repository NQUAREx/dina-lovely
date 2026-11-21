"""Extruded chamfered masonry; fixed 24px ground footprint and 20px rise.

The side shell is drawn before the roof, including on stacked tiles. In a
vertical run the next roof occludes the face, but never exposes floor through
its chamfers. Every cut roof corner has a corresponding vertical stone plane.
"""
from PIL import Image, ImageDraw
import random


def wall_art(variant=0):
  im=Image.new('RGBA',(32,64));d=ImageDraw.Draw(im);r=random.Random(914+variant)
  top=['#8e7b94','#887b93','#927d94','#8c8098'][variant]
  # Ground outline stays x4..27,y31..54. The roof is its 20px extrusion.
  roof=[(7,11),(24,11),(27,14),(27,31),(24,34),(7,34),(4,31),(4,14)]
  base=[(x,y+20) for x,y in roof]
  d.polygon(base,fill='#51465e')
  # Full shell: no transparent triangular seam below any roof chamfer.
  for index,p in enumerate(roof):
   q=roof[(index+1)%len(roof)]
   d.polygon([p,q,(q[0],q[1]+20),(p[0],p[1]+20)],fill='#67556f')
  # Left bevel, broad forward face, right bevel and side return.
  d.polygon([(4,31),(7,34),(7,54),(4,51)],fill='#8f768b')
  d.polygon([(7,34),(24,34),(24,54),(7,54)],fill='#75617d')
  d.polygon([(24,34),(27,31),(27,51),(24,54)],fill='#493f58')
  d.polygon([(25,15),(27,14),(27,51),(25,52)],fill='#51435f')
  d.line((5,32,5,50),fill='#ad8e9d')
  # Mortar courses wrap around the cut corners instead of stopping at the roof.
  for y in (40,47):
   d.line((7,y,23,y),fill='#4f435d')
   d.line((8,y+1,23,y+1),fill='#987b90')
   d.line((4,y-3,7,y),fill='#62516d')
   d.line((24,y,27,y-3),fill='#332f48')
  d.line((15,35,15,39),fill='#5a4b64');d.line((19,41,19,46),fill='#584961')
  d.line((12,48,12,52),fill='#584961')
  d.line((7,54,24,54),fill='#38354c')
  d.line((8,52,23,52),fill='#8e7088')
  for x,y in [(10,37),(21,43),(9,50)]:d.line((x,y,x+2,y),fill='#a4889b')
  d.polygon(roof,fill=top)
  # Raised, directional roof bevel gives long vertical runs a solid side edge.
  d.polygon([(4,14),(7,11),(7,31),(9,34),(7,34),(4,31)],fill='#ab8da2')
  d.polygon([(24,11),(27,14),(27,31),(24,34),(22,34),(24,31)],fill='#5a4b68')
  d.line([(4,14),(7,11),(24,11)],fill='#ceb0bd')
  d.line((8,13,23,13),fill='#b298ac')
  d.line([(7,32),(23,32),(25,30)],fill='#6b5877')
  # Pixel mineral clusters, never smooth shading.
  for n in range(17):
   x=r.randrange(8,24);y=r.randrange(15,31)
   d.point((x,y),fill=r.choice(['#a58b9f','#9b829b','#7d708a','#b39aaa']))
  x=11+variant%2*4;y=20
  for dx,dy in [(0,0),(2,0),(-1,1),(1,1),(3,1),(0,2),(2,2),(1,3)]:d.point((x+dx,y+dy),fill='#baa0af')
  return im
