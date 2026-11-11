"""Deterministic ground relief, cut foliage and a partly buried stone. Original pixel art."""
from pathlib import Path
from PIL import Image, ImageDraw
import random, math
R=Path(__file__).resolve().parents[1]; A=R/'assets'
rng=random.Random(81473)
# A continuous, shaded grass carpet: low patches, many bent blade clusters,
# stones and tiny wildflowers. Runtime keeps these patches contiguous and bakes
# room-specific details into one stationary texture.
sheet=Image.new('RGB',(96,192))
base_sheet=Image.new('RGB',(96,192));clump_sheet=Image.new('RGBA',(256,32))
for palette,base in enumerate([(60,85,80),(80,108,98)]):
 im=Image.new('RGB',(96,96));d=ImageDraw.Draw(im)
 for y in range(96):
  for x in range(96):
   v=math.sin(x*math.tau/96)+math.cos(y*math.tau/48)+.7*math.sin((x+y)*math.tau/96)
   shade=round(v*1.5)+rng.randrange(-1,2)
   im.putpixel((x,y),tuple(max(0,min(255,c+shade)) for c in base))
 base_sheet.paste(im,(0,palette*96))
 def wrap(layer,x,y):
  for dx in [-96,0,96]:
   for dy in [-96,0,96]:im.paste(layer,(x+dx,y+dy),layer)
 lift=palette*13
 for n in range(285):
  clump=Image.new('RGBA',(16,16));cd=ImageDraw.Draw(clump)
  cd.ellipse((3,11,13,14),fill=(44+lift,68+lift,63+lift,85))
  for blade in range(rng.randrange(2,5)):
   x=rng.randrange(5,12);h=rng.randrange(1,4);bend=rng.choice([-3,-2,-1,1,2,3]);mid=12-h//2
   dark=(56+lift,83+lift,73+lift);green=(76+lift,104+lift,89+lift);tip=(102+lift,127+lift,105+lift)
   if n%7==0:green=(88+lift,107+lift,86+lift);tip=(113+lift,130+lift,105+lift)
   cd.line((x+1,13,x+1,mid,x+bend+1,12-h),fill=dark,width=2)
   cd.line((x,12,x,mid-1,x+bend,11-h),fill=green)
   cd.point((x+bend,11-h),fill=tip)
   if h>4:cd.point((x+bend,12-h),fill=(tip[0]+8,tip[1]+5,tip[2]+5))
  if n<12:clump_sheet.alpha_composite(clump,(n*16,palette*16))
  wrap(clump,rng.randrange(96)-8,rng.randrange(96)-12)
 for n in range(22):
  stone=Image.new('RGBA',(10,8));sd=ImageDraw.Draw(stone)
  sd.ellipse((1,4,8,7),fill=(57,76,69,100))
  sd.polygon([(2,3),(4,1),(7,2),(8,4),(6,6),(2,5)],fill=rng.choice(['#8b9b94','#9da89a','#889a92','#a8ae9d']))
  sd.line((3,2,5,1,7,2),fill='#c6cabc');sd.line((2,5,6,6,8,4),fill='#6c8277')
  if n<2:clump_sheet.alpha_composite(stone,((12+n)*16+3,palette*16+5))
  wrap(stone,rng.randrange(96)-4,rng.randrange(96)-4)
 for n in range(18):
  flower=Image.new('RGBA',(8,9));fd=ImageDraw.Draw(flower)
  fd.line((4,8,4,3),fill='#7f9a83');fd.point((3,6),fill='#a2b39a')
  color=rng.choice(['#d5c6a8','#c5b7cc','#c6b5c8','#d0c19c'])
  fd.point((3,2),fill=color);fd.point((5,2),fill=color);fd.point((4,1),fill=color);fd.point((4,3),fill=color);fd.point((4,2),fill='#f0dca4')
  if n<2:clump_sheet.alpha_composite(flower,((14+n)*16+4,palette*16+4))
  wrap(flower,rng.randrange(96)-4,rng.randrange(96)-7)
 sheet.paste(im,(0,palette*96))
base_sheet.save(A/'grass_variants.png')
clump_sheet.save(A/'grass_clumps.png')
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
