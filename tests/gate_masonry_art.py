"""Pillar courses use exactly the projected wall side-face pixels."""
from pathlib import Path
from PIL import Image,ImageOps
A=Path(__file__).resolve().parents[1]/'assets'
course=Image.open(A/'wall_exposed.png').convert('RGBA').crop((4,34,28,54)).resize((24,12),Image.Resampling.NEAREST)
for f in A.glob('junction_*.png'):
 im=Image.open(f).convert('RGBA')
 if f.stem.endswith('right'):im=ImageOps.mirror(im)
 for y in range(12):
  for x in range(24):
   c=course.getpixel((x,y))
   if c[3]==255:assert im.getpixel((12+x,59+y))==c,(f.name,x,y)
print('PASS pillar masonry uses identical projected wall-face pixels')
