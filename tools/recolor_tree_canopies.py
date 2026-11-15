"""Distinct sunlit tree palettes; preserve silhouettes, trunks, fruit and alpha exactly."""
from pathlib import Path
from PIL import Image
import json,math
ROOT=Path(__file__).resolve().parents[1];SRC=ROOT/'tools/art_source/tree_palette';A=ROOT/'assets'
# Cohesive hedge greens: modest warm/cool variation, shared teal shadows and sage highlights.
PALETTES=[((30,65,59),(80,126,94),(147,173,116)),((29,66,58),(75,127,94),(137,170,119)),((29,64,62),(77,122,99),(142,171,129)),((34,67,56),(88,129,91),(153,174,117)),((31,66,60),(82,129,101),(145,175,128)),((34,66,56),(88,126,92),(151,170,116))]
def recolor(im,variant):
 out=im.copy();low,mid,hi=PALETTES[variant%6]
 for y in range(im.height):
  for x in range(im.width):
   r,g,b,a=im.getpixel((x,y))
   # Restrict to foliage: fruit, wood and soft ground shadows are untouched.
   if a!=255 or not (g>r*1.10 and g>b*.92):continue
   lum=(r*.22+g*.65+b*.13)/255
   light=max(0,min(1,(lum-.17)/.52 + .10*(.5-x/im.width)+.12*(.45-y/im.height)))
   # Coherent two-source-pixel leaf clusters add a quiet living surface.
   cluster=math.sin((x//max(1,im.width//32))*1.7+(y//max(1,im.height//48))*2.3+variant)*.035
   light=max(0,min(1,light+cluster));t=min(1,light*2) if light<.5 else (light-.5)*2
   c0,c1=(low,mid) if light<.5 else (mid,hi)
   out.putpixel((x,y),tuple(round(v*(1-t)+w*t) for v,w in zip(c0,c1))+(a,))
 assert im.getchannel('A').tobytes()==out.getchannel('A').tobytes()
 return out
atlas=Image.open(A/'atlas.png').convert('RGBA');ids=json.loads((A/'atlas.json').read_text())
for f in sorted(SRC.glob('*.png')):
 name=f.stem;variant=int(name[-1]) if name[-1].isdigit() else 0
 im=recolor(Image.open(f).convert('RGBA'),variant)
 if name.startswith('atlas_'):
  i=ids[name[6:]];atlas.paste(im,(i%16*32,i//16*48))
 else:im.save(A/f.name)
atlas.save(A/'atlas.png')
print('PASS: recolored standalone/atlas canopies; all source alpha masks preserved')
