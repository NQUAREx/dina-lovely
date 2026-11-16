"""Material-specific pixel boundaries on the established 24px footprint.

Renderer keeps roof rows0:34 at2x, side rows34:64 at2x/1.2x. Unchanged
collision footprint, no anti-aliasing, game foliage/soil/masonry palettes.
"""
from pathlib import Path
from PIL import Image,ImageDraw
import random
A=Path(__file__).resolve().parents[1]/'assets'

def foliage(variant,trees=False):
    im=Image.new('RGBA',(32,64));d=ImageDraw.Draw(im);r=random.Random(182+variant)
    # Deep stems and roots disappear beneath a connected canopy.
    d.polygon([(6,30),(25,30),(27,47),(23,53),(7,53),(4,47)],fill='#29483f')
    if trees:
        for x,y in [(10,44),(22,47)]:
            d.rectangle((x-2,y-13,x+2,y+5),fill='#66544e')
            d.line((x-1,y-11,x-1,y+3),fill='#9a7f68')
            d.polygon([(x-2,y),(x-4,y+5),(x+4,y+5),(x+1,y-3)],fill='#66544e')
    else:
        d.rectangle((6,32,25,46),fill='#3c6250')
    # Several overlapping broadleaf crowns read as a thicket, not stone tiles.
    crowns=[(14,17,11),(22,27,8),(8,30,8),(17,35,9)] if trees else [(9,24,8),(22,23,8),(16,32,11)]
    for cx,cy,rad in crowns:
        cy+=r.choice([-1,0,1]);dark='#274e43' if trees else '#315d49'
        mid='#4d795d' if trees else '#58815e';light='#71916a' if trees else '#8fa775'
        points=[(cx-rad+2,cy-rad//2),(cx-rad//2,cy-rad),(cx+2,cy-rad),
                (cx+rad-2,cy-rad//2),(cx+rad,cy+2),(cx+rad-3,cy+rad-2),
                (cx,cy+rad),(cx-rad+1,cy+rad//2)]
        d.polygon(points,fill=dark)
        d.polygon([(x,y-2) for x,y in points[0:6]]+[(cx-3,cy+rad-3),(cx-rad+2,cy+2)],fill=mid)
        d.line([(cx-rad+3,cy-2),(cx-rad+3,cy-rad//2),(cx-rad//2,cy-rad+2),(cx,cy-rad+2)],fill=light,width=1)
        for i in range(4):
            x=cx+r.randint(-rad//2,rad//2);y=cy+r.randint(-rad//2,rad//2)
            d.line((x,y,x+1,y),fill=r.choice([light,mid,dark]))
    return im

def earth(variant):
    im=Image.new('RGBA',(32,64));d=ImageDraw.Draw(im);r=random.Random(572+variant)
    # Rounded eroded bank, with sloping sides and exposed sediment strata.
    d.polygon([(6,30),(25,29),(29,43),(27,51),(22,54),(7,54),(3,49),(3,41)],fill='#574c50')
    d.polygon([(6,27),(24,27),(27,39),(24,49),(7,50),(4,44)],fill='#7d695e')
    d.polygon([(7,20),(12,12),(20,13),(26,24),(28,34),(24,40),(8,40),(3,34)],fill='#8f7966')
    d.polygon([(7,20),(12,12),(20,13),(24,21),(22,31),(15,35),(6,32)],fill='#a48d73')
    d.line([(5,34),(10,37),(19,37),(25,33)],fill='#bc9e7c')
    d.line([(5,43),(12,45),(22,44),(26,40)],fill='#665751')
    d.line([(8,48),(17,49),(23,47)],fill='#9b8069')
    d.line([(14,16),(12,21),(15,25),(13,29)],fill='#8f7966')
    for n in range(18):
        x=r.randrange(7,25);y=r.randrange(22,49)
        if im.getpixel((x,y))[3]:d.line((x,y,x+1,y),fill=r.choice(['#b29a7d','#776359','#967c67']))
    for x,y in [(9+variant%2*3,30),(23,40),(11,46)]:
        d.polygon([(x,y),(x+2,y-1),(x+3,y+1),(x+1,y+2)],fill='#8b8a83')
        d.point((x+1,y),fill='#c0b3a0')
    return im

def fence(variant):
    im=Image.new('RGBA',(32,64));d=ImageDraw.Draw(im)
    # Dressed cubic garden blocks: clean large faces instead of brick courses.
    d.polygon([(4,28),(27,28),(27,50),(24,54),(7,54),(4,51)],fill='#636572')
    d.polygon([(6,29),(24,29),(24,51),(7,51),(6,49)],fill='#949697')
    d.line((7,48,23,48),fill='#b1b1aa')
    d.line((15,35,15,48),fill='#777b80')
    d.line((16,35,16,47),fill='#b1b1aa')
    roof=[(7,11),(24,11),(27,14),(27,31),(24,34),(7,34),(4,31),(4,14)]
    d.polygon(roof,fill='#a7aaa3')
    d.polygon([(4,14),(7,11),(7,31),(9,34),(7,34),(4,31)],fill='#c2c4b5')
    d.polygon([(24,11),(27,14),(27,31),(24,34),(22,34),(24,31)],fill='#737d7c')
    d.line([(7,12),(23,12)],fill='#d2cebc')
    d.line([(8,31),(23,31),(25,29)],fill='#838f85')
    # Recessed square cap detailing makes an unmistakable garden fence.
    d.rectangle((10,16,21,27),outline='#8a958c')
    d.line((11,17,20,17),fill='#bfc0ac')
    d.line((11,18,11,25),fill='#bfc0ac')
    for x,y in [(9+variant,29),(21,14),(6,42)]:d.line((x,y,x+1,y),fill='#849475')
    return im

for room in range(7):
    for variant,suffix in enumerate(['','1','2','3']):
        for kind in ['exposed','stacked']:
            if room==0:im=foliage(variant)
            elif room==1:im=foliage(variant,True)
            elif room==3:im=earth(variant)
            elif room==5:im=fence(variant)
            else:im=Image.open(A/f'wall_{kind}{suffix}.png').convert('RGBA')
            im.save(A/f'wall_room{room}_{kind}{suffix}.png')
print('Generated bushes, tree thickets, earth banks and dressed garden fence; other masonry unchanged')

if __name__=='__main__':
    sheet=Image.new('RGBA',(7*112,160),'#242538')
    for room in range(7):
        tile=Image.open(A/f'wall_room{room}_exposed.png')
        projected=Image.new('RGBA',(64,104))
        projected.alpha_composite(tile.crop((0,0,32,34)).resize((64,68),Image.Resampling.NEAREST))
        projected.alpha_composite(tile.crop((0,34,32,64)).resize((64,36),Image.Resampling.NEAREST),(0,68))
        sheet.alpha_composite(projected,(room*112+24,24))
        ImageDraw.Draw(sheet).text((room*112+44,136),str(room),fill='#e4d0bd')
    sheet.save('/tmp/room-materials.png')
