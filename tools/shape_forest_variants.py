from PIL import Image
from pathlib import Path
import json
A=Path(__file__).resolve().parents[1]/'assets';im=Image.open(A/'atlas.png').convert('RGBA');ids=json.loads((A/'atlas.json').read_text())
for base in ['tree','tree_apples']:
 for v,(w,h) in enumerate([(28,30),(32,28),(30,33)]):
  i=ids[base+'_variant'+str(v)];x=i%16*32;y=i//16*48;s=im.crop((x,y,x+32,y+48));c=s.crop((0,0,32,32)).resize((w,h),Image.Resampling.NEAREST);s.paste((0,0,0,0),(0,0,32,32));s.alpha_composite(c,((32-w)//2,32-h));im.paste(s,(x,y))
for base in ['hedge_tree','hedge_tree_apples']:
 for v,(w,h) in enumerate([(56,62),(64,57),(60,65)]):
  p=A/(base+'_variant'+str(v)+'.png');s=Image.open(p).convert('RGBA');c=s.crop((0,0,64,65)).resize((w,h),Image.Resampling.NEAREST);s.paste((0,0,0,0),(0,0,64,65));s.alpha_composite(c,((64-w)//2,65-h));s.save(p)
im.save(A/'atlas.png')
