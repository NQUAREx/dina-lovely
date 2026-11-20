"""Append the embroidered final-room accessories to the character atlas."""
from pathlib import Path
import json

from PIL import Image, ImageDraw, ImageOps

ASSETS = Path(__file__).resolve().parents[1] / 'assets'
DARK = '#624053'
GOLD_SHADE = '#96704d'
GOLD = '#d6a75e'
GOLD_LIGHT = '#ffe3a0'
GEM_DARK = '#254b4a'
GEM = '#477c6e'
GEM_LIGHT = '#b3e1af'
DRESS = ('#2b2037', '#58364d', '#85506a', '#402c42', GOLD)
MANTLE = ('#422940', '#644052', '#ae6c77', '#81546a')
OLD_DRESS = ('#302d48', '#55516c', '#77718a', '#403c58', '#bd9eaf')
OLD_SCARF = ('#65576d', '#8e7c90', '#c7b0be', '#b29baa')
ITEMS = ('gold_brocade', 'gold_mantle', 'gold_veil', 'emerald_diadem', 'gold_beads')


def reweave(source, old, new):
    palette = {bytes.fromhex(a[1:]): tuple(bytes.fromhex(b[1:])) for a, b in zip(old, new)}
    layer = source.copy()
    layer.putdata([palette.get(bytes(pixel[:3]), pixel[:3]) + (pixel[3],) for pixel in source.getdata()])
    return layer


def clipped(layer, embroidery):
    embroidery.putalpha(Image.composite(embroidery.getchannel('A'), Image.new('L', layer.size), layer.getchannel('A')))
    layer.alpha_composite(embroidery)
    return layer


def diamond(draw, x, y, side=2):
    draw.polygon([(x, y-side), (x+side, y), (x, y+side), (x-side, y)], fill=GOLD_SHADE)
    draw.point((x, y-1), fill=GOLD_LIGHT)
    draw.point((x, y), fill=GOLD)


def embroidery(layer, face):
    overlay = Image.new('RGBA', layer.size)
    draw = ImageDraw.Draw(overlay)
    offset = -1 if face in (1, 4, 6) else 1 if face in (3, 5, 7) else 0
    drop = layer.getbbox()[3]
    for y in range(drop-14, drop-4, 5):
        row = layer.getchannel('A').crop((0, y, 32, y+1)).getbbox()
        if not row:
            continue
        center = (row[0]+row[2])//2+offset
        for x in (center-4, center+3) if y < drop-8 else (center-6, center, center+6):
            diamond(draw, x, y)
    for x in range(32):
        ys = [y for y in range(drop-4, drop) if layer.getpixel((x, y))[3]]
        if ys:
            draw.point((x, ys[-1]), fill=GOLD_SHADE)
        if len(ys) > 2:
            draw.point((x, ys[-2]), fill=GOLD_LIGHT if x % 4 == 0 else GOLD)
    return clipped(layer, overlay)


def mantle(scarf, face, bob):
    layer = Image.new('RGBA', (32, 48))
    draw = ImageDraw.Draw(layer)
    if face in (0, 4, 5):
        drift = {0:0, 4:-1, 5:1}[face]
        draw.polygon([(7, 25+bob), (23, 25+bob), (25+drift, 36), (22+drift, 40),
                      (8+drift, 40), (5+drift, 37)], fill=DARK)
        draw.polygon([(8, 26+bob), (22, 27+bob), (23+drift, 37), (20+drift, 39),
                      (9+drift, 38), (7+drift, 36)], fill=MANTLE[1])
        draw.line([(8, 30+bob), (7+drift, 37), (11+drift, 39), (19+drift, 39),
                   (23+drift, 37), (22, 31+bob)], fill=GOLD_SHADE)
        diamond(draw, 15+drift, 35, 3)
        draw.point((12+drift, 37), fill=GOLD)
        draw.point((18+drift, 37), fill=GOLD)
    elif face in (1, 3):
        if face == 3:
            points = [(8, 23+bob), (14, 26+bob), (15, 35), (11, 38), (6, 37), (8, 32)]
        else:
            points = [(31-x, y) for x, y in [(8, 23+bob), (14, 26+bob), (15, 35), (11, 38), (6, 37), (8, 32)]]
        draw.polygon(points, fill=MANTLE[1])
        draw.line(points[2:5], fill=GOLD)
    else:
        for x in (6, 24):
            draw.polygon([(x, 27+bob), (x+2, 25+bob), (x+3, 33+bob), (x, 35+bob)], fill=DARK)
            draw.line((x+1, 30+bob, x+1, 34+bob), fill=GOLD)
    collar = reweave(scarf, OLD_SCARF, MANTLE)
    overlay = Image.new('RGBA', layer.size)
    detail = ImageDraw.Draw(overlay)
    for y in range(8+bob, 31+bob):
        for x in range(32):
            if scarf.getpixel((x, y))[:3] in [(199,176,190), (178,155,170)]:
                if y < 16+bob or (x+y)%4 == 0:
                    detail.point((x,y), fill=GOLD_LIGHT if (x+y)%3 == 0 else GOLD)
    layer.alpha_composite(clipped(collar, overlay))
    return layer


