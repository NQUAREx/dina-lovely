"""Draw the garden quest sprites at the game's two-screen-pixel scale."""

import random
from pathlib import Path

from PIL import Image, ImageDraw


ASSETS = Path(__file__).resolve().parents[1] / "assets"
CELL = 64
COLUMNS = 8

SOIL_RIM = "#765d50"
SOIL = "#544746"
SOIL_SHADE = "#403c43"
GREEN_EDGE = "#244b45"
GREEN_SHADE = "#365c4c"
GREEN_MID = "#497454"
GREEN_TOP = "#5b8964"
GREEN_LIGHT = "#7ca06c"
GREEN_TIP = "#a1b778"
WOOD_EDGE = "#47383d"
WOOD_SHADE = "#664b45"
WOOD_MID = "#886351"
WOOD_TOP = "#af8762"
WOOD_LIGHT = "#cfab7b"
WICKER_EDGE = "#594349"
WICKER_DARK = "#84604b"
WICKER_MID = "#ad805a"
WICKER_LIT = "#d1a676"
WICKER_HIGHLIGHT = "#e7c58d"


def canvas():
    sprite = Image.new("RGBA", (CELL, CELL))
    return sprite, ImageDraw.Draw(sprite)


def shape(draw, points, color, x=0, y=0):
    draw.polygon([(x + px, y + py) for px, py in points], fill=color)


def grass_pile(variant):
    sprite, d = canvas()
    shapes = [
        [(23, 51), (26, 48), (30, 48), (31, 45), (34, 46), (39, 49), (41, 51), (38, 54), (28, 55)],
        [(23, 53), (25, 53), (28, 50), (31, 50), (36, 47), (40, 48), (41, 51), (36, 53), (27, 56)],
        [(25, 53), (26, 49), (28, 48), (29, 44), (32, 42), (35, 44), (36, 48), (40, 50), (40, 53), (35, 56), (28, 56)],
        [(23, 52), (26, 48), (31, 46), (34, 50), (37, 48), (40, 50), (41, 52), (36, 55), (25, 54)],
        [(23, 53), (24, 51), (27, 49), (31, 51), (34, 49), (38, 50), (41, 52), (40, 54), (28, 55)],
        [(24, 52), (25, 48), (29, 47), (32, 45), (36, 45), (38, 48), (41, 52), (36, 55), (28, 55)],
    ]
    base, body, light, straw = [
        ("#334c39", "#697646", "#94a060", "#b6b276"),
        ("#404e32", "#7c8049", "#a6a269", "#c3b884"),
        ("#35483b", "#56764e", "#829e61", "#a3b17b"),
        ("#414d39", "#738553", "#a5a873", "#cab888"),
        ("#3c483b", "#617650", "#89a566", "#b2bd87"),
        ("#394a31", "#7c8954", "#a6ad6f", "#c6bc82"),
    ][variant]
    d.polygon(shapes[variant], fill=base)
    d.polygon([(x, y - (1 if y >= 51 else 0)) for x, y in shapes[variant][1:-1]], fill=body)
    rng = random.Random(1507 + variant)
    for _ in range(22):
        x, y = rng.randint(24, 40), rng.randint(45, 54)
        if sprite.getpixel((x, y))[3] and sprite.getpixel((x + 1, y - 1))[3]:
            color = rng.choices([base, light, straw], weights=[4, 4, 1])[0]
            d.line((x, y, x + 1, y - 1), fill=color)
    # Strands thrown across the heap make the cuttings distinct from lawn grass.
    strands = [
        [(24, 49, 30, 51), (33, 48, 38, 51), (29, 52, 34, 51)],
        [(28, 52, 34, 47), (31, 49, 37, 50), (35, 52, 39, 53)],
        [(27, 50, 31, 47), (30, 46, 36, 49), (32, 52, 37, 51)],
        [(25, 52, 30, 50), (30, 51, 36, 48), (33, 53, 37, 52)],
        [(24, 49, 30, 52), (29, 49, 35, 49), (34, 51, 40, 52)],
        [(27, 52, 32, 49), (33, 46, 35, 48), (35, 50, 39, 51)],
    ][variant]
    for index, strand in enumerate(strands):
        d.line(strand, fill=straw if index == 1 else light)
    return sprite


