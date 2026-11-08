from PIL import Image,ImageDraw,ImageFont
from pathlib import Path
R=Path(__file__).resolve().parents[1];A=R/'assets'
im=Image.new('RGB',(960,540),'#242538');d=ImageDraw.Draw(im)
for y in range(540):
 c=(36+int(14*y/540),37+int(10*y/540),56+int(10*y/540));d.line((0,y,960,y),fill=c)
for i in range(35):
 x=(i*137+50)%960;y=(i*91+40)%540;d.rectangle((x,y,x+2,y+2),fill='#bc9ca8')
f=ImageFont.truetype(str(A/'title.ttf'),42);small=ImageFont.truetype(str(A/'body.ttf'),15)
d.text((480,260),'Сад, где живёт любовь',font=f,anchor='mm',fill='#f5e3cf')
d.text((480,315),'МАЛЕНЬКОЕ ПУТЕШЕСТВИЕ К БОЛЬШОМУ ЧУВСТВУ',font=small,anchor='mm',fill='#dca4b7')
d.line((370,211,590,211),fill='#997488',width=1)
im.save(A/'cover.png')
im=Image.new('RGBA',(64,64),'#292c42');d=ImageDraw.Draw(im)
d.rounded_rectangle((3,3,60,60),12,outline='#e5a6bd',width=2)
d.polygon([(32,48),(14,31),(14,21),(21,16),(29,18),(32,24),(35,18),(43,16),(50,21),(50,31)],fill='#e5a6bd')
d.line((19,23,23,21,27,23),fill='#f9d6cc',width=3)
im.resize((128,128),Image.Resampling.NEAREST).save(A/'icon.png')
