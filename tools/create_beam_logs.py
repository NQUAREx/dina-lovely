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
    ("#302634", "#48323b", "#60424a", "#785353", "#916757", "#aa8067"),
    ("#322937", "#45343e", "#62484a", "#795751", "#926d5d", "#a5816e"),
    ("#332936", "#48343c", "#62444b", "#795450", "#956c5c", "#ac836d"),
)


def log_sprite(length, variant):
    palette = PALETTES[variant]
    rng = Random(8321 + variant * 42991 + length * 797)
    shape = Image.new("L", (length, CELL_HEIGHT))
    tip = length - 1
    outline = [(8, 2), (tip-9, 2), (tip-9, 4), (tip-4, 4), (tip-4, 7),
               (tip-1, 7), (tip-1, 11), (tip, 11), (tip, 17), (tip-2, 17),
               (tip-2, 21), (tip-6, 21), (tip-6, 24), (7, 24), (7, 22),
               (3, 22), (3, 18), (0, 18), (0, 10), (2, 10), (2, 6), (5, 6), (5, 4), (8, 4)]
    ImageDraw.Draw(shape).polygon(outline, fill=255)
    bark = Image.new("RGBA", shape.size)
    draw = ImageDraw.Draw(bark)
    for y0, y1, shade in [(2, 4, 3), (5, 8, 5), (9, 12, 4), (13, 16, 3),
                          (17, 20, 2), (21, 23, 1), (24, 25, 0)]:
        draw.rectangle((0, y0, tip, y1), fill=palette[shade])

    # Broad broken ridges follow the bark length. Smaller flecks are sparse
    # so the bark reads in the same pixel clusters as the room's wall art.
    for y, colors in [(5, (3, 4, 5)), (9, (2, 3, 5)), (13, (2, 4, 4)), (18, (0, 1, 3)), (21, (0, 2, 2))]:
        x = rng.randrange(-7, 4)
        while x < length:
            run = rng.randrange(6, 22, 2)
            color = palette[rng.choice(colors)]
            draw.rectangle((x, y, x+run, y+1), fill=color)
            if run > 11:
                draw.rectangle((x+run-5, y+2, x+run+3, y+3), fill=color)
            x += run + rng.randrange(6, 17, 2)

    for x in (length//3 + rng.randint(-5, 6), length*3//4):
        y = rng.randint(10, 15)
        draw.polygon([(x-7,y),(x-3,y-2),(x+3,y-2),(x+8,y),(x+4,y+2),(x-4,y+2)], fill=palette[2])
        draw.rectangle((x-2,y-1,x+3,y), fill=palette[0])
        draw.line((x-3,y+2,x+4,y+2), fill=palette[4], width=2)
        draw.rectangle((x-6,y-4,x+2,y-3), fill=palette[4])

    # Bark folds wrap around both tips, leaving no exposed cross-section.
    for line in [[(5,5),(3,9),(2,14),(4,19),(7,22)],
                 [(tip-7,4),(tip-4,8),(tip-2,13),(tip-4,18),(tip-8,22)]]:
        draw.line(line, fill=palette[2], width=2)
    draw.line((11,23,tip-9,23), fill=palette[0], width=2)
    bark.putalpha(shape)
    return bark


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
