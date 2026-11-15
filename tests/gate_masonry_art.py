"""Column roof retains wall perspective; shaft omits vertical mortar joints."""
from pathlib import Path
from PIL import Image
A=Path(__file__).resolve().parents[1]/'assets'
w=Image.open(A/'wall_exposed.png').convert('RGBA')
for f in A.glob('junction_*.png'):
 im=Image.open(f).convert('RGBA')
 # The unchanged wall roof maps at native scale, shifted down by8+2px.
 for y in range(19,34):
  for x in range(4,28):
   c=w.getpixel((x,y-8))
   if c[3]==255:assert im.getpixel((x+8,y+2))==c,(f.name,x,y)
 # Collars project two pixels beyond the unchanged shaft.
 assert im.getpixel((10,30))[3]==255 and im.getpixel((10,90))[3]==255
print('PASS original wall roof perspective retained with narrow upper/lower collars')
