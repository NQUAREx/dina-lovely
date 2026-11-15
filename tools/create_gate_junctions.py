"""Raised gate piers: projecting stepped capitals, shadowed shafts and warm insets.
The shaft keeps the original ground footprint and render anchor; ornaments are visual.
"""
from PIL import Image,ImageOps,ImageDraw
from pathlib import Path
A=Path(__file__).resolve().parents[1]/'assets'
for room in ['hedge','stone']:
 for corridor in ['stone','tree']:
  for end in ['top','bottom']:
   im=Image.new('RGBA',(48,112));d=ImageDraw.Draw(im)
   # Grounded broad plinth: distinct dark silhouette against the masonry behind.
   d.polygon([(10,83),(37,83),(39,87),(39,90),(34,94),(13,94),(8,90),(8,87)],fill='#3c354d')
   d.polygon([(11,83),(36,83),(37,87),(33,90),(14,90),(10,87)],fill='#a38a9d')
   d.line((12,84,35,84),fill='#d0b0ba');d.line((13,92,34,92),fill='#62516b')
   # The wall runs behind this narrow, darker freestanding shaft.
   d.polygon([(12,40),(35,40),(35,85),(32,88),(15,88),(12,85)],fill='#3c354d')
   d.rectangle((14,43,32,84),fill='#75617c')
   d.line((14,43,14,83),fill='#c0a0af',width=2)
   d.line((32,43,32,84),fill='#51445e',width=2)
   d.rectangle((18,49,29,79),fill='#493d56')
   d.line((18,49,29,49),fill='#b698aa');d.line((18,49,18,79),fill='#9d7e98')
   d.rectangle((20,52,27,77),fill='#67536f')
   d.line((20,77,27,77),fill='#95758e')
   # A warm relief inset makes the gate post readable separately from cold walls.
   d.rectangle((21,54,26,68),fill='#a58175')
   d.line((21,54,26,54),fill='#dfbf91')
   d.rectangle((23,57,24,65),fill='#efcca0')
   d.rectangle((22,72,25,74),fill='#c1989b')
   d.line((15,80,31,80),fill='#ad8d9f');d.line((15,83,31,83),fill='#594860')
   # Projecting capital throws a fixed, fully opaque cornice shadow on the shaft.
   d.polygon([(9,35),(38,35),(38,43),(34,47),(13,47),(9,43)],fill='#392f48')
   d.rectangle((10,36,37,40),fill='#a38b9e');d.line((11,37,36,37),fill='#d7b5c0')
   d.rectangle((12,41,35,43),fill='#67536f')
   # Wide top slab and its bevels extend beyond both wall shoulders.
   d.polygon([(12,16),(35,16),(41,22),(41,32),(35,38),(12,38),(6,32),(6,22)],fill='#3c354d')
   d.polygon([(12,17),(35,17),(40,22),(40,31),(35,36),(12,36),(7,31),(7,22)],fill='#b69aa9')
   d.polygon([(7,22),(12,17),(12,31),(15,36),(12,36),(7,31)],fill='#d7b5bf')
   d.polygon([(35,17),(40,22),(40,31),(35,36),(32,36),(35,31)],fill='#75617d')
   d.polygon([(13,19),(34,19),(37,22),(37,29),(33,33),(14,33),(10,29),(10,22)],fill='#c5a6b3')
   d.line([(8,22),(12,18),(35,18)],fill='#f0d0cd')
   d.line([(11,29),(14,32),(33,32),(36,29)],fill='#a08299')
   # Raised central cap, broad top lit from the left. No disconnected ornament.
   d.polygon([(18,12),(29,12),(33,16),(33,22),(29,26),(18,26),(14,22),(14,16)],fill='#69576f')
   d.polygon([(18,11),(29,11),(32,14),(32,20),(29,23),(18,23),(15,20),(15,14)],fill='#d1b1ba')
   d.line([(16,14),(18,12),(29,12)],fill='#f4d6ce')
   d.line((18,21,29,21),fill='#a3839b')
   d.rectangle((21,15,26,18),fill='#b995a7');d.line((22,15,25,15),fill='#ead0c0')
   for side,s in [('left',im),('right',ImageOps.mirror(im))]:s.save(A/f'junction_{room}_{corridor}_{end}_{side}.png')
print('Generated 16 tall gate piers with projecting capitals and grounded plinths')
