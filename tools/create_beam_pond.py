"""Paint the beam hall's lily pool on a two-world-unit pixel grid."""
from pathlib import Path
import math
import random

from PIL import Image, ImageDraw

ASSETS = Path(__file__).resolve().parents[1] / "assets"
rng = random.Random(65431)


def paint_water():
    width, height = 216, 312
    image = Image.new("RGB", (width, height), "#2c5356")
    draw = ImageDraw.Draw(image)
    for y in range(height):
        for x in range(width):
            edge = min(x, width - x - 1)
            bank = min(y, height - y - 1)
            wave = math.sin(x * .073 + y * .018) * 2 + math.sin(y * .084 - x * .34)
            light = round(2 + 2 * wave - max(0, 7 - edge) * 1.7)
            if bank < 12:
                light += (12 - bank) // 3
            image.putpixel((x, y), (39 + light, 77 + light, 82 + light))
    for _ in range(340):
        x, y = rng.randrange(5, width - 5), rng.randrange(5, height - 5)
        length = rng.choice((2, 3, 5, 7))
        color = rng.choice(("#355c60", "#42696c", "#315457", "#507475"))
        draw.line((x, y, x + length, y), fill=color)
        if rng.random() < .35:
            draw.point((x + length + 2, y - 1), fill="#42696c")
    # Weathered retaining lip across the two banks; sides meet the wall.
    for y in (0, height - 4):
        draw.rectangle((0, y, width, y + 3), fill="#293e42")
        for x in range(-4, width, 12):
            w = rng.randrange(8, 12)
            draw.rectangle((x, y, x + w, y + 2), fill=rng.choice(("#62736c", "#536966", "#65746f")))
            draw.line((x + 1, y, x + w - 2, y), fill="#7c8880")
    image.save(ASSETS / "beam_pond.png")


def paint_lily(variant):
    width, height = 72, 60
    cx, cy = 36, 30
    image = Image.new("RGBA", (width, height))
    draw = ImageDraw.Draw(image)
    notch = -.9 - variant * .72
    outline = []
    for index in range(32):
        theta = notch + .17 + index * ((math.tau - .34) / 31)
        rough = 1 + .034 * math.cos(theta * 5 + variant) + rng.uniform(-.017, .017)
        outline.append((round(cx + math.cos(theta) * 26 * rough),
                        round(cy + math.sin(theta) * 26 * rough)))
    outline.append((round(cx + math.cos(notch) * 9), round(cy + math.sin(notch) * 8)))
    draw.polygon([(x, y + 4) for x, y in outline], fill="#1c3f3e")
    draw.polygon(outline, fill="#315950")
    inner = [(round(cx + (x-cx) * .94), round(cy + (y-cy) * .91) - 1) for x, y in outline[:-1]] + [outline[-1]]
    mask = Image.new("1", image.size)
    ImageDraw.Draw(mask).polygon(inner, fill=1)
    for y in range(height):
        for x in range(width):
            if not mask.getpixel((x, y)):
                continue
            n = math.sin(x * .21 + y * .31 + variant) * .57 + math.sin((x-y) * .16) * .83
            light = -y * .13 - x * .05 + n * 3 + rng.choice((-1, 0, 1))
            base = (76 + variant % 3 * 3, 121 + variant % 2 * 4, 83 + variant * 2)
            image.putpixel((x, y), tuple(round(c + light) for c in base) + (255,))
    vein = Image.new("RGBA", image.size)
    vd = ImageDraw.Draw(vein)
    for angle in (-2.8, -2.15, -.8, -.15, .68, 1.55, 2.37):
        if abs(math.remainder(angle - notch, math.tau)) < .27:
            continue
        tx = round(cx + 23 * math.cos(angle))
        ty = round(cy + 23 * math.sin(angle))
        mx = (cx + tx) // 2
        my = (cy + ty) // 2
        vd.line(((cx, cy), (mx, my - 2), (tx, ty)), fill="#517956")
        vd.point((tx, ty - 1), fill="#8fa866")
    vd.line(inner[17:28], fill="#92a974")
    image.paste(vein, mask=Image.composite(vein.getchannel("A"), Image.new("L", image.size), mask))
    if variant in (1, 3, 5):
        x = 29 + (variant % 2) * 13
        y = 38 if variant == 1 else 20
        draw.polygon(((x - 7,y), (x - 3,y - 5), (x,y - 3), (x + 3,y - 7),
                      (x + 7,y - 2), (x + 6,y + 2), (x,y + 5), (x - 5,y + 3)), fill="#786077")
        draw.polygon(((x - 5,y), (x - 3,y - 4), (x,y - 2), (x + 2,y - 6),
                      (x + 5,y - 2), (x + 3,y + 2), (x - 2,y + 3)), fill="#cf9aac")
        draw.line(((x - 1,y), (x + 1,y - 2)), fill="#f7d5bc")
    return image


if __name__ == "__main__":
    paint_water()
    lilies = Image.new("RGBA", (72 * 6, 60))
    for index in range(6):
        lilies.paste(paint_lily(index), (72 * index, 0))
    lilies.save(ASSETS / "beam_lilies.png")
