"""Draw the ten garden species into unused 32×48 atlas cells."""
import json
from pathlib import Path

from PIL import Image, ImageDraw


ASSETS = Path(__file__).resolve().parents[1] / "assets"
CELL = (32, 48)
STEM, LEAF, VEIN, SHADE = "#557e65", "#79a36d", "#a0bb7a", "#3c6658"
# Name, stem tips, foliage shape and flower head. Palettes run from shade to light.
SPECIES = [
    ("tulip", [(11, 21), (21, 15)], "blade", "cup", ("#953f5b", "#d56e83", "#f3a5a0")),
    ("daisy", [(8, 26), (16, 16), (24, 24)], "small", "ray", ("#b5a9b3", "#f0e0ce", "#fff1d4")),
    ("iris", [(12, 13), (23, 22)], "blade", "iris", ("#574880", "#8972b7", "#c7ade0")),
    ("marigold", [(10, 22), (20, 17)], "fern", "ruffle", ("#a66142", "#dc9a4e", "#f3cc70")),
    ("bluebell", [(12, 14), (21, 19)], "small", "bells", ("#4c6390", "#8498cb", "#b8c6ef")),
    ("poppy", [(16, 12), (24, 25)], "fern", "poppy", ("#903d58", "#cd5669", "#ef8790")),
    ("clover", [(7, 29), (16, 23), (25, 28)], "clover", "ruffle", ("#9c5678", "#cb839e", "#eeb8bf")),
    ("lupin", [(10, 21), (19, 10), (25, 24)], "clover", "spike", ("#685489", "#a57dab", "#dab0ca")),
    ("orchid", [(14, 14), (21, 24)], "blade", "orchid", ("#965571", "#d691ae", "#f1cad4")),
    ("forget_me_not", [(7, 26), (15, 19), (24, 21)], "small", "cluster", ("#4c7d88", "#83b0c1", "#bfdad9")),
]


def leaves(draw, shape, x, y, side, length):
    tip = (x + side * length, y - (8 if shape == "blade" else 4))
    if shape == "clover":
        tx, ty = tip
        draw.line((x, y, tx, ty), fill=STEM)
        for bx, by in [(tx - 2, ty), (tx + 2, ty), (tx, ty - 3)]:
            draw.ellipse((bx - 2, by - 1, bx + 2, by + 2), fill=LEAF)
            draw.point((bx, by - 1), fill=VEIN)
        return
    draw.polygon([(x, y + 1), (x + side * 3, y - 4), tip,
                  (x + side * (length - 2), y - 1), (x + side * 3, y + 2)], fill=SHADE)
    draw.line((x, y, *tip), fill=LEAF)
    draw.point(tip, fill=VEIN)
    if shape == "fern":
        for step in (3, 5, 7):
            if step < length:
                draw.line((x + side * step, y - 1, x + side * (step + 1), y - 5), fill=LEAF)


def head(d, shape, x, y, colors):
    dark, mid, light = colors
    if shape == "cup":
        d.polygon([(x-5,y-5),(x-2,y-3),(x,y-6),(x+2,y-3),(x+5,y-5),
                   (x+4,y+2),(x+2,y+4),(x-2,y+4),(x-4,y+2)], fill=dark)
        d.polygon([(x-4,y-4),(x-2,y-2),(x,y-5),(x+3,y-2),(x+4,y-3),
                   (x+2,y+2),(x-2,y+2)], fill=mid)
        d.line((x-1,y-3,x-2,y), fill=light)
    elif shape == "ray":
        for dx,dy in [(-4,-2),(-2,-4),(1,-4),(4,-2),(4,1),(2,3),(-1,4),(-4,2)]:
            d.rectangle((x+dx-1,y+dy-1,x+dx+1,y+dy+1), fill=dark)
            d.line((x+dx,y+dy-1,x,y), fill=mid)
            d.point((x+dx,y+dy-1), fill=light)
        d.ellipse((x-2,y-2,x+2,y+2), fill="#c28849")
        d.line((x-1,y-1,x+1,y-1), fill="#f3c775")
    elif shape == "iris":
        d.polygon([(x-6,y+1),(x-4,y-3),(x-1,y-3),(x,y-7),(x+3,y-5),
                   (x+3,y-2),(x+6,y),(x+4,y+4),(x+1,y+2),(x-2,y+5)], fill=dark)
        d.line((x-5,y,x-2,y-2,x,y,x+1,y-5), fill=mid, width=2)
        d.line((x,y,x+5,y), fill=light)
        d.point((x-1,y+1), fill="#efca83")
    elif shape in ("bells", "spike", "cluster"):
        offsets = {"bells": [(1,0),(4,4),(1,8)], "spike": [(0,-4),(-2,-1),(2,1),(-2,3),(1,5)],
                   "cluster": [(-2,-1),(2,-3),(3,1)]}[shape]
        for dx,dy in offsets:
            bx, by = x+dx, y+dy
            d.ellipse((bx-2,by-2,bx+2,by+2), fill=dark)
            d.rectangle((bx-1,by-2,bx+1,by), fill=mid)
            d.point((bx-1,by-2), fill=light)
            if shape == "cluster":
                d.point((bx,by), fill="#eccda5")
    else:
        if shape == "poppy":
            petals = [(-4,-2),(-1,-4),(3,-3),(5,0),(2,2),(-3,2)]
        elif shape == "orchid":
            petals = [(-4,-1),(0,-5),(4,-1),(-2,2),(2,2),(0,4)]
        else:
            petals = [(-3,-1),(-2,-3),(1,-4),(3,-2),(3,1),(0,3),(-3,2)]
        for dx,dy in petals:
            d.ellipse((x+dx-2,y+dy-2,x+dx+2,y+dy+2), fill=dark)
        for dx,dy in petals:
            d.ellipse((x+dx-1,y+dy-2,x+dx+1,y+dy+1), fill=mid)
            d.line((x+dx-1,y+dy-1,x+dx,y+dy-1), fill=light)
        d.ellipse((x-2,y-1,x+2,y+2), fill="#56384f" if shape == "poppy" else mid)
        d.point((x,y), fill="#eec485" if shape != "poppy" else "#bd8a8b")


