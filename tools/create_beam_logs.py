"""Draw the sliding logs with stepped bark, cut ends and fixed-size growth rings."""
from pathlib import Path
from random import Random

from PIL import Image, ImageDraw

MIN_LENGTH = 70
MAX_LENGTH = 135
CELL_WIDTH = 136
CELL_HEIGHT = 28
COLUMNS = 8
VARIANTS = 3

PALETTES = (
    ("#382733", "#573641", "#74474a", "#92594e", "#ad7157", "#c18a66"),
    ("#3b2933", "#62413b", "#7f5145", "#9c644d", "#b57c59", "#ca936d"),
    ("#362a36", "#553c46", "#704d49", "#885d52", "#a37964", "#bc9274"),
)


def grain(draw, rng, start, stop, palette):
    for index in range(41):
        y = rng.randint(4, 22)
        x = rng.randint(start, stop)
        points = [(x, y)]
        for _ in range(rng.randint(2, 5)):
            x += rng.randint(2, 10)
            y += rng.choice((-1, 0, 0, 1))
            points.append((x, y))
        # Highlights are strongest along the cylinder's upper shoulder.
        shade = rng.choice((1, 2, 4, 5)) if y < 13 else rng.choice((0, 1, 3))
        draw.line(points, fill=palette[shade])
        if index % 5 == 0:
            draw.line([(px, py + 1) for px, py in points[:-1]], fill=palette[max(0, shade - 1)])


def log_sprite(length, variant):
    palette = PALETTES[variant]
    rng = Random(8321 + variant * 42991 + length * 797)
    center = length - 12
    image = Image.new("RGBA", (length, CELL_HEIGHT))
    mask = Image.new("L", image.size)
    outline = [(12, 2), (center, 2), (length-5, 5), (length-2, 9),
               (length-1, 15), (length-4, 21), (center+1, 24), (10, 24),
               (5, 22), (1, 17), (0, 11), (3, 6), (7, 3)]
    ImageDraw.Draw(mask).polygon(outline, fill=255)

    bark = Image.new("RGBA", image.size)
    draw = ImageDraw.Draw(bark)
    bands = [(2, 4, 3), (5, 8, 5), (9, 12, 4), (13, 16, 3),
             (17, 20, 2), (21, 23, 1), (24, 25, 0)]
    for top, bottom, shade in bands:
        draw.rectangle((0, top, length-1, bottom), fill=palette[shade])
    grain(draw, rng, 12, length-7, palette)
    for x in (length//2 + rng.randint(-9, 8), length*3//4):
        y = rng.randint(10, 16)
        draw.line([(x-9,y-1),(x-4,y-2),(x+3,y-2),(x+7,y),(x+13,y+1)], fill=palette[1])
        draw.line([(x-7,y+2),(x-3,y+1),(x+2,y+1),(x+5,y),(x+8,y+1)], fill=palette[4])
        draw.polygon([(x-3,y),(x,y-1),(x+3,y),(x+1,y+2)], fill=palette[0])
        draw.point((x+2,y), fill=palette[2])
    draw.line([(12,3),(center-15,3),(center-9,4),(center-1,4)], fill=palette[5])
    draw.line([(11,23),(center-4,23),(center+3,22),(length-4,19)], fill=palette[0])
    draw.line([(center,3),(center+6,6),(length-2,11),(length-2,16),(center+7,21)], fill=palette[2])
    image.paste(bark, mask=mask)

    # The near end is a tilted ellipse. Offset the inner growth rings
    # to give the cut wood a pith and a natural split.
    draw = ImageDraw.Draw(image)
    draw.polygon([(9,2),(15,3),(19,6),(22,11),(22,16),(19,21),(14,24),
                  (8,24),(3,21),(0,16),(0,10),(3,6)], fill=palette[0])
    draw.polygon([(9,3),(14,4),(18,6),(20,11),(20,16),(17,20),(13,22),
                  (8,22),(4,19),(2,15),(2,10),(5,6)], fill="#8e6051")
    draw.polygon([(9,4),(14,5),(17,7),(19,11),(19,15),(16,19),(12,21),
                  (8,20),(4,17),(3,13),(4,9),(6,6)], fill="#d9ad79")
    draw.line([(7,5),(11,4),(15,6),(18,9),(19,12)], fill="#efc58e")
    draw.line([(8,20),(13,20),(17,17),(19,14)], fill="#ad775b")
    draw.line([(7,7),(11,6),(15,8),(17,11),(17,15),(14,18),(10,19),
               (7,17),(5,14),(5,11),(7,7)], fill="#ba855f")
    draw.line([(8,9),(12,8),(15,10),(15,14),(12,16),(9,16),(7,13),(8,9)],
              fill="#ba855f")
    draw.line([(10,10),(13,11),(13,13),(11,14),(9,12),(10,10)], fill="#a67558")
    draw.point((11,12), fill="#86574b")
    draw.line([(3,14),(6,13),(8,14),(9,13)], fill="#87574d")
    draw.line([(14,19),(14,17),(13,16)], fill="#9c6853")
    draw.point((6,8), fill="#f0c490")
    return image


def generate():
    count = (MAX_LENGTH - MIN_LENGTH + 1) * VARIANTS
    rows = (count + COLUMNS - 1) // COLUMNS
    atlas = Image.new("RGBA", (COLUMNS * CELL_WIDTH, rows * CELL_HEIGHT))
    for variant in range(VARIANTS):
        for length in range(MIN_LENGTH, MAX_LENGTH + 1):
            index = variant * (MAX_LENGTH - MIN_LENGTH + 1) + length - MIN_LENGTH
            atlas.paste(log_sprite(length, variant),
                        (index % COLUMNS * CELL_WIDTH, index // COLUMNS * CELL_HEIGHT))
    path = Path(__file__).resolve().parents[1] / "assets/beam_logs.png"
    atlas.save(path, optimize=True)


if __name__ == "__main__":
    generate()