def leaf(d, x, y, direction, color, light=None):
    shape(d, [(0, 0), (direction, -2), (direction * 4, -3),
              (direction * 3, -1), (direction, 1)], color, x, y)
    if light:
        d.point((x + direction * 2, y - 2), fill=light)


def foliage_lobe(d, x, y, radius_x, radius_y, palette):
    edge, shade, mid, top, highlight = palette
    w, h = radius_x, radius_y
    shape(d, [(-w, 2), (-w, -1), (-w + 1, -2), (-w + 2, -h + 1),
              (-w + 4, -h + 1), (-w + 5, -h), (w - 4, -h),
              (w - 3, -h + 1), (w - 1, -h + 2), (w - 1, -2),
              (w, -1), (w, 2), (w - 1, 3), (w - 1, h - 1),
              (w - 3, h - 1), (w - 4, h), (-w + 4, h),
              (-w + 3, h - 1), (-w + 1, h - 2), (-w + 1, 3)], edge, x, y)
    shape(d, [(-w + 1, -1), (-w + 2, -3), (-w + 4, -h + 1),
              (w - 4, -h + 1), (w - 2, -h + 2), (w - 1, 0),
              (w - 2, 3), (w - 4, h - 1), (-w + 4, h - 1),
              (-w + 2, h - 2)], shade, x, y)
    shape(d, [(-w + 2, -1), (-w + 3, -3), (-w + 5, -h + 1),
              (w - 4, -h + 1), (w - 2, -2), (w - 2, 1),
              (w - 4, 3), (1, h - 2), (-w + 3, h - 2)], mid, x, y)
    shape(d, [(-w + 3, -2), (-w + 4, -3), (-w + 6, -h + 1),
              (w - 4, -h + 1), (w - 3, -2), (w - 5, 0),
              (1, 1), (-w + 3, 1)], top, x, y)
    d.line((x - w + 5, y - h + 1, x - w + 8, y - h + 1), fill=highlight)
    d.point((x - w + 4, y - h + 2), fill=highlight)


def berry(d, x, y, style, small=False):
    dark, medium, highlight = {
        "ripe": ("#863e5b", "#d86388", "#ffb5b0"),
        "unripe": ("#45694a", "#a0a85f", "#c6c17a"),
    }[style]
    if small:
        d.point((x, y + 1), fill=dark)
        d.point((x + 1, y), fill=dark)
        d.point((x, y), fill=highlight)
    else:
        shape(d, [(-1, -1), (1, -1), (2, 0), (2, 1), (1, 2), (-1, 2), (-2, 1), (-2, 0)], dark, x, y)
        d.rectangle((x - 1, y - 1, x + 1, y + 1), fill=medium)
        d.point((x - 1, y), fill=highlight)


