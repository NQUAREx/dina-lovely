"""Deterministic ground relief, cut foliage and a partly buried stone. Original pixel art."""
from pathlib import Path
from PIL import Image, ImageDraw
import random
R=Path(__file__).resolve().parents[1]; A=R/'assets'
rng=random.Random(81473)
# Sixteen seamless 24px patches for each existing grass palette. Fine relief stays
# baked into the ground, never moves with the camera or becomes a floating sprite.
sheet=Image.new('RGB',(96,192))
for palette,base in enumerate([(49,77,78),(83,104,97)]):
 for variant in range(16):
  im=Image.new('RGB',(24,24),base);d=ImageDraw.Draw(im)
  def tone(offset):return tuple(max(0,min(255,c+offset)) for c in base)
  for n in range(13):
   x=rng.randrange(24);y=rng.randrange(24)
   d.point((x,y),fill=tone(rng.choice([-5,-3,4,6])))
  for n in range(rng.randrange(4,7)):
   x=rng.randrange(24);y=rng.randrange(24);h=rng.choice([2,2,3])
   for dx,dy,c in [(0,1,-10),(1,1,-7),(0,0,9),(0,-1,13),(1,-1,4),(-1,0,-3)]:
    d.point(((x+dx)%24,(y+dy)%24),fill=tone(c))
   if h==3:d.point((x,(y-2)%24),fill=tone(8))
  if variant%4==0:
   x,y=rng.randrange(24),rng.randrange(24)
   for dx,dy,c in [(0,1,-13),(1,1,-9),(0,0,12),(1,0,6)]:d.point(((x+dx)%24,(y+dy)%24),fill=tone(c))
  sheet.paste(im,((variant%4)*24,palette*96+(variant//4)*24))
sheet.save(A/'grass_variants.png')
# Distinct, low cut stems. Small highlights show severed ends above their shadows.
im=Image.new('RGBA',(72,24));d=ImageDraw.Draw(im)
for variant in range(3):
 ox=variant*24
 for n in range(32):
  x=ox+rng.randrange(2,22);y=rng.randrange(3,22);h=rng.choice([1,2,2,3])
  d.line((x,y,x+1,y+1),fill=(30,59,44,140))
  d.line((x,y,x+rng.choice([-1,0,1]),y-h),fill=rng.choice(['#3e654c','#507653','#5c8058']))
  d.point((x,y-h),fill=rng.choice(['#91a575','#a1ad7d','#7c9867']))
 for n in range(7):
  x=ox+rng.randrange(2,21);y=rng.randrange(3,22)
  d.line((x,y,x+2,y+1),fill='#527451');d.point((x,y),fill='#7b986a')
im.save(A/'hedge_stubble.png')
# A stone lip inside the leaves, not a floating icon or a second complete item.
im=Image.new('RGBA',(17,17));d=ImageDraw.Draw(im)
d.polygon([(9,10),(11,8),(14,9),(16,12),(14,15),(10,14)],fill='#304c3e')
d.polygon([(10,10),(12,9),(14,10),(15,12),(13,14),(10,13)],fill='#8c9190')
d.line((11,10,12,9,14,10),fill='#c9c6ad');d.line((10,13,13,14,15,12),fill='#626f69')
d.point((12,11),fill='#dfc98c');d.point((13,11),fill='#b9ad8b')
d.line((9,14,11,13,12,14),fill='#547954');d.point((14,14),fill='#688a5e')
im.save(A/'stone_peek.png')
print('Created grass variants, cut stems and hidden-stone foliage overlay')

# Pressed petals keep their colours; their contact shadow is drawn in the floor
# pass instead of being baked into a sprite sorted above nearby hedge crowns.
import json
atlas=Image.open(A/'atlas.png').convert('RGBA');ids=json.loads((A/'atlas.json').read_text())
for kind in ['flowers','blueflowers']:
 for frame in [1,2]:
  idx=ids[kind+'_pressed_'+str(frame)];ox=(idx%16)*32;oy=(idx//16)*48
  for y in range(48):
   for x in range(32):
    if atlas.getpixel((ox+x,oy+y))[:3]==(40,67,58):atlas.putpixel((ox+x,oy+y),(0,0,0,0))
atlas.save(A/'atlas.png')
