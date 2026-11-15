"""Posts have mirrored fittings and a solid inner foot return."""
from pathlib import Path
from PIL import Image, ImageOps
A=Path(__file__).resolve().parents[1]/'assets'
for path in A.glob('junction_*_left.png'):
 left=Image.open(path).convert('RGBA')
 right=Image.open(path.with_name(path.name.replace('_left','_right'))).convert('RGBA')
 assert left.size==(96,224)
 assert ImageOps.mirror(left).tobytes()==right.tobytes()
 assert left.getpixel((74,160))[3]==255
 for y in range(94,172):
  assert all(left.getpixel((x,y))[3]==255 for x in range(24,72))
print('PASS mirrored posts, continuous shaft, solid inner pedestal return')
