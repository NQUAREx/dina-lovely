"""Bake pixel silhouettes for every body pose and cloth deformation."""
import json
from math import sin

from PIL import Image, ImageDraw

from create_royal_outfit import ASSETS, DARK, GOLD, GOLD_LIGHT, GOLD_SHADE, diamond

WIDTH, HEIGHT, COLUMNS = 48, 40, 64
TOP = 7
SWAY_STEPS, SPREAD_STEPS = 9, 7
GARMENTS = ('gold_brocade', 'gold_mantle')
FRAME_COUNTS = (4, 8, 4, 8, 4, 4, 4, 4)


def flowing_mantle(layer, face):
    """Extend the shoulder cloth, behind the hood and over the brocade."""
    base = Image.new('RGBA', layer.size)
    draw = ImageDraw.Draw(base)
    if face in (0, 4, 5):
        draw.polygon([(9, 26), (23, 26), (26, 40), (23, 43), (19, 42),
                      (16, 44), (10, 43), (6, 40)], fill='#54334d')
        draw.line([(7, 39), (11, 42), (15, 42), (18, 43), (23, 42), (25, 40)], fill=GOLD)
        diamond(draw, 16, 39)
    else:
        sides = (1,) if face in (1, 6) else (-1,) if face in (3, 7) else (-1, 1)
        for side in sides:
            def point(x, y):
                return (x if side == -1 else 31-x, y)

            draw.polygon([point(10, 24), point(12, 28), point(13, 37),
                          point(10, 42), point(5, 41), point(6, 34)], fill=DARK)
            draw.line([point(6, 35), point(5, 40), point(9, 41), point(12, 37)], fill=GOLD_SHADE)
            draw.line([point(6, 40), point(9, 41), point(11, 39)], fill=GOLD_LIGHT)
    base.alpha_composite(layer)
    return base


def deform(layer, garment, sway, spread, face, frame):
    output = Image.new('RGBA', (WIDTH, HEIGHT))
    attachment = 30 if garment == 0 else 23
    spread_depth = 5.5 if garment == 0 else 4.2
    travel = 7.0 if garment == 0 else 9.0
    bottom = layer.getbbox()[3] - 1
    padding = (WIDTH - layer.width) // 2
    for y in range(TOP, TOP + HEIGHT):
        # Keep the bodice and head attached while the lower fabric swings.
        weight = max(0., (y - attachment) / (bottom - attachment))
        lift = spread * (2.1 if garment == 0 else 2.9)
        source_y = round(y + lift * weight ** 2)
        if source_y >= layer.height:
            continue
        row = layer.crop((0, source_y, 32, source_y + 1))
        bounds = row.getbbox()
        if bounds is None:
            continue
        left, _, right, _ = bounds
        expansion = round(spread * spread_depth * weight)
        fold = sin(weight * 6.0 + frame * 1.4 + face * .7) * spread * weight
        shift = round(sway * travel * weight ** 1.45 + fold)
        strip = row.crop((left, 0, right, 1))
        if expansion:
            strip = strip.resize((strip.width + expansion * 2, 1), Image.Resampling.NEAREST)
        output.paste(strip, (padding + left + shift - expansion, y - TOP))
    return output


def generate():
    atlas = Image.open(ASSETS / 'atlas.png').convert('RGBA')
    sprites = json.loads((ASSETS / 'atlas.json').read_text())
    slots = len(GARMENTS) * sum(FRAME_COUNTS) * SWAY_STEPS * SPREAD_STEPS
    sheet = Image.new('RGBA', (COLUMNS * WIDTH, -(-slots // COLUMNS) * HEIGHT))
    index = 0
    for garment, item in enumerate(GARMENTS):
        for face, count in enumerate(FRAME_COUNTS):
            for frame in range(count):
                sprite = sprites[f'wear_{item}_{face}_{frame}']
                x, y = sprite % 16 * 32, sprite // 16 * 48
                layer = atlas.crop((x, y, x + 32, y + 48))
                if garment == 1:
                    layer = flowing_mantle(layer, face)
                for spread in range(SPREAD_STEPS):
                    for sway in range(SWAY_STEPS):
                        pose = deform(layer, garment, sway / 4 - 1, spread / 6, face, frame)
                        sheet.paste(pose, (index % COLUMNS * WIDTH, index // COLUMNS * HEIGHT))
                        index += 1
    sheet.save(ASSETS / 'royal_cloth.png', optimize=True)


if __name__ == '__main__':
    generate()
