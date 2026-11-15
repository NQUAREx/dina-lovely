"""Gate posts built solely from the same projected blocks as the walls."""
from pathlib import Path
from PIL import Image,ImageDraw
A=Path(__file__).resolve().parents[1]/'assets'
def projected_wall():
 wall=Image.open(A/'wall_exposed.png').convert('RGBA')
 # Pillars keep the wall face, but not its staggered vertical brick joints.
 for x,y0,y1 in [(15,35,39),(19,41,46),(12,48,52)]:
  for y in range(y0,y1+1):wall.putpixel((x,y),wall.getpixel((x-1,y)))
 tile=Image.new('RGBA',(32,64))
 tile.alpha_composite(wall.crop((0,0,32,34)),(0,8))
 tile.alpha_composite(wall.crop((0,34,32,64)).resize((32,18),Image.Resampling.NEAREST),(0,42))
 return tile
def column():
 im=Image.new('RGBA',(48,112));tile=projected_wall();d=ImageDraw.Draw(im)
 # Narrow, chamfered upper and lower collars; no sharp dilated corners.
 d.polygon([(12,19),(35,19),(37,21),(37,44),(35,47),(12,47),(10,44),(10,21)],fill='#62536f')
 d.line([(10,22),(12,19),(35,19),(37,21)],fill='#b298ac',width=1)
 d.polygon([(12,85),(35,85),(37,87),(37,92),(35,94),(12,94),(10,92),(10,87)],fill='#51475f')
 d.line([(10,87),(12,85),(35,85),(37,87)],fill='#b298ac')
 d.line([(11,92),(13,93),(34,93),(36,91)],fill='#75617d')
 # Same roof, chamfers, face, lighting and source pixels. Stack by the
 # wall's 12-source-pixel rise, with the existing column's ground anchor.
 for y in (38,26,14,2):im.alpha_composite(tile,(8,y))
 return im
if __name__=='__main__':
 im=column()
 for room in ['hedge','stone']:
  for corridor in ['stone','tree']:
   for end in ['top','bottom']:
    for side in ['left','right']:im.save(A/f'junction_{room}_{corridor}_{end}_{side}.png')
 print('Generated gate posts from identical projected wall blocks; no added outline')
