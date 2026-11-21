from PIL import Image,ImageDraw
from pathlib import Path
R=Path(__file__).resolve().parents[1];A=R/'assets'
im=Image.new('RGBA',(64,64),'#292c42');d=ImageDraw.Draw(im)
d.rounded_rectangle((3,3,60,60),12,outline='#e5a6bd',width=2)
d.polygon([(32,48),(14,31),(14,21),(21,16),(29,18),(32,24),(35,18),(43,16),(50,21),(50,31)],fill='#e5a6bd')
d.line((19,23,23,21,27,23),fill='#f9d6cc',width=3)
im.resize((128,128),Image.Resampling.NEAREST).save(A/'icon.png')
