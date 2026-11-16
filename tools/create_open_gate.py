"""Authored opened gate plane: receding rails, separated bars, visible thickness."""
from PIL import Image,ImageDraw
from pathlib import Path
import json
A=Path(__file__).resolve().parents[1]/'assets'
im=Image.new('RGBA',(32,48));d=ImageDraw.Draw(im)
# Outer hinge stays at the right. Free edge recedes into the garden.
for x in [16,20,24,27,30]:
 t=(x-16)/14;top=round(13+t*8);bottom=round(33+t*13)
 d.rectangle((x,top,x+1,bottom),fill='#826b79');d.line((x,top,x,bottom-1),fill='#c2abb0')
d.polygon([(16,12),(31,20),(31,23),(16,15)],fill='#d9b886')
d.line((16,12,30,20),fill='#f0d4a0')
d.polygon([(16,32),(31,43),(31,46),(16,35)],fill='#aa7e70')
d.line((16,32,30,43),fill='#d4a48b')
d.polygon([(30,20),(31,21),(31,46),(30,45)],fill='#503e56')
d.polygon([(19,22),(21,22),(23,25),(25,25),(27,29),(23,32),(19,27)],fill='#c57e96')
d.point((20,23),fill='#ffe0c5')
# Keep the FULL opened plane in a dedicated padded image. The atlas gate
# convention crops y16..48 for closed leaves; that crop removes the receding
# upper free corner at y12, so open leaves must never use the closed UV box.
# Four clear pixels around the art also prevent edge sampling from clipping.
padded=Image.new('RGBA',(40,56))
padded.alpha_composite(im,(4,4))
padded.save(A/'open_gate_leaf.png')

atlas=Image.open(A/'atlas.png').convert('RGBA');ids=json.loads((A/'atlas.json').read_text());i=ids['gate_ajar'];atlas.paste(im,(i%16*32,i//16*48));atlas.save(A/'atlas.png')
