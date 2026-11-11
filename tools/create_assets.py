"""Reproducible original pixel artwork. Licensed audio is kept separately."""
from PIL import Image, ImageDraw
import random, math, wave, struct, json
from pathlib import Path
R=Path(__file__).resolve().parents[1]; A=R/'assets'; random.seed(17)
NAMES=[]; atlas=Image.new('RGBA',(32*16,48*36))
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
  d.rectangle((1,24,26,28),fill='#46554c');d.line((3,24,24,24),fill='#a6b18c');d.rectangle((9,25,18,29),fill='#92704d');d.rectangle((11,29,14,36),fill='#5b4946');d.rectangle((18,28,21,32),fill='#655447');d.line((15,20,15,24),fill='#434c47');d.polygon([(24,22),(28,20),(31,26),(28,31),(24,29)],fill='#809575');d.line((28,21,30,26),fill='#bdc29c')
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
def flashlight_rest(d):
 d.polygon([(5,20),(23,18),(23,25),(5,24)],fill='#687d80');d.line((7,20,21,19),fill='#b2c5bb',width=2)
 d.rectangle((21,17,25,26),fill='#bed0bf');d.rectangle((25,18,28,25),fill='#fff1a9');d.rectangle((12,20,16,22),fill='#e3bc85')
sprite('flashlight_rest',flashlight_rest)
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
def house_door(d):
 d.rectangle((13,30,20,43),fill='#57474e');d.line((14,31,14,42),fill='#927166');d.line((17,31,17,42),fill='#755950');d.point((19,37),fill='#e3bb7a')
def house_door_open(d):
 d.rectangle((11,28,22,43),fill='#232737');d.line((11,28,22,28),fill='#ad8d76')
 # Articulated rib cage, pelvis, arms and separate lower legs.
 d.line((16,33,16,39),fill='#e1d6ba',width=2)
 for y in [34,36]:
  d.line((13,y,19,y),fill='#b4ad9c');d.point((12,y-1),fill='#e7dcc4');d.point((20,y-1),fill='#e7dcc4')
 d.line((12,34,11,38),fill='#cec3ae');d.point((11,39),fill='#f0e3c9')
 d.line((20,34,21,38),fill='#cec3ae');d.point((21,39),fill='#f0e3c9')
 d.line((14,39,18,39),fill='#e4d8bc',width=2)
 d.line((14,40,13,43),fill='#b7b09f');d.line((18,40,19,43),fill='#b7b09f')
 d.point((12,43),fill='#e9dcc1');d.point((20,43),fill='#e9dcc1')
 d.polygon([(22,28),(26,31),(26,43),(22,43)],fill='#795d57');d.line((23,30,23,41),fill='#b18b70')
 d.ellipse((23,35,24,36),fill='#e5c48b')
sprite('house_door',house_door);sprite('house_door_open',house_door_open);sprite('house_door_empty',house_door_open)
def relic_skull(d):
 d.polygon([(12,30),(20,30),(23,33),(23,37),(20,39),(20,42),(12,42),(12,39),(9,37),(9,33)],fill='#777969')
 d.polygon([(12,29),(20,29),(22,32),(22,36),(19,38),(19,41),(13,41),(13,38),(10,36),(10,32)],fill='#e3d9bd')
 d.line((13,30,19,30),fill='#fff0d1');d.rectangle((12,33,14,35),fill='#343946');d.rectangle((18,33,20,35),fill='#343946')
 d.polygon([(16,35),(15,38),(17,38)],fill='#7a786e');d.line((14,39,18,39),fill='#9c9483')
 for x in [14,16,18]:d.point((x,41),fill='#827f75')
sprite('skull_relic',relic_skull)
def skull_stand(d,full=False):
 d.ellipse((2,40,30,46),fill='#342f46');d.rectangle((7,30,25,43),fill='#6b6077');d.rectangle((9,31,23,42),fill='#908098')
 d.polygon([(3,23),(9,19),(25,19),(30,24),(28,31),(5,31)],fill='#b6a2ad');d.line((5,24,27,24),fill='#e1c5be')
 d.polygon([(12,22),(20,22),(23,25),(22,28),(19,29),(13,29),(10,27),(10,24)],fill='#484353')
 d.rectangle((14,28,18,30),fill='#484353');d.line((10,23,13,21,20,21,24,24),fill='#7e7185')
 d.rectangle((8,31,24,35),fill='#544857');d.line((9,31,23,31),fill='#c6a79c');d.rectangle((10,32,22,34),fill='#242538');d.line((9,35,23,35),fill='#e1c5be')
 d.line((12,38,20,38),fill='#d0abac');d.polygon([(14,37),(16,39),(18,37),(17,36),(16,37),(15,36)],fill='#d995b4')
 if full:
  # Dedicated inserted-skull artwork, matching the relic palette.
  d.polygon([(13,19),(20,19),(22,22),(22,25),(19,27),(19,29),(14,29),(14,27),(11,25),(11,22)],fill='#e3d9bd')
  d.line((14,20,19,20),fill='#fff0d1');d.rectangle((13,22,15,24),fill='#343946');d.rectangle((18,22,20,24),fill='#343946');d.point((17,25),fill='#7a786e')
  for x in [15,17,19]:d.point((x,28),fill='#827f75')
