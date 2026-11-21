"""Material-specific pixel boundaries on the established 24px footprint.

Renderer keeps roof rows0:34 at2x, side rows34:64 at2x/1.2x. Unchanged
collision footprint, no anti-aliasing, game foliage/soil/masonry palettes.
"""
from pathlib import Path
from PIL import Image,ImageDraw
import random
from create_wall_art import wall_art

A=Path(__file__).resolve().parents[1]/'assets'

def thicket(variant):
    im=Image.new('RGBA',(32,64));d=ImageDraw.Draw(im);r=random.Random(19103+variant*137)
    # Rounded broadleaf masses on the same small pixel grid as the maze.
    # Every silhouette is a union of round lobes, not pointed polygon fans.
    trunks=[(r.randint(9,13),r.randint(43,47)),(r.randint(20,23),r.randint(43,48))]
    for x,y in trunks:
        d.rectangle((x-2,y-15,x+1,y+4),fill='#51483f')
        d.line((x-1,y-12,x-1,y+2),fill='#796650')
        d.line((x-2,y+2,x-4,y+4),fill='#51483f',width=2)
        d.line((x,y+2,x+3,y+4),fill='#51483f',width=2)
    crowns=[(r.randint(13,18),r.randint(17,21),r.randint(10,12),r.randint(10,13))]
    crowns += [(r.randint(7,11),r.randint(29,34),r.randint(6,8),r.randint(7,9)),
               (r.randint(22,24),r.randint(27,33),r.randint(6,8),r.randint(7,10)),
               (r.randint(14,19),r.randint(37,40),r.randint(8,10),r.randint(7,9))]
    for cx,cy,rx,ry in crowns:
        rx=min(rx,cx,31-cx)
        d.ellipse((cx-rx,cy-ry,cx+rx,cy+ry),fill='#193c32')
        d.ellipse((cx-rx,cy-ry,cx+rx-1,cy+ry-3),fill='#254c3c')
        d.ellipse((cx-rx+1,cy-ry,cx+rx-2,cy+ry-5),fill='#315744')
        # Broken broad highlights follow round crown volumes. No sharp wedges
        # or long diagonal outlines reaching the silhouette.
        d.arc((cx-rx+2,cy-ry+2,cx+rx-3,cy+ry-7),190,272,fill='#57745a',width=1)
        for ox,oy in [(-rx//3,-ry//4),(rx//3,0),(0,ry//3)]:
            px=cx+ox+r.randint(-1,1);py=cy+oy+r.randint(-1,1)
            d.line((px,py,px+2,py),fill=r.choice(['#254c3c','#3f634b','#57745a']))
            if r.random()<.5:d.point((px+1,py-1),fill='#3f634b')
    # Low round leaf clusters attach to roots without a triangular skirt.
    for cx,cy in [(7,44),(14,48),(23,45)]:
        cy+=r.randint(-2,2)
        d.ellipse((cx-4,cy-4,cx+4,cy+3),fill='#193c32')
        d.ellipse((cx-4,cy-4,cx+3,cy+1),fill='#254c3c')
        d.line((cx-2,cy-3,cx,cy-3),fill='#3f634b')
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

for room in range(1, 7):
    for variant in range(16 if room==1 else 4):
        suffix='' if variant==0 else str(variant)
        for kind in ['exposed','stacked']:
            if room==1:im=thicket(variant)
            elif room==3:im=earth(variant)
            elif room==5:im=fence(variant)
            else:im=wall_art(variant)
            if room==4:
                for y in range(im.height):
                    for x in range(im.width):
                        r,g,b,a=im.getpixel((x,y))
                        if a:im.putpixel((x,y),(round(r*.65),round(g*.65),round(b*.65),a))
            im.save(A/f'wall_room{room}_{kind}{suffix}.png')
print('Generated dark varied thickets, excavation-soil banks and squared timber fence')

if __name__=='__main__':
    sheet=Image.new('RGBA',(6*112,160),'#242538')
    for room in range(1, 7):
        tile=Image.open(A/f'wall_room{room}_exposed.png')
        projected=Image.new('RGBA',(64,104))
        projected.alpha_composite(tile.crop((0,0,32,34)).resize((64,68),Image.Resampling.NEAREST))
        projected.alpha_composite(tile.crop((0,34,32,64)).resize((64,36),Image.Resampling.NEAREST),(0,68))
        sheet.alpha_composite(projected,((room-1)*112+24,24))
        ImageDraw.Draw(sheet).text(((room-1)*112+44,136),str(room),fill='#e4d0bd')
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
