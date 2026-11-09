"""Reproducible original pixel artwork. Licensed audio is kept separately."""
from PIL import Image, ImageDraw
import random, math, wave, struct, json
from pathlib import Path
R=Path(__file__).resolve().parents[1]; A=R/'assets'; random.seed(17)
NAMES=[]; atlas=Image.new('RGBA',(32*16,48*8))
def sprite(name,fn):
 im=Image.new('RGBA',(32,48));d=ImageDraw.Draw(im);fn(d);i=len(NAMES);NAMES.append(name);atlas.paste(im,((i%16)*32,(i//16)*48))
def leaf(d,x,y,r=6):
 d.ellipse((x-r,y-r,x+r,y+r),fill='#183e43'); d.ellipse((x-r,y-r,x+r-1,y+r-3),fill=random.choice(['#376453','#44785b','#548568']));d.line((x-r+3,y-r+2,x,y-r+1),fill='#83aa73')
def hedge(d):
 d.rectangle((3,24,28,40),fill='#25433d');d.rectangle((4,35,27,40),fill='#192f35')
 for y in [24,30]:
  for x in [6,14,23]:leaf(d,x,y,7)
 for x,y in [(7,21),(22,27),(17,19)]:d.point((x,y),fill='#bfd28b')
sprite('hedge',hedge)
def tree(d):
 d.rectangle((13,25,18,43),fill='#60474b');d.line((14,28,14,41),fill='#a07865',width=2)
 for x,y,r in [(15,12,11),(8,20,8),(23,20,8),(15,23,10)]:leaf(d,x,y,r)
sprite('tree',tree)
def flower(d,c='#e99bb6'):
 for x,y in [(8,32),(16,27),(24,34)]:
  d.line((x,y,x,42),fill='#6c9c72');d.line((x,38,x-4,35),fill='#9dbb79',width=2)
  for dx,dy in [(0,-2),(-2,0),(2,0),(0,2)]:d.rectangle((x+dx-1,y+dy-1,x+dx+1,y+dy+1),fill=c)
  d.point((x,y),fill='#ffe4a0')
sprite('flowers',flower)
sprite('blueflowers',lambda d:flower(d,'#b6b3ed'))
def lamp(d):
 d.ellipse((9,39,22,43),fill='#36394b');d.rectangle((14,22,17,41),fill='#66536a');d.rectangle((10,15,21,26),fill='#473d55');d.rectangle((12,17,19,24),fill='#ffdca0');d.rectangle((13,18,17,22),fill='#fff4ca');d.polygon([(8,15),(15,10),(23,15)],fill='#8b6879')
sprite('lamp',lamp)
def note(d):
 d.rectangle((5,26,26,41),fill='#895969');d.rectangle((6,27,25,39),fill='#fff0d9');d.line((6,27,16,34,25,27),fill='#c58b94',width=1)
 d.polygon([(12,30),(15,30),(16,32),(17,30),(20,30),(21,32),(21,34),(16,39),(11,34),(11,32)],fill='#a53261')
 d.polygon([(12,31),(14,31),(16,34),(18,31),(20,31),(20,34),(16,38),(12,34)],fill='#ef7092');d.point((13,32),fill='#ffd3d6')
sprite('note',note)
def chest(d,opened=False):
 d.rectangle((3,27,28,42),fill='#543c51');d.rectangle((5,29,26,39),fill='#a36269');d.rectangle((5,29,26,31),fill='#e4ae86');d.rectangle((6,34,25,36),fill='#7c4c5b');d.rectangle((8,28,10,41),fill='#dbb580');d.rectangle((23,28,25,41),fill='#dbb580');
 if opened:d.rectangle((4,16,27,24),fill='#b87b77');d.rectangle((5,25,26,29),fill='#ffdf91')
 else:d.rounded_rectangle((3,22,28,30),radius=3,fill='#b87979');d.line((5,23,26,23),fill='#edbb91');d.rectangle((14,28,18,34),fill='#ffdb8f')
sprite('chest',chest);sprite('chest_open',lambda d:chest(d,True))
def well(d):
 d.ellipse((3,29,29,44),fill='#6a687f');d.rectangle((3,30,29,39),fill='#96919d');d.ellipse((3,25,29,35),fill='#c4afae');d.ellipse((7,27,25,32),fill='#37586b');d.rectangle((5,13,7,30),fill='#805e67');d.rectangle((25,13,27,30),fill='#805e67');d.polygon([(1,15),(16,4),(31,15)],fill='#805571');d.line((2,14,16,5,30,14),fill='#c08b96',width=2);d.line((16,15,16,29),fill='#d8b895')
sprite('well',well)
def can(d):
 d.ellipse((6,27,24,42),fill='#426d80');d.rectangle((7,29,22,39),fill='#7bb9bb');d.line((8,27,8,23,19,23,19,28),fill='#a8d3c8',width=2);d.polygon([(21,33),(27,27),(30,28),(24,38)],fill='#9dccc5')
sprite('can',can)
def plant(d,grown):
 d.ellipse((4,35,28,44),fill='#54404d');d.line((16,40,16,28 if grown else 35),fill='#83b47d',width=2);d.ellipse((8,31 if grown else 35,16,37),fill='#6c9c72');d.ellipse((16,28 if grown else 34,23,35),fill='#a1c483')
 if grown:flower(d)
sprite('sprout',lambda d:plant(d,False));sprite('bloom',lambda d:plant(d,True))
def arch(d):
 d.rectangle((1,15,6,43),fill='#8f8497');d.rectangle((26,15,31,43),fill='#8f8497');d.arc((1,1,31,31),180,360,fill='#c6abba',width=6);d.line((3,22,3,40),fill='#c4a6ad',width=2);d.line((28,22,28,40),fill='#c4a6ad',width=2)
 for x,y in [(4,18),(26,10),(29,25)]:leaf(d,x,y,3)
sprite('arch',arch)
def candle(d):
 d.ellipse((9,39,23,43),fill='#8c6d74');d.rectangle((12,27,19,40),fill='#ead6bd');d.line((13,28,13,38),fill='#fff0ce');d.ellipse((14,19,18,26),fill='#ffd68f');d.point((16,20),fill='#fff6d4')
sprite('candle',candle)
def stone(d):
 d.rounded_rectangle((3,20,28,43),3,fill='#57516d');d.rectangle((5,22,26,36),fill='#93839b');d.line((6,23,25,23),fill='#d0b3ba');d.rectangle((9,28,22,31),fill='#cab0bb')
sprite('stone',stone)
def hero(d,face,frame):
 b=frame%2; sway=[0,1,0,-1][frame]
 # Fully covered silhouette: long dress, gloves, layered scarf and opaque veil.
 d.polygon([(11,24+b),(22,24+b),(27+sway,44),(5+sway,44)],fill='#302d48')
 d.polygon([(13,26+b),(19,26+b),(23+sway,43),(9+sway,43)],fill='#55516c')
 d.line((12,31+b,10+sway,42),fill='#77718a');d.line((20,29+b,24+sway,42),fill='#403c58',width=2)
 d.line((7+sway,43,25+sway,43),fill='#bd9eaf')
 d.rounded_rectangle((6,7+b,26,29+b),8,fill='#65576d')
 d.polygon([(7,15+b),(25,15+b),(28,33+b),(18,30+b),(5,33+b)],fill='#8e7c90')
 d.line((9,12+b,16,9+b,23,13+b),fill='#c7b0be',width=2)
 if face!=0:
  d.rounded_rectangle((10 if face!=3 else 13,15+b,23 if face!=1 else 20,28+b),3,fill='#d6a383')
  # Open featureless skin, framed by scarf.
 else:d.line((15,15+b,17,30+b),fill='#b29baa')
 d.rectangle((6,31+b,9,35+b),fill='#4a435d');d.rectangle((23,31+b,26,35+b),fill='#4a435d')
 d.point((23,12+b),fill='#f3d19c')
for direction in range(4):
 for frame in range(4):sprite(f'hero{direction}_{frame}',lambda d,di=direction,f=frame:hero(d,di,f))
def enemy(d,kind):
 c=['#8e9dd0','#b890bf','#df9a9b'][kind]
 if kind==1:d.polygon([(7,29),(2,13),(13,25),(20,25),(29,13),(25,34)],fill=c)
 d.ellipse((5,24,27,42),fill='#47445f');d.ellipse((5,21,27,39),fill=c);d.ellipse((9,24,17,28),fill='#e4cfe5')
 for x in [11,21]:d.rectangle((x,31,x+1,33),fill='#39364d')
 d.line((15,35,18,35),fill='#6d536e')
for k in range(3):sprite('enemy'+str(k),lambda d,k=k:enemy(d,k))
def weapon(d,kind):
 if kind=='sword':
  d.polygon([(15,9),(18,14),(18,31),(15,34),(12,31),(12,14)],fill='#b9d6dc');d.line((15,12,15,31),fill='#f4e8d0');d.rectangle((8,32,22,34),fill='#d0a776');d.rectangle((13,35,17,42),fill='#795568')
 elif kind=='rifle':
  # AK-pattern silhouette: wooden butt/handguard, steel receiver, curved magazine.
  d.polygon([(1,25),(9,25),(10,28),(3,33),(1,32)],fill='#9e6846');d.line((2,26,7,26),fill='#d29a63')
  d.rectangle((9,23,21,28),fill='#41434d');d.rectangle((18,24,26,28),fill='#a16d48');d.line((19,24,25,24),fill='#d49b64')
  d.rectangle((25,24,31,26),fill='#6c7477');d.rectangle((28,21,29,25),fill='#41434d')
  d.line((11,22,19,22),fill='#abb3b0');d.rectangle((11,28,14,34),fill='#77563e')
  d.polygon([(17,28),(21,28),(22,34),(25,38),(21,40),(18,35)],fill='#545963');d.line((19,30,20,35,23,38),fill='#899093')

 else:
  d.rectangle((3,23,26,31),fill='#697e70');d.rectangle((5,24,24,26),fill='#a7b496');d.polygon([(25,21),(31,27),(25,33)],fill='#be9a8c');d.rectangle((8,31,12,38),fill='#594b60');d.rectangle((16,30,19,35),fill='#594b60')
for kind in ['rpg','rifle','sword']:
 def rack(d,k=kind):
  d.rectangle((3,34,28,39),fill='#886775');d.rectangle((5,39,8,45),fill='#4e4358');d.rectangle((24,39,27,45),fill='#4e4358');weapon(d,k)
 sprite('rack_'+kind,rack)
 sprite('weapon_'+kind,lambda d,k=kind:weapon(d,k))
sprite('rocket_item',lambda d:(d.rectangle((8,22,24,27),fill='#a4b39b'),d.polygon([(24,20),(30,25),(24,30)],fill='#d49b8a'),d.polygon([(8,22),(3,18),(5,25),(3,32),(8,27)],fill='#eab879')))
sprite('fertilizer',lambda d:(d.rounded_rectangle((7,23,25,43),3,fill='#b89d81'),d.rectangle((8,24,24,27),fill='#f0d6a5'),d.ellipse((13,30,20,38),fill='#678a6e'),d.line((16,31,16,39),fill='#abc18e')))
for stage in [1,2]:
 def growing(d,st=stage):
  plant(d,False);d.line((16,40,16,23 if st==2 else 29),fill='#82aa79',width=2);d.ellipse((9,27,16,32),fill='#90b57e');d.ellipse((16,25,24,30),fill='#6c996b')
  if st==2:d.ellipse((12,18,20,27),fill='#c68caa');d.line((16,19,16,25),fill='#efb7c9')
 sprite('plant'+str(stage),growing)
def flashlight(d):
 d.polygon([(13,24),(21,24),(19,43),(14,43)],fill='#687d80');d.rectangle((12,22,22,27),fill='#bed0bf');d.rectangle((13,20,21,23),fill='#fff1a9');d.rectangle((15,32,18,36),fill='#e3bc85')
def shovel(d):
 d.rounded_rectangle((10,8,21,16),2,outline='#bca58f',width=2);d.line((16,15,16,34),fill='#9a7e69',width=3);d.polygon([(10,31),(22,31),(21,41),(16,46),(11,41)],fill='#9facb2');d.line((16,33,16,42),fill='#d5dfd8')
def mound(d):
 d.ellipse((3,31,29,44),fill='#4d3b45');d.polygon([(4,37),(9,30),(15,28),(22,30),(29,37)],fill='#96735e');d.line((8,34,13,31,19,32),fill='#c29d78');d.point((22,35),fill='#d0b08b')
def skull(d):
 d.ellipse((9,26,24,39),fill='#c9c3af');d.rectangle((12,35,21,42),fill='#d6ccae');d.rectangle((11,30,15,34),fill='#38313d');d.rectangle((19,30,22,34),fill='#38313d');d.polygon([(16,34),(14,37),(18,37)],fill='#51434b');d.line((14,39,14,42),fill='#7a6569');d.line((18,39,18,42),fill='#7a6569')
sprite('flashlight',flashlight);sprite('shovel',shovel);sprite('mound',mound);sprite('skull',skull)
sprite('dug',lambda d:(d.ellipse((2,30,30,44),fill='#87674f'),d.ellipse((6,32,26,42),fill='#382f3b'),d.line((8,32,22,31),fill='#ba9270')))
sprite('moving_bar',lambda d:(d.rectangle((5,24,26,41),fill='#4b4050'),d.rectangle((5,24,26,29),fill='#b6a1a0'),d.rectangle((5,30,26,38),fill='#bf9d70'),d.polygon([(5,30),(10,30),(18,38),(13,38)],fill='#594956'),d.polygon([(17,30),(22,30),(26,34),(26,38),(25,38)],fill='#594956')))
sprite('rack_empty',lambda d:(d.rectangle((3,34,28,39),fill='#886775'),d.rectangle((5,39,8,45),fill='#4e4358'),d.rectangle((24,39,27,45),fill='#4e4358')))
sprite('pedestal',lambda d:(d.ellipse((6,38,26,44),fill='#443b51'),d.rectangle((10,27,22,41),fill='#827387'),d.rectangle((6,23,26,29),fill='#baa3a4'),d.line((8,24,24,24),fill='#e0c5ae')))
sprite('doorpost',lambda d:(d.rectangle((10,7,22,43),fill='#5f566b'),d.rectangle((11,8,21,12),fill='#b7a1ac'),d.rectangle((9,39,24,44),fill='#95818e'),d.rectangle((13,15,20,19),fill='#dfb583'),d.line((12,22,12,36),fill='#968495')))
def house(d):
 d.rectangle((5,23,27,43),fill='#82706e');d.rectangle((7,26,25,41),fill='#b69a83');d.polygon([(1,25),(16,8),(31,25)],fill='#514759');d.line((3,24,16,10,29,24),fill='#9f7a82',width=2);d.rectangle((13,30,20,43),fill='#423e50');d.rectangle((8,29,11,34),fill='#d8bd83')
def pond(d):
 d.ellipse((1,19,31,45),fill='#687b72');d.ellipse((4,22,28,42),fill='#345a6b');d.arc((6,24,25,38),0,160,fill='#789e9c',width=1);d.ellipse((8,26,15,30),fill='#7b9b70');d.line((17,33,24,33),fill='#a0bbb0')
sprite('house',house);sprite('pond',pond)
sprite('bench',lambda d:(d.rectangle((2,25,29,30),fill='#9a7b6e'),d.rectangle((2,33,29,37),fill='#b38c78'),d.rectangle((5,37,8,44),fill='#504758'),d.rectangle((24,37,27,44),fill='#504758')))
for variant in range(3):
 def varied(d,v=variant):
  hedge(d)
  if v==0:
   for x,y in [(7,23),(18,27),(24,22)]:d.rectangle((x,y,x+2,y+2),fill='#ead9c2')
  elif v==1:
   for x,y in [(5,20),(17,18),(26,26)]:d.line((x,y,x+2,y-4),fill='#b4cb82',width=2)
  else:
   d.rectangle((14,23,17,32),fill='#826248');leaf(d,16,18,9)
 sprite('hedge'+str(variant),varied)
sprite('berries',lambda d:(d.ellipse((8,24,24,38),fill='#487b50'),d.rectangle((12,25,15,28),fill='#dc7694'),d.rectangle((20,29,23,32),fill='#d95378')))
sprite('rake',lambda d:(d.line((13,39,20,13),fill='#ae8866',width=2),d.line((12,13,26,17),fill='#c8c5b0',width=2),[d.line((x,14,x-2,20),fill='#c8c5b0') for x in range(13,27,3)]))
def weeds(d):
 d.ellipse((2,33,30,46),fill='#4f5037')
 for i in range(100):
  x=random.randrange(4,29);y=random.randrange(28,44)
  d.line((x,y,x+random.choice([-2,-1,1,2]),y-random.randrange(2,7)),fill=random.choice(['#40614b','#5b7a50','#80965c','#9caa67']))
 for x,y in [(8,35),(21,31),(25,39)]:d.ellipse((x-2,y-1,x+2,y+1),fill='#63874f')
sprite('weeds',weeds)
sprite('note_open',lambda d:(d.polygon([(5,28),(16,16),(26,28)],fill='#e8c8b8'),d.rectangle((5,28,26,41),fill='#d9ad9e'),d.polygon([(6,29),(16,36),(25,29),(25,40),(6,40)],fill='#f6dfc8')))
def distinct_flower(d,v,stage):
 basey=43
 stemtop=[27,21,14][stage]
 d.ellipse((5,38,27,46),fill='#514a37')
 colors=['#ed7397','#f1d15b','#aa97e9','#e9a85b','#95c9e1','#eee0ee']
 if v==0: # Rose: branching leaves, layered bud.
  d.line((16,42,16,stemtop),fill='#54835e',width=2)
  d.polygon([(16,35),(8,30),(9,36),(16,38),(23,30),(22,36)],fill='#79a463')
  y=stemtop
  if stage==0:d.ellipse((13,y,19,y+6),fill='#9f6579')
  elif stage==1:d.polygon([(12,y+3),(14,y-2),(19,y-1),(21,y+5),(16,y+8)],fill=colors[v]);d.line((14,y,17,y+4),fill='#ba476a')
  else:
   for r,c in [(7,'#a83e67'),(5,colors[v]),(3,'#ffb6c9')]:d.ellipse((16-r,y-r,16+r,y+r),fill=c)
   d.line((14,y,17,y-2,19,y+1,15,y+3),fill='#c34f78')
 elif v==1: # Sunflower: thick stem, large broad leaves.
  d.line((16,43,16,stemtop),fill='#76914c',width=3);d.polygon([(15,35),(5,30),(6,37),(15,39),(26,31),(23,39)],fill='#a0af57')
  y=stemtop
  if stage==0:d.rectangle((13,y,19,y+5),fill='#8d9c4e')
  else:
   for n in range(8):
    a=n*math.tau/8; x=16+round(math.cos(a)*(5 if stage==1 else 8));yy=y+round(math.sin(a)*(5 if stage==1 else 8));d.ellipse((x-2,yy-3,x+2,yy+3),fill=colors[v])
   d.ellipse((12,y-4,20,y+4),fill='#79533c');d.point((15,y-2),fill='#c49358')
 elif v==2: # Lavender: multiple tall spikes.
  for x,off in [(10,3),(16,0),(22,5)]:
   top=stemtop+off;d.line((16,43,x,top),fill='#5f8b72')
   for y in range(top,top+(4 if stage==0 else 10 if stage==1 else 16),3):d.rectangle((x-2,y,x+2,y+2),fill=colors[v] if stage else '#729184')
 elif v==3: # Tulips: closed cups, long blade leaves.
  d.polygon([(14,43),(5,23),(8,37),(16,43),(25,24),(23,40)],fill='#83a46b')
  for x,off in [(12,4),(20,0)]:
   y=stemtop+off;d.line((x,43,x,y+6),fill='#638758');d.polygon([(x-4,y),(x-1,y+2),(x+2,y-1),(x+4,y),(x+3,y+7),(x,y+9),(x-3,y+6)],fill=colors[v] if stage else '#8e9c63')
 elif v==4: # Bluebells: curved stems with drooping bells.
  d.line((12,43,13,stemtop+2,19,stemtop),fill='#5e8b72',width=2)
  for off in range(1 if stage==0 else 2 if stage==1 else 3):
   x=18+(off%2)*5;y=stemtop+off*7;d.line((13,y+3,x,y),fill='#5e8b72');d.polygon([(x-2,y),(x+1,y),(x+4,y+5),(x-4,y+5)],fill=colors[v] if stage else '#6d9d96');d.line((x-3,y+5,x+3,y+5),fill='#d5ebf2')
 else: # White daisies: three thin branches and fine petals.
  for x,off in [(8,6),(16,0),(24,8)]:
   y=stemtop+off;d.line((16,43,x,y),fill='#72986d')
   if stage==0:d.ellipse((x-2,y,x+2,y+4),fill='#a0b084')
   else:
    for dx,dy in [(-4,0),(4,0),(0,-4),(0,4)]:d.ellipse((x+dx-2,y+dy-2,x+dx+2,y+dy+2),fill=colors[v])
    d.rectangle((x-1,y-1,x+1,y+1),fill='#e6bc64')
for variant in range(6):
 for stage in range(3):sprite(('bloom'+str(variant)) if stage==2 else ('bud'+str(variant)+'_'+str(stage)),lambda d,v=variant,s=stage:distinct_flower(d,v,s))

def swing(d):
 d.line((3,43,7,5,25,5,29,43),fill='#806955',width=3);d.line((6,5,26,5),fill='#d0ad7d',width=3)
 d.line((11,8,11,32),fill='#c5b394');d.line((22,8,22,32),fill='#c5b394');d.rectangle((8,33,25,36),fill='#b9866b')
sprite('swing',swing)
def berry_hedge(d):
 hedge(d)
 for x,y in [(6,22),(14,25),(24,22),(20,30),(8,31)]:
  d.rectangle((x,y,x+2,y+2),fill='#e86189');d.point((x,y),fill='#ffb5c4')
sprite('hedge_berry',berry_hedge)
for i in range(3):
 def path_stone(d,v=i):
  x=16;y=34
  pts=[(x-10,y-3),(x-4,y-8-v),(x+7,y-6),(x+11,y),(x+6,y+6),(x-6,y+7)]
  d.polygon([(xx,yy+2) for xx,yy in pts],fill='#75573d');d.polygon(pts,fill=['#c9aa72','#bb925b','#d6b67d'][v]);d.line((x-6,y-5,x+3,y-5),fill='#e5c995')
 sprite('path_stone'+str(i),path_stone)
atlas.save(A/'atlas.png');(A/'atlas.json').write_text(json.dumps({n:i for i,n in enumerate(NAMES)}))
# Seamless textured ground tiles.
im=Image.new('RGB',(24*4,24));d=ImageDraw.Draw(im)
for k,base in enumerate(['#314d4e','#85777c','#48495e','#536861']):
 d.rectangle((k*24,0,k*24+23,23),fill=base)
 for i in range(35):
  x=k*24+random.randrange(24);y=random.randrange(24);d.point((x,y),fill=['#3a5956','#97868a','#56546b','#637a6b'][k])
 if k==1:d.line((k*24,23,k*24+23,23),fill='#70636f');d.line((k*24+23,0,k*24+23,23),fill='#70636f')
im.save(A/'ground.png')
# Soft radial light, shared by all lamps.
im=Image.new('RGBA',(64,64))
for y in range(64):
 for x in range(64):
  a=max(0,1-math.hypot(x-31.5,y-31.5)/32)**2;im.putpixel((x,y),(255,204,137,int(a*85)))
im.save(A/'glow.png')
# Bespoke illustrated keepsake used only until the couple supplies a real photo.
im=Image.new('RGB',(540,360),'#383c58');d=ImageDraw.Draw(im)
for y in range(360):d.line((0,y,540,y),fill=(56+int(y*.12),60+int(y*.08),88+int(y*.06)))
d.ellipse((370,35,440,105),fill='#f2d6b8')
for i in range(80):
 x=random.randrange(540);y=random.randrange(230);d.point((x,y),fill='#e5c8b2')
for x in range(0,540,35):d.ellipse((x-40,250+random.randrange(30),x+65,400),fill='#2c4d50')
d.rectangle((130,271,410,283),fill='#aa7d83');d.rectangle((150,304,160,350),fill='#5a4b5d');d.rectangle((380,304,390,350),fill='#5a4b5d');d.rectangle((130,298,410,311),fill='#9b717e')
for x,c in [(245,'#bd7c9c'),(295,'#7f91b5')]:
 d.ellipse((x-18,210,x+18,246),fill='#e5bba5');d.rounded_rectangle((x-21,240,x+21,299),10,fill=c);d.ellipse((x-20,204,x+20,227),fill='#594555');d.line((x-9,298,x-12,334),fill='#49455c',width=10);d.line((x+9,298,x+14,334),fill='#49455c',width=10)
d.polygon([(224,241),(264,241),(273,330),(215,330)],fill='#65576d')
d.ellipse((222,200,266,245),fill='#8e7c90')
d.polygon([(223,217),(264,217),(271,258),(219,258)],fill='#8e7c90')
d.line((263,254,277,254),fill='#51495f',width=9)
im.save(A/'keepsake.png')
print('Created original pixel artwork. Sound assets are licensed recordings; see assets/SFX-CREDITS.md')