sprite('skull_stand',lambda d:skull_stand(d));sprite('skull_stand_full',lambda d:skull_stand(d,True))
def reply_hand(d,cloth,light):
 d.rectangle((13,35,19,44),fill=cloth);d.line((14,36,14,42),fill=light)
 d.rectangle((14,31,18,35),fill='#c99883');d.line((15,31,17,31),fill='#e5b69b')
for dress,cloth,light in [('black_dress','#55516c','#77718a'),('white_dress','#d9d4da','#fff5eb'),('peach_dress','#a96872','#d99c99'),('lavender_dress','#8b77a6','#bfafd7')]:
 sprite('reply_hand_'+dress,lambda d,c=cloth,l=light:reply_hand(d,c,l))
sprite('bench',lambda d:(d.rectangle((2,25,29,30),fill='#9a7b6e'),d.rectangle((2,33,29,37),fill='#b38c78'),d.rectangle((5,37,8,44),fill='#504758'),d.rectangle((24,37,27,44),fill='#504758')))
sprite('berries',lambda d:(d.ellipse((8,24,24,38),fill='#487b50'),d.rectangle((12,25,15,28),fill='#dc7694'),d.rectangle((20,29,23,32),fill='#d95378')))
sprite('rake',lambda d:(d.line((13,39,20,13),fill='#ae8866',width=2),d.line((12,13,26,17),fill='#c8c5b0',width=2),[d.line((x,14,x-2,20),fill='#c8c5b0') for x in range(13,27,3)]))
# Optional tools use their own authored sprites, independent of weapons.
def axe(d):
 d.line((11,43,21,18),fill='#624c42',width=4);d.line((12,42,22,18),fill='#bb9565',width=2)
 d.polygon([(18,18),(22,15),(28,17),(30,23),(25,27),(21,24)],fill='#424653')
 d.polygon([(21,17),(27,18),(29,23),(25,25),(22,23)],fill='#c9d1cf');d.line((27,19,28,23,25,25),fill='#f7eed8',width=1)
 d.rectangle((18,20,21,24),fill='#817665')
def shears(d):
 d.polygon([(10,35),(8,27),(10,17),(13,16),(15,30)],fill='#515967');d.polygon([(20,35),(24,28),(23,17),(20,16),(17,30)],fill='#515967')
 d.line((11,18,11,26,15,32),fill='#e0e4db',width=2);d.line((21,18,22,26,17,32),fill='#b9c9c5',width=2)
 d.rectangle((14,29,18,33),fill='#9eaaab');d.point((16,31),fill='#f5e7c8')
 for x in [10,21]:
  d.rectangle((x-4,34,x+3,42),fill='#786a65');d.rectangle((x-3,35,x+2,41),fill='#d9bb80');d.rectangle((x-1,37,x+1,39),fill='#302d48')
def drill(d):
 d.rectangle((10,20,22,32),fill='#55667a');d.rectangle((12,19,20,30),fill='#bda36b');d.line((13,20,18,20),fill='#f1d59a')
 d.rectangle((7,23,11,26),fill='#6d5960');d.rectangle((21,23,25,26),fill='#6d5960');d.line((8,24,10,24),fill='#d2af82')
 d.rectangle((14,31,18,35),fill='#b7c0c0');d.polygon([(12,35),(20,35),(18,40),(16,46),(13,40)],fill='#667a85')
 for y in [35,38,41]:d.line((13,y,19,y+2),fill='#d4d9cf',width=1)
 d.rectangle((12,23,14,25),fill='#d77781');d.rectangle((18,26,20,29),fill='#394453')
def shears_closed(d):
 shears(d);d.rectangle((7,14,25,33),fill=(0,0,0,0))
 d.polygon([(12,33),(14,17),(16,16),(17,30),(21,33)],fill='#5d6c77');d.line((15,18,14,30),fill='#e1e6d8',width=2);d.line((18,18,18,29),fill='#bdcbc5',width=2);d.rectangle((14,30,18,33),fill='#9eaaab')
