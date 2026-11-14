"""Structural continuity checks for independently rendered portal artwork."""
from PIL import Image,ImageOps
from pathlib import Path
A=Path(__file__).resolve().parents[1]/'assets'
for room in ['stone','hedge']:
 for corridor in ['stone','tree']:
  for end in ['top','bottom']:
   left=Image.open(A/f'junction_{room}_{corridor}_{end}_left.png').convert('RGBA')
   right=Image.open(A/f'junction_{room}_{corridor}_{end}_right.png').convert('RGBA')
   assert left.size==(48,112)
   assert ImageOps.mirror(left).tobytes()==right.tobytes()
   # One connected masonry structure must reach room and corridor edge.
   points={(x,y) for y in range(112) for x in range(48) if left.getpixel((x,y))[3]>200}
   reached=set();stack=[min(points)]
   while stack:
    p=stack.pop()
    if p in reached:continue
    reached.add(p)
    for q in [(p[0]-1,p[1]),(p[0]+1,p[1]),(p[0],p[1]-1),(p[0],p[1]+1)]:
     if q in points and q not in reached:stack.append(q)
   assert len(reached)>=len(points)*.98,(room,corridor,end,'disconnected structure')
   assert any(x==0 for x,y in reached)
   assert any(y==(0 if end=='top' else 111) for x,y in reached)
arch=Image.open(A/'gate_lintel.png').convert('RGBA')
assert arch.size==(128,48)
assert any(arch.getpixel((x,10))[3] for x in range(128))
print('PASS mirrored connected portal tiles and separate overhead lintel')
