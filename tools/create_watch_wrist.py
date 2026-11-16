"""Keep the Casio on the anatomical left wrist, even when it is occluded."""
from pathlib import Path
from PIL import Image, ImageDraw
import json,math
A=Path(__file__).resolve().parents[1]/'assets'
def generate():
 atlas=Image.open(A/'atlas.png').convert('RGBA');ids=json.loads((A/'atlas.json').read_text())
 sheet=Image.new('RGBA',(8*96,8*144),'#242538')
 for face in range(8):
  for frame in range(8 if face in [1,3] else 4):
   i=ids[f'hero{face}_{frame}'];base=atlas.crop((i%16*32,i//16*48,i%16*32+32,i//16*48+48))
   overlay=Image.new('RGBA',(32,48));d=ImageDraw.Draw(overlay)
   b=frame%2;step=[0,2,0,-2][frame%4]
   expected={0:(7.5,33+b),2:(24.5,33+b),4:(7.5,33+b+step/2),5:(8,31+b-step/2),6:(24,31+b-step/2),7:(24.5,33+b+step/2)}.get(face)
   if face==1:expected=(16-round(math.sin(frame*math.tau/8)*3)+.5,35.5+(frame in [1,2,5,6]))
   # Looking right exposes the right arm. The left wrist is behind the torso,
   # so the watch must disappear rather than teleport onto the visible arm.
   if expected is not None:
    pixels={(x,y) for y in range(28,40) for x in range(32) if base.getpixel((x,y))[:3]==(74,67,93) and base.getpixel((x,y))[3]}
    groups=[]
    while pixels:
     stack=[pixels.pop()];group=[]
     while stack:
      q=stack.pop();group.append(q)
      for n in [(q[0]-1,q[1]),(q[0]+1,q[1]),(q[0],q[1]-1),(q[0],q[1]+1)]:
       if n in pixels:pixels.remove(n);stack.append(n)
     if len(group)>=3:groups.append(group)
    group=min(groups,key=lambda g:sum((sum(p[k] for p in g)/len(g)-expected[k])**2 for k in [0,1]))
    x=round(sum(p[0] for p in group)/len(group));y=min(p[1] for p in group)+1
    d.rectangle((x-2,y,x+1,y+1),fill='#b36c94');d.rectangle((x-1,y-1,x,y+2),fill='#f0b1cc');d.point((x-1,y),fill='#fff1e5');d.point((x,y+1),fill='#9e739e')
   i=ids[f'wear_pink_watch_{face}_{frame}'];atlas.paste(overlay,(i%16*32,i//16*48))
   tile=base.copy();tile.alpha_composite(overlay);sheet.alpha_composite(tile.resize((96,144),Image.Resampling.NEAREST),(face*96,frame*144))
 atlas.save(A/'atlas.png');sheet.save('/tmp/watch-left-wrist.png')
 print('Generated left-wrist Casio overlays for all 40 facing/frame poses')
if __name__=='__main__':generate()