sprite('shears_closed',shears_closed)
def drill_spin(d,phase):
 drill(d);d.polygon([(12,35),(20,35),(18,40),(16,46),(13,40)],fill='#667a85')
 for y in range(35+phase,43,3):d.line((13,y,19,y+2),fill='#d4d9cf',width=1)
for phase in range(2):sprite('drill_spin'+str(phase),lambda d,p=phase:drill_spin(d,p))
def book_stand(d):
 d.ellipse((6,40,27,45),fill='#3c3448');d.rectangle((13,25,20,42),fill='#8b6b69');d.line((14,27,14,40),fill='#c09a82')
 d.polygon([(3,18),(25,15),(30,31),(7,35)],fill='#675063');d.line((5,19,25,16),fill='#c19c8b')
 d.polygon([(5,17),(15,18),(19,29),(8,31)],fill='#efe0c5');d.polygon([(15,18),(25,15),(29,27),(19,29)],fill='#fff3da')
 d.line((15,18,19,29),fill='#ae917f');d.line((8,20,14,21),fill='#bca59c');d.line((9,23,15,24),fill='#bca59c');d.line((19,20,24,19),fill='#c7b2a6');d.line((20,23,25,22),fill='#c7b2a6')
 d.line((20,28,22,34),fill='#d47c9f',width=2)
def table_piece(d):
 d.rectangle((5,23,27,44),fill='#614953');d.rectangle((7,24,25,42),fill='#95745c')
 for x in [8,14,20]:d.line((x,25,x,41),fill='#745946')
 d.rectangle((3,21,29,29),fill='#bc9468');d.line((4,22,27,22),fill='#e1bb84');d.line((4,28,28,28),fill='#83624c')
 for x in [7,24]:d.line((x,30,x,44),fill='#513e43',width=2)
def fallen_tree(d):
 d.ellipse((2,36,12,44),fill='#483e37');d.rectangle((4,33,10,40),fill='#886249');d.ellipse((3,31,11,36),fill='#cba16c');d.ellipse((5,32,9,34),outline='#886249')
 d.line((11,40,26,36),fill='#58483e',width=5);d.line((12,38,27,35),fill='#b08b60',width=2)
 for x,y,r in [(23,30,7),(27,33,5),(20,35,7)]:leaf(d,x,y,r)
for name,fn in [('axe',axe),('shears',shears),('drill',drill),('secret_book',book_stand),('tool_table_piece',table_piece),('fallen_tree',fallen_tree)]:sprite(name,fn)

def gunner(d):
 d.ellipse((7,19,25,42),fill='#4b5266');d.polygon([(7,33),(25,33),(28,43),(19,41),(14,44),(5,42)],fill='#67758a')
 d.ellipse((7,12,25,30),fill='#9eafb2');d.ellipse((10,14,22,27),fill='#bbc7bd');d.rectangle((10,18,22,22),fill='#41495a')
 d.rectangle((12,19,14,20),fill='#eed9a6');d.rectangle((18,19,20,20),fill='#eed9a6');d.line((8,28,21,37),fill='#bd9e70',width=2)
 d.rectangle((13,33,18,35),fill='#ece0be');d.line((9,39,13,39),fill='#3c4558');d.line((21,39,25,39),fill='#3c4558')
sprite('enemy_gunner',gunner)
def pistol(d):
 d.rectangle((10,23,29,27),fill='#485160');d.line((12,23,28,23),fill='#c2cac6');d.rectangle((28,24,31,26),fill='#2e3743')
 d.polygon([(14,27),(20,27),(18,35),(13,34)],fill='#8b6e55');d.point((15,29),fill='#c8a27b')
sprite('enemy_pistol',pistol)
def fallen_gunner(d):
 d.ellipse((4,34,29,44),fill='#485363');d.ellipse((7,29,24,40),fill='#acb9b0')
 for x in [11,19]:d.line((x-2,32,x+2,36),fill='#465160');d.line((x+2,32,x-2,36),fill='#465160')
 d.rectangle((21,39,30,41),fill='#4f5863');d.rectangle((23,41,25,44),fill='#8b6e55')
sprite('corpse6',fallen_gunner)
def rocketeer(d):
 gunner(d);d.rectangle((8,14,24,18),fill='#716c53');d.rectangle((9,12,22,14),fill='#98a377');d.rectangle((8,26,24,34),fill='#4d5c46');d.line((16,27,16,34),fill='#c6a570',width=2)
