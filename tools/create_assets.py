"""Reproducible original pixel artwork. Licensed audio is kept separately."""
from PIL import Image, ImageDraw
import random, math, wave, struct, json
from pathlib import Path
R=Path(__file__).resolve().parents[1]; A=R/'assets'; random.seed(17)
NAMES=[]; atlas=Image.new('RGBA',(32*16,48*32))
def sprite(name,fn):
 im=Image.new('RGBA',(32,48));d=ImageDraw.Draw(im);fn(d);i=len(NAMES);NAMES.append(name);atlas.paste(im,((i%16)*32,(i//16)*48))
def leaf(d,x,y,r=6):
 d.ellipse((x-r,y-r,x+r,y+r),fill='#183e43'); d.ellipse((x-r,y-r,x+r-1,y+r-3),fill=random.choice(['#376453','#44785b','#548568']));d.line((x-r+3,y-r+2,x,y-r+1),fill='#83aa73')
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
for i in range(3):
 def path_stone(d,v=i):
  x=16;y=34
  pts=[(x-10,y-3),(x-4,y-8-v),(x+7,y-6),(x+11,y),(x+6,y+6),(x-6,y+7)]
  d.polygon([(xx,yy+2) for xx,yy in pts],fill='#75573d');d.polygon(pts,fill=['#c9aa72','#bb925b','#d6b67d'][v]);d.line((x-6,y-5,x+3,y-5),fill='#e5c995')
 sprite('path_stone'+str(i),path_stone)
for name,color in [('flowers','#e99bb6'),('blueflowers','#b6b3ed')]:
 for frame in range(3):
  def pressed(d,c=color,f=frame):
   if f==0:flower(d,c);return
   for n,(x,normal) in enumerate([(8,32),(16,27),(24,34)]):
    spread=[-6,1,6][n] if f==2 else [-4,1,4][n]
    head=max(5,min(26,x+spread));y=42+(n%2) if f==2 else 35+(n%2)*2
    d.line((x,42,x+spread//2,39,head,y),fill='#395c47',width=3)
    d.line((x,41,x+spread//2,38,head,y),fill='#80ac77',width=1)
    for side in [-1,1]:
     lx=x+side*4+(spread//3);ly=40 if f==2 else 38
     d.polygon([(x,41),(lx-side*2,ly-2),(lx+side*3,ly),(lx,ly+2)],fill='#608d60')
     d.line((x,41,lx,ly),fill='#b1c88a')
    shadow='#8b6076' if name=='flowers' else '#777599'
    d.ellipse((head-4,y,head+4,y+2),fill='#28433a')
    for dx,dy in [(-3,0),(3,0),(0,-1),(0,1)]:
     d.ellipse((head+dx-2,y+dy-1,head+dx+2,y+dy+1),fill=shadow)
     d.line((head+dx-1,y+dy-1,head+dx+1,y+dy-1),fill=c)
    d.point((head,y),fill='#f8d993');d.point((head-1,y),fill='#fff1c1')
    if f==2:d.point((max(0,head-4),min(47,y+2)),fill=c)
  sprite(name+'_pressed_'+str(frame),pressed)
def bed(d,mode):
 d.ellipse((3,30,29,45),fill='#4a3b36');d.ellipse((5,31,27,43),fill='#6e503a' if mode!='wet' else '#473c35')
 for n in range(35):
  x=random.randrange(7,26);y=random.randrange(33,42);d.point((x,y),fill=random.choice(['#826146','#987557','#583e31']) if mode!='wet' else '#665243')
 if mode=='fertilized':
  for n in range(40):d.point((random.randrange(7,26),random.randrange(33,42)),fill=random.choice(['#e5d2a1','#bba875','#d0c7a8']))
for mode in ['empty','fertilized','wet']:sprite('bed_'+mode,lambda d,m=mode:bed(d,m))
def border(d,variant=0):
 rng=random.Random(701+variant)
 for n in range(11):
  a=n*math.tau/11+rng.uniform(-.14,.14)
  x=16+round(math.cos(a)*rng.uniform(13,15));y=38+round(math.sin(a)*rng.uniform(7,9))
  w=rng.choice([2,2,3]);h=rng.choice([1,2])
  d.polygon([(x-w,y),(x-w+1,y-h),(x+1,y-h),(x+w,y),(x+w-1,y+h),(x-1,y+h)],fill=rng.choice(['#8e8b7b','#aaa18c','#b5a88c','#99998a']))
  d.line((x-w+1,y-h,x,y-h),fill='#d8c8aa')
  d.point((x+w-1,y+h),fill='#6d7167')
sprite('bed_border',border)
for v in range(6):
 for stage in range(2):
  def plant_state(d,v=v,s=stage):
   bed(d,'wet');buds=[]
   if v==0:
    d.line((16,42,16,25),fill='#67945c',width=2)
    for y in [31,37]:d.polygon([(16,y),(8,y-5),(9,y),(16,y+2),(23,y-5),(22,y)],fill='#86aa69')
    buds=[(16,23)]
   elif v==1:
    d.line((16,43,16,23),fill='#799544',width=3);d.ellipse((5,30,15,36),fill='#a0ad58');d.ellipse((17,26,28,33),fill='#879d4b');buds=[(16,21)]
   elif v==2:
    for x,y in [(10,28),(16,21),(22,26)]:
     d.line((16,42,x,y),fill='#739884');d.line((x-3,34,x,37,x+3,32),fill='#96b9a5');buds.append((x,y-2))
   elif v==3:
    for x,y in [(7,24),(13,22),(19,26),(25,21)]:d.polygon([(16,43),(x-1,y),(x+2,y+8),(19,40)],fill='#7fa76c')
    buds=[(13,20),(23,24)]
   elif v==4:
    d.line((11,43,13,28,20,23,24,26),fill='#628b79',width=2);d.ellipse((6,32,15,37),fill='#82a793');d.ellipse((18,31,26,35),fill='#7caa98');buds=[(24,28),(19,34)]
   else:
    for n in range(7):
     a=n*math.tau/7;x=16+round(math.cos(a)*10);y=38+round(math.sin(a)*4);d.polygon([(16,40),(x-2,y-2),(x,y-5),(x+2,y)],fill='#98b67a')
    d.line((16,40,14,25),fill='#729965');d.line((17,40,23,29),fill='#729965');buds=[(14,23),(23,27)]
   if s:
    for x,y in buds:
     c=['#bd597e','#c7aa48','#9680c8','#d88d52','#8ab3c4','#d9c5d6'][v]
     d.ellipse((x-2,y-3,x+2,y+3),fill=c);d.line((x,y-3,x+1,y+2),fill='#aac08b')
  sprite(('seedling' if stage==0 else 'flower_bud')+str(v),plant_state)
def path_end(d):
 # Three-pixel islands, with equal scale on both axes in the game.
 for y in range(0,48,3):
  density=max(0,min(1,(y-2)/38))
  for x in range(6,27,3):
   edge=min(x-5,29-x)/4
   if random.random()<density*min(1,edge):d.rectangle((x,y,x+2,y+2),fill=random.choice(['#a47a4d','#b58a57','#c29a63','#86633f']))
sprite('path_end',path_end)
for variant in range(8):
 def detail(d,v=variant):
  if v<2:
   for x,y in [(10,38),(17,39),(22,36)]:d.line((x,y,x-1,y-3-v),fill=['#64866a','#78956f'][v]);d.point((x+1,y),fill='#3e6654')
  elif v<4:
   for x,y in [(12,37),(22,40)]:d.polygon([(x-2,y),(x,y-2),(x+3,y-1),(x+2,y+2),(x-1,y+2)],fill='#46605b');d.line((x-1,y-1,x+1,y-1),fill=['#8d9580','#a3997c'][v-2])
  elif v<6:
   for x,y in [(10,35),(21,39)]:
    d.line((x,y+3,x,y),fill='#668f67');d.point((x,y),fill=['#d9ba83','#c7aed2'][v-4]);d.point((x+1,y),fill='#edf0c1')
  else:
   d.ellipse((3,31,29,44),fill=(38,66,49,36) if v==6 else (132,112,74,30))
   for n in range(12):d.point((random.randrange(5,28),random.randrange(33,43)),fill=(141,151,98,45))
 sprite('grass_detail'+str(variant),detail)
def gate_panel(d):
 d.rectangle((0,17,31,20),fill='#d9b886');d.rectangle((0,41,31,44),fill='#7b5b62');d.line((0,41,31,41),fill='#d1a885')
 for x in [2,8,14,20,26,30]:
  d.rectangle((x,20,x+1,42),fill='#826b79');d.line((x,20,x,39),fill='#c2abb0')
 d.polygon([(10,28),(13,26),(16,29),(19,26),(22,28),(22,32),(16,37),(10,32)],fill='#c57e96');d.point((12,28),fill='#ffe0c5')
sprite('gate_panel',gate_panel)
def empty_rpg(d):
 weapon(d,'rpg')
 d.rectangle((25,20,31,34),fill=(0,0,0,0));d.ellipse((23,23,27,31),fill='#363d39');d.line((23,23,25,22,27,25),fill='#acb69c')
sprite('weapon_rpg_empty',empty_rpg)
# Separate perspective artwork: no runtime squashing of the closed gate.
def gate_ajar(d):
 d.polygon([(31,17),(20,26),(20,47),(31,43)],fill='#503e56')
 d.polygon([(31,17),(20,26),(20,29),(31,20)],fill='#d9b886')
 d.polygon([(20,44),(31,40),(31,43),(20,47)],fill='#aa7e70')
 for x in [20,24,28,31]:
  top=26-int((x-15)*.56);bottom=45-int((x-15)*.25)
  d.line((x,top,x,bottom),fill='#c2abb0',width=1)
 d.polygon([(20,32),(22,30),(24,32),(26,29),(28,31),(25,37),(21,38)],fill='#ce8da3')
sprite('gate_ajar',gate_ajar)
def padlock(d,opened=False):
 d.arc((11,25,23,39),175 if opened else 180,330 if opened else 360,fill='#e9c686',width=3)
 d.rectangle((10,34,23,44),fill='#6d4654');d.rectangle((11,34,22,42),fill='#d9ac67');d.line((12,35,20,35),fill='#ffe0a0');d.rectangle((16,37,17,40),fill='#69474d')
sprite('lock_closed',lambda d:padlock(d));sprite('lock_open',lambda d:padlock(d,True))
def lamp_off(d):
 lamp(d);d.rectangle((12,17,19,24),fill='#333443');d.line((13,18,16,20,14,22,17,24),fill='#7d7880')
sprite('lamp_off',lamp_off)
def crate(d):
 d.polygon([(4,24),(23,21),(29,26),(10,30)],fill='#a78165');d.polygon([(4,24),(10,30),(10,44),(4,39)],fill='#69504c');d.rectangle((10,29,28,44),fill='#89634f')
 for x in [11,19,27]:d.line((x,30,x,43),fill='#4c4247')
 d.line((11,31,26,42),fill='#c19a72',width=2);d.line((11,42,26,31),fill='#a78061',width=2)
sprite('crate',crate)
def column(d):
 d.ellipse((5,38,27,46),fill='#343445');d.rectangle((7,37,25,42),fill='#696575');d.rectangle((10,12,22,38),fill='#7f7a89');d.rectangle((11,13,14,37),fill='#aca0a4');d.rectangle((20,13,22,37),fill='#555468');d.rectangle((7,9,25,14),fill='#b1a0a6');d.line((8,10,24,10),fill='#d2bdb8')
sprite('column',column)
for k in range(6):
 def corpse(d,k=k):
  color=['#7f8bb9','#9d7da5','#bd8285','#75a68e','#939abe','#a66c83'][k]
  if k%3==1:d.polygon([(6,35),(3,24),(13,33),(24,31),(30,27),(27,40)],fill=color)
  d.ellipse((3,34,29,45),fill='#393444');d.ellipse((4,31,28,42),fill=color);d.line((8,33,16,32),fill='#b5a4c1')
  for x in [11,21]:d.line((x-2,35,x+2,39),fill='#3e3042');d.line((x-2,39,x+2,35),fill='#3e3042')
  d.line((14,41,18,41),fill='#633e50')
 sprite('corpse'+str(k),corpse)
def blood(d):
 for x,y,r in [(15,35,8),(7,39,4),(24,33,3),(23,42,3)]:d.ellipse((x-r,y-r//2,x+r,y+r//2),fill='#783e50')
 for x,y in [(3,31),(29,40),(21,27),(8,45)]:d.rectangle((x,y,x+1,y+1),fill='#a64c60')
sprite('blood_pool',blood)
def apple_tree(d):
 tree(d)
 for x,y in [(9,15),(22,18),(14,27),(19,9)]:
  d.rectangle((x-2,y-1,x+2,y+2),fill='#9b3d53');d.rectangle((x-1,y-2,x+1,y+1),fill='#d56468');d.point((x-1,y-1),fill='#ffd19c');d.line((x,y-3,x+1,y-4),fill='#b8bc74')
sprite('tree_apples',apple_tree)
# One integrated silhouette prevents foliage/tree depth swapping.
def hedge_tree(d,fruit=False):
 # Raised crown, a long exposed trunk, and low shrubs on either side.
 d.rectangle((13,16,18,42),fill='#493c3f');d.rectangle((14,19,17,39),fill='#805b48');d.line((14,20,14,37),fill='#ba8863')
 for x,y,r in [(15,7,9),(8,13,7),(23,13,7),(16,15,7)]:leaf(d,x,y,r)
 if fruit:
  for x,y in [(9,10),(22,14),(18,5)]:
   d.rectangle((x-2,y-1,x+2,y+2),fill='#ac455b');d.point((x-1,y-1),fill='#ffd19c')
sprite('hedge_tree',lambda d:hedge_tree(d));sprite('hedge_tree_apples',lambda d:hedge_tree(d,True))
for v in range(6):sprite('bed_border'+str(v),lambda d,v=v:border(d,v))
# Plant-only overlays keep every stone behind the foliage, without painting
# another soil oval over the stone border.
soil_colors={tuple(bytes.fromhex(c)) for c in ['4a3b36','473c35','665243','514a37','6e503a','826146','987557','583e31','574b41']}
for name in ['weeds']+['seedling'+str(v) for v in range(6)]+['bloom'+str(v) for v in range(6)]:
 i=NAMES.index(name);im=atlas.crop(((i%16)*32,(i//16)*48,(i%16+1)*32,(i//16+1)*48))
 for y in range(30,48):
  for x in range(32):
   if im.getpixel((x,y))[:3] in soil_colors:im.putpixel((x,y),(0,0,0,0))
 i=len(NAMES);NAMES.append(name+'_plant');atlas.paste(im,((i%16)*32,(i//16)*48))
# Dedicated romantic room artwork and correctly aligned wearable animation layers.
def tiny_heart(d,x,y,c='#db8ca6'):
 d.polygon([(x-3,y-1),(x-1,y-3),(x,y-1),(x+2,y-3),(x+4,y-1),(x+3,y+1),(x,y+4),(x-3,y+1)],fill=c)
def romantic_candle(d):
 candle(d);tiny_heart(d,15,33,'#ba728d')
sprite('candle_heart',romantic_candle)
def romantic_column(d):
 column(d)
 for n in range(9):
  a=n*math.tau/9;x=16+round(math.cos(a)*7);y=23+round(math.sin(a)*7)
  d.ellipse((x-2,y-1,x+2,y+1),fill='#6a956b');d.point((x,y-1),fill='#b5c48b')
 d.line((12,29,10,36),fill='#d18aa2',width=2);d.line((20,29,23,35),fill='#b57895',width=2);tiny_heart(d,16,29)
sprite('column_wreath',romantic_column)
def heart_stand(d):
 d.ellipse((5,39,27,46),fill='#494253');d.rectangle((14,22,18,41),fill='#907479');d.line((14,26,14,39),fill='#d5b29a')
 d.polygon([(5,13),(9,9),(13,10),(16,14),(20,9),(25,10),(28,14),(26,20),(16,29),(6,21)],fill='#75495f')
 d.polygon([(7,13),(10,11),(13,13),(16,17),(21,11),(25,12),(26,15),(24,19),(16,26),(8,20)],fill='#d892ac')
 d.line((10,13,12,14),fill='#ffd4d4',width=2)
 d.line((10,28,7,36),fill='#d9b38e');d.line((22,27,25,35),fill='#ad7c96')
sprite('heart_stand',heart_stand)
def footprint(d):
 d.ellipse((12,32,19,39),fill='#fff4dd');d.rectangle((13,36,18,41),fill='#fff4dd');d.rectangle((13,43,18,45),fill='#fff4dd')
 d.point((13,33),fill=(0,0,0,0));d.point((18,44),fill=(0,0,0,0))
sprite('footprint',footprint)
ACCESSORIES=['wreath','veil','crown','rose_scarf','peach_dress','brooch','heart_tiara']
def head_piece(d,item,b=0,shift=0):
 if item=='wreath':
  for x,y in [(7,13),(9,10),(13,9),(18,9),(23,11),(25,14)]:
   d.ellipse((x-2,y-1+b,x+2,y+1+b),fill='#739b68');d.point((x,y-1+b),fill='#b0c78b')
  for x,y in [(10,10),(20,10),(25,13)]:d.rectangle((x-1,y-1+b,x+1,y+1+b),fill='#efa4be');d.point((x,y+b),fill='#ffe0ac')
 elif item=='crown':
  d.polygon([(8,7+b),(12,11+b),(16,4+b),(20,11+b),(25,7+b),(23,15+b),(10,15+b)],fill='#9e7544')
  d.polygon([(9,8+b),(12,12+b),(16,6+b),(20,12+b),(24,9+b),(22,13+b),(11,13+b)],fill='#ebc66f');d.point((16,10+b),fill='#f2a4ac')
 elif item=='heart_tiara':
  d.arc((7,5+b,26,21+b),180,350,fill='#e5c1bc',width=2);tiny_heart(d,16,6+b,'#db85a4')
  for x in [8,11,21,25]:d.rectangle((x,11+b,x+1,12+b),fill='#fff0c7')
def accessory_pickup(d,item):
 if item in ['wreath','crown','heart_tiara']:
  im=Image.new('RGBA',(32,48));head_piece(ImageDraw.Draw(im),item)
  # Translate the head ornament onto the ground icon baseline.
  for y in range(22):
   for x in range(32):
    c=im.getpixel((x,y))
    if c[3]:d.point((x,y+22),fill=c)
 elif item=='veil':
  d.polygon([(10,23),(23,23),(26,42),(7,42)],fill='#675268');d.line((11,25,22,25),fill='#b991aa',width=2);d.line((13,29,11,40),fill='#856b84')
 elif item=='rose_scarf':
  d.polygon([(8,25),(23,22),(27,40),(17,36),(8,42),(5,34)],fill='#bc8097');d.line((9,27,20,25,23,36),fill='#edb2c0',width=2)
 elif item=='peach_dress':
  d.polygon([(12,22),(20,22),(23,29),(20,29),(27,44),(5,44),(12,29),(8,29)],fill='#a96976');d.line((14,25,12,41),fill='#df9c9a',width=2);d.line((7,43,25,43),fill='#edc4b5')
 else:
  for n in range(5):
   a=n*math.tau/5;x=16+round(math.cos(a)*5);y=34+round(math.sin(a)*5);d.ellipse((x-3,y-3,x+3,y+3),fill='#d28da9')
  d.ellipse((14,32,18,36),fill='#ffe2a1');d.line((16,39,20,42),fill='#89a478',width=2)
for item in ACCESSORIES:sprite('accessory_'+item,lambda d,item=item:accessory_pickup(d,item))
DRESS_COLORS={'302d48':'593a4b','55516c':'a96872','77718a':'d99c99','403c58':'83505f','bd9eaf':'e3b2a7'}
SCARF_COLORS={'65576d':'7d4a62','8e7c90':'b4758d','c7b0be':'e8afbb','b29baa':'c994aa'}
for item in ACCESSORIES:
 for direction in range(4):
  for frame in range(4):
   im=Image.new('RGBA',(32,48));d=ImageDraw.Draw(im);b=frame%2
   if item in ['peach_dress','rose_scarf']:
    base=NAMES.index('hero'+str(direction)+'_'+str(frame));base=atlas.crop(((base%16)*32,(base//16)*48,(base%16+1)*32,(base//16+1)*48))
    palette={tuple(bytes.fromhex(k)):tuple(bytes.fromhex(v)) for k,v in (DRESS_COLORS if item=='peach_dress' else SCARF_COLORS).items()}
    for y in range(48):
     for x in range(32):
      c=base.getpixel((x,y))
      if c[:3] in palette and c[3]:im.putpixel((x,y),palette[c[:3]]+(c[3],))
   elif item=='veil' and direction!=0:
    d.rounded_rectangle((10 if direction!=3 else 13,15+b,23 if direction!=1 else 20,28+b),3,fill='#4e4057');d.line((12 if direction!=3 else 15,24+b,20,24+b),fill='#79627b')
   elif item=='brooch' and direction!=0:
    x=11 if direction==1 else 23 if direction==3 else 20;y=31+b
    for dx,dy in [(-2,0),(2,0),(0,-2),(0,2)]:d.rectangle((x+dx-1,y+dy-1,x+dx+1,y+dy+1),fill='#d99ab2')
    d.point((x,y),fill='#ffe3a3')
   elif item in ['wreath','crown','heart_tiara']:head_piece(d,item,b)
   i=len(NAMES);NAMES.append('wear_'+item+'_'+str(direction)+'_'+str(frame));atlas.paste(im,((i%16)*32,(i//16)*48))
# Subtle engraved hearts live in the final floor texture itself.
romance=Image.open(A/'ground.png').convert('RGB');rd=ImageDraw.Draw(romance)
for tile in [1,3]:
 base=romance.getpixel((tile*24+10,10));color=tuple(min(255,c+v) for c,v in zip(base,(9,4,8)))
 x=tile*24+12;y=11
 rd.polygon([(x-3,y-1),(x-1,y-2),(x,y),(x+2,y-2),(x+4,y),(x,y+4),(x-3,y+1)],fill=color)
romance.save(A/'ground_romance.png')
i=NAMES.index('fertilizer');im=atlas.crop(((i%16)*32,(i//16)*48,(i%16+1)*32,(i//16+1)*48));fd=ImageDraw.Draw(im)
fd.polygon([(8,24),(16,20),(24,24),(16,28)],fill='#e4cea1');fd.ellipse((11,22,22,25),fill='#6d563e');fd.point((16,24),fill='#c5aa7c')
i=len(NAMES);NAMES.append('fertilizer_open');atlas.paste(im,((i%16)*32,(i//16)*48))
# Individual classic leaf crowns retained pixel-for-pixel from the original art.
source=Image.open(R/'tools/art_source/classic_leaves.png').convert('RGBA')
for v in range(12):
 im=Image.new('RGBA',(32,48));im.paste(source.crop((v*17,0,(v+1)*17,17)),(8,24))
 i=len(NAMES);NAMES.append('crown_leaf_'+str(v));atlas.paste(im,((i%16)*32,(i//16)*48))
 bd=ImageDraw.Draw(im);bd.rectangle((15,28,17,30),fill='#e86189');bd.point((15,28),fill='#ffc8cc')
 i=len(NAMES);NAMES.append('crown_berry_'+str(v));atlas.paste(im,((i%16)*32,(i//16)*48))
# Shared front-face material, sampled only on the unified moving wall contour.
Image.open(R/'tools/art_source/classic_side.png').save(A/'hedge_material.png')
trees=Image.open(R/'tools/art_source/classic_trees.png').convert('RGBA')
for n,name in enumerate(['hedge_tree','hedge_tree_apples']):
 i=NAMES.index(name);atlas.paste(trees.crop((n*32,0,(n+1)*32,48)),((i%16)*32,(i//16)*48))
# Unrelated artwork stays unchanged when the foliage generator changes its RNG use.
retained=Image.open(R/'tools/art_source/retained.png').convert('RGBA')
retained_names=json.loads((R/'tools/art_source/retained.json').read_text())
for name in NAMES:
 if name not in retained_names:continue
 old=retained_names[name];new=NAMES.index(name)
 atlas.paste(retained.crop(((old%16)*32,(old//16)*48,(old%16+1)*32,(old//16+1)*48)),((new%16)*32,(new//16)*48))
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
