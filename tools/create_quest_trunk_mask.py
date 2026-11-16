from pathlib import Path
from PIL import Image
import json
A=Path(__file__).resolve().parents[1]/'assets'
ids=json.loads((A/'atlas.json').read_text());atlas=Image.open(A/'atlas.png').convert('RGBA')
for name in ['quest_tree']+['quest_tree_damage'+str(n) for n in range(1,7)]:
 i=ids[name];s=atlas.crop((i%16*32,i//16*48,i%16*32+32,i//16*48+48));mask=Image.new('RGBA',s.size)
 for y in range(25,44):
  for x in range(32):
   r,g,b,a=s.getpixel((x,y))
   if a and r>g*1.10 and r>b*1.10:mask.putpixel((x,y),(255,255,255,255))
 mask.save(A/(name+'_trunk.png'))
