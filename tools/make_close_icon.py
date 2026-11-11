"""A crisp cross, matching the game's original pixel UI palette."""
from pathlib import Path
from PIL import Image, ImageDraw
im=Image.new('RGBA',(24,24));d=ImageDraw.Draw(im)
# Separate stepped diagonals retain their shape with nearest filtering.
for i in range(5,19):
 for x,y in [(i,i),(23-i,i)]:d.rectangle((x-1,y-1,x+1,y+1),fill='#534457')
im.save(Path(__file__).resolve().parents[1]/'assets/close_icon.png')

light=im.copy()
for y in range(24):
 for x in range(24):
  if light.getpixel((x,y))[3]:light.putpixel((x,y),(245,227,207,255))
light.save(Path(__file__).resolve().parents[1]/'assets/close_icon_light.png')
