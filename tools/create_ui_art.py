"""Reproducible pixel UI frames and semantic action icons; no gameplay assets."""
from pathlib import Path
from PIL import Image,ImageDraw
A=Path(__file__).resolve().parents[1]/'assets'/'ui';A.mkdir(exist_ok=True)
for state,bg,edge in [('normal','#4b364f','#c38b9e'),('hover','#67465e','#f4c69f'),('pressed','#382c42','#a5718d'),('disabled','#403846','#746578'),('panel','#302538','#bb879b'),('paper','#fff4df','#ba879a'),('focus','#4b364f','#f5d5a6')]:
 im=Image.new('RGBA',(64,64));d=ImageDraw.Draw(im)
 d.polygon([(6,0),(57,0),(63,6),(63,57),(57,63),(6,63),(0,57),(0,6)],fill='#251f30')
 d.polygon([(7,2),(56,2),(61,7),(61,56),(56,61),(7,61),(2,56),(2,7)],fill=edge)
 d.polygon([(8,4),(55,4),(59,8),(59,55),(55,59),(8,59),(4,55),(4,8)],fill=bg)
 d.line([(8,6),(55,6),(57,8)],fill='#e6b3b6' if state!='disabled' else '#877387',width=1)
 d.line([(6,9),(6,54),(9,57),(54,57)],fill='#78536f',width=1)
 d.line([(9,60),(55,60),(60,55)],fill='#6d4a63',width=1)
 for x,y in [(8,8),(55,55)]:
  d.line((x-5,y+6,x+5,y-4),fill='#657548',width=2)
  d.rectangle((x-5,y+1,x-2,y+3),fill='#a1a564');d.rectangle((x+2,y-5,x+4,y-2),fill='#839953')
  for dx,dy in [(-2,0),(2,0),(0,-2),(0,2)]:d.rectangle((x+dx-1,y+dy-1,x+dx+1,y+dy+1),fill='#e7b5ba' if state!='disabled' else '#8b7987')
  d.point((x,y),fill='#f7d59b')
 im.save(A/f'frame_{state}.png')
