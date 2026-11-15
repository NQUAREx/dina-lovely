"""Authored tree variety, visible wood and exact foliage-only masks."""
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1];A=ROOT/'assets';SRC=ROOT/'tools/art_source/tree_palette'
shapes=set()
for variant in range(6):
 plain=Image.open(A/f'hedge_tree_variant{variant}.png').convert('RGBA')
 shapes.add(plain.getchannel('A').tobytes())
 for stem in ['hedge_tree','hedge_tree_apples']:
  name=f'{stem}_variant{variant}'
  im=Image.open(A/f'{name}.png').convert('RGBA');source=Image.open(SRC/f'{name}.png').convert('RGBA');mask=Image.open(A/f'{name}_crown.png').convert('RGBA')
  assert im.getchannel('A').tobytes()==source.getchannel('A').tobytes(),name
  wood=0;leaves=0
  crown_bottom=max(y for y in range(plain.height) for x in range(plain.width) if plain.getpixel((x,y))[3]==255 and plain.getpixel((x,y))[1]>plain.getpixel((x,y))[0]*1.1 and plain.getpixel((x,y))[1]>plain.getpixel((x,y))[2]*.92)
  for n,(p,c,s) in enumerate(zip(im.getdata(),mask.getdata(),source.getdata())):
   assert c[3]<=p[3],name+' crown extends outside tree'
   if n//im.width>crown_bottom and s[3]==255 and s[0]>s[1]*1.06 and s[0]>s[2]*1.1:
    wood+=1;assert p==s and c[3]==0,name+' trunk changed or highlighted'
   if c[3]:leaves+=1
  assert wood>=20 and leaves>100,name+' missing trunk or crown'
assert len(shapes)==6,'Tree silhouette variation lost'
print('PASS six distinct authored silhouettes; visible unchanged trunks; each crown mask excludes wood')
