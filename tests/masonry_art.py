"""The raised roof chamfers must reveal stone faces, never floor between cells."""
from pathlib import Path
from PIL import Image
A=Path(__file__).resolve().parents[1]/'assets'
for variant in range(4):
 suffix='' if variant==0 else str(variant)
 tiles=[Image.open(A/f'wall_{kind}{suffix}.png').convert('RGBA') for kind in ['stacked','exposed']]
 for tile in tiles:
  assert tile.size==(32,64)
  for y in range(34,51):
   for x in range(4,28):assert tile.getpixel((x,y))[3]==255,'roof chamfer has no side shell'
 # Three cells: vertical step is TILE48 / art2x =24 source pixels.
 wall=Image.new('RGBA',(32,112))
 for n in range(3):wall.alpha_composite(tiles[int(n==2)],(0,n*24))
 for y in range(14,100):
  for x in range(4,28):assert wall.getpixel((x,y))[3]==255,(variant,x,y,'floor gap in vertical wall')
 assert tiles[1].getbbox()==(4,11,28,55),'footprint or raised roof anchor moved'
print('PASS four masonry variants: closed chamfer sides and gap-free stacked walls')
