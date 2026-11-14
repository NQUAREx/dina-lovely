"""Joined gate masonry at atlas pixel scale, with a separate vaulted lintel."""
from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageOps

A = Path(__file__).resolve().parents[1] / 'assets'
atlas = Image.open(A / 'atlas.png').convert('RGBA')
ids = json.loads((A / 'atlas.json').read_text())
# Existing garden masonry palette; every source pixel renders as two screen pixels.
SHADE = '#5d566e'
JOINT = '#716476'
STONE = '#958294'
LIGHT = '#b6a0ad'
EDGE = '#c5aeb9'


def sprite(name):
    i = ids[name]
    return atlas.crop((i % 16 * 32, i // 16 * 48,
                       i % 16 * 32 + 32, i // 16 * 48 + 48))


def masonry(size, polygon):
    """Continuous coursed stone, clipped to a beveled architectural footprint."""
    layer = Image.new('RGBA', size, STONE)
    d = ImageDraw.Draw(layer)
    for y in range(0, size[1], 8):
        d.line((0, y, size[0], y), fill=JOINT)
        d.line((0, y + 1, size[0], y + 1), fill=LIGHT)
        for x in range(-8 if y // 8 % 2 else 0, size[0], 16):
            d.line((x, y + 1, x, y + 7), fill=JOINT)
    mask = Image.new('L', size)
    md = ImageDraw.Draw(mask)
    md.polygon(polygon, fill=255)
    layer.putalpha(mask)
    d.line(polygon + [polygon[0]], fill=JOINT)
    return layer


def pillar(im):
    """Capital, shaft and plinth physically overlap both wall arms."""
    d = ImageDraw.Draw(im)
    # Beveled capital: broad enough to bear the lintel and corridor wall.
    d.polygon([(14, 36), (33, 36), (37, 40), (37, 44),
               (10, 44), (10, 40)], fill=JOINT)
    d.polygon([(14, 37), (33, 37), (36, 40), (11, 40)], fill=EDGE)
    d.rectangle((12, 41, 35, 43), fill=STONE)
    # Shaft continues into the horizontal masonry; no transparent seam.
    d.rectangle((16, 44, 31, 77), fill=SHADE)
    d.rectangle((17, 44, 29, 76), fill='#81758b')
    d.line((18, 45, 18, 75), fill=LIGHT)
    d.line((29, 45, 29, 76), fill=JOINT)
    for y in (56, 68):
        d.line((19, y, 28, y), fill=JOINT)
        d.line((19, y + 1, 28, y + 1), fill='#958294')
    # Small warm inset echoes the original doorpost ornament.
    d.rectangle((20, 47, 27, 52), fill='#e2bd80')
    d.line((20, 47, 27, 47), fill='#f1d5a1')
    # Chamfered, continuous foot; same center and extent as the former post.
    d.polygon([(14, 76), (33, 76), (39, 81), (39, 84),
               (8, 84), (8, 81)], fill=JOINT)
    d.polygon([(15, 76), (32, 76), (37, 80), (10, 80)], fill=LIGHT)
    d.rectangle((9, 81, 38, 83), fill=STONE)
    d.line((9, 81, 38, 81), fill=EDGE)


def junction(room, corridor, end):
    im = Image.new('RGBA', (48, 112))
    # Solid horizontal transition meets the existing room wall at x=0.
    # Both room materials terminate against the same masonry connector.
    # Hedge is therefore never used to conceal an architectural gap.
    arm = masonry(im.size, [(0, 57), (15, 57), (22, 63), (22, 76),
                            (16, 82), (0, 82)])
    im.alpha_composite(arm)
    d = ImageDraw.Draw(im)
    d.line((0, 58, 14, 58, 20, 64), fill=EDGE)
    d.line((0, 81, 15, 81), fill=SHADE)
    if end == 'top':
        shape = [(12, 0), (35, 0), (35, 43), (30, 48),
                 (17, 48), (12, 43)]
    else:
        shape = [(17, 69), (30, 69), (35, 74), (35, 111),
                 (12, 111), (12, 74)]
    im.alpha_composite(masonry(im.size, shape))
    d = ImageDraw.Draw(im)
    if end == 'top':
        d.line((13, 0, 13, 41), fill=LIGHT)
        d.line((34, 0, 34, 42), fill=SHADE)
    else:
        d.line((13, 76, 13, 111), fill=LIGHT)
        d.line((34, 76, 34, 111), fill=SHADE)
    pillar(im)
    return im


for room in ['hedge', 'stone']:
    for corridor in ['stone', 'tree']:
        for end in ['top', 'bottom']:
            im = junction(room, corridor, end)
            for side, image in [('left', im), ('right', ImageOps.mirror(im))]:
                image.save(A / f'junction_{room}_{corridor}_{end}_{side}.png')

# A shallow pointed romantic vault. Springing feet align with the pillar capitals.
# Source 128x48; screen rect: door position + (-128,-174), size (256,96).
outline = [(7, 47), (7, 28), (12, 21), (24, 15), (42, 8), (56, 4),
           (64, 1), (72, 4), (86, 8), (104, 15), (116, 21), (121, 28),
           (121, 47), (105, 47), (105, 32), (97, 26), (82, 20),
           (64, 15), (46, 20), (31, 26), (23, 32), (23, 47)]
lintel = masonry((128, 48), outline)
d = ImageDraw.Draw(lintel)
d.line([(8, 46), (8, 28), (13, 22), (25, 16), (43, 9),
        (57, 5), (64, 2)], fill=EDGE)
d.line([(120, 46), (120, 28), (115, 22), (103, 16), (85, 9),
        (71, 5), (64, 2)], fill=EDGE)
# The intrados reads as a single joined curve rather than disconnected blocks.
d.line([(23, 46), (23, 32), (31, 26), (46, 20), (64, 15),
        (82, 20), (97, 26), (105, 32), (105, 46)], fill=SHADE, width=2)
for x in (8, 105):
    d.rectangle((x, 42, x + 14, 46), fill=STONE)
    d.line((x, 42, x + 14, 42), fill=EDGE)
# Center keystone and restrained heart relief, from the existing warm accents.
d.polygon([(59, 4), (69, 4), (68, 18), (60, 18)], fill=LIGHT)
d.line((59, 4, 69, 4), fill=EDGE)
d.polygon([(61, 9), (62, 8), (64, 10), (66, 8), (67, 9),
           (67, 11), (64, 14), (61, 11)], fill='#c38391')
# Mirror source pixels exactly so the opening and every bevel share one axis.
lintel.paste(ImageOps.mirror(lintel.crop((0, 0, 64, 48))), (64, 0))
lintel.save(A / 'gate_lintel.png')
print('Generated 16 joined masonry junctions and gate_lintel.png')
