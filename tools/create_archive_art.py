"""Original archive box, layered paper and navigation icons for the letter pile."""
from pathlib import Path
from PIL import Image, ImageDraw
import json

root = Path(__file__).resolve().parents[1]
assets = root / "assets"
art = {}
for opened in [False, True]:
    image = Image.new("RGBA", (32, 48))
    d = ImageDraw.Draw(image)
    d.ellipse((2, 39, 30, 46), fill="#282b3b")
    d.polygon([(2, 27), (27, 24), (31, 29), (28, 43), (5, 44), (1, 38)], fill="#563d44")
    d.rectangle((4, 29, 27, 41), fill="#a77859")
    d.line((5, 30, 26, 30), fill="#ddb789")
    d.line((5, 36, 26, 36), fill="#7e5149")
    d.line((5, 37, 26, 37), fill="#c5956d")
    d.polygon([(27, 29), (30, 27), (29, 40), (27, 43)], fill="#76504b")
    for x in [6, 24]:
        d.rectangle((x, 29, x + 1, 41), fill="#d4ae7c")
        d.point((x, 31), fill="#60505b")
        d.point((x, 39), fill="#60505b")
    d.rectangle((13, 32, 20, 36), fill="#725762")
    d.rectangle((14, 33, 19, 35), fill="#e8d6b7")
    d.line((15, 34, 18, 34), fill="#a58c86")
    if opened:
        d.polygon([(3, 16), (6, 9), (27, 9), (29, 17), (26, 23), (5, 23)], fill="#72524c")
        d.polygon([(6, 16), (8, 12), (25, 12), (26, 17), (24, 20), (7, 20)], fill="#ba8e67")
        d.line((8, 12, 24, 12), fill="#e2be8f")
        d.polygon([(3, 25), (7, 20), (26, 20), (30, 26), (26, 31), (6, 31)], fill="#ddb384")
        d.polygon([(6, 25), (9, 22), (24, 22), (27, 26), (24, 29), (8, 29)], fill="#453844")
        for x, y in [(7, 25), (9, 23), (10, 21)]:
            d.polygon([(x, y), (x + 13, y - 1), (x + 16, y + 3), (x + 2, y + 5)], fill="#b9a7a3")
            d.polygon([(x, y - 1), (x + 13, y - 2), (x + 16, y + 2), (x + 2, y + 3)], fill="#fff1d8")
            d.line((x + 4, y + 1, x + 11, y), fill="#c2b0ae")
        d.line((5, 31, 26, 31), fill="#f0cc96")
    else:
        d.polygon([(2, 26), (7, 20), (25, 20), (30, 26), (27, 30), (4, 30)], fill="#c49a70")
        d.line((4, 26, 8, 22, 24, 22, 28, 26), fill="#f0ce9a")
        d.line((5, 28, 26, 28), fill="#7e5350")
        d.polygon([(9, 26), (15, 24), (20, 26), (17, 29), (11, 29)], fill="#fff0d8")
        d.line((11, 27, 16, 26), fill="#bc9e9f")
    art["letter_box_open" if opened else "letter_box"] = image

atlas = Image.open(assets / "atlas.png").convert("RGBA")
ids = json.loads((assets / "atlas.json").read_text())
for name, image in art.items():
    if name not in ids:
        ids[name] = max(ids.values()) + 1
    n = ids[name]
    height = (n // 16 + 1) * 48
    if height > atlas.height:
        expanded = Image.new("RGBA", (512, height))
        expanded.paste(atlas, (0, 0))
        atlas = expanded
    atlas.paste(image, (n % 16 * 32, n // 16 * 48))
atlas.save(assets / "atlas.png")
(assets / "atlas.json").write_text(json.dumps(ids))

for variant in range(3):
    paper = Image.new("RGBA", (160, 104))
    d = ImageDraw.Draw(paper)
    d.polygon([(3, 6), (156, 4), (159, 100), (6, 103), (1, 100)], fill="#5c495d")
    d.polygon([(1, 3), (152, 0), (158, 5), (158, 98), (4, 100), (0, 96)], fill="#e3cdb6")
    d.polygon([(2, 3), (151, 1), (157, 5), (156, 95), (5, 98), (1, 95)], fill=["#fff3dd", "#fff7e8", "#f6ecd9"][variant])
    d.line((7, 9, 148, 7), fill="#e5cdbc")
    d.line((6, 33, 150, 31), fill="#ddc7b6")
    for i, y in enumerate(range(43, 90, 10)):
        d.line((13, y, 136 - ((variant * 11 + i * 17) % 32), y - 1), fill="#d4c4b7")
    d.polygon([(149, 1), (157, 6), (149, 9)], fill="#bca5a1")
    d.polygon([(149, 1), (155, 5), (150, 6)], fill="#fffdf3")
    for x, y in [(10, 94), (145, 91), (5, 21)]:
        d.point((x, y), fill="#ceb5aa")
    paper.save(assets / f"archive_sheet_{variant}.png")

for down in [False, True]:
    image = Image.new("RGBA", (24, 24))
    d = ImageDraw.Draw(image)
    points = [(4, 14), (12, 6), (20, 14), (16, 18), (12, 14), (8, 18)]
    if down:
        points = [(x, 24 - y) for x, y in points]
    d.polygon([(x, y + 2) for x, y in points], fill="#342c42")
    d.polygon(points, fill="#ffead0")
    image.save(assets / ("archive_down.png" if down else "archive_up.png"))