# Each drawing is an individual, readable 24px silhouette in the UI palette.
names=['dig','axe','pickaxe','craft','repair','water','fill','rake','fertilizer','grow','seed','shears','drill','letter','book','stats','key','gate','chest','rune','reset','wear','sit','stand','swing','apple','berries','fish','feed','pet','cat','skull','insert_skull','write','medkit','take','flashlight','attack','material']
for name in names:
 im=Image.new('RGBA',(24,24));d=ImageDraw.Draw(im);ink='#f5d3ac';rose='#d48fa6';shadow='#805b79';leaf='#a2ab77'
 def line(points,fill=ink,w=2):d.line(points,fill=fill,width=w)
 if name in ['dig','axe','pickaxe','rake','repair','craft','shears','drill']:
  line([(5,20),(16,5)],shadow,4);line([(5,19),(16,5)],ink,2)
  if name=='dig':d.polygon([(10,12),(16,16),(11,22),(7,22),(5,19)],fill=rose);d.rectangle((15,2,20,6),outline=ink,width=2)
  elif name=='axe':d.polygon([(11,3),(21,7),(20,13),(13,10)],fill=rose)
  elif name=='pickaxe':line([(7,7),(12,3),(17,4),(22,9)],rose,3)
  elif name=='rake':line([(9,4),(21,12)],rose,3);[line([(x,4+(x-9)*.65),(x-3,8+(x-9)*.65)]) for x in [10,14,18,21]]
  elif name=='repair':d.arc((11,1,22,12),0,290,fill=rose,width=3)
  elif name=='craft':d.polygon([(12,2),(22,9),(19,13),(9,6)],fill=rose)
  elif name=='drill':d.rectangle((8,3,20,10),fill=rose);line([(7,6),(2,6)]);line([(13,10),(11,16)],ink,4)
  else:d.ellipse((2,14,9,21),outline=rose,width=2);d.ellipse((11,14,18,21),outline=rose,width=2);line([(6,15),(18,2)]);line([(14,15),(9,2)])
 elif name in ['water','fill']:
  d.rectangle((6,9,16,18),fill=rose);d.arc((12,7,23,17),260,100,fill=ink,width=2);line([(6,11),(2,6),(1,7)]);d.arc((7,3,15,12),180,360,fill=ink,width=2)
  if name=='fill':line([(12,0),(12,4)]);line([(9,2),(12,5),(15,2)])
 elif name in ['letter','book','write','stats']:
  d.rectangle((3,4,20,19),fill=ink)
  if name=='letter':line([(3,5),(11,12),(20,5)],shadow,1)
  elif name=='book':line([(11,4),(11,19)],shadow,2);line([(5,8),(8,8)],rose,1);line([(14,8),(18,8)],rose,1)
  elif name=='write':line([(11,17),(21,3)],shadow,3)
  else:
   for x,h in [(6,5),(11,9),(16,12)]:d.rectangle((x,17-h,x+2,17),fill=shadow)
 elif name in ['key','gate','chest','reset','rune','wear','medkit','flashlight','attack','skull','insert_skull']:
  if name=='key':d.ellipse((12,2,21,11),outline=ink,width=3);line([(14,10),(4,20)],ink,3);line([(7,15),(10,18)])
  elif name=='gate':d.rectangle((3,3,20,21),outline=ink,width=2);[line([(x,5),(x,20)],rose,2) for x in [7,12,17]]
  elif name=='chest':d.rectangle((3,9,21,20),fill=rose);d.arc((3,2,21,16),180,360,fill=ink,width=3);d.rectangle((10,10,14,14),fill=ink)
  elif name=='reset':d.arc((3,3,21,21),30,300,fill=ink,width=3);d.polygon([(3,3),(10,4),(3,10)],fill=rose)
  elif name=='rune':d.polygon([(12,1),(21,11),(12,22),(3,11)],fill=rose);line([(8,12),(12,5),(16,12),(12,18)],ink)
  elif name=='wear':d.polygon([(3,18),(2,5),(8,10),(12,3),(16,10),(22,5),(21,18)],fill=ink);line([(4,20),(20,20)],rose)
  elif name=='medkit':d.rectangle((3,6,21,21),fill=rose);d.rectangle((7,2,17,6),outline=ink,width=2);line([(12,9),(12,18)],ink,3);line([(8,13),(16,13)],ink,3)
  elif name=='flashlight':d.polygon([(3,21),(8,22),(17,9),(11,5)],fill=ink);d.polygon([(13,4),(20,1),(23,8),(18,10)],fill=rose)
  elif name=='attack':line([(4,20),(19,3)],ink,3);line([(5,13),(12,20)],rose,3)
  else:d.ellipse((5,2,19,16),fill=ink);d.rectangle((8,13,16,20),fill=ink);d.rectangle((7,7,10,10),fill=shadow);d.rectangle((14,7,17,10),fill=shadow)
 elif name in ['fish','feed']:
  d.ellipse((4,7,19,17),fill=ink);d.polygon([(17,12),(23,6),(23,18)],fill=rose);d.point((7,11),fill=shadow)
  if name=='feed':line([(2,21),(16,21)],rose)
 elif name in ['cat','pet']:
  d.polygon([(3,4),(9,8),(15,8),(21,4),(20,17),(16,21),(8,21),(4,17)],fill=ink);d.point((8,13),fill=shadow);d.point((16,13),fill=shadow);d.polygon([(10,17),(14,17),(12,19)],fill=rose)
  if name=='pet':d.polygon([(9,2),(10,0),(12,1),(14,0),(15,2),(12,5)],fill=rose)
 elif name in ['sit','stand','swing']:
  d.ellipse((9,1,14,6),fill=ink);line([(11,8),(11,14),(18,14),(18,21)],ink,3);line([(5,12),(5,18),(15,18)],rose,2)
  if name=='stand':line([(11,14),(8,22)],ink,3)
  if name=='swing':line([(3,1),(3,19),(21,19),(21,1)],rose,1)
 elif name in ['apple','berries','seed','grow','fertilizer']:
  if name=='apple':d.ellipse((5,7,20,21),fill=rose);line([(12,7),(14,2)],ink);d.rectangle((15,3,20,5),fill=leaf)
  elif name=='berries':
   for x,y in [(7,10),(15,10),(11,17)]:d.ellipse((x-3,y-3,x+3,y+3),fill=rose)
   line([(8,5),(18,3)],leaf,3)
  elif name=='fertilizer':d.polygon([(5,4),(19,4),(21,21),(3,21)],fill=ink);line([(12,17),(12,10)],shadow);d.ellipse((7,8,12,12),fill=leaf);d.ellipse((12,6,17,10),fill=leaf)
  else:line([(12,21),(12,9)],ink);d.ellipse((3,7,12,13),fill=leaf);d.ellipse((12,3,21,9),fill=leaf);line([(4,22),(20,22)],rose)
 else:
  # Open palm for gathering, with a pebble badge for materials.
  d.polygon([(5,13),(4,8),(6,7),(8,12),(8,3),(10,3),(11,11),(12,2),(14,2),(14,11),(16,4),(18,5),(17,12),(20,9),(22,11),(18,19),(12,22),(7,19)],fill=ink)
  if name=='material':d.polygon([(2,17),(6,15),(9,19),(6,22),(2,21)],fill=rose)
 im.save(A/f'action_{name}.png')
print('Generated pixel UI frames and',len(names),'action icons')