sprite('enemy_rocketeer',rocketeer)
sprite('corpse7',fallen_gunner)
def poison_pool(d):
 d.ellipse((1,30,30,44),fill='#243d32');d.ellipse((2,29,29,41),fill='#4c753b')
 for x,y,r in [(8,34,5),(19,32,6),(24,37,4),(13,38,5)]:
  d.ellipse((x-r,y-r//2,x+r,y+r//2),fill='#729c42');d.line((x-r+1,y-1,x,y-2),fill='#a6c958')
 for x,y in [(7,33),(20,30),(24,37),(14,38)]:d.point((x,y),fill='#d1df7a')
sprite('poison_pool',poison_pool)
def poison_glob(d):
 d.ellipse((7,20,25,39),fill='#345336');d.ellipse((8,20,24,35),fill='#79a344');d.ellipse((11,21,18,25),fill='#c1d970');d.rectangle((16,35,19,42),fill='#629140')
sprite('poison_glob',poison_glob)

def cat_art(d,face,frame=0,idle=False,sit=False):
 outline='#574754';fur='#c9996e';light='#e7bf91';cream='#f4dcc0';stripe='#98684f'
 b=frame%2 if frame<2 else 0
 if sit:face=2
 if face in [0,2]:
  hx=16;hy=27 if face==0 else 35;by=36 if face==0 else 30
  d.line((21,by+3,25,by+3,27,by-1-b,25,by-4),fill=outline,width=3);d.line((21,by+3,25,by+2,26,by-b),fill=fur,width=2)
  d.ellipse((9,by-5-b,23,by+7),fill=outline);d.ellipse((10,by-5-b,22,by+5),fill=fur);d.ellipse((13,by-1,20,by+5),fill=cream)
  for x,off in [(11,frame%2),(20,(frame+1)%2)]:
   yy=42 if sit else 41+off;d.rectangle((x,yy-3,x+3,yy),fill=outline);d.rectangle((x,yy-2,x+2,yy),fill=cream)
 else:
  hx=9 if face==1 else 23;hy=33;bx=19 if face==1 else 13
  tx=27 if face==1 else 5
  d.line((tx,35,tx+(2 if face==1 else -2),31-b,tx,27-b),fill=outline,width=3);d.line((tx,34,tx,29-b),fill=fur,width=2)
  d.ellipse((bx-7,29-b,bx+7,40),fill=outline);d.ellipse((bx-6,29-b,bx+6,38),fill=fur)
  for x,off in [(bx-4,frame%2),(bx+3,(frame+1)%2)]:d.rectangle((x,38+off,x+2,42+off),fill=cream)
  d.line((bx-1,30-b,bx,33-b),fill=stripe,width=2);d.line((bx+3,31-b,bx+3,33-b),fill=stripe)
 # Head and triangular ears have a separate silhouette for every direction.
 d.polygon([(hx-6,hy-3),(hx-6,hy-10),(hx-2,hy-7),(hx+3,hy-7),(hx+6,hy-10),(hx+6,hy-2)],fill=outline)
 d.ellipse((hx-6,hy-7,hx+6,hy+5),fill=outline);d.ellipse((hx-5,hy-7,hx+5,hy+3),fill=light)
 d.polygon([(hx-5,hy-7),(hx-5,hy-9),(hx-2,hy-6)],fill='#da9f9f');d.polygon([(hx+3,hy-7),(hx+5,hy-9),(hx+5,hy-6)],fill='#da9f9f')
 d.line((hx-1,hy-6,hx,hy-3),fill=stripe);d.point((hx-3,hy-5),fill=stripe);d.point((hx+3,hy-5),fill=stripe)
 if face!=0:
  d.ellipse((hx-3,hy,hx+3,hy+3),fill=cream)
  for x in [hx-3,hx+3]:
   if idle and frame==2:d.line((x-1,hy-1,x,hy-1),fill=outline)
   else:d.rectangle((x,hy-2,x+1,hy),fill='#37473e');d.point((x,hy-2),fill='#fff1d2')
  d.point((hx,hy+1),fill='#c57c8e');d.line((hx-7,hy,hx-4,hy+1),fill='#e9ccb0');d.line((hx+4,hy+1,hx+7,hy),fill='#e9ccb0')
for face in range(4):
 for frame in range(4):sprite('cat_walk'+str(face)+'_'+str(frame),lambda d,f=face,n=frame:cat_art(d,f,n))
 for frame in range(3):sprite('cat_idle'+str(face)+'_'+str(frame),lambda d,f=face,n=frame:cat_art(d,f,n,True))
for frame in range(2):sprite('cat_sit'+str(frame),lambda d,n=frame:cat_art(d,2,2 if n else 0,True,True))
def cat_hut(d):
 d.ellipse((1,40,31,46),fill='#35413f');d.rectangle((4,22,28,43),fill='#8f715c');d.rectangle((6,23,26,41),fill='#bc9a71')
 for x in [9,14,19,24]:d.line((x,25,x,40),fill='#967450')
 d.polygon([(11,43),(11,32),(13,28),(19,28),(22,32),(22,43)],fill='#343243');d.line((10,42,10,32,13,27,19,27,23,32,23,42),fill='#e2bd8a',width=2)
 d.polygon([(0,25),(16,9),(31,25),(29,28),(16,16),(3,28)],fill='#654d60');d.line((2,24,16,11,29,24),fill='#bd8a97',width=2)
 d.polygon([(12,19),(14,17),(16,19),(18,17),(20,19),(16,23)],fill='#e1abac');d.ellipse((24,38,31,42),fill='#6a9ba5');d.line((25,38,30,38),fill='#b5d8d2')
sprite('cat_hut',cat_hut)
def fish(d):
 d.polygon([(5,31),(10,34),(10,30),(14,27),(23,27),(28,32),(23,37),(14,37),(10,34),(5,38)],fill='#44596c')
 d.polygon([(6,32),(10,34),(6,36)],fill='#b5c4cf');d.ellipse((10,28,27,36),fill='#92b8c2');d.line((13,29,21,29,25,31),fill='#d7e9df',width=2)
 d.line((13,35,23,35),fill='#d4d7be');d.polygon([(15,28),(18,24),(21,28)],fill='#8096b1');d.point((24,31),fill='#354453');d.point((23,30),fill='#f1ebcf');d.line((15,31,17,33,15,35),fill='#759ba9')
sprite('cat_fish',fish)
def paw(d):
 d.ellipse((14,39,18,43),fill='#ffffff')
 for x,y in [(12,37),(15,35),(18,35),(20,37)]:d.rectangle((x,y,x+1,y+2),fill='#ffffff')
sprite('cat_paw',paw)
def stats_stone(d):
 d.ellipse((3,40,30,46),fill='#41404d');d.rectangle((5,38,28,44),fill='#6d6b80')
 d.polygon([(6,40),(6,15),(9,10),(13,8),(22,8),(27,13),(27,40)],fill='#55566b')
 d.polygon([(7,38),(7,15),(10,11),(14,9),(22,9),(25,13),(25,38)],fill='#9293a2');d.line((8,16,8,36),fill='#c4bec2');d.line((10,11,14,10,21,10,24,13),fill='#d4c7c3')
 d.rectangle((10,19,23,33),fill='#707387');d.polygon([(13,17),(15,15),(17,17),(19,15),(21,17),(17,21)],fill='#d8a7af')
 for y,w in [(24,8),(28,10),(32,6)]:d.line((12,y,12+w,y),fill='#c8b8af');d.point((11,y),fill='#55566b')
 d.line((9,39,24,39),fill='#c0afb0')
sprite('stats_stone',stats_stone)

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
ACCESSORIES=['black_dress','dark_scarf','wreath','veil','crown','rose_scarf','peach_dress','heart_tiara','pink_watch','white_scarf','white_dress','daisy_wreath','silver_crown','rose_wreath','lavender_dress','white_veil']
HEAD_ITEMS=['wreath','crown','heart_tiara','daisy_wreath','silver_crown','rose_wreath']
DRESS_PALETTES={
 'black_dress':{k:k for k in ['302d48','55516c','77718a','403c58','bd9eaf']},
 'peach_dress':{'302d48':'593a4b','55516c':'a96872','77718a':'d99c99','403c58':'83505f','bd9eaf':'e3b2a7'},
 'white_dress':{'302d48':'9992a4','55516c':'d9d4da','77718a':'fff5eb','403c58':'b7adbd','bd9eaf':'fff9ee'},
 'lavender_dress':{'302d48':'514565','55516c':'8b77a6','77718a':'bfafd7','403c58':'6a597d','bd9eaf':'e0cce6'}}
SCARF_PALETTES={
 'dark_scarf':{k:k for k in ['65576d','8e7c90','c7b0be','b29baa']},
 'rose_scarf':{'65576d':'7d4a62','8e7c90':'b4758d','c7b0be':'e8afbb','b29baa':'c994aa'},
 'white_scarf':{'65576d':'aba5b4','8e7c90':'ddd8df','c7b0be':'fff7ee','b29baa':'eee8e5'}}
def head_piece(d,item,b=0):
 if item in ['wreath','daisy_wreath','rose_wreath']:
  for x,y in [(7,13),(9,10),(13,9),(18,9),(23,11),(25,14)]:
   d.ellipse((x-2,y-1+b,x+2,y+1+b),fill='#628b68');d.point((x,y-1+b),fill='#b0c78b')
  for x,y in [(9,12),(15,9),(23,12)]:
   if item=='daisy_wreath':
    for dx,dy in [(-2,0),(2,0),(0,-2),(0,2)]:d.rectangle((x+dx,y+dy+b,x+dx+1,y+dy+1+b),fill='#fff2db')
    d.rectangle((x,y+b,x+1,y+1+b),fill='#e3b562')
   elif item=='rose_wreath':
    d.ellipse((x-2,y-2+b,x+2,y+2+b),fill='#ab486b');d.rectangle((x-1,y-1+b,x+1,y+1+b),fill='#e98c9c');d.point((x,y+b),fill='#ffd1bc')
   else:d.rectangle((x-1,y-1+b,x+1,y+1+b),fill='#efa4be');d.point((x,y+b),fill='#ffe0ac')
 elif item in ['crown','silver_crown']:
  dark,light,gem=('#766e94','#e0dde9','#aa8ed0') if item=='silver_crown' else ('#9e7544','#ebc66f','#f2a4ac')
  d.polygon([(8,7+b),(12,11+b),(16,4+b),(20,11+b),(25,7+b),(23,15+b),(10,15+b)],fill=dark)
  d.polygon([(9,8+b),(12,12+b),(16,6+b),(20,12+b),(24,9+b),(22,13+b),(11,13+b)],fill=light);d.rectangle((15,9+b,17,11+b),fill=gem)
  if item=='silver_crown':
   for x in [9,16,24]:d.point((x,7+b if x!=16 else 4+b),fill='#fff6e4')
 elif item=='heart_tiara':
  d.arc((7,5+b,26,21+b),180,350,fill='#e5c1bc',width=2);tiny_heart(d,16,6+b,'#db85a4')
  for x in [8,11,21,25]:d.rectangle((x,11+b,x+1,12+b),fill='#fff0c7')
def accessory_pickup(d,item):
 if item in HEAD_ITEMS:
  im=Image.new('RGBA',(32,48));head_piece(ImageDraw.Draw(im),item)
  for y in range(22):
   for x in range(32):
    c=im.getpixel((x,y))
    if c[3]:d.point((x,y+22),fill=c)
 elif item in ['veil','white_veil']:
  base,light=('#d9d5df','#fff5eb') if item=='white_veil' else ('#675268','#b991aa')
  d.polygon([(10,23),(23,23),(26,42),(7,42)],fill=base)
  for x in [10,18]:d.rectangle((x,27,x+4,28),fill=(0,0,0,0))
 elif item in SCARF_PALETTES:
  base,light=('#d4cdda','#fff5ed') if item=='white_scarf' else ('#65576d','#c7b0be') if item=='dark_scarf' else ('#bc8097','#edb2c0')
  d.polygon([(8,25),(23,22),(27,40),(17,36),(8,42),(5,34)],fill=base);d.line((9,27,20,25,23,36),fill=light,width=2)
 elif item in DRESS_PALETTES:
  palette=DRESS_PALETTES[item]
  d.polygon([(12,22),(20,22),(23,29),(20,29),(27,44),(5,44),(12,29),(8,29)],fill='#'+palette['55516c'])
  d.line((14,25,12,41),fill='#'+palette['77718a'],width=2);d.line((7,43,25,43),fill='#'+palette['bd9eaf']);d.line((20,32,24,42),fill='#'+palette['403c58'])
 elif item=='pink_watch':
  d.rounded_rectangle((12,21,20,45),3,fill='#ad668c');d.rectangle((14,23,18,43),fill='#edb4c7')
  d.rounded_rectangle((9,29,23,39),3,fill='#a27082');d.rectangle((11,30,21,37),fill='#fce9df');d.rectangle((12,31,20,36),fill='#d3acc8');d.line((16,32,16,34,19,34),fill='#754c74');d.point((12,31),fill='#fff8ec')
for item in ACCESSORIES:sprite('accessory_'+item,lambda d,item=item:accessory_pickup(d,item))
for item in ACCESSORIES:
 for direction in range(4):
  for frame in range(4):
   im=Image.new('RGBA',(32,48));d=ImageDraw.Draw(im);b=frame%2
   if item in DRESS_PALETTES or item in SCARF_PALETTES:
    base=NAMES.index('hero'+str(direction)+'_'+str(frame));base=atlas.crop(((base%16)*32,(base//16)*48,(base%16+1)*32,(base//16+1)*48))
    palette={tuple(bytes.fromhex(k)):tuple(bytes.fromhex(v)) for k,v in (DRESS_PALETTES.get(item) or SCARF_PALETTES[item]).items()}
    for y in range(48):
     for x in range(32):
      c=base.getpixel((x,y))
      if c[:3] in palette and c[3]:im.putpixel((x,y),palette[c[:3]]+(c[3],))
   elif item in ['veil','white_veil'] and direction!=0:
    left,right=(13,23) if direction==3 else (10,20) if direction==1 else (10,23)
    base,light=('#d3cedb','#fff4eb') if item=='white_veil' else ('#4e4057','#79627b')
    d.rounded_rectangle((left,15+b,right,28+b),3,fill=base)
    holes=[(11,15),(18,22)] if direction==2 else [(left+1,left+4),(right-4,right-1)]
    for x1,x2 in holes:d.rectangle((x1,18+b,x2,19+b),fill=(0,0,0,0))
   elif item in HEAD_ITEMS:head_piece(d,item,b)
   elif item=='pink_watch':
    x=7 if direction in [0,1] else 24;y=33+b
    d.rectangle((x-1,y,x+2,y+1),fill='#b36c94');d.rectangle((x,y-1,x+1,y+2),fill='#f0b1cc');d.point((x,y),fill='#fff1e5');d.point((x+1,y+1),fill='#9e739e')
   i=len(NAMES);NAMES.append('wear_'+item+'_'+str(direction)+'_'+str(frame));atlas.paste(im,((i%16)*32,(i//16)*48))
# Distinct quest loot, inserted-key padlock and compact garden task badges.
def gate_key(d):
 d.ellipse((6,23,17,34),fill='#8b6849');d.ellipse((7,23,17,33),fill='#e4ba68');d.ellipse((10,26,14,30),fill=(0,0,0,0))
 d.line((15,31,27,42),fill='#936548',width=4);d.line((15,30,28,41),fill='#f0ca7e',width=2)
 d.line((24,36,22,39,25,42),fill='#f7d794',width=2);d.point((9,25),fill='#fff1bc')
sprite('gate_key',gate_key)
def open_key_lock(d):
 padlock(d,True)
 d.line((17,38,29,38),fill='#ffe1a0',width=2);d.line((24,39,24,42),fill='#cc995b',width=2);d.line((28,39,28,41),fill='#f1c77c',width=2)
 d.ellipse((27,34,31,40),outline='#f6dba0',width=1)
sprite('lock_open_key',open_key_lock)
def need_badge(d,kind):
 if kind=='rake':
  d.line((11,33,19,23),fill='#ae8866',width=2);d.line((16,21,23,27),fill='#c8c5b0',width=2)
  for x,y in [(16,21),(19,23),(22,26)]:d.line((x,y,x-2,y+3),fill='#c8c5b0')
 elif kind=='fertilizer':
  d.polygon([(12,22),(21,22),(23,33),(11,33)],fill='#b89d81');d.line((13,24,20,24),fill='#f0d6a5');d.line((16,27,16,30),fill='#678a6e');d.line((14,28,18,28),fill='#678a6e');d.point((17,27),fill='#abc18e')
 elif kind=='water':
  d.polygon([(16,21),(11,28),(10,31),(12,34),(20,34),(23,31),(21,27)],fill='#426d80')
  d.polygon([(16,23),(12,29),(12,31),(14,33),(19,33),(21,30),(19,27)],fill='#7bb9bb');d.line((13,28,13,31),fill='#b8e8ed',width=2)
for kind in ['rake','fertilizer','water']:sprite('need_'+kind,lambda d,k=kind:need_badge(d,k))
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
 if name not in retained_names or name in ["weapon_rpg","weapon_rpg_empty","rack_rpg"]:continue
 old=retained_names[name];new=NAMES.index(name)
 atlas.paste(retained.crop(((old%16)*32,(old//16)*48,(old%16+1)*32,(old//16+1)*48)),((new%16)*32,(new//16)*48))
# Maze trees use the exact ordinary tree canopy and bark, not enlarged shrub leaves.
for target,source_name in [('hedge_tree','tree'),('hedge_tree_apples','tree_apples')]:
 old=NAMES.index(source_name);new=NAMES.index(target)
 atlas.paste(atlas.crop(((old%16)*32,(old//16)*48,(old%16+1)*32,(old//16+1)*48)),((new%16)*32,(new//16)*48))
# Bake full-size, cooler tree variants once; never resample their pixels at runtime.
for name in ['hedge_tree','hedge_tree_apples']:
 i=NAMES.index(name)
 im=atlas.crop(((i%16)*32,(i//16)*48,(i%16+1)*32,(i//16+1)*48))
 for y in range(35):
  for x in range(32):
   r,g,b,a=im.getpixel((x,y))
   if a and g>r and g>b:im.putpixel((x,y),(round(r*.86),round(g*.98),min(255,round(b*1.12)),a))
 im.resize((64,96),Image.Resampling.NEAREST).save(A/(name+'.png'))
for name in ['gate_key','lock_open_key']:
 i=NAMES.index(name);atlas.crop(((i%16)*32,(i//16)*48,(i%16+1)*32,(i//16+1)*48)).save(A/(name+'.png'))
# A separate original first-aid case; fixed atlas position appended after retained artwork.
def medkit(d):
 d.ellipse((4,40,28,45),fill='#272938');d.rectangle((11,23,21,28),fill='#4c4857');d.rectangle((13,24,19,27),fill='#b9b4ac')
 d.polygon([(4,29),(7,26),(25,26),(29,30),(29,41),(26,44),(6,44),(3,40)],fill='#676676')
 d.rectangle((5,28,26,40),fill='#f0e8d4');d.rectangle((5,39,26,42),fill='#b9b3ae');d.line((6,28,25,28),fill='#fff9e6');d.line((27,30,27,40),fill='#908b98')
 d.rectangle((13,30,18,38),fill='#d85d78');d.rectangle((10,32,21,35),fill='#d85d78');d.line((14,30,17,30),fill='#ffb4b5')
 for px in [7,24]:d.rectangle((px,36,px+1,40),fill='#817a86')
sprite('medkit',medkit)
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
# One continuous long workbench, not a stack of repeated furniture tiles.
bench=Image.new('RGBA',(48,160));bd=ImageDraw.Draw(bench)
bd.rectangle((5,147,43,158),fill='#302b3b')
for x in [7,35]:
 bd.rectangle((x,134,x+6,158),fill='#5f4549');bd.line((x+1,136,x+1,155),fill='#98715a')
bd.polygon([(4,1),(43,1),(47,5),(47,147),(3,147),(0,142),(0,5)],fill='#75513f')
for x,c in [(3,'#b58b60'),(14,'#c29a6c'),(25,'#b28a5f'),(36,'#be9366')]:bd.rectangle((x,4,min(45,x+10),141),fill=c)
for x in [13,24,35]:bd.line((x,5,x,140),fill='#886245')
bd.line((4,2,43,2,45,4),fill='#e0bc87',width=2);bd.line((3,143,45,143),fill='#e1b780',width=2)
for i in range(90):
 x=random.randrange(4,45);y=random.randrange(6,138);bd.line((x,y,x,y+random.randrange(2,7)),fill=random.choice(['#ad8056','#cba575','#9c724c']))
for x,y in [(9,21),(28,52),(17,91),(38,127)]:bd.ellipse((x-2,y-4,x+2,y+4),outline='#9a6c47');bd.line((x,y-1,x,y+1),fill='#71503c')
bench.save(A/'tool_table.png')

# Long RPG-7-style silhouette: separate loaded/empty shoulder launcher artwork.
for loaded in [False,True]:
 launcher=Image.new('RGBA',(64,32));ld=ImageDraw.Draw(launcher)
 ld.polygon([(1,10),(7,11),(7,17),(1,19)],fill='#4c5750');ld.line((1,10,1,18),fill='#acb19a',width=2)
 ld.rectangle((6,11,49,16),fill='#4e6351');ld.line((7,11,47,11),fill='#a4b18c');ld.line((8,15,49,15),fill='#34463e')
 ld.rectangle((16,11,32,17),fill='#9b764e');ld.line((17,12,30,12),fill='#d2a16a');ld.line((20,14,28,14),fill='#704e36')
 ld.polygon([(23,17),(29,17),(27,29),(22,28)],fill='#655042');ld.line((24,19,23,26),fill='#bc9264')
 ld.rectangle((34,16,38,23),fill='#4d4841');ld.line((34,22,37,22),fill='#9c8b70')
 ld.rectangle((34,6,41,10),fill='#414b48');ld.line((35,6,40,6),fill='#adb5a0');ld.rectangle((37,10,39,12),fill='#77836f')
 if loaded:
  ld.rectangle((48,12,52,15),fill='#bec2a1');ld.polygon([(51,9),(57,7),(63,13),(57,20),(51,17)],fill='#6c805f');ld.line((52,9,57,8,61,12),fill='#bdc49a');ld.line((52,17,57,19,62,14),fill='#3e5544')
 else:
  ld.rectangle((48,11,51,16),fill='#8b9b83');ld.rectangle((50,12,51,15),fill='#283b32')
 launcher.save(A/('rpg_loaded.png' if loaded else 'rpg_empty.png'))

# Page seam garlands and pause button share the original pixel-art palette.
import runpy
runpy.run_path(str(R/"tools/create_frame_art.py"))
# Seven carved keepsake stones and separate socket states.
runpy.run_path(str(R/"tools/create_rune_art.py"))
# Physical archive for the collected letter pile.
runpy.run_path(str(R/"tools/create_archive_art.py"))
# Keep the longer, narrower RPG head in held, reloading and flying artwork.
runpy.run_path(str(R/"tools/redraw_rpg_head.py"))
