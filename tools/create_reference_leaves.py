from PIL import Image,ImageDraw
from pathlib import Path
A=Path(__file__).resolve().parents[1]/'assets'
for opened in [False,True]:
 s=Image.new('RGBA',(72,68));d=ImageDraw.Draw(s)
 if not opened:
  d.rectangle((0,1,71,6),fill='#b99454');d.line((0,1,71,1),fill='#f4dda2',width=2)
  d.rectangle((0,60,71,66),fill='#a88365');d.line((0,60,71,60),fill='#e2c488',width=2)
  for x in [4,16,28,40,52,64]:
   d.rectangle((x,6,x+2,61),fill='#ad8e59');d.line((x,7,x,59),fill='#eed598')
  d.polygon([(22,24),(28,20),(35,26),(42,20),(49,24),(49,34),(35,46),(22,34)],fill='#c887a2');d.line((23,24,28,21,33,25),fill='#f2bed0',width=2)
 else:
  d.polygon([(70,1),(46,19),(46,25),(70,7)],fill='#d9ba78');d.line((46,19,70,1),fill='#f4dda2',width=2)
  d.polygon([(46,59),(70,50),(70,56),(46,65)],fill='#b18b6b');d.line((46,59,70,50),fill='#e8cd93',width=2)
  for x in [46,54,62,70]:
   t=(x-46)/24;top=20-18*t;bottom=60-9*t
   d.line((x,top,x,bottom),fill='#ad8e59',width=3);d.line((x-1,top,x-1,bottom-1),fill='#eed598')
  d.polygon([(49,33),(53,29),(57,32),(62,27),(66,30),(66,36),(56,46),(50,42)],fill='#c887a2');d.line((50,33,53,30,56,33),fill='#f2bed0')
 s.save(A/('reference_gate_leaf_open.png' if opened else 'reference_gate_leaf_closed.png'))