def veil(white_veil):
    layer = reweave(white_veil, ('#d3cedb',), ('#5a3c56',))
    bottom = layer.getbbox()
    if bottom is None:
        return layer
    draw = ImageDraw.Draw(layer)
    left, top, right, foot = bottom
    for x in range(left, right):
        opaque = [y for y in range(top, foot) if layer.getpixel((x,y))[3]]
        if opaque:
            draw.point((x, opaque[-1]), fill=GOLD)
        if len(opaque)>4 and x%3==1:
            draw.point((x, opaque[-3]), fill=GOLD_LIGHT)
    return layer


def diadem(face, bob):
    layer = Image.new('RGBA', (32, 48))
    draw = ImageDraw.Draw(layer)
    offset = -2 if face in (1,4,6) else 2 if face in (3,5,7) else 0
    x = 16+offset
    if face == 0:
        draw.line([(7,13+bob), (10,10+bob), (15,9+bob), (21,9+bob), (25,13+bob)], fill=GOLD_SHADE, width=3)
        draw.line([(8,12+bob), (12,10+bob), (20,10+bob), (24,12+bob)], fill=GOLD)
        for bead in (10,14,20,23):
            draw.point((bead,10+bob+(bead in (10,23))), fill=GOLD_LIGHT)
        return layer
    span = 7 if face in (1,3) else 10
    draw.line([(x-span,13+bob), (x-4,9+bob), (x,12+bob), (x+4,9+bob), (x+span,13+bob)],
              fill=GOLD_SHADE, width=3)
    draw.line([(x-span,13+bob), (x-4,10+bob), (x,12+bob), (x+4,10+bob), (x+span,13+bob)], fill=GOLD)
    for gem_x in (x-5,x+5):
        diamond(draw, gem_x, 9+bob)
        draw.point((gem_x, 9+bob), fill=GEM)
    draw.polygon([(x,2+bob), (x+4,7+bob), (x+3,11+bob), (x,14+bob),
                  (x-3,11+bob), (x-4,7+bob)], fill=GOLD_SHADE)
    draw.polygon([(x,3+bob), (x+3,7+bob), (x+2,11+bob), (x,12+bob),
                  (x-2,10+bob), (x-3,7+bob)], fill=GOLD)
    draw.polygon([(x,4+bob), (x+2,7+bob), (x,10+bob), (x-2,7+bob)], fill=GEM_DARK)
    draw.polygon([(x,5+bob), (x+1,7+bob), (x,9+bob), (x-1,7+bob)], fill=GEM)
    draw.point((x,6+bob), fill=GEM_LIGHT)
    draw.point((x+1,3+bob), fill=GOLD_LIGHT)
    return layer


