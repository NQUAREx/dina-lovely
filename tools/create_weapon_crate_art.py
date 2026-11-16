"""Original eight-pose steel case, drawn on the game's native pixel grid.

Two tall pale recessed lids hinge against the sides of a deep dark tray.
Coordinates are authored anew from the reference proportions; no photograph
pixels are extracted. Each leaf always meets the hinge and the tray rim.
"""
from pathlib import Path
from PIL import Image, ImageDraw
A = Path(__file__).resolve().parents[1] / 'assets'


def generate():
    sheet = Image.new('RGBA', (512, 48))
    for frame in range(8):
        t = frame / 7
        im = Image.new('RGBA', (64, 48))
        d = ImageDraw.Draw(im)
        # Low, wide body and its bevelled front; steel uses cool neutral greys.
        d.rectangle((17, 38, 46, 43), fill='#303942')
        d.rectangle((16, 28, 47, 40), fill='#424b55')
        d.rectangle((18, 29, 45, 38), fill='#71777b')
        d.rectangle((19, 30, 20, 37), fill='#4b535b')
        d.rectangle((43, 30, 44, 37), fill='#4b535b')
        d.rectangle((23, 30, 40, 32), fill='#a1a4a3')
        d.rectangle((23, 33, 40, 37), fill='#4b555e')
        d.rectangle((26, 34, 37, 35), fill='#303c47')
        d.line((18, 39, 45, 39), fill='#555e66')
        # Raised rim. The interior has a broad rear plane and deep black well.
        d.rectangle((17, 11, 46, 29), fill='#7d8b96')
        d.rectangle((18, 12, 45, 28), fill='#414a53')
        d.rectangle((19, 14, 44, 27), fill='#242c35')
        d.rectangle((20, 13, 43, 16), fill='#3b454e')
        d.rectangle((19, 17, 44, 26), fill='#202832')
        d.rectangle((25, 17, 38, 18), fill='#424b54')
        d.line((18, 29, 45, 29), fill='#a0a9ae')
        # Hinges connect to the inner edge at every opening pose.
        for side in (-1, 1):
            if side < 0:
                x0 = round(18 - 15*t)
                x1 = round(31 - 13*t)
            else:
                x0 = round(32 + 13*t)
                x1 = round(45 + 15*t)
            top = round(11 - 6*t)
            bottom = round(28 - 3*t)
            d.rectangle((x0, top+1, x1, bottom+1), fill='#46515b')
            d.rectangle((x0, top, x1, bottom-1), fill='#91a8b8')
            # Stepped outer corners and thick machined inner frame.
            d.rectangle((x0+1, top+1, x1-1, bottom-2), fill='#7f919f')
            d.rectangle((x0+3, top+2, x1-3, bottom-4), fill='#4a535c')
            d.rectangle((x0+4, top+4, x1-3, bottom-5), fill='#c2c4c2')
            d.line((x0+4, bottom-4, x1-3, bottom-4), fill='#e1e3de')
            d.line((x0+2, top, x1-1, top), fill='#b3c7d3')
            # A narrow steel return joins the lid to the chest, no floor gap.
            hx = 18 if side < 0 else 45
            d.rectangle((hx, 23, hx+1, 29), fill='#7f8e99')
        if frame == 0:
            d.rectangle((29, 25, 34, 30), fill='#b2b4ac')
            d.rectangle((31, 27, 32, 28), fill='#48515a')
        sheet.alpha_composite(im, (frame*64, 0))
    sheet.save(A / 'iron_weapon_crates.png')


if __name__ == '__main__':
    generate()
