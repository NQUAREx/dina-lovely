"""Build static Pixelify Sans derivatives with a complete Russian alphabet.

The upstream font omits U+041E and U+041F. О shares the Latin O outline.
П uses the existing capital height, side bearings and pixel stroke widths.
The derivative family is named Garden Pixel. See assets/PIXELIFY-OFL.txt.
"""
from pathlib import Path
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont
from fontTools.pens.ttGlyphPen import TTGlyphPen

root = Path(__file__).resolve().parents[1]
for output, weight, style in [("body", 600, "SemiBold"), ("title", 700, "Bold")]:
    font = instantiateVariableFont(TTFont(root / "tools/art_source/PixelifySans.ttf"), {"wght": weight})
    cmap = font.getBestCmap()
    h_name = cmap[ord("H")]
    h = font["glyf"][h_name]
    h.recalcBounds(font["glyf"])
    # Left/right vertical strokes and a top crossbar on the same pixel grid.
    coordinates = h.getCoordinates(font["glyf"])[0]
    inner_left = sorted({x for x, y in coordinates})[1]
    inner_right = sorted({x for x, y in coordinates})[-2]
    stroke = inner_left - h.xMin
    points = [(h.xMin, h.yMin), (h.xMin, h.yMax), (h.xMax, h.yMax),
              (h.xMax, h.yMin), (inner_right, h.yMin), (inner_right, h.yMax - stroke),
              (inner_left, h.yMax - stroke), (inner_left, h.yMin)]
    pen = TTGlyphPen(None)
    pen.moveTo(points[0])
    for point in points[1:]:
        pen.lineTo(point)
    pen.closePath()
    glyph_name = "uni041F"
    font["glyf"][glyph_name] = pen.glyph()
    font["hmtx"][glyph_name] = font["hmtx"][h_name]
    order = font.getGlyphOrder()
    if glyph_name not in order:
        font.setGlyphOrder(order + [glyph_name])
    for table in font["cmap"].tables:
        if table.isUnicode():
            table.cmap[0x041E] = cmap[ord("O")]
            table.cmap[0x041F] = glyph_name
    for record in font["name"].names:
        names = {1: "Garden Pixel", 2: style, 3: f"GardenPixel-{style}-1.0",
                 4: f"Garden Pixel {style}", 6: f"GardenPixel-{style}",
                 16: "Garden Pixel", 17: style}
        if record.nameID in names:
            record.string = names[record.nameID].encode(record.getEncoding())
    assert all(cp in font.getBestCmap() for cp in [0x401, 0x451] + list(range(0x410, 0x450)))
    font.save(root / f"assets/{output}.ttf")
