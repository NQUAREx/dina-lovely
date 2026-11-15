"""Standalone posts with the wall's actual in-game masonry projection.

Walls draw the roof at 2x and the side at (2x, 1.2x). Bake that projection
at screen resolution: resizing a whole 48px post by 2 would lose the odd
pixel rows in its mortar. Only the continuous side material repeats, never
block roofs, bottom outlines or the seams between stacked blocks.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageOps

A = Path(__file__).resolve().parents[1] / 'assets'
NEAREST = Image.Resampling.NEAREST


def masonry_strip(height):
    wall = Image.open(A / 'wall_exposed.png').convert('RGBA')
    # Two interior courses, including both chamfered side faces. No tile rim.
    material = wall.crop((4, 35, 28, 49))
    # The next course starts on the last row of this crop. Continue the first
    # course's joint across the repeat boundary, instead of a one-pixel stub.
    material.putpixel((12 - 4, 13), wall.getpixel((13, 48)))
    material.putpixel((15 - 4, 13), wall.getpixel((15, 35)))
    strip = Image.new('RGBA', (48, height))
    # Same nearest-neighbour sampling as draw_texture_rect_region: 2x wide,
    # 36/30 high. Sampling continuously keeps the 8/9px mortar rhythm.
    for y in range(height):
        sy = int((y + .5) / 1.2) % 14
        for x in range(48):
            strip.putpixel((x, y), material.getpixel((x // 2, sy)))
    return strip


def column():
    wall = Image.open(A / 'wall_exposed.png').convert('RGBA')
    im = Image.new('RGBA', (96, 224))
    d = ImageDraw.Draw(im)
    # One continuous 24-source-pixel shaft, the same width as a wall block.
    im.alpha_composite(masonry_strip(90), (24, 86))
    # Small chamfered foot, with the original ground anchor.
    d.polygon([(24,172),(71,172),(75,176),(75,184),(71,188),
               (24,188),(20,184),(20,176)], fill='#51435f')
    d.polygon([(24,172),(71,172),(75,176),(71,180),(24,180),(20,176)], fill='#8e7b94')
    d.line([(20,176),(24,172),(71,172)], fill='#b298ac', width=2)
    d.rectangle((24,180,71,183), fill='#75617d')
    d.line((24,186,71,186), fill='#493f58', width=2)
    # Capital is wider than the shaft, with one roof in exactly the wall's
    # top-down projection; its perimeter is a solid bevel, not a black stroke.
    d.polygon([(24,30),(71,30),(75,34),(75,84),(71,88),
               (24,88),(20,84),(20,34)], fill='#75617d')
    d.polygon([(20,34),(24,30),(24,78),(28,84),(24,84),(20,80)], fill='#ab8da2')
    d.polygon([(71,30),(75,34),(75,84),(71,88),(67,88),(71,80)], fill='#51435f')
    d.line([(20,34),(24,30),(71,30)], fill='#ceb0bd', width=2)
    # Copy only the roof, not the side shell already present in the wall PNG.
    roof = wall.crop((4,11,28,35)).resize((48,48), NEAREST)
    mask = Image.new('L', (24,24))
    ImageDraw.Draw(mask).polygon([(3,0),(20,0),(23,3),(23,20),
                                 (20,23),(3,23),(0,20),(0,3)], fill=255)
    roof.putalpha(mask.resize((48,48), NEAREST))
    im.alpha_composite(roof, (24,34))
    d.rectangle((24,84,71,87), fill='#987b90')
    d.rectangle((24,88,71,91), fill='#62516d')
    # Cooler grey stone keeps a little of the garden's violet ambient light.
    pixels = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r,g,b,a = pixels[x,y]
            if a:
                v = round(r*.30 + g*.48 + b*.22)
                pixels[x,y] = (min(255,v+2),v,min(255,v+7),a)
    d = ImageDraw.Draw(im)
    # Ivy grows ON the masonry: continuous bent shoots follow the face,
    # flatten over the chamfer, and disappear behind its outer edge.
    ivy=Image.new('RGBA',(48,112));iv=ImageDraw.Draw(ivy)
    shoots=[[(14,86),(17,82),(19,79),(18,75),(16,73),(17,70),
             (21,67),(22,64),(20,61),(17,59),(16,56),(17,53),
             (20,50),(21,47),(19,44)],
            [(17,70),(15,68),(14,64),(12,62),(11,60)],
            [(18,75),(22,73),(24,70),(25,68),(24,66)],
            [(17,53),(15,51),(14,48),(12,47),(11,45)]]
    # No detached outline: contact shadow is darkened stone, close to stems.
    shadow=Image.new('RGBA',(48,112));sd=ImageDraw.Draw(shadow)
    for points in shoots:
        sd.line([(x+1,y+1) for x,y in points],fill=(28,38,34,100),width=2)
        iv.line(points,fill=(56,83,73),width=1)
    # Small anchoring roots enter horizontal mortar rather than floating.
    for x,y,dx in [(19,79,3),(17,70,-3),(22,64,3),(17,59,-3),(20,50,3)]:
        iv.line([(x,y),(x+dx,y),(x+dx+1,y-1)],fill=(56,83,73))
    # Irregular leaves rotate along the shoots. On the side bevel they are
    # foreshortened and darker; there are deliberate gaps exposing the stone.
    leaves=[(16,82,-1),(20,78,1),(17,75,-1),(19,72,1),
            (20,67,-1),(23,65,1),(19,61,1),(16,58,-1),
            (18,54,1),(20,49,1),(18,46,-1),(15,67,-1),
            (13,63,-1),(23,71,1),(25,68,1),(14,49,-1),(12,46,-1)]
    for i,(x,y,direction) in enumerate(leaves):
        side=x<16
        width=1 if side else 2
        tip=(x+direction*width,y-2)
        shape=[(x,y+1),(x-direction,y-1),tip,(x+direction*(width+1),y)]
        sd.polygon([(px+1,py+1) for px,py in shape],fill=(28,38,34,110))
        iv.polygon(shape,fill=(56,83,73) if side else (76,104,89))
        if not side:iv.line((x,y,tip[0],tip[1]),fill=(102,127,105))
    shadow=shadow.resize(im.size,NEAREST);ivy=ivy.resize(im.size,NEAREST)
    # Clip to the stone silhouette; leaves cannot hang as a separate ribbon.
    from PIL import ImageChops
    for layer in (shadow,ivy):
        layer.putalpha(ImageChops.multiply(layer.getchannel('A'),im.getchannel('A')))
        im.alpha_composite(layer)
    # Lawn wildflowers grow at a few shoot junctions, with the same sprite.
    flowers=Image.open(A/'grass_clumps.png').convert('RGBA')
    for i,(x,y) in enumerate([(35,111),(41,154)]):
        flower=flowers.crop(((14+i%2)*16+4,4,(14+i%2)*16+12,13))
        im.alpha_composite(flower,(x-4,y-4))
    # The lantern is in front of the plant; foliage never paints over its cage.
    # Draw in source-sized pixels then enlarge 2x, matching the wall grid.
    lantern=Image.new('RGBA',(16,18));ld=ImageDraw.Draw(lantern)
    ld.rectangle((2,4,4,12),fill='#393843')
    ld.rectangle((3,3,8,5),fill='#77717c')
    # Broad visible lid: same top-down depth as the column capital.
    ld.polygon([(5,2),(11,2),(14,5),(14,8),(11,10),(5,10),(3,8),(3,5)],fill='#474550')
    ld.polygon([(5,2),(11,2),(14,5),(11,8),(5,8),(3,5)],fill='#89808a')
    ld.line((5,3,10,3),fill='#b2a3a7')
    ld.rectangle((5,9,11,14),fill='#e2b47c')
    ld.rectangle((6,9,8,12),fill='#f5d49a')
    ld.polygon([(12,9),(14,7),(14,13),(12,15)],fill='#9a754f')
    ld.rectangle((4,9,5,14),fill='#49434c')
    ld.rectangle((10,9,11,14),fill='#49434c')
    ld.rectangle((4,14,11,15),fill='#514b55')
    ld.line((12,15,14,13),fill='#363541')
    im.alpha_composite(lantern.resize((32,36),NEAREST),(26,88))
    # Inner side of the square footing runs BACK along the depth of the
    # footprint, rather than extending the front bar into the opening.
    # Shaft side ends at x71. A two-pixel ledge wraps it from rear to front.
    d.polygon([(70,138),(74,140),(74,180),(70,184)],fill='#92909a')
    d.polygon([(74,140),(76,142),(76,182),(72,188),(72,180),(74,178)],fill='#55535f')
    d.line((72,142,72,178),fill='#b0a7ae',width=2)
    d.line((74,144,74,180),fill='#6f6977',width=2)
    d.polygon([(70,180),(74,178),(76,180),(76,184),(72,188),(70,188)],fill='#66616f')
    return im


if __name__ == '__main__':
    im = column()
    for room in ['hedge', 'stone']:
        for corridor in ['stone', 'tree']:
            for end in ['top', 'bottom']:
                for side in ['left', 'right']:
                    # Lighting stays aligned with the walls on both posts.
                    (ImageOps.mirror(im) if side == 'right' else im).save(A / f'junction_{room}_{corridor}_{end}_{side}.png')
    print('Generated 16 standalone posts with wall-projected continuous masonry')