def bush(variant, stage):
    sprite, d = canvas()
    rng = random.Random(713 + variant)
    is_wild, wet = stage == "wild", stage == "watered"
    d.ellipse((19, 49, 45, 56), fill=SOIL_SHADE if wet else SOIL)
    d.ellipse((20, 49, 44, 54), fill="#4b605d" if wet else SOIL_RIM)
    d.ellipse((21, 51, 43, 55), fill="#404c49" if wet else SOIL)
    d.line((22, 54, 28, 54), fill="#6f8d82" if wet else "#796454")
    for x, y in [(23, 52), (41, 54), (28, 55), (36, 53), (43, 51)]:
        d.point((x, y), fill="#82938a" if wet else "#ab8e70")
    # A dark rooted trunk stays in the same place while the canopy changes.
    d.line((32, 54, 31, 42, 27, 38), fill=WOOD_EDGE, width=3)
    d.line((32, 53, 32, 44, 38, 40), fill=WOOD_SHADE, width=2)
    d.line((31, 51, 31, 45, 29, 43), fill=WOOD_TOP)
    if is_wild:
        shoots = [
            [(19, 43), (17, 38), (20, 34), (17, 29)],
            [(39, 42), (46, 38), (48, 33), (46, 26)],
            [(30, 34), (32, 24), (29, 19), (31, 14)],
            [(37, 36), (41, 28), (45, 22)],
        ]
        for index, shoot in enumerate(shoots):
            if variant % 2 == index % 2 or index == 2:
                d.line(shoot, fill=GREEN_EDGE, width=2)
                d.line(shoot, fill="#688159")
                for x, y in shoot[1:]:
                    direction = 1 if x < 22 else -1 if x > 44 else rng.choice([-1, 1])
                    leaf(d, x, y, direction, "#6b8e5b", "#96a668")
        lobes = [
            [(23, 41, 7, 6), (39, 43, 9, 6), (28, 34, 10, 8), (33, 42, 10, 7), (25, 28, 7, 7)],
            [(23, 42, 7, 6), (40, 37, 9, 9), (31, 31, 8, 8), (33, 43, 10, 7), (40, 27, 7, 6)],
            [(22, 38, 7, 7), (40, 43, 8, 6), (28, 30, 7, 10), (31, 43, 10, 7), (37, 37, 7, 8)],
            [(24, 43, 7, 6), (40, 42, 8, 7), (31, 31, 8, 9), (33, 42, 9, 7), (40, 30, 8, 7)],
        ][variant]
        palette = (GREEN_EDGE, "#3a5f46", "#52764f", "#668a58", "#8a9f63")
    else:
        lobes = [
            (23, 43 - (variant == 1), 7, 6), (41, 43 - (variant == 2), 7, 6),
            (32, 36 - variant % 2, 11 + (variant != 3), 8 - (variant == 3)),
            (32, 43, 11, 7),
        ]
        palette = (GREEN_EDGE, GREEN_SHADE, GREEN_MID, GREEN_TOP, GREEN_LIGHT)
    for x, y, w, h in lobes:
        foliage_lobe(d, x, y, w, h, palette)
    for x, y in [(23, 41), (40, 41), (29, 33), (34, 38), (28, 44), (39, 45)]:
        x += rng.choice([-1, 0, 1])
        y += rng.choice([-1, 0, 1])
        leaf(d, x, y, rng.choice([-1, 1]), GREEN_TOP if is_wild else GREEN_LIGHT, GREEN_TIP)
    if is_wild:
        # Some stems hang below the lobes; they disappear after pruning.
        for index, x in enumerate([21, 28, 40]):
            direction = 1 if index == 2 else -1
            d.line((x + 1, 46, x + direction, 49, x, 53), fill="#5f8051", width=1)
            leaf(d, x, 51, direction, "#7c925e")
    if wet:
        for x, y in [(24, 42), (35, 34), (40, 41), (32, 46), (44, 48)]:
            d.line((x, y + 1, x + 1, y + 1), fill="#4f857b")
            d.point((x, y), fill="#a5c8bc")
    if stage in ["ripe", "picked"]:
        clusters = [
            [(22, 42), (31, 34), (40, 41), (33, 45)],
            [(24, 40), (36, 35), (43, 43), (30, 45)],
            [(21, 44), (29, 33), (39, 38), (38, 46)],
            [(25, 38), (33, 33), (42, 42), (27, 46)],
        ][variant]
        for index, (x, y) in enumerate(clusters):
            d.line((x + 1, y - 3, x, y - 1), fill="#a4aa76")
            if stage == "ripe":
                berry(d, x, y, "ripe")
                berry(d, x + (-3 if index % 2 else 3), y + 2, "ripe", small=True)
            elif index % 2 == 0:
                berry(d, x, y, "unripe", small=True)
            else:
                d.point((x, y - 1), fill="#bd9874")
    bounds = sprite.getbbox()
    assert bounds[2] - bounds[0] <= 34, (variant, stage, bounds)
    return sprite


