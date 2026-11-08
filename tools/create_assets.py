"""Original pixel artwork and original synthesized music; deterministic, no downloads."""
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
 d.rectangle((6,28,25,41),fill='#9a6474');d.rectangle((6,27,25,38),fill='#f7e5c8');d.line((6,27,15,34,25,27),fill='#cc9b95');d.polygon([(13,33),(15,35),(18,32),(17,30),(15,31),(14,30)],fill='#ca6c88')
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
 b=1 if frame%2 else 0;step=2 if frame==1 else -2 if frame==3 else 0
 d.rectangle((10+step,39,14+step,44),fill='#443a53');d.rectangle((18-step,39,22-step,44),fill='#443a53')
 d.polygon([(10,27+b),(22,27+b),(25,39+b),(7,39+b)],fill='#b66c9c');d.line((9,36+b,23,36+b),fill='#efb5c4',width=2)
 d.rectangle((6,28+b,9,34+b),fill='#f5c5ad');d.rectangle((23,28+b,25,34+b),fill='#f5c5ad')
 d.rounded_rectangle((7,10+b,24,28+b),5,fill='#49384d');d.rectangle((10,16+b,21,27+b),fill='#f6cbb2');d.rectangle((8,11+b,23,17+b),fill='#674458');d.rectangle((7,15+b,10,29+b),fill='#674458');d.rectangle((22,14+b,24,29+b),fill='#674458');d.line((10,12+b,19,12+b),fill='#a16b75',width=2)
 if face!=0:
  for x in ([12,19] if face==2 else [11] if face==1 else [20]):d.rectangle((x,20+b,x+1,22+b),fill='#433849')
  d.point((16,25+b),fill='#c9848d')
 else:d.rectangle((10,17+b,21,27+b),fill='#674458')
 d.rectangle((20,12+b,25,14+b),fill='#e9a9c1');d.point((23,13+b),fill='#ffe7ac')
for direction in range(4):
 for frame in range(4):sprite(f'hero{direction}_{frame}',lambda d,di=direction,f=frame:hero(d,di,f))
def enemy(d,kind):
 c=['#8e9dd0','#b890bf','#df9a9b'][kind]
 if kind==1:d.polygon([(7,29),(2,13),(13,25),(20,25),(29,13),(25,34)],fill=c)
 d.ellipse((5,24,27,42),fill='#47445f');d.ellipse((5,21,27,39),fill=c);d.ellipse((9,24,17,28),fill='#e4cfe5')
 for x in [11,21]:d.rectangle((x,31,x+1,33),fill='#39364d')
 d.line((15,35,18,35),fill='#6d536e')
for k in range(3):sprite('enemy'+str(k),lambda d,k=k:enemy(d,k))
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
d.line((263,254,277,254),fill='#e5bba5',width=9)
im.save(A/'keepsake.png')
def wav(name,seconds,sample):
 rate=22050
 with wave.open(str(A/name),'w') as w:
  w.setparams((1,2,rate,0,'NONE','not compressed'));w.writeframes(b''.join(struct.pack('<h',int(max(-1,min(1,sample(i/rate)))*20000)) for i in range(int(seconds*rate))))
notes=[60,64,67,71,69,67,64,62,57,60,64,67,65,64,60,59,53,57,60,64,62,60,57,55,55,59,62,67,64,62,59,62]
def music(t):
 beat=.52;i=int(t/beat);u=t%beat;n=notes[i%len(notes)];f=440*2**((n-69)/12);env=min(1,u/.015)*math.exp(-u*4);mel=(math.sin(2*math.pi*f*t)+.25*math.sin(4*math.pi*f*t))*env*.17
 root=[48,45,41,43][(i//8)%4];pad=sum(math.sin(2*math.pi*440*2**((root+j-69)/12)*t) for j in [0,7,12])*.024;fade=min(1,t/.5,(16.64-t)/.5);return (mel+pad)*fade
wav('garden.wav',16.64,music)
wav('chime.wav',.7,lambda t:sum(math.sin(2*math.pi*f*t) for f in [659,830,988])*.15*math.exp(-t*7))
wav('attack.wav',.16,lambda t:math.sin(2*math.pi*(550*t-900*t*t))*.24*(1-t/.16))
wav('hurt.wav',.2,lambda t:math.sin(2*math.pi*150*t)*.25*(1-t/.2))
print('Created',len(NAMES),'original sprites')
