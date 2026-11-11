"""Original pixel contours and physical particle sprites; no external assets."""
from pathlib import Path
from PIL import Image, ImageDraw
import random, math
A=Path(__file__).resolve().parents[1]/'assets';rng=random.Random(73421)
# Hand-shaped ground-plane silhouettes. All contain the centre and overlap nearby stamps.
shapes=[[(4,13),(6,8),(14,4),(24,4),(32,8),(36,14),(32,20),(23,24),(12,22),(6,19)],
[(3,12),(8,5),(18,3),(25,6),(34,8),(37,14),(30,19),(22,21),(12,24),(5,19)],
[(5,8),(14,5),(22,3),(31,6),(35,11),(32,15),(35,19),(27,23),(15,22),(7,18),(3,13)],
[(3,14),(7,8),(12,7),(17,3),(26,5),(28,9),(35,11),(37,17),(30,22),(18,24),(8,20)],
[(5,10),(12,4),(23,4),(32,7),(35,12),(31,18),(26,19),(23,24),(13,23),(7,18),(3,16)],
[(3,13),(6,7),(17,4),(29,5),(35,10),(33,16),(29,17),(27,22),(16,24),(8,21)],
[(4,9),(10,5),(20,3),(28,7),(32,7),(36,14),(32,20),(21,23),(12,21),(9,17),(3,15)],
[(3,11),(9,6),(18,5),(24,3),(32,8),(36,13),(34,19),(27,23),(18,22),(10,24),(5,18)]]
im=Image.new('RGBA',(320,28));d=ImageDraw.Draw(im)
for n,points in enumerate(shapes):d.polygon([(x+n*40,y) for x,y in points],fill='white')
im.save(A/'dig_shapes.png')
# 12px particle tiles: six earth clods, four hot jets and six smoke puffs.
im=Image.new('RGBA',(192,12))
for n in range(16):
 tile=Image.new('RGBA',(12,12));d=ImageDraw.Draw(tile)
 if n<6:
  x,y=6,6;rx=rng.randrange(2,5);ry=rng.randrange(2,4)
  points=[(x-rx,y-1),(x-rx+1,y-ry),(x+1,y-ry),(x+rx,y-1),(x+rx-1,y+ry),(x-2,y+ry)]
  d.polygon(points,fill=['#76523a','#89613f','#9b744c','#644b36','#b18a5b','#806647'][n])
  d.line((x-rx+1,y-ry,x+1,y-ry,x+rx-1,y-1),fill='#c39c69')
  d.line((x-rx,y,x-2,y+ry,x+rx-1,y+ry),fill='#4d3b2e');d.point((x+1,y-1),fill='#a58960')
 elif n<10:
  jitter=n-6
  d.polygon([(2,9),(1,6),(4,5),(3,1+jitter%2),(6,3),(8,0),(10,5),(9,7),(11,9),(8,11),(4,11)],fill='#bb573b')
  d.polygon([(3,9),(3,6),(5,5),(6,2),(8,5),(9,8),(8,10),(5,10)],fill='#ef9145')
  d.polygon([(5,9),(4,7),(6,6),(7,4),(8,8),(7,10)],fill='#ffd27c');d.point((6,8),fill='#fff0b1')
 else:
  for x,y,r in [(5,7,4),(8,6,3),(4,4,3),(7,3,2)]:d.ellipse((x-r,y-r,x+r,y+r),fill=['#666260','#73706a','#807c72','#8d897f','#a09a89','#696b67'][n-10])
  d.line((2,6,2,4,4,2,7,2,9,4),fill='#aaa291');d.line((2,9,4,11,8,11,10,9),fill='#514f4b')
 im.alpha_composite(tile,(n*12,0))
