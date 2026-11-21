"""Generate the masonry shuttle, and floor rails."""
from pathlib import Path
from PIL import Image, ImageDraw

ASSETS = Path(__file__).resolve().parent.parent / "assets"


def make_shuttle():
    texture = Image.new("RGBA", (72, 92))
    draw = ImageDraw.Draw(texture)
    draw.polygon([(5, 0), (66, 0), (71, 5), (71, 86), (66, 91),
                  (5, 91), (0, 86), (0, 5)], fill="#31283e")
    draw.polygon([(6, 2), (65, 2), (69, 6), (69, 60), (64, 65),
                  (7, 65), (2, 60), (2, 6)], fill="#726078")
    draw.line([(3, 56), (3, 7), (7, 3), (65, 3), (68, 6)], fill="#a18a9e", width=2)
    draw.polygon([(6, 67), (65, 67), (68, 62), (68, 84), (64, 88),
                  (7, 88), (3, 84), (3, 62)], fill="#594962")
    draw.line([(6, 87), (65, 87)], fill="#42364e", width=2)
    for y in (6, 35):
        for x in (6, 26, 46):
            color = ("#7c6a7f", "#726276", "#806d82")[(x // 20 + y // 25) % 3]
            draw.rectangle((x + 1, y + 1, x + 17, y + 24), fill=color)
            draw.line([(x + 2, y + 22), (x + 2, y + 2), (x + 16, y + 2)], fill="#938096")
            draw.line([(x + 2, y + 24), (x + 17, y + 24), (x + 17, y + 3)], fill="#57465e")
            for dx, dy in ((4, 8), (10, 10), (8, 13), (12, 16), (7, 18), (5, 19)):
                draw.point((x + dx, y + dy), fill="#9b8798")
    for y, shift in ((70, 0), (77, 7), (84, 0)):
        draw.line([(5, y), (66, y)], fill="#41354d")
        for x in range(19 + shift, 66, 15):
            draw.line([(x, y), (x, min(y + 6, 85))], fill="#493d54")
    return texture


def make_rails():
    texture = Image.new("RGBA", (72, 24))
    draw = ImageDraw.Draw(texture)
    for y in (5, 18):
        draw.rectangle((5, y, 66, y + 2), fill="#292b37")
        draw.line([(11, y), (61, y)], fill="#51485a")
    for x in (8, 62):
        draw.rectangle((x - 1, 0, x + 1, 23), fill="#2d2939")
        draw.line([(x, 0), (x, 23)], fill="#62586c")
        draw.point((x, 6), fill="#8f7e93")
        draw.point((x, 19), fill="#8f7e93")
    return texture


if __name__ == "__main__":
    for name, graphic in (("block", make_shuttle()), ("rail", make_rails())):
        graphic.save(ASSETS / f"beam_crusher_{name}.png", optimize=True)