def plant(tips, foliage, shape, colors, stage):
    image = Image.new("RGBA", CELL)
    d = ImageDraw.Draw(image)
    for i, (full_x, full_y) in enumerate(tips):
        scale = (0.55, 0.83, 1.0)[stage]
        x = round(16 + (full_x - 16) * scale)
        y = round(42 + (full_y - 42) * scale)
        root = 13 + i * 3
        d.line((root, 43, root, 37, x, y), fill=SHADE, width=2)
        d.line((root + 1, 41, root + 1, 37, x, y), fill=STEM)
        for side, dy in ((-1, 1), (1, -3)):
            leaves(d, foliage, root, 37 + dy, side, 5 + stage)
        if stage == 0:
            leaves(d, foliage, x, y + 4, -1 if i % 2 == 0 else 1, 4)
        elif stage == 1:
            d.ellipse((x-2,y-4,x+2,y+1), fill=colors[0])
            d.line((x-1,y-3,x,y-3), fill=colors[1])
            d.line((x+1,y+1,x+2,y-1), fill=LEAF)
        else:
            head(d, shape, x, y, colors)
    return image


GROWTH_FRAMES = 12
ROOT_Y = 43


def scaled_plant(image, factor):
    region = image.crop((0, 0, CELL[0], ROOT_Y + 1))
    width, height = max(1, round(region.width * factor)), max(1, round(region.height * factor))
    output = Image.new("RGBA", CELL)
    output.paste(region.resize((width, height), Image.Resampling.NEAREST),
                 ((CELL[0] - width) // 2, ROOT_Y + 1 - height))
    return output


def transition(source, target, progress):
    if progress == 1:
        return target
    early = scaled_plant(source, 1 + 0.12 * progress)
    late = scaled_plant(target, 0.80 + 0.20 * progress)
    output = Image.new("RGBA", CELL)
    for y in range(CELL[1]):
        for x in range(CELL[0]):
            # The lower stem fills before the upper leaves and petal tips.
            jitter = ((x * 17 + y * 13) % 11) / 55
            threshold = 0.13 + (ROOT_Y - y) * 0.013 + jitter
            layer = late if progress > threshold else early
            output.putpixel((x, y), layer.getpixel((x, y)))
    return output


def growth_sheet(atlas, ids):
    def tile(name):
        index = ids[name]
        x, y = index % 16 * CELL[0], index // 16 * CELL[1]
        return atlas.crop((x, y, x + CELL[0], y + CELL[1]))

    sheet = Image.new("RGBA", (CELL[0] * 16, CELL[1] * (3 * GROWTH_FRAMES + 1)))
    for species in range(16):
        sprout = tile(f"seedling{species}_plant")
        bloom = tile(f"bloom{species}_plant")
        if species < 6:
            bud = tile(f"flower_bud{species}")
            soil = {(74, 59, 54), (71, 60, 53), (102, 82, 67)}
            for y in range(30, CELL[1]):
                for x in range(CELL[0]):
                    if bud.getpixel((x, y))[:3] in soil:
                        bud.putpixel((x, y), (0, 0, 0, 0))
        else:
            bud = tile(f"flower_bud{species}_plant")
        for n in range(GROWTH_FRAMES):
            progress = (n + 1) / GROWTH_FRAMES
            frames = (scaled_plant(sprout, progress), transition(sprout, bud, progress),
                      transition(bud, bloom, progress))
            for stage, frame in enumerate(frames):
                sheet.paste(frame, (species * CELL[0], (stage * GROWTH_FRAMES + n) * CELL[1]))
        dry = scaled_plant(sprout, 0.69)
        for y in range(CELL[1]):
            for x in range(CELL[0]):
                r, g, b, alpha = dry.getpixel((x, y))
                if alpha:
                    dry.putpixel((x, y), (min(187, g + 15), round(g * 0.73), round(g * 0.48), alpha))
        sheet.paste(dry, (species * CELL[0], 3 * GROWTH_FRAMES * CELL[1]))
    sheet.save(ASSETS / "garden_growth.png")


def main():
    atlas_path = ASSETS / "atlas.png"
    manifest = ASSETS / "atlas.json"
    ids = json.loads(manifest.read_text())
    next_id = max(ids.values()) + 1
    art = []
    for i, (_, *spec) in enumerate(SPECIES, 6):
        for stage, prefix in enumerate(("seedling", "flower_bud", "bloom")):
            key = f"{prefix}{i}_plant"
            if key not in ids:
                ids[key] = next_id
                next_id += 1
            art.append((ids[key], plant(*spec, stage)))
    atlas = Image.open(atlas_path).convert("RGBA")
    height = max(atlas.height, ((max(ids.values()) // 16) + 1) * CELL[1])
    output = Image.new("RGBA", (atlas.width, height))
    output.paste(atlas, (0, 0))
    for index, sprite in art:
        output.paste(sprite, ((index % 16) * CELL[0], (index // 16) * CELL[1]))
    output.save(atlas_path)
    manifest.write_text(json.dumps(ids))
    growth_sheet(output, ids)


if __name__ == "__main__":
    main()
