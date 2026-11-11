"""Small original leaf and petal silhouettes for contact bursts."""
from PIL import Image,ImageDraw
from pathlib import Path
source=Image.open(Path(__file__).resolve().parents[1]/'tools/art_source/classic_leaves.png').convert('RGBA')
im=Image.new('RGBA',(48,8))
shapes=[[(1,5),(2,2),(5,1),(6,1),(6,4),(3,6)],[(1,3),(3,1),(5,1),(6,3),(5,6),(3,6)],[(1,5),(1,3),(3,3),(3,1),(6,1),(6,4),(4,6)],[(1,5),(2,3),(4,1),(6,2),(5,5),(3,6)],[(2,6),(1,3),(2,1),(4,1),(6,3),(5,5)],[(1,4),(2,2),(4,1),(6,3),(6,5),(3,6)]]
for i,shape in enumerate(shapes):
 d=ImageDraw.Draw(im);x=i*8
 d.polygon([(x+a,b) for a,b in shape],fill='#efffe8')
 d.line((x+2,5,x+5,2),fill='#92ba8b')
 d.point((x+3,2),fill='#ffffff')
 if i<4:
  # Preserve actual canopy pixels; silhouettes add no new colors or glow.
  for py in range(8):
   for px in range(8):
    if im.getpixel((x+px,py))[3]==0:continue
    color=source.getpixel((i*3*17+5+px,4+py))
    if color[3]==0:color=source.getpixel((i*3*17+8,8))
    im.putpixel((x+px,py),color)
im.save(Path(__file__).resolve().parents[1]/'assets/leaf_bits.png')