def beads(face, bob, icon=False):
    layer = Image.new('RGBA', (32, 48))
    draw = ImageDraw.Draw(layer)
    if icon:
        points = [(9,25),(8,30),(9,34),(12,37),(16,39),(20,38),(23,35),(24,30),(23,25),(19,22),(14,22)]
    elif face == 2:
        points = [(11,30),(13,32),(16,34),(19,32),(21,30)]
    elif face == 3:
        points = [(18,30),(21,32),(22,34)]
    elif face == 7:
        points = [(13,30),(15,32),(18,34),(20,33),(22,31)]
    elif face in (1,6):
        return ImageOps.mirror(beads(3 if face == 1 else 7, bob))
    else:
        return layer
    for x,y in points:
        y += bob
        draw.rectangle((x-1,y,x,y+1), fill=GOLD_SHADE)
        draw.point((x,y), fill=GOLD)
        draw.point((x-1,y), fill=GOLD_LIGHT)
    if icon:
        diamond(draw,16,41,3)
    return layer


def pickup(item):
    layer = Image.new('RGBA', (32,48))
    draw = ImageDraw.Draw(layer)
    if item == 'gold_brocade':
        draw.polygon([(11,19),(21,19),(24,25),(20,28),(27,44),(5,44),(12,28),(8,25)],fill=DRESS[0])
        draw.polygon([(13,22),(19,22),(18,28),(24,42),(8,42),(14,28)],fill=DRESS[1])
        draw.line([(14,29),(12,36),(11,42)],fill=DRESS[2])
        return embroidery(layer,2)
    if item == 'gold_mantle':
        draw.polygon([(12,20),(20,20),(24,24),(25,31),(28,41),(21,43),(9,42),(4,40),(8,27)],fill=DARK)
        draw.line([(12,22),(10,27),(9,35),(7,39),(14,41),(23,41),(25,40),(22,32)],fill=GOLD)
        diamond(draw,16,24)
        for x,y in [(12,30),(20,31),(15,36),(21,38),(11,38)]:
            diamond(draw,x,y)
    if item == 'gold_veil':
        draw.polygon([(9,26),(13,22),(21,22),(24,26),(25,39),(20,43),(11,43),(7,39)],fill='#5a3c56')
        draw.rectangle((10,28,14,29),fill=(0,0,0,0))
        draw.rectangle((18,28,22,29),fill=(0,0,0,0))
        draw.line([(8,38),(12,41),(20,41),(24,38)],fill=GOLD)
        diamond(draw,16,35)
    if item == 'emerald_diadem':
        layer.alpha_composite(diadem(2,0),(0,24))
    if item == 'gold_beads':
        return beads(2,0,True)
    return layer


def generate():
    atlas_file = ASSETS / 'atlas.png'
    index_file = ASSETS / 'atlas.json'
    atlas = Image.open(atlas_file).convert('RGBA')
    index = json.loads(index_file.read_text())
    next_id = max(index.values())+1

    def rect(sprite_id):
        x,y = sprite_id%16*32, sprite_id//16*48
        return x,y,x+32,y+48

    def get(name):
        return atlas.crop(rect(index[name]))

    def put(name, layer):
        nonlocal atlas, next_id
        if name not in index:
            index[name] = next_id
            next_id += 1
        x,y,_,bottom = rect(index[name])
        if bottom > atlas.height:
            grown = Image.new('RGBA', (atlas.width,bottom))
            grown.paste(atlas)
            atlas = grown
        atlas.paste(layer, (x,y))

    for item in ITEMS:
        put(f'accessory_{item}',pickup(item))
    for face in range(8):
        for frame in range(8 if face in (1,3) else 4):
            scarf = get(f'wear_dark_scarf_{face}_{frame}')
            dress = get(f'wear_black_dress_{face}_{frame}')
            white_veil = get(f'wear_white_veil_{face}_{frame}')
            # The hood's top edge carries the actual vertical offset of each pose.
            bob = scarf.getbbox()[1] - get(f'wear_dark_scarf_{face}_0').getbbox()[1]
            layers = (embroidery(reweave(dress,OLD_DRESS,DRESS),face),
                      mantle(scarf,face,bob), veil(white_veil), diadem(face,bob), beads(face,bob))
            for item, layer in zip(ITEMS, layers):
                put(f'wear_{item}_{face}_{frame}', layer)
    atlas.save(atlas_file)
    index_file.write_text(json.dumps(index))


if __name__ == '__main__':
    generate()
