"""Gate posts built solely from the same projected blocks as the walls."""
from pathlib import Path
from PIL import Image
A=Path(__file__).resolve().parents[1]/'assets'
def projected_wall():
 wall=Image.open(A/'wall_exposed.png').convert('RGBA')
 tile=Image.new('RGBA',(32,64))
 tile.alpha_composite(wall.crop((0,0,32,34)),(0,8))
 tile.alpha_composite(wall.crop((0,34,32,64)).resize((32,18),Image.Resampling.NEAREST),(0,42))
 return tile
def column():
 im=Image.new('RGBA',(48,112));tile=projected_wall()
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
