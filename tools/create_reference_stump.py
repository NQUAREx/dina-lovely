"""Original broad cut stump and matching standing-tree bark, on the atlas grid.

The stump's source diameter is twice the standing trunk's: quest_tree renders
at twice the normal sprite scale, so both cuts have the same world diameter.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageColor
import json
A=Path(__file__).resolve().parents[1]/'assets'
def generate():
 atlas=Image.open(A/'atlas.png').convert('RGBA');ids=json.loads((A/'atlas.json').read_text())
 def get(name):
  i=ids[name];return atlas.crop((i%16*32,i//16*48,i%16*32+32,i//16*48+48))
 def put(name,s):
  i=ids[name];atlas.paste(s,(i%16*32,i//16*48))
 # A broad oval cutting plane above a short dark bark cylinder, with roots.
 stump=Image.new('RGBA',(32,48));d=ImageDraw.Draw(stump)
 d.polygon([(7,34),(24,34),(26,39),(29,44),(23,45),(20,43),(11,44),(4,45),(2,42),(6,39)],fill='#49382e')
 d.polygon([(6,34),(25,34),(25,41),(22,43),(9,43),(5,41)],fill='#654735')
 d.polygon([(6,35),(10,36),(10,42),(6,41),(4,43),(3,42)],fill='#80583d')
 d.polygon([(22,35),(25,34),(25,39),(28,43),(24,44),(21,41)],fill='#51392e')
 d.line((12,37,12,41,10,44),fill='#422f29')
 d.line((18,37,18,42,20,44),fill='#422f29')
 d.line((8,37,8,40),fill='#a16d47')
 d.line((22,37,22,41,24,43),fill='#976541')
 # Stepped outer bark rim; the cut top is mostly visible from above.
 rim=[(8,27),(22,27),(26,30),(27,34),(24,37),(8,38),(4,35),(4,31)]
 d.polygon(rim,fill='#6d4c33')
 d.polygon([(9,28),(21,28),(25,30),(26,33),(23,36),(9,36),(5,34),(5,31)],fill='#b38a4e')
 d.line([(8,29),(12,28),(21,28),(24,30)],fill='#c49b5d')
 d.line([(8,34),(10,35),(21,35),(24,33)],fill='#94703e')
 d.polygon([(11,30),(20,30),(23,32),(20,34),(12,34),(8,32)],outline='#96713f')
 d.line([(12,31),(18,31),(20,32),(18,33),(14,33),(13,32),(16,32)],fill='#c29a58')
 d.line((23,29,21,31,22,32),fill='#795534')
 put('quest_stump',stump)
 # Bark of the still-standing tree matches the stump's wood and root flare.
 for name in ['quest_tree']+['quest_tree_damage'+str(n) for n in range(1,7)]:
  s=get("quest_tree");d=ImageDraw.Draw(s)
  # Only the existing woody trunk pixels are recoloured; crowns unchanged.
  for y in range(27,44):
   for x in range(32):
    r,g,b,a=s.getpixel((x,y))
    if a and r>g*1.10 and r>b*1.10 and (r,g,b) not in [(101,71,53),(128,88,61),(161,109,71)]:
     value=r*.30+g*.48+b*.22
     s.putpixel((x,y),ImageColor.getcolor('#654735' if value<110 else '#80583d' if value<145 else '#a16d47','RGBA'))
  d.polygon([(12,39),(21,39),(22,42),(24,43),(20,44),(17,43),(12,44),(9,43)],fill='#654735')
  d.line((13,33,13,40,11,43),fill='#a16d47')
  d.line((17,31,17,39,18,42),fill='#49382e')
  d.line((20,35,20,41,22,43),fill='#80583d')
  # Keep the authored chopping scars readable after bark recolouring.
  if name!='quest_tree':
   stage=int(name[-1])
   depth=2+stage
   top=34-stage//3;bottom=38+stage//3
   # A growing axe wedge exposes pale wood; the rest is the exact base tree.
   d.polygon([(11,top),(12+depth,36),(11,bottom)],fill=(0,0,0,0))
   d.polygon([(12,top),(13+depth,36),(12,bottom),(14,bottom-1),(14+depth,36),(14,top+1)],fill='#b38a4e')
   d.line([(12,top),(13+depth,36)],fill='#d0aa69')
   d.line([(13+depth,36),(12,bottom)],fill='#795534')
  put(name,s)
 atlas.save(A/'atlas.png')
 print('Generated reference-style broad stump and matching dark tree bark')
if __name__=='__main__':generate()
