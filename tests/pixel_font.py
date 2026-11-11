"""Catch missing Russian letters, case aliases and accidental accented glyphs."""
from pathlib import Path
from fontTools.ttLib import TTFont
root = Path(__file__).resolve().parents[1]
upper = 'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ'
fonts = [TTFont(root / f'assets/{name}.ttf') for name in ['body', 'title']]
for font in fonts:
    cmap = font.getBestCmap()
    for cap, lower in zip(upper, upper.lower()):
        assert ord(cap) in cmap and ord(lower) in cmap
        assert cmap[ord(cap)] != cmap[ord(lower)]
        glyph = font['glyf'][cmap[ord(lower)]]
        glyph.recalcBounds(font['glyf'])
        assert glyph.yMax <= (720 if lower in 'бёй' else 520), lower
    for char in 'КкВв':
        glyph = font['glyf'][cmap[ord(char)]]
        glyph.recalcBounds(font['glyf'])
        assert glyph.yMax <= (720 if char.isupper() else 520) and glyph.yMin == 0
    assert 'GSUB' not in font
for char in upper + upper.lower() + 'abcdefghijklmnopqrstuvwxyz0123456789':
    regular = fonts[0]['glyf'][fonts[0].getBestCmap()[ord(char)]]
    bold = fonts[1]['glyf'][fonts[1].getBestCmap()[ord(char)]]
    regular.recalcBounds(fonts[0]['glyf']); bold.recalcBounds(fonts[1]['glyf'])
    assert bold.xMax > regular.xMax and bold.yMax > regular.yMax
print('PASS complete Russian cases, lowercase heights, clean К/В, separate bold strokes and no case substitutions')
