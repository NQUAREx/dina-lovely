"""Restore the six authored tree silhouettes and visible trunks; outline foliage only.

The previous procedural redraw reused one lobe arrangement and covered the trunk.
Source snapshots retain the authored geometry; only foliage palette changes here.
"""
from pathlib import Path
from PIL import Image
import json,math
ROOT=Path(__file__).resolve().parents[1]
A=ROOT/'assets';SRC=ROOT/'tools/art_source/tree_palette'
PALETTES=[((30,65,59),(80,126,94),(147,173,116)),((29,66,58),(75,127,94),(137,170,119)),((29,64,62),(77,122,99),(142,171,129)),((34,67,56),(88,129,91),(153,174,117)),((31,66,60),(82,129,101),(145,175,128)),((34,66,56),(88,126,92),(151,170,116))]
def foliage(pixel):
 r,g,b,a=pixel
 return a==255 and g>r*1.10 and g>b*.92

def prepare(source,plain,variant):
 out=source.copy();mask=Image.new('RGBA',source.size)
 low,mid,hi=PALETTES[variant%6]
 for y in range(source.height):
  for x in range(source.width):
   pixel=source.getpixel((x,y));r,g,b,a=pixel
   # Use the matching plain tree as the silhouette, so apples do not create
   # holes and the wood/shadow never leak into the canopy-only highlight.
   if foliage(plain.getpixel((x,y))) and a:
    mask.putpixel((x,y),(255,255,255,a))
   if not foliage(pixel):continue
   lum=(r*.22+g*.65+b*.13)/255
   light=max(0,min(1,(lum-.17)/.52+.10*(.5-x/source.width)+.12*(.45-y/source.height)))
   t=min(1,light*2) if light<.5 else (light-.5)*2
   c0,c1=(low,mid) if light<.5 else (mid,hi)
   out.putpixel((x,y),tuple(round(v*(1-t)+w*t) for v,w in zip(c0,c1))+(a,))
 assert out.getchannel('A').tobytes()==source.getchannel('A').tobytes()
 return out,mask

def plain_name(name):return name.replace('tree_apples','tree')
def generate():
 ids=json.loads((A/'atlas.json').read_text());atlas=Image.open(A/'atlas.png').convert('RGBA');masks=Image.new('RGBA',atlas.size)
 for file in sorted(SRC.glob('*.png')):
  name=file.stem;variant=int(name[-1]) if name[-1].isdigit() else 0
  source=Image.open(file).convert('RGBA')
  plain_file=SRC/(plain_name(name)+'.png')
  plain=Image.open(plain_file if plain_file.exists() else file).convert('RGBA')
  image,crown=prepare(source,plain,variant)
  if name.startswith('atlas_'):
   key=name[6:];i=ids[key];pos=(i%16*32,i//16*48)
   atlas.paste(image,pos);masks.paste(crown,pos)
   if key=='quest_tree':
    i=ids['quest_tree_outline'];pos=(i%16*32,i//16*48);atlas.paste(image,pos);masks.paste(crown,pos)
   if key.startswith('quest_tree_damage') and not key.endswith('_outline'):
    outline=key+'_outline'
    if outline in ids:
     i=ids[outline];pos=(i%16*32,i//16*48);atlas.paste(image,pos);masks.paste(crown,pos)
  else:
   image.save(A/file.name)
   if '_variant' in name:crown.save(A/(name+'_crown.png'))
 atlas.save(A/'atlas.png');masks.save(A/'tree_crowns.png')
 print('PASS restored six authored silhouettes, visible original trunks and matching crown-only masks')
if __name__=='__main__':generate()
