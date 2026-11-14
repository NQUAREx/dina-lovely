"""Lavender masonry: exposed front and continuous stacked top-plane variants."""
from PIL import Image, ImageDraw
from pathlib import Path
import random
A=Path(__file__).resolve().parents[1]/'assets'
for joined in (False,True):
 im=Image.new('RGBA',(32,48));d=ImageDraw.Draw(im);r=random.Random(120)
 bottom=43 if joined else 33
 d.rectangle((4,20,27,bottom),fill='#81768d')
 for y in range(21,bottom,6):
  d.line((4,y,27,y),fill='#675f78')
  for x in range(4+(6 if (y//6)%2 else 0),28,12):
   d.line((x,y,x,min(y+5,bottom)),fill='#675f78')
   d.line((x+1,y+1,min(x+10,27),y+1),fill='#99879c')
 for _ in range(22):
  x=r.randrange(5,27);y=r.randrange(21,bottom+1)
  d.point((x,y),fill=r.choice(['#877b91','#a08ba0','#756b83']))
 d.line((4,20,27,20),fill='#b39aaf');d.line((4,21,4,bottom),fill='#99859e');d.line((27,21,27,bottom),fill='#5c566e')
 if not joined:
  d.rectangle((4,34,27,42),fill='#625b75')
  d.line((4,34,27,34),fill='#b09aae')
  d.line((5,35,26,35),fill='#84758f')
  d.line((4,39,27,39),fill='#504b63')
  for x,y in [(12,35),(20,40)]:d.line((x,y,x,y+3),fill='#49465d')
  d.line((5,43,26,43),fill='#403e55')
 im.save(A/('wall_stacked.png' if joined else 'wall_exposed.png'))
