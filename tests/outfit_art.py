"""Pixel-art contracts: complete frame sets, blank rectangular veil openings and no removed pin."""
import json
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
names = json.loads((root / 'assets/atlas.json').read_text())
content = json.loads((root / 'content/letters.json').read_text())
atlas = Image.open(root / 'assets/atlas.png').convert('RGBA')
items = ['black_dress', 'dark_scarf', 'wreath', 'veil', 'crown', 'rose_scarf', 'peach_dress', 'heart_tiara', 'pink_watch', 'white_scarf', 'white_dress', 'daisy_wreath', 'silver_crown', 'rose_wreath', 'lavender_dress', 'white_veil']

def sprite(name):
    index = names[name]
    return atlas.crop((index % 16 * 32, index // 16 * 48, index % 16 * 32 + 32, index // 16 * 48 + 48))

assert all('brooch' not in name for name in names)
assert 'accessory_brooch' not in content['ui']
assert max(names.values()) // 16 * 48 + 48 <= atlas.height
for item in items:
    assert sprite('accessory_' + item).getbbox()
    assert content['ui']['accessory_' + item]['text']
    for direction in range(4):
        for frame in range(4):
            image = sprite(f'wear_{item}_{direction}_{frame}')
            if direction == 0 and item in ['veil', 'white_veil']:
                assert image.getbbox() is None
            else:
                assert image.getbbox(), (item, direction, frame)
            if item in ['veil', 'white_veil'] and direction != 0:
                assert len({pixel[:3] for pixel in [pixel for _, pixel in image.getcolors(1536)] if pixel[3]}) == 1
                left, right = (13, 23) if direction == 3 else (10, 20) if direction == 1 else (10, 23)
                holes = [(11, 15), (18, 22)] if direction == 2 else [(left + 1, left + 4), (right - 4, right - 1)]
                base = sprite(f'hero{direction}_{frame}')
                for x1, x2 in holes:
                    for y in range(18 + frame % 2, 20 + frame % 2):
                        for x in range(x1, x2 + 1):
                            assert image.getpixel((x, y))[3] == 0
                            assert base.getpixel((x, y))[:3] == (214, 163, 131)
print('PASS 16 icons, 256 aligned outfit frames, plain veils with two skin-only rectangular openings, no brooch')
