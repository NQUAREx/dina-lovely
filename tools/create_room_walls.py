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

def thicket(variant):
    im=Image.new('RGBA',(32,64));d=ImageDraw.Draw(im);r=random.Random(19103+variant*137)
    # Stable roots close the boundary; varied crowns and trunk positions keep
    # the visible silhouette irregular without changing its collision anchor.
    d.polygon([(5,35),(25,33),(28,43),(24,48),(20,46),(16,53),(12,49),(8,52),(3,44)],fill='#203d35')
    trunks=[(r.randint(8,13),r.randint(42,47)),(r.randint(20,24),r.randint(43,48))]
    for x,y in trunks:
        d.rectangle((x-2,y-15,x+1,y+4),fill='#51483f')
        d.line((x-1,y-12,x-1,y+2),fill='#796650')
        d.polygon([(x-2,y),(x-5,y+5),(x+3,y+5),(x+1,y-4)],fill='#51483f')
    crowns=[]
    # Each variant has its own main mass and irregular satellite lobes.
    crowns.append((r.randint(12,19),r.randint(15,23),r.randint(9,12),r.randint(9,14)))
    for n in range(r.randint(3,5)):
        crowns.append((r.randint(7,25),r.randint(25,39),r.randint(5,9),r.randint(6,10)))
    for cx,cy,rx,ry in crowns:
        pts=[(cx-rx,cy),(cx-rx+2,cy-ry//2),(cx-rx//2,cy-ry),
             (cx+rx//3,cy-ry),(cx+rx-1,cy-ry//2),(cx+rx,cy+2),
             (cx+rx//2,cy+ry-1),(cx-2,cy+ry),(cx-rx+1,cy+ry//2)]
        d.polygon(pts,fill='#193c32')
        d.polygon([(x,y-2) for x,y in pts[:-2]]+[(cx-3,cy+ry-3),(cx-rx+2,cy+2)],fill='#315744')
        d.line([(cx-rx+2,cy-2),(cx-rx+2,cy-ry//2),(cx-rx//2,cy-ry+2),(cx,cy-ry+2)],fill='#57745a')
        for n in range(5):
            x=cx+r.randint(-rx//2,rx//2);y=cy+r.randint(-ry//2,ry//2)
            d.line((x,y,x+1,y),fill=r.choice(['#254c3c','#3f634b','#57745a']))
    # Irregular rooted forest floor; no continuous flat green hem.
    for cx,cy in [(5,43),(12,48),(21,46),(26,41)]:
        cy+=r.randint(-3,3)
        d.polygon([(cx-4,cy),(cx-3,cy-4),(cx,cy-6),(cx+4,cy-3),(cx+5,cy+1),(cx+1,cy+4)],fill='#254b3a')
        d.line((cx-2,cy-3,cx+1,cy-4),fill='#487354')
    return im

def earth(variant):
    from create_earth_blocks import earth_block
    return earth_block(variant)

def fence(variant):
    im=Image.new('RGBA',(32,64));d=ImageDraw.Draw(im)
    # Solid squared timber fence, not stone painted brown: endgrain cap,
    # upright planks, inset cross rail and forged nail heads.
    d.polygon([(4,28),(27,28),(27,50),(24,54),(7,54),(4,51)],fill='#514238')
    d.polygon([(6,29),(24,29),(24,51),(7,51),(6,49)],fill='#927354')
    for x in (10,16,22):
        d.line((x,34,x,50),fill='#5e4b3d')
        d.line((x+1,35,x+1,49),fill='#b1946d')
    d.rectangle((7,42,23,45),fill='#725b45')
    d.line((7,42,23,42),fill='#c0a17a')
    for x in (8,21):d.point((x,44),fill='#454344')
    roof=[(7,11),(24,11),(27,14),(27,31),(24,34),(7,34),(4,31),(4,14)]
    d.polygon(roof,fill='#a48a66')
    d.polygon([(4,14),(7,11),(7,31),(9,34),(7,34),(4,31)],fill='#c0a17a')
    d.polygon([(24,11),(27,14),(27,31),(24,34),(22,34),(24,31)],fill='#6d5945')
    d.line((8,12,23,12),fill='#d3b48a')
    d.line([(7,32),(23,32),(25,30)],fill='#756047')
    # End-grain square rings distinguish a timber top from a stone cap.
    d.rectangle((10,16,21,28),outline='#806847')
    d.line([(12,18),(19,18),(19,25),(13,25),(13,21),(16,21)],fill='#c0a17a')
    for x,y in [(8+variant,29),(22,15)]:d.point((x,y),fill='#735f46')
    return im

for room in range(7):
    for variant in range(16 if room==1 else 4):
        suffix='' if variant==0 else str(variant)
        for kind in ['exposed','stacked']:
            if room==0:im=foliage(variant)
            elif room==1:im=thicket(variant)
            elif room==3:im=earth(variant)
            elif room==5:im=fence(variant)
            else:im=Image.open(A/f'wall_{kind}{suffix}.png').convert('RGBA')
            if room==4:
                for y in range(im.height):
                    for x in range(im.width):
                        r,g,b,a=im.getpixel((x,y))
                        if a:im.putpixel((x,y),(round(r*.65),round(g*.65),round(b*.65),a))
            im.save(A/f'wall_room{room}_{kind}{suffix}.png')
print('Generated dark varied thickets, excavation-soil banks and squared timber fence')

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
    variants=Image.new('RGBA',(16*72,240),'#242538')
    for row,room in enumerate([1,3]):
        for n in range(16 if room==1 else 4):
            suffix='' if n==0 else str(n)
            tile=Image.open(A/f'wall_room{room}_exposed{suffix}.png')
            projected=Image.new('RGBA',(64,104))
            projected.alpha_composite(tile.crop((0,0,32,34)).resize((64,68),Image.Resampling.NEAREST))
            projected.alpha_composite(tile.crop((0,34,32,64)).resize((64,36),Image.Resampling.NEAREST),(0,68))
            variants.alpha_composite(projected,(n*72+4,row*120+4))
    variants.save('/tmp/organic-wall-variants.png')
