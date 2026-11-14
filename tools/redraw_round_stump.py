"""A round, low stump with bark relief, growth rings and an engraved heart."""
from PIL import Image,ImageDraw
from pathlib import Path
import json
A=Path(__file__).resolve().parents[1]/'assets';im=Image.open(A/'atlas.png').convert('RGBA');ids=json.loads((A/'atlas.json').read_text());s=Image.new('RGBA',(32,48));d=ImageDraw.Draw(s)
d.ellipse((3,38,29,46),fill='#38564a')
d.polygon([(6,30),(5,39),(7,43),(13,45),(22,44),(27,40),(26,30)],fill='#896d59',outline='#645e50')
d.ellipse((6,33,26,44),fill='#98785e')
for x,y in [(7,35),(11,38),(16,39),(21,38),(25,34)]:
 d.line((x,y,x-1,y+4),fill='#695c4e');d.line((x+1,y,x+1,y+3),fill='#b19370')
d.ellipse((5,26,27,38),fill='#735f4f');d.ellipse((6,25,26,36),fill='#c4a37b',outline='#94775c');d.ellipse((8,27,24,34),fill='#d9bb94',outline='#b1916b');d.arc((10,28,22,33),0,350,fill='#b99b75')
d.polygon([(11,28),(14,27),(16,29),(19,27),(22,28),(22,31),(16,35),(11,31)],fill='#b77f87',outline='#986770')
d.line((18,29,15,29,14,30,17,31,18,32,15,33),fill='#f0d1ba')
i=ids['quest_stump'];im.paste(s,(i%16*32,i//16*48));im.save(A/'atlas.png')
s.resize((256,384),Image.Resampling.NEAREST).save('/tmp/round-stump.png')
