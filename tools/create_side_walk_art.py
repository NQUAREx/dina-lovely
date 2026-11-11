"""Original eight-frame lateral walk cycles and aligned wardrobe layers."""
from pathlib import Path
import runpy,math
from PIL import Image,ImageDraw
R=Path(__file__).resolve().parents[1]
art=runpy.run_path(str(R/'tools/create_diagonal_art.py'));save=art['save'];ns=art['ns']
def profile(face,bob):
 # Rounded side opening stays two pixels inside the hood's outer silhouette.
 points=[]
 for i in range(24):
  angle=i*math.tau/24
  x=round(18.5+3.5*math.cos(angle));y=round(21.5+5.5*math.sin(angle))+bob
  points.append((x if face==3 else 32-x,y))
 return points

def pose(face,frame):
 im=Image.new('RGBA',(32,48));d=ImageDraw.Draw(im);s=1 if face==3 else -1
 phase=frame*math.tau/8;stride=round(math.sin(phase)*3);bob=1 if frame in [1,2,5,6] else 0;trail=round(math.sin(phase-.6)*2)
 # Feet move in opposite phases; skirt opens only enough to reveal the step.
 for offset,step in [(-2,-stride),(2,stride)]:
  x=16+offset+step;d.rectangle((x-2,41-bob,x+2,45-bob),fill='#302d48');d.line((x,45-bob,x+s*3,45-bob),fill='#77718a',width=2)
 far=16-stride*s
 d.line((16,28+bob,far,35+bob),fill='#403c58',width=3)
 d.polygon([(12,24+bob),(21,24+bob),(24-s+trail,42),(20+stride//2,44),(9+trail,43),(8+trail,41)],fill='#302d48')
 d.polygon([(14,26+bob),(19,26+bob),(21+trail,41),(13+trail,43),(11+trail,41)],fill='#55516c')
 d.line((14-s,29+bob,12+trail,38,12+trail,41),fill='#77718a')
 d.line((19+s,29+bob,20+trail,37,22+trail,42),fill='#403c58',width=2)
 d.line((10+trail,42,15+trail,43,22+trail,42),fill='#bd9eaf')
 d.rounded_rectangle((7,7+bob,25,29+bob),7,fill='#65576d')
 # Long back fold and narrow featureless profile, with the hood facing sideways.
 back=9 if s>0 else 23
 d.polygon([(8,16+bob),(24,16+bob),(24-s*2,30+bob),(back-s*2+trail,35+bob),(back-s*3,26+bob)],fill='#8e7c90')
 d.line((11+s,12+bob,16+s*2,9+bob,22+s,13+bob),fill='#c7b0be',width=2)
 d.polygon(profile(face,bob),fill='#d6a383',outline='#8e7c90')

 d.line((back,17+bob,back-s,27+bob,back-s*2+trail,31+bob),fill='#65576d')
 near=16+stride*s
 d.line((17,29+bob,near,35+bob),fill='#55516c',width=4)
 d.rectangle((near-1,34+bob,near+2,37+bob),fill='#4a435d')
 d.point((22+s,12+bob),fill='#f3d19c')
 return im,bob,near

def layer(item,face,frame,base,bob,near):
 im=Image.new('RGBA',(32,48));d=ImageDraw.Draw(im);s=1 if face==3 else -1
 palette=ns['DRESS_PALETTES'].get(item) or ns['SCARF_PALETTES'].get(item)
 if palette:
  palette={tuple(bytes.fromhex(k)):tuple(bytes.fromhex(v)) for k,v in palette.items()}
  for y in range(48):
   for x in range(32):
    c=base.getpixel((x,y))
    if c[3] and c[:3] in palette:im.putpixel((x,y),palette[c[:3]]+(255,))
 elif item in ns['HEAD_ITEMS']:
  tmp=Image.new('RGBA',(32,48));ns['head_piece'](ImageDraw.Draw(tmp),item,bob)
  for y in range(24):
   for x in range(32):
    c=tmp.getpixel((x,y))
    if c[3]:im.putpixel((round(16+(x-16)*.73)+s,y),c)
 elif item in ['veil','white_veil']:
  d.polygon(profile(face,bob),fill='#d3cedb' if item=='white_veil' else '#4e4057')
  left,right=(18,21) if s>0 else (11,14)
  d.rectangle((left,19+bob,right,20+bob),fill=(0,0,0,0))
 elif item=='pink_watch':
  d.rectangle((near-1,34+bob,near+2,35+bob),fill='#b36c94');d.rectangle((near,33+bob,near+1,36+bob),fill='#f0b1cc');d.point((near,34+bob),fill='#fff1e5')
 return im
for face in [1,3]:
 for frame in range(8):
  base,bob,near=pose(face,frame);save(f'hero{face}_{frame}',base)
  for item in ns['ACCESSORIES']:save(f'wear_{item}_{face}_{frame}',layer(item,face,frame,base,bob,near))
# save() retains its atlas in the original module namespace.
atlas=save.__globals__['atlas'];names=save.__globals__['names']
atlas.save(R/'assets/atlas.png')
import json
(R/'assets/atlas.json').write_text(json.dumps(names))
