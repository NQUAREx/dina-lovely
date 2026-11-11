"""Build two readable Garden Pixel faces with independently drawn alphabets.

Russian capitals and lowercase, Latin and digits come from pixel_alphabet.py.
Pixelify Sans provides punctuation and remaining symbols under the OFL.
"""
from pathlib import Path
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont
from fontTools.pens.ttGlyphPen import TTGlyphPen
from pixel_alphabet import PATTERNS, DESCENDERS

root = Path(__file__).resolve().parents[1]
for output, weight, style, thick_x, thick_y in [
    ("body", 600, "Medium", 12, 8), ("title", 700, "Bold", 32, 18)
]:
    font = instantiateVariableFont(TTFont(root / "tools/art_source/PixelifySans.ttf"), {"wght": weight})
    cmap = font.getBestCmap()
    order = list(font.getGlyphOrder())
    for char, rows in PATTERNS.items():
        width = len(rows[0])
        assert all(len(row) == width for row in rows), char
        pen = TTGlyphPen(None)
        # Merge touching cells into horizontal runs so bold strokes have no seams.
        for row, pixels in enumerate(rows):
            col = 0
            while col < width:
                if pixels[col] == '0':
                    col += 1
                    continue
                start = col
                while col < width and pixels[col] == '1':
                    col += 1
                left, right = 45 + start * 90, 45 + col * 90 + thick_x
                bottom = (len(rows) - row - 1) * 100 - DESCENDERS.get(char, 0)
                top = bottom + 100 + thick_y
                pen.moveTo((left, bottom))
                pen.lineTo((left, top))
                pen.lineTo((right, top))
                pen.lineTo((right, bottom))
                pen.closePath()
        name = f"garden_{ord(char):04X}"
        font['glyf'][name] = pen.glyph()
        font['hmtx'][name] = ((width + 1) * 90 + thick_x, 45)
        order.append(name)
        for table in font['cmap'].tables:
            if table.isUnicode():
                table.cmap[ord(char)] = name
    font.setGlyphOrder(order)
    for tag in ['GSUB', 'GPOS', 'kern']:
        if tag in font:
            del font[tag]
    font['hhea'].ascent = 950
    font['hhea'].descent = -250
    font['hhea'].lineGap = 0
    font['OS/2'].sTypoAscender = 950
    font['OS/2'].sTypoDescender = -250
    font['OS/2'].sTypoLineGap = 0
    font['OS/2'].usWinAscent = 950
    font['OS/2'].usWinDescent = 250
    font['OS/2'].sxHeight = 500 + thick_y
    font['OS/2'].sCapHeight = 700 + thick_y
    font['OS/2'].usWeightClass = weight
    for record in font['name'].names:
        names = {1: 'Garden Pixel', 2: style, 3: f'GardenPixel-{style}-2.0',
                 4: f'Garden Pixel {style}', 6: f'GardenPixel-{style}',
                 16: 'Garden Pixel', 17: style}
        if record.nameID in names:
            record.string = names[record.nameID].encode(record.getEncoding())
    font.save(root / f'assets/{output}.ttf')
