"""Eight pixel poses of a steel weapon case with two outward opening lids."""
from pathlib import Path
from PIL import Image, ImageDraw
A=Path(__file__).resolve().parents[1]/'assets'
def generate():
 sheet=Image.new('RGBA',(512,48))
 for frame in range(8):
  im=Image.new('RGBA',(64,48));d=ImageDraw.Draw(im)
  # The base remains on the original footprint; lids swing beyond it.
  d.rectangle((18,39,46,44),fill='#303943')
  d.rectangle((17,28,46,41),fill='#56616c');d.rectangle((20,31,43,40),fill='#74777a')
  d.line((18,28,45,28),fill='#b6c3ca');d.line((18,41,45,41),fill='#343d47',width=2)
  d.rectangle((26,33,38,38),fill='#46525d');d.rectangle((28,35,36,36),fill='#303b46')
  d.rectangle((19,19,44,29),fill='#718592');d.rectangle((21,21,42,27),fill='#222b36')
  d.line((22,22,41,22),fill='#3b4650');d.line((27,24,36,24),fill='#46535e')
  spread=round(frame/7*13)
  # Symmetric hinged leaves: pale recessed inner surfaces, dark thick rims.
  for side in [-1,1]:
   if side<0: x0,x1=18-spread,31-round(frame/7*13)
   else:x0,x1=32+round(frame/7*12),45+spread
   y0=18-round(frame/7*5); y1=28-round(frame/7*2)
   d.rectangle((x0,y0,x1,y1+1),fill='#3c4854')
   d.rectangle((x0,y0,x1,y1-1),fill='#8fa8b9')
   if x1-x0>4:
    d.rectangle((x0+2,y0+2,x1-2,y1-3),fill='#c2c6c7')
    d.line((x0+2,y1-2,x1-2,y1-2),fill='#e0e3df')
    d.line((x0+1,y0+1,x1-1,y0+1),fill='#b4c9d3')
   hinge=18 if side<0 else 44
   d.rectangle((hinge,26,hinge+1,30),fill='#afbdc2')
  if frame==0:
   d.rectangle((29,26,34,31),fill='#b5b49f');d.point((31,28),fill='#414550')
  sheet.alpha_composite(im,(frame*64,0))
 sheet.save(A/'iron_weapon_crates.png')
if __name__=='__main__':generate()
