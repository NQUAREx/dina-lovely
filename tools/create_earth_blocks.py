"""Excavation earth cubes on the exact standard chamfered wall footprint.

Rows0:34 are the roof; rows34:64 are the vertical shell. The game projects
these regions with the same sizes used by its stone and timber boundaries.
"""
from pathlib import Path
from PIL import Image, ImageDraw
import random

from create_wall_art import wall_art

A = Path(__file__).resolve().parents[1] / 'assets'
ROOF = [(7,11),(24,11),(27,14),(27,31),(24,34),(7,34),(4,31),(4,14)]

def earth_block(variant):
    variant %= 4
    r = random.Random(72541 + variant * 971)
    im = Image.new('RGBA', (32,64))
    d = ImageDraw.Draw(im)
    # Continuous soil shell, including every bevel: no holes at cut corners.
    for n,p in enumerate(ROOF):
        q = ROOF[(n+1) % len(ROOF)]
        d.polygon([p,q,(q[0],q[1]+20),(p[0],p[1]+20)], fill='#553c2e')
    d.polygon([(4,31),(7,34),(7,54),(4,51)],fill='#856043')
    d.polygon([(7,34),(24,34),(24,54),(7,54)],fill='#674832')
    d.polygon([(24,34),(27,31),(27,51),(24,54)],fill='#3d2c26')
    d.polygon([(25,15),(27,14),(27,51),(25,52)],fill='#493428')
    # Soil horizons are broken, gently wavy bands, not brick mortar seams.
    for y,shadow,light in [(39,'#51392d','#805b3e'),(46,'#493428','#785139')]:
        wave = [(7,y),(11,y+1),(16,y),(20,y+1),(24,y)]
        d.line(wave,fill=shadow)
        d.line([(x,yy+1) for x,yy in wave],fill=light)
        d.line([(4,y-3),(7,y)],fill='#664832')
        d.line([(24,y),(27,y-3)],fill='#342722')
    d.line((7,54,24,54),fill='#322721')
    d.line((8,52,23,52),fill='#79523a')
    # Compact earth top: broad flat plane with a crumbled but aligned bevel.
    tops = ['#89633f','#84603e','#8d6745','#806040']
    d.polygon(ROOF,fill=tops[variant % 4])
    d.polygon([(4,14),(7,11),(7,31),(9,34),(7,34),(4,31)],fill='#a27a4f')
    d.polygon([(24,11),(27,14),(27,31),(24,34),(22,34),(24,31)],fill='#59412e')
    d.line([(4,14),(7,11),(24,11)],fill='#b08a59')
    d.line([(7,32),(23,32),(25,30)],fill='#654832')
    # Irregular packed clods and mineral grains keep the surface earthy.
    for n in range(30):
        x,y = r.randrange(8,24),r.randrange(14,31)
        colour = r.choice(['#785439','#a17a50','#926c46','#6a4a33'])
        d.line((x,y,x+r.choice([0,1,1,2]),y),fill=colour)
        if n % 5 == 0:d.point((x,y+1),fill='#6a4a33')
    # Distinct geological patches span multiple pixels, so variation reads at
    # game scale rather than disappearing into random single-pixel noise.
    if variant == 1:  # Moist, compacted soil: broad cool dark clods.
        for points in [[(9,17),(14,15),(18,17),(17,21),(11,22),(8,20)],
                       [(17,25),(22,23),(24,26),(22,29),(18,29)]]:
            d.polygon(points, fill='#664b37')
        d.line([(10,17),(14,16),(17,18)],fill='#96724d')
        d.polygon([(8,42),(14,40),(18,42),(16,45),(9,45)],fill='#4b382c')
    elif variant == 2:  # Pale mineral pocket and angular embedded stones.
        d.polygon([(15,17),(21,16),(24,19),(21,23),(17,22)],fill='#a98a5b')
        d.line([(16,18),(21,17),(23,19)],fill='#b89a6b')
        for x,y in [(10,26),(20,38),(10,47)]:
            d.polygon([(x,y),(x+3,y-1),(x+5,y+1),(x+4,y+3),(x,y+2)],fill='#676253')
            d.line([(x,y),(x+3,y-1),(x+4,y)],fill='#a49c7d')
    elif variant == 3:  # Deep humus with sparse exposed roots.
        d.polygon([(8,23),(12,20),(17,22),(20,28),(17,31),(10,29)],fill='#614633')
        d.line([(8,24),(12,22),(16,23)],fill='#856343')
        d.polygon([(15,36),(21,35),(24,38),(22,42),(16,41)],fill='#49362b')
    # Small broken root fibres wrap onto the front soil face.
    x = 10 + variant * 3
    d.line([(x,30),(x+1,34),(x,37),(x+2,39)],fill='#a68054')
    d.line([(x+1,34),(x+3,35),(x+2,37)],fill='#493528')
    # Embedded slate/ochre stones, never a decorative masonry pattern.
    for n in range(4):
        x,y = r.randrange(9,22),r.randrange(36,51)
        d.polygon([(x,y),(x+2,y-1),(x+3,y+1),(x+1,y+2)],fill='#514d40')
        d.line((x,y,x+1,y-1),fill='#a29876')
    # Two genuinely darker soils, not just identical surfaces with new noise.
    # One cool damp loam, one deep humus; preserve roof/face lighting contrast.
    if variant in (1,3):
        factors = (.83,.86,.91) if variant == 1 else (.68,.73,.81)
        pixels = im.load()
        for y in range(64):
            for x in range(32):
                red,green,blue,alpha = pixels[x,y]
                pixels[x,y] = (round(red*factors[0]),round(green*factors[1]),
                               round(blue*factors[2]),alpha)
    # Clamp coverage to the same standard block shell used throughout game.
    mask = wall_art().getchannel('A')
    im.putalpha(mask)
    return im

def generate():
    for variant in range(4):
        tile=earth_block(variant)
        suffix='' if variant==0 else str(variant)
        for kind in ['exposed']:  # stacked blocks reuse the exposed artwork
            tile.save(A/f'wall_room3_{kind}{suffix}.png')
    print('Generated four detailed earth cubes in standard wall perspective')

if __name__=='__main__':generate()
