"""Narrow PG-7-style ogive, preserving the launcher, grip and muzzle anchors."""
from pathlib import Path
from PIL import Image,ImageDraw
import json
root=Path(__file__).resolve().parents[1];assets=root/'assets'
p=assets/'rpg_loaded.png';im=Image.open(p).convert('RGBA');d=ImageDraw.Draw(im)
d.rectangle((46,7,63,20),fill=(0,0,0,0))
d.rectangle((44,12,49,15),fill='#bec2a1')
d.polygon([(46,12),(49,9),(54,9),(60,11),(63,13),(63,14),(60,16),(54,18),(49,18),(46,15)],fill='#6c805f')
d.line([(47,12),(50,10),(54,10),(61,13)],fill='#bdc49a')
d.line([(47,15),(50,17),(55,17),(62,14)],fill='#3e5544')
d.point((63,14),fill='#b9bba0');im.save(p)
atlas_path=assets/'atlas.png';atlas=Image.open(atlas_path).convert('RGBA');idx=json.loads((assets/'atlas.json').read_text())['rocket_item']
rocket=Image.new('RGBA',(32,48));d=ImageDraw.Draw(rocket)
d.polygon([(3,21),(7,23),(13,23),(13,26),(7,26),(3,29),(5,25)],fill='#78876a')
d.rectangle((7,23,17,25),fill='#a4b39b');d.line((8,23,17,23),fill='#d3d7b4')
d.polygon([(11,23),(15,20),(20,20),(27,22),(31,24),(28,27),(21,29),(15,29),(11,26)],fill='#6c805f')
d.line([(12,23),(16,21),(21,21),(29,24)],fill='#bdc49a');d.line([(12,26),(16,28),(22,28),(30,24)],fill='#3e5544')
atlas.paste(rocket,((idx%16)*32,(idx//16)*48));atlas.save(atlas_path)
# Matching narrow heads on the standing and dropped launcher sprites.
for name in ['weapon_rpg','rack_rpg']:
 idx=json.loads((assets/'atlas.json').read_text())[name];x=(idx%16)*32;y=(idx//16)*48
 tile=atlas.crop((x,y,x+32,y+48));d=ImageDraw.Draw(tile)
 d.rectangle((20,20,31,32),fill=(0,0,0,0))
 d.rectangle((20,24,24,28),fill='#46554c')
 d.polygon([(20,25),(22,22),(25,22),(29,24),(31,26),(28,28),(25,30),(22,29),(20,27)],fill='#6c805f')
 d.line([(21,25),(23,23),(26,23),(30,26)],fill='#bdc49a');d.line([(21,27),(24,29),(27,28),(30,26)],fill='#3e5544')
 atlas.paste(tile,(x,y))
atlas.save(atlas_path)
