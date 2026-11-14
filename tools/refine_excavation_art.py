"""Distinct angular stone sprites and outline masks from the actual damage alpha."""
from PIL import Image,ImageDraw
from pathlib import Path
import json,runpy
A=Path(__file__).resolve().parents[1]/'assets';im=Image.open(A/'atlas.png').convert('RGBA');ids=json.loads((A/'atlas.json').read_text())
def get(n):
 i=ids[n];return im.crop((i%16*32,i//16*48,i%16*32+32,i//16*48+48))
def put(n,s):
 global im
 if n not in ids:ids[n]=max(ids.values())+1
 i=ids[n]
 if (i//16+1)*48>im.height:
  b=Image.new('RGBA',(512,(i//16+1)*48));b.paste(im,(0,0));im=b
 im.paste(s,(i%16*32,i//16*48))
s=Image.new('RGBA',(32,48));d=ImageDraw.Draw(s)
d.ellipse((3,39,30,46),fill=(38,57,54,100));d.polygon([(2,31),(9,18),(19,14),(27,23),(30,35),(23,43),(9,42)],fill='#7e8d91',outline='#566d75');d.polygon([(9,18),(19,14),(25,23),(15,26),(2,31)],fill='#b0b6ae');d.polygon([(15,26),(25,23),(30,35),(23,43),(18,35)],fill='#6d8088');d.polygon([(2,31),(15,26),(18,35),(9,42),(4,38)],fill='#929f9f');d.line((9,19,19,15,24,22),fill='#d1ceba');d.line((4,31,14,27,17,34),fill='#b6bdb1');put('quest_rock',s)
for stage in range(1,4):
 t=s.copy();d=ImageDraw.Draw(t)
 for n in range(stage*3):
  x=6+(n*7)%19;y=23+(n*5)%13;d.line((x,y,x+2,y+2,x+1,y+5),fill='#4c626d');d.line((x+2,y+2,x+5,y+1),fill='#637985')
 put('quest_rock_damage'+str(stage),t)
for n,poly in enumerate([[(10,40),(13,35),(19,36),(22,41),(17,44)],[(9,41),(12,37),(20,36),(24,40),(21,44),(12,44)],[(11,42),(12,35),(17,33),(21,38),(19,44)]]):
 t=Image.new('RGBA',(32,48));d=ImageDraw.Draw(t);d.polygon(poly,fill=['#9faeab','#8d9f9e','#a8b1a5'][n],outline='#5d7778');d.line((poly[0][0]+2,poly[0][1]-1,poly[1][0]+1,poly[1][1]+1,poly[2][0]-1,poly[2][1]+1),fill='#d0cdbc');put('quest_pebble'+str(n),t)
for name in ['quest_tree']+['quest_tree_damage'+str(i) for i in range(1,7)]:
 t=get(name)
 for y in range(48):
  for x in range(32):
   if t.getpixel((x,y))[:3]==(48,79,72):t.putpixel((x,y),(0,0,0,0))
 put(name+'_outline',t)
im.save(A/'atlas.png');(A/'atlas.json').write_text(json.dumps(ids)+'\n')
runpy.run_path(str(Path(__file__).with_name('redraw_round_stump.py')))
