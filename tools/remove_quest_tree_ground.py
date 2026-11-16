"""Remove the painted green base from quest tree states; use world floor shadow."""
import json
from pathlib import Path
from PIL import Image
A=Path(__file__).resolve().parents[1]/'assets'
im=Image.open(A/'atlas.png').convert('RGBA');ids=json.loads((A/'atlas.json').read_text())
for name in ['quest_tree']+['quest_tree_damage'+str(i) for i in range(1,7)]:
 i=ids[name]
 for y in range(38,48):
  for x in range(32):
   p=(i%16*32+x,i//16*48+y);r,g,b,a=im.getpixel(p)
   if a and g>r and b>r:im.putpixel(p,(0,0,0,0))
im.save(A/'atlas.png')