def shears(on_ground, opened=False):
    sprite, d = canvas()
    if opened:
        shape(d, [(31, 48), (33, 44), (41, 40), (43, 40), (40, 44),
                  (34, 48)], "#424951")
        d.line((33, 46, 41, 41), fill="#b2bec0", width=2)
        d.line((37, 43, 41, 41), fill="#e0dfd6")
        shape(d, [(32, 47), (35, 49), (43, 54), (41, 54), (35, 52),
                  (32, 50)], "#424951")
        d.line((34, 49, 41, 53), fill="#9ca9ac", width=2)
        d.line((37, 51, 41, 53), fill="#c2cac3")
    else:
        shape(d, [(31, 47), (34, 45), (42, 46), (43, 47), (39, 49),
                  (34, 50), (31, 50)], "#424951")
        shape(d, [(31, 47), (34, 46), (42, 46), (40, 47), (34, 48), (31, 49)], "#b2bec0")
        d.line((35, 46, 41, 46), fill="#e0dfd6")
        d.line((35, 49, 39, 48), fill="#798a92")
    # Hinge rivet and wrapped grips share a hand anchor across both poses.
    shape(d, [(31, 46), (26, 44), (23, 45), (23, 47), (27, 48), (31, 48)], WOOD_EDGE)
    shape(d, [(31, 48), (27, 48), (23, 49), (23, 52), (26, 53), (31, 51)], WOOD_EDGE)
    d.line((24, 46, 26, 45, 29, 46, 31, 47), fill="#b98b68")
    d.line((24, 50, 24, 51, 26, 52, 29, 51), fill="#a67860")
    d.point((25, 46), fill="#e0b28a")
    d.point((25, 50), fill="#d4a681")
    d.rectangle((30, 47, 33, 49), fill="#a3a9a8")
    d.point((32, 47), fill="#e3d5b1")
    d.point((32, 49), fill="#5e6468")
    if on_ground:
        piece = sprite.crop(sprite.getbbox()).rotate(36, resample=Image.Resampling.NEAREST, expand=True)
        sprite = Image.new("RGBA", (CELL, CELL))
        sprite.paste(piece, (32 - piece.width // 2, 55 - piece.height))
    return sprite


def basket(d, x, y, fill, small=False):
    """The basket rim is at y=0 and the grip at y=-6."""
    w = 6 if small else 7
    height = 5 if small else 7
    handle = [(x - w + 2, y), (x - w + 2, y - 3), (x - 3, y - 6),
              (x + 3, y - 6), (x + w - 2, y - 3), (x + w - 2, y)]
    d.line(handle, fill=WICKER_EDGE, width=2)
    d.line([(hx, hy - 1) for hx, hy in handle], fill=WICKER_LIT)
    d.line((x - 3, y - 7, x + 1, y - 7), fill=WICKER_HIGHLIGHT)
    shape(d, [(-w, -1), (-w + 2, -3), (w - 2, -3), (w, -1),
              (w, 2), (w - 2, height - 1), (w - 4, height),
              (-w + 4, height), (-w + 2, height - 1), (-w, 2)], WICKER_EDGE, x, y)
    shape(d, [(-w + 1, 1), (w - 1, 1), (w - 2, 4), (w - 4, height - 1),
              (-w + 4, height - 1), (-w + 2, 4)], WICKER_MID, x, y)
    d.line((x - w + 2, y + 4, x + w - 3, y + 4), fill=WICKER_DARK)
    if not small:
        d.line((x - 3, y + 5, x + 3, y + 5), fill=WICKER_LIT)
    d.ellipse((x - w + 1, y - 2, x + w - 1, y + 2), fill="#6b4b42")
    d.line((x - w + 3, y, x + w - 3, y), fill="#ac7955")
    if fill:
        berries = [(-3, -1), (0, -2), (3, -1)]
        if fill == 2:
            berries = [(-4, -2), (-2, -4), (1, -4), (4, -2), (-1, -1), (2, -1)]
        for bx, by in berries:
            berry(d, x + bx, y + by, "ripe", small=small)
    d.line((x - w + 1, y + 2, x + w - 1, y + 2), fill=WICKER_LIT)
    d.line((x - w + 2, y + 2, x - 1, y + 2), fill=WICKER_HIGHLIGHT)
    for offset, dy in [(-4, 3), (-2, 4), (0, 3), (2, 4), (4, 3)]:
        d.point((x + offset, y + dy), fill=WICKER_HIGHLIGHT if offset < 2 else WICKER_DARK)


def basket_sprite(fill, on_ground):
    sprite, d = canvas()
    basket(d, 32, 47 if on_ground else 45, fill)
    return sprite


def display_table(delivered):
    sprite, d = canvas()
    # Back legs and a stretcher beneath the top.
    for x in (12, 46):
        d.rectangle((x, 35, x + 4, 46), fill=WOOD_EDGE)
        d.line((x + 1, 36, x + 1, 45), fill=WOOD_SHADE)
    d.rectangle((15, 46, 48, 50), fill=WOOD_EDGE)
    d.line((17, 47, 46, 47), fill=WOOD_TOP)
    d.line((20, 48, 29, 48), fill=WOOD_MID)
    # Joinery and the front legs terminate at the ground anchor.
    for x in (13, 45):
        shape(d, [(0, 0), (6, 0), (6, 12), (4, 14), (0, 14)], WOOD_EDGE, x, 41)
        d.rectangle((x + 1, 42, x + 4, 53), fill=WOOD_MID)
        d.line((x + 1, 43, x + 1, 52), fill=WOOD_TOP)
    shape(d, [(7, 32), (11, 28), (52, 28), (57, 32), (57, 42), (54, 45),
              (9, 45), (7, 43)], WOOD_EDGE)
    shape(d, [(9, 33), (12, 29), (51, 29), (55, 33),
              (55, 38), (9, 38)], WOOD_TOP)
    d.rectangle((9, 39, 55, 42), fill=WOOD_MID)
    d.line((10, 39, 54, 39), fill=WOOD_LIGHT)
    d.line((10, 42, 54, 42), fill=WOOD_SHADE)
    d.line((14, 30, 49, 30), fill=WOOD_LIGHT)
    d.line((11, 36, 53, 36), fill="#765546")
    d.line((13, 34, 21, 34), fill="#d0a578")
    d.line((43, 34, 51, 34), fill="#946c51")
    # Folded runner visible both before and after delivery, with brass tacks.
    shape(d, [(12, 32), (14, 29), (50, 29), (53, 32), (50, 37), (13, 37)], "#5f555e")
    shape(d, [(14, 32), (16, 30), (49, 30), (51, 32), (49, 35), (15, 35)], "#8a6e78")
    d.line((15, 32, 50, 32), fill="#b38b91")
    d.line((15, 35, 48, 35), fill="#ac8a8c")
    d.point((11, 40), fill="#dfba81")
    d.point((53, 40), fill="#dfba81")
    d.rectangle((28, 40, 35, 41), fill=WOOD_EDGE)
    d.line((30, 40, 33, 40), fill="#e4ba79")
    # Numbered spaces are shown by three stitched diamonds, then real baskets.
    for index, x in enumerate((17, 32, 47)):
        if index < delivered:
            basket(d, x, 29, 2, small=True)
        else:
            d.point((x, 33), fill="#d8ad99")
            d.point((x + 1, 34), fill="#bd9496")
            d.point((x - 1, 34), fill="#bd9496")
            d.point((x, 35), fill="#664f61")
    return sprite


def main():
    sprites = {variant: grass_pile(variant) for variant in range(6)}
    for first, stage in [(8, "wild"), (16, "pruned"), (24, "watered"),
                         (32, "ripe"), (36, "picked")]:
        for variant in range(4):
            sprites[first + variant] = bush(variant, stage)
    sprites[40] = shears(on_ground=True)
    sprites[41] = shears(on_ground=False)
    for fill in range(3):
        sprites[42 + fill] = basket_sprite(fill, on_ground=False)
        sprites[45 + fill] = basket_sprite(fill, on_ground=True)
    for delivered in range(4):
        sprites[48 + delivered] = display_table(delivered)
    sprites[52] = shears(on_ground=False, opened=True)
    rows = max(sprites) // COLUMNS + 1
    atlas = Image.new("RGBA", (CELL * COLUMNS, CELL * rows))
    for index, sprite in sprites.items():
        atlas.paste(sprite, (index % COLUMNS * CELL, index // COLUMNS * CELL))
    atlas.save(ASSETS / "garden_quest.png")


if __name__ == "__main__":
    main()
