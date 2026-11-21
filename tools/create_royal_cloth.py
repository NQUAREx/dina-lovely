"""Build brocade and mantle shells and fitted linings for every walk pose."""
import json
from math import sin, tau

from PIL import Image, ImageChops, ImageDraw

from create_royal_outfit import (
    ASSETS, DARK, GOLD, GOLD_LIGHT, GOLD_SHADE, OLD_DRESS, OLD_SCARF,
    diamond, reweave,
)

WIDTH, HEIGHT, COLUMNS = 48, 40, 16
TOP = 7
FRAME_COUNTS = (4, 8, 4, 8, 4, 4, 4, 4)


def flowing_mantle(layer, face, heroine):
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
    # Paired, tapering slopes pick up the light across the fabric hanging
    # from the crown. Leave the embroidered selvedge and filigree untouched.
    fold = Image.new('RGBA', layer.size)
    relief = ImageDraw.Draw(fold)
    bob = layer.getbbox()[1] - TOP
    if face in (0, 4, 5):
        shift = {0: 0, 4: -2, 5: 2}[face]
        folds = [
            [(14+shift, 14+bob), (12+shift, 18+bob), (12+shift, 23+bob),
             (11+shift, 28), (9+shift, 33), (9+shift, 36)],
            [(20+shift, 17+bob), (21+shift, 21+bob), (20+shift, 26),
             (21+shift, 29), (22+shift, 33)],
        ]
    else:
        sides = (1,) if face in (1, 6) else (-1,) if face in (3, 7) else (-1, 1)
        folds = []
        for side in sides:
            ridge = [(10, 13+bob), (9, 17+bob), (9, 22+bob), (10, 27+bob),
                     (9, 31), (8, 34), (8, 38)]
            folds.append([(x if side < 0 else 31-x, y) for x, y in ridge])
    for ridge in folds:
        relief.line([(x+1, y) for x, y in ridge[1:-1]], fill='#553749')
        relief.line(ridge, fill='#785064')
        relief.line(ridge[2:4], fill='#805568')
    # The long panels continue behind the chin, including on three-quarter
    # poses. Read the face opening directly from its own animated frame.
    for y in range(layer.height):
        for x in range(layer.width):
            if heroine.getpixel((x, y))[:3] in ((214, 163, 131), (188, 142, 120)):
                base.putpixel((x, y), (0, 0, 0, 0))
            elif base.getpixel((x, y)) in MANTLE_GROUND and fold.getpixel((x, y))[3]:
                base.putpixel((x, y), fold.getpixel((x, y)))
    return base


MANTLE_GROUND = {(100, 64, 82, 255), (98, 64, 83, 255), (84, 51, 77, 255)}


def dress_shell(layer, face, frame):
    # The source wardrobe recolors the lateral shoes together with the skirt.
    # Keep those pixels on the fitted layer; embroidered shoes must not bend
    # in midair when the hem lifts. Follow the walk artist's skirt silhouette.
    if face not in (1, 3):
        return layer
    phase = frame * tau / 8
    sign = 1 if face == 3 else -1
    trail = round(sin(phase - .6)*2)
    stride = round(sin(phase)*3)
    hem = [(8+trail, 41), (9+trail, 43), (20+stride//2, 44), (24-sign+trail, 42)]
    skirt = Image.new('L', layer.size)
    draw = ImageDraw.Draw(skirt)
    draw.polygon([(0, 0), (31, 0), (31, 38), (hem[-1][0], 38),
                  *reversed(hem), (hem[0][0], 38), (0, 38)], fill=255)
    layer.putalpha(ImageChops.multiply(layer.getchannel('A'), skirt))
    # A continuous piping along the real hem, above the grounded shoes.
    trim = Image.new('RGBA', layer.size)
    edge = ImageDraw.Draw(trim)
    edge.line(hem, fill=GOLD_SHADE)
    edge.line([(x, y-1) for x, y in hem], fill=GOLD)
    edge.point((hem[1][0]+1, hem[1][1]-1), fill=GOLD_LIGHT)
    trim.putalpha(ImageChops.multiply(trim.getchannel('A'), layer.getchannel('A')))
    layer.alpha_composite(trim)
    return layer


def generate():
    atlas = Image.open(ASSETS / 'atlas.png').convert('RGBA')
    sprites = json.loads((ASSETS / 'atlas.json').read_text())
    pose_count = sum(FRAME_COUNTS)
    rows = (4 * pose_count + COLUMNS - 1) // COLUMNS
    sheet = Image.new('RGBA', (COLUMNS * WIDTH, rows * HEIGHT))

    def source(name):
        sprite = sprites[name]
        x, y = sprite % 16 * 32, sprite // 16 * 48
        return atlas.crop((x, y, x + 32, y + 48))

    pose = 0
    for face, count in enumerate(FRAME_COUNTS):
        for frame in range(count):
            # Match the exact skin, glove and shoe openings in the base pose.
            # Subdued tones on the inner face keep the moving outer embroidery
            # legible when a turn opens the distance between the two layers.
            dress_lining = reweave(source(f'wear_black_dress_{face}_{frame}'), OLD_DRESS,
                                   ('#483044', '#59394e', '#76505b', '#513547', '#684653'))
            heroine = source(f'hero{face}_{frame}')
            # The sleeve belongs to the body animation. It can peek out when
            # the scarf swings back during a diagonal turn.
            for y in range(28, 41):
                for x in range(heroine.width):
                    if heroine.getpixel((x, y)) == (74, 67, 93, 255):
                        dress_lining.putpixel((x, y), (82, 54, 71, 255))
            mantle_lining = reweave(source(f'wear_dark_scarf_{face}_{frame}'), OLD_SCARF,
                                    ('#503549', '#5c3e50', '#6c4a5a', '#654455'))
            mantle = flowing_mantle(source(f'wear_gold_mantle_{face}_{frame}'), face, heroine)
            layers = (dress_shell(source(f'wear_gold_brocade_{face}_{frame}'), face, frame),
                      mantle, dress_lining, mantle_lining)
            for bank, layer in enumerate(layers):
                index = bank * pose_count + pose
                sheet.paste(layer.crop((0, TOP, 32, TOP + HEIGHT)),
                            (index % COLUMNS * WIDTH + 8, index // COLUMNS * HEIGHT))
            pose += 1
    sheet.save(ASSETS / 'royal_cloth.png', optimize=True)


if __name__ == '__main__':
    generate()
