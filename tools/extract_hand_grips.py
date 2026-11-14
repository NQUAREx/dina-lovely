"""Read actual glove silhouettes from every shipped frame; no independent walk oscillator."""
from pathlib import Path
from PIL import Image
import json,math
R=Path(__file__).resolve().parents[1];im=Image.open(R/'assets/atlas.png').convert('RGBA');ids=json.loads((R/'assets/atlas.json').read_text());out={}
for face in range(8):
 for frame in range(8 if face in [1,3] else 4):
  i=ids[f'hero{face}_{frame}'];s=im.crop((i%16*32,i//16*48,i%16*32+32,i//16*48+48));pixels={(x,y) for y in range(28,40) for x in range(32) if s.getpixel((x,y))[:3]==(74,67,93) and s.getpixel((x,y))[3]}
  expected=(24.5 if face==0 else 7.5,34+frame%2)
  if face in [1,3]:expected=(16+round(math.sin(frame*math.tau/8)*3),35+(frame in [1,2,5,6]))
  if face>=4:
   b=frame%2;step=[0,2,0,-2][frame];expected={4:(24,32+b-step/2),5:(8,32+b-step/2),6:(7.5,34+b+step/2),7:(24.5,34+b+step/2)}[face]
  groups=[]
  while pixels:
   stack=[pixels.pop()];group=[]
   while stack:
    p=stack.pop();group.append(p)
    for q in [(p[0]+1,p[1]),(p[0]-1,p[1]),(p[0],p[1]+1),(p[0],p[1]-1)]:
     if q in pixels:pixels.remove(q);stack.append(q)
   if len(group)>=3:groups.append(group)
  centers=[((min(x for x,y in g)+max(x for x,y in g))/2,(min(y for x,y in g)+max(y for x,y in g))/2) for g in groups]
  out[f'{face}:{frame}']=min(centers,key=lambda p:(p[0]-expected[0])**2+(p[1]-expected[1])**2) if centers else expected
(R/'assets/hand_grips.json').write_text(json.dumps(out)+'\n')