im.save(A/'physical_particles.png')
# Eight jagged blast frames, built with pixel clusters rather than smooth circles.
im=Image.new('RGBA',(384,48))
for frame in range(8):
 tile=Image.new('RGBA',(48,48));d=ImageDraw.Draw(tile);r=[7,13,18,22,23,22,20,18][frame]
 points=[]
 for n in range(24):
  angle=n*math.tau/24;radius=r*rng.uniform(.72,1.08)
  points.append((round((24+math.cos(angle)*radius)/2)*2,round((24+math.sin(angle)*radius*.85)/2)*2))
 d.polygon(points,fill=['#efb367','#d97a40','#a45336','#835238','#6f5746','#655b51','#676259','#69645b'][frame])
 if frame<5:
  for n in range(11):
   x=rng.randrange(max(4,24-r),min(43,24+r));y=rng.randrange(max(5,24-r),min(42,24+r));size=rng.randrange(3,7)
   d.rectangle((x//2*2,y//2*2,x//2*2+size,y//2*2+size),fill=rng.choice(['#ffd18a','#f6a151','#e88139']))
  core=max(2,10-frame*2);d.polygon([(24-core,22),(22,22-core),(26,22-core),(24+core,23),(26,24+core),(21,24+core)],fill='#fff0b9' if frame<3 else '#ffc26a')
 for n in range(8):
  angle=n*math.tau/8+.25;dist=r+3+(frame%3)*2;x=round(24+math.cos(angle)*dist);y=round(24+math.sin(angle)*dist*.85)
  if 0<=x<46 and 0<=y<46:d.rectangle((x,y,x+1,y+1),fill='#ffca70' if frame<5 else '#81786a')
 im.alpha_composite(tile,(frame*48,0))
im.save(A/'rocket_blast.png')
print('Created 8 excavation silhouettes, earth/fire/smoke sprites and 8 blast frames')
# Heavy iron weapon crates: closed, cracked lid and fully opened artwork.
im=Image.new('RGBA',(96,48))
for frame in range(3):
 tile=Image.new('RGBA',(32,48));d=ImageDraw.Draw(tile)
 d.ellipse((1,39,30,46),fill='#2b3038');d.polygon([(3,28),(28,28),(30,31),(29,43),(4,44),(2,40)],fill='#3c4750')
 d.rectangle((4,29,27,40),fill='#71818a');d.line((4,29,27,29),fill='#b6bfc0');d.rectangle((5,39,27,42),fill='#4c606a')
 for x in [5,24]:
  d.rectangle((x,29,x+2,42),fill='#a2adb0');d.line((x+1,30,x+1,40),fill='#ced1c6')
 for x,y in [(7,32),(25,32),(7,39),(25,39)]:d.point((x,y),fill='#e2d8b7')
 if frame==0:
  d.polygon([(2,28),(5,19),(25,19),(29,28)],fill='#586b77');d.line((5,20,25,20,28,27),fill='#a6b3b8')
  d.rectangle((7,22,9,28),fill='#b0b9b6');d.rectangle((22,22,24,28),fill='#b0b9b6')
  d.rectangle((13,27,18,35),fill='#c1b18b');d.arc((13,24,18,30),180,360,fill='#e4d7af',width=2);d.point((15,31),fill='#45484c');d.line((15,32,16,33),fill='#45484c')
 else:
  d.rectangle((4,26,27,30),fill='#202d34');d.line((5,28,26,28),fill='#45535b')
  top=13 if frame==2 else 18
  d.polygon([(3,top),(27,top),(29,top+8),(3,top+8)],fill='#536774');d.rectangle((5,top+2,25,top+6),fill='#82939b')
  d.line((4,top,26,top,28,top+7),fill='#c3c9bf');d.rectangle((7,top+1,9,top+7),fill='#aeb8b9');d.rectangle((22,top+1,24,top+7),fill='#aeb8b9')
  d.rectangle((14,30,17,32),fill='#c1b18b')
 im.alpha_composite(tile,(frame*32,0))
im.save(A/'iron_weapon_crates.png')
im=Image.new('RGBA',(12,12));d=ImageDraw.Draw(im)
d.rectangle((2,7,8,11),fill='#56516b');d.line((3,8,7,8),fill='#9990a0')
d.polygon([(2,6),(3,3),(5,2),(8,2),(10,4),(10,7),(8,9),(3,8)],fill='#bb937b')
d.line((3,4,4,3,8,3,9,4),fill='#e4b99a');d.line((3,7,8,8,10,6),fill='#896e66')
for x in [4,6,8]:d.point((x,4),fill='#f1c9aa')
im.save(A/'fist.png')
