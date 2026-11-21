"""Bake fitted brocade folds and rest poses for the simulated mantle."""
import json

from PIL import Image, ImageDraw

from create_royal_outfit import ASSETS, DARK, GOLD, GOLD_LIGHT, GOLD_SHADE, diamond

WIDTH, HEIGHT, COLUMNS = 48, 40, 16
TOP = 7
DRESS_FOLDS = 5
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


def dress_fold(layer, bend):
    """Reposition folds within the fabric while preserving every alpha pixel."""
    result = layer.copy()
    bottom = layer.getbbox()[3] - 1
    for y in range(31, bottom + 1):
        sway = round(bend * ((y - 30) / (bottom - 30)) ** 1.4)
        if not sway:
            continue
        for x in range(layer.width):
            original = layer.getpixel((x, y))
            sample = layer.getpixel((max(0, min(layer.width - 1, x - sway)), y))
            if original[3] and sample[3]:
                result.putpixel((x, y), sample[:3] + (original[3],))
    return result


def generate():
    atlas = Image.open(ASSETS / 'atlas.png').convert('RGBA')
    sprites = json.loads((ASSETS / 'atlas.json').read_text())
    slots = sum(FRAME_COUNTS) * (DRESS_FOLDS + 1)
    sheet = Image.new('RGBA', (COLUMNS * WIDTH, -(-slots // COLUMNS) * HEIGHT))
    index = 0
    for garment, item in enumerate(GARMENTS):
        for face, count in enumerate(FRAME_COUNTS):
            for frame in range(count):
                sprite = sprites[f'wear_{item}_{face}_{frame}']
                x, y = sprite % 16 * 32, sprite // 16 * 48
                layer = atlas.crop((x, y, x + 32, y + 48))
                if garment == 0:
                    poses = [dress_fold(layer, fold - DRESS_FOLDS // 2) for fold in range(DRESS_FOLDS)]
                else:
                    poses = [flowing_mantle(layer, face)]
                for pose in poses:
                    sheet.paste(pose.crop((0, TOP, 32, TOP + HEIGHT)),
                                (index % COLUMNS * WIDTH + 8, index // COLUMNS * HEIGHT))
                    index += 1
    sheet.save(ASSETS / 'royal_cloth.png', optimize=True)


if __name__ == '__main__':
    generate()
