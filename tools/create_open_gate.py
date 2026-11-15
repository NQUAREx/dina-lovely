"""Authored opened gate plane: receding rails, separated bars, visible thickness."""
from PIL import Image,ImageDraw
from pathlib import Path
import json
A=Path(__file__).resolve().parents[1]/'assets'
im=Image.new('RGBA',(32,48));d=ImageDraw.Draw(im)
# Outer hinge stays at the right. Free edge recedes into the garden.
for x in [10,15,20,25,30]:
 t=(x-10)/20;top=round(18+t*3);bottom=round(38+t*8)
 d.rectangle((x,top,x+1,bottom),fill='#826b79');d.line((x,top,x,bottom-1),fill='#c2abb0')
d.polygon([(10,17),(31,20),(31,23),(10,20)],fill='#d9b886')
d.line((10,17,30,20),fill='#f0d4a0')
d.polygon([(10,37),(31,43),(31,46),(10,40)],fill='#aa7e70')
d.line((10,37,30,43),fill='#d4a48b')
d.polygon([(30,20),(31,21),(31,46),(30,45)],fill='#503e56')
d.polygon([(15,26),(18,25),(21,28),(24,27),(26,30),(21,36),(15,31)],fill='#c57e96')
d.point((17,26),fill='#ffe0c5')
atlas=Image.open(A/'atlas.png').convert('RGBA');ids=json.loads((A/'atlas.json').read_text());i=ids['gate_ajar'];atlas.paste(im,(i%16*32,i//16*48));atlas.save(A/'atlas.png')
