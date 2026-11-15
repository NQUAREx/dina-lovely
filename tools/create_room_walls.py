"""Seven related masonry finishes; identical footprint and bevel geometry."""
from pathlib import Path
from PIL import Image,ImageDraw
A=Path(__file__).resolve().parents[1]/'assets'
# moss limestone, cold slate, lilac granite, warm sandstone, iron basalt,
# garden stone, pale rose marble. Preserve the wall's directional values.
shifts=[(-5,9,-5),(-12,-5,2),(0,0,0),(13,7,-6),(-19,-16,-11),(0,8,-3),(16,7,9)]
for room,shift in enumerate(shifts):
 for suffix in ['', '1','2','3']:
  for kind in ['exposed','stacked']:
   im=Image.open(A/f'wall_{kind}{suffix}.png').convert('RGBA')
   for y in range(im.height):
    for x in range(im.width):
     r,g,b,a=im.getpixel((x,y))
     if a:im.putpixel((x,y),tuple(max(0,min(255,c+d)) for c,d in zip((r,g,b),shift))+(a,))
   d=ImageDraw.Draw(im)
   if room in [0,5]:
    for x,y in [(8,28),(9,29),(21,16),(22,17)]:d.point((x,y),fill='#7b8d70' if room==0 else '#8c9b81')
   elif room==3:d.line((11,24,15,24),fill='#b7a08d')
   elif room==4:
    for x,y in [(9,17),(22,28)]:d.rectangle((x,y,x+1,y+1),fill='#797883')
   elif room==6:d.line([(10,17),(12,19),(11,22),(14,25)],fill='#cfb4c0')
   im.save(A/f'wall_room{room}_{kind}{suffix}.png')
print('Generated seven masonry families, four variants each')
