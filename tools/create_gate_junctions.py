"""Quiet pixel masonry gate posts; same footprint, canvas and render anchor."""
from PIL import Image,ImageOps,ImageDraw,ImageFilter
from pathlib import Path
A=Path(__file__).resolve().parents[1]/'assets'
for room in ['hedge','stone']:
 for corridor in ['stone','tree']:
  for end in ['top','bottom']:
   im=Image.new('RGBA',(48,112));d=ImageDraw.Draw(im)
   # Small square plinth, not an ornamental pedestal.
   d.polygon([(12,83),(35,83),(37,85),(37,90),(35,92),(12,92),(10,90),(10,85)],fill='#51475f')
   d.rectangle((12,84,35,88),fill='#88758f')
   d.line((12,84,35,84),fill='#aa91a6');d.line((12,90,35,90),fill='#62536f',width=2)
   # Muted masonry shaft shares the wall palette, with simple vertical returns.
   d.rectangle((12,43,35,85),fill='#62536f')
   d.rectangle((15,44,31,85),fill='#81708a')
   d.rectangle((12,44,14,85),fill='#a18a9f')
   d.rectangle((32,44,35,85),fill='#51475f')
   # Match the wall side courses after its 0.6x extrusion compression:
   # 7 source px * 2 * .6 ~= 8 world px, i.e. 4 column source px.
   # Use the wall's actual side-face pixels and the same 20->12 projection,
   # rather than approximating its mortar colors or brick proportions.
   wall=Image.open(A/'wall_exposed.png').convert('RGBA')
   course=wall.crop((4,34,28,54)).resize((24,12),Image.Resampling.NEAREST)
   for y in range(47,85,12):
    part=course.crop((0,0,24,min(12,85-y)))
    im.alpha_composite(part,(12,y))
   # A restrained square capital: two source pixels beyond the shaft, no crown.
   d.rectangle((10,40,37,47),fill='#51475f')
   d.rectangle((11,39,36,43),fill='#9c859b')
   d.line((12,40,35,40),fill='#b79caf')
   d.rectangle((13,44,34,46),fill='#62536f')
   # Broad roof plane and darker bevels match the cubical wall blocks.
   d.polygon([(12,17),(35,17),(37,19),(37,41),(35,43),(12,43),(10,41),(10,19)],fill='#8e7b94')
   d.polygon([(10,19),(12,17),(12,39),(15,42),(12,42),(10,40)],fill='#aa91a6')
   d.polygon([(35,17),(37,19),(37,41),(35,43),(33,43),(35,40)],fill='#62536f')
   d.line((12,18,35,18),fill='#baa0af');d.line((14,20,33,20),fill='#a58ba1')
   d.line((14,41,33,41),fill='#77617e')
   for x,y in [(16,32),(25,34),(31,31),(20,36)]:d.rectangle((x,y,x+1,y+1),fill='#a58ba1')
   # A single source-pixel dark rim separates the existing capital from the
   # rear wall without changing its shape, palette or position.
   cap=im.getchannel('A');cap.paste(0,(0,48,48,112))
   rim=cap.filter(ImageFilter.MaxFilter(3))
   backing=Image.new('RGBA',im.size,'#51475f');backing.putalpha(rim)
   backing.alpha_composite(im);im=backing
   for side,s in [('left',im),('right',ImageOps.mirror(im))]:s.save(A/f'junction_{room}_{corridor}_{end}_{side}.png')
print('Generated 16 restrained masonry gate posts, without ornate crowns or metal insets')
