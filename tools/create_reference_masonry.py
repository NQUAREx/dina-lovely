"""Paint reference-inspired lavender garden masonry, preserving world-size anchors.

Wall textures are 48x112 pixels/world units; pillar 64x160 and lintel 256x64.
The generator uses an intentionally limited, muted lavender palette and crisp
pixel shapes. All images are RGBA. Runtime supplies geometry and placement.
"""
from pathlib import Path
from PIL import Image, ImageDraw
import random
import math

OUT = Path(__file__).resolve().parents[1] / 'assets'
P = dict(out='#443e52', dark='#51485d', mortar='#62596c', stone='#7d6d85',
         light='#9b849b', top='#b59ba9', shine='#c7acb8', gold='#d1aa69',
         goldlight='#f0d28c', inset='#66556f', pink='#ad7794')

def heart(d, x, y, color, scale=1):
    points=[(0,1),(1,0),(2,0),(3,1),(4,0),(5,0),(6,1),(6,3),(3,6),(0,3)]
    d.polygon([(round(x+a*scale),round(y+b*scale)) for a,b in points],fill=color)

def glow(im,x,y):
    # Soft, deliberately restrained light washes the bricks behind the fixture.
    for radius in range(29,3,-1):
        layer=Image.new('RGBA',im.size);d=ImageDraw.Draw(layer)
        d.ellipse((x-radius,y-radius,x+radius,y+radius),fill=(235,167,86,2 if radius>18 else 3))
        im.alpha_composite(layer)

def lantern(im,x,y):
    glow(im,x,y+5);d=ImageDraw.Draw(im)
    d.line((x-2,y-12,x-2,y-17,x+1,y-20,x+4,y-18,x+4,y-14,x+1,y-12),fill='#51404c',width=2)
    d.line((x-2,y-16,x-1,y-18,x+1,y-18),fill='#aa805c')
    d.rectangle((x-2,y-12,x+2,y-8),fill='#72523b')
    d.polygon([(x-9,y-5),(x-5,y-8),(x-3,y-11),(x+3,y-11),(x+5,y-8),(x+9,y-5)],fill='#79523a')
    d.line((x-7,y-5,x+7,y-5),fill='#d1a061',width=2)
    d.polygon([(x-7,y-3),(x+7,y-3),(x+5,y+15),(x+2,y+18),(x-2,y+18),(x-5,y+15)],fill='#6d4836')
    d.rectangle((x-4,y-1,x+4,y+12),fill='#e6ad5d')
    d.rectangle((x-2,y,x+2,y+12),fill='#ffe7a9')
    d.line((x,y,x,y+12),fill='#fff5c8')
    d.line((x-5,y-1,x-4,y+13),fill='#bb864b')
    d.line((x+5,y-1,x+4,y+13),fill='#a67443')
    d.line((x-4,y+15,x+4,y+15),fill='#c3975c')
    d.rectangle((x-2,y+18,x+2,y+20),fill='#71503c')

def ivy(im,seed=0):
    d=ImageDraw.Draw(im);r=random.Random(915+seed)
    for start,end in [(6,74),(13,45),(36,31)]:
        points=[]
        for y in range(6,end,5): points.append((start+round(math.sin(y*.21)*3),y))
        d.line(points,fill='#536c47',width=2)
        for x,y in points:
            for direction in [-1,1]:
                xx=x+direction*r.randrange(2,6); yy=y+r.randrange(-2,3)
                d.polygon([(xx-direction*3,yy+2),(xx-direction*3,yy-1),(xx,yy-4),(xx+direction*3,yy-3),(xx+direction*3,yy)],fill=r.choice(['#587547','#6c8950','#789654']))
                d.point((xx,yy-2),fill='#9bb26d')
    for x,y in [(7,12),(20,8),(36,15),(11,41)]:
        for dx,dy in [(0,-2),(-2,0),(2,0),(0,2)]:d.rectangle((x+dx,y+dy,x+dx+1,y+dy+1),fill='#c18b9f')
        d.rectangle((x,y,x+1,y+1),fill='#ecd0ad')

def relief(d,x,y):
    d.rectangle((x-17,y-18,x+17,y+19),fill='#5b5067')
    d.line((x-18,y+19,x-18,y-19,x+17,y-19),fill='#89758c',width=2)
    d.line((x-16,y+17,x+16,y+17,x+16,y-17),fill='#746079')
    # A cut-stone raised heart, including a lit upper rim and dark lower bevel.
    heart(d,x-10,y-8,'#57485f',3.4)
    heart(d,x-10,y-10,'#aa829c',3.2)
    heart(d,x-8,y-7,'#745f7a',2.6)
    d.point((x-7,y-8),fill='#c19aac');d.point((x+6,y-8),fill='#b38da4')
    d.rectangle((x-15,y+14,x-13,y+15),fill='#9a8195')
    d.rectangle((x+13,y-15,x+14,y-13),fill='#8b738b')

def wall(variant=0,vertical=False):
    im=Image.new('RGBA',(48,112));d=ImageDraw.Draw(im);r=random.Random(444)
    d.rectangle((0,17,47,104),fill=P['mortar'])
    for row,y in enumerate(range(20,95,14)):
        for x in range(-16 if row%2 else 0,48,32):
            shade=r.choice(['#75667f','#7b6b82','#78687e','#806e85'])
            d.rectangle((x,y,x+29,y+11),fill=shade)
            d.line((x,y,x+29,y),fill='#8b7890')
            d.line((x+29,y+1,x+29,y+11),fill='#6b5b74')
            for _ in range(5):
                xx=x+r.randrange(2,28);yy=y+r.randrange(2,10)
                d.point((xx,yy),fill=r.choice(['#8d7a91','#716077','#948095']))
    # A darker projecting foundation with a stepped, pale upper lip.
    d.rectangle((0,93,47,95),fill='#51495f')
    d.rectangle((0,96,47,99),fill='#947f94');d.line((0,96,47,96),fill='#b49aa9')
    d.rectangle((0,100,47,107),fill='#786780');d.line((0,106,47,106),fill='#675970')
    d.rectangle((0,108,47,111),fill='#51495f')
    # Broad coping has a warm sunlit upper plane, cool overhanging underside.
    d.rectangle((0,3,47,8),fill=P['top']);d.line((0,3,47,3),fill=P['shine'])
    d.line((0,8,47,8),fill='#a58b9f')
    d.rectangle((0,9,47,13),fill='#998095');d.line((0,9,47,9),fill='#c0a4b2')
    d.rectangle((0,14,47,18),fill='#574e63');d.line((0,14,47,14),fill='#79677e')
    d.rectangle((0,19,47,21),fill='#675b71')
    if vertical:
        d.polygon([(8,0),(36,0),(47,4),(0,4)],fill=P['top']);d.line((8,0,36,0),fill=P['shine'])
        if variant==0:
            # Hanging velvet standard, gold bottom point and heart appliqué.
            d.rectangle((12,20,36,44),fill='#54445f')
            d.polygon([(14,23),(34,23),(34,41),(24,46),(14,41)],fill='#8d647e')
            d.line((14,23,14,41,24,46,34,41,34,23),fill='#b49672')
            d.polygon([(18,24),(31,24),(31,40),(24,44),(18,40)],fill='#805a75')
            heart(d,21,28,'#b58099',1)
            d.rectangle((10,19,38,21),fill='#c4a070')
            d.rectangle((12,21,15,24),fill='#d6b77e');d.rectangle((33,21,36,24),fill='#d6b77e')
        else:lantern(im,24,26)
    else:
        if variant==0:relief(d,24,57)
        elif variant==1:lantern(im,25,50)
        elif variant==2:ivy(im)
    return im

def pillar():
    im=Image.new('RGBA',(64,160));d=ImageDraw.Draw(im)
    # Outer side planes remain visible beside the lighter, inset front shaft.
    d.polygon([(15,13),(50,13),(54,136),(10,136)],fill='#574b64')
    d.rectangle((17,14,46,137),fill='#7a667f')
    d.rectangle((19,14,22,136),fill='#9b8298');d.rectangle((44,14,47,136),fill='#66546f')
    d.rectangle((23,51,42,131),fill='#68546f')
    d.line((23,129,23,73,27,68,37,68,42,73,42,129),fill='#c9a76e',width=2)
    d.line((26,127,26,75,29,72,35,72,39,76,39,127),fill='#9b8090')
    d.line((28,125,28,76),fill='#776179')
    heart(d,26,51,P['goldlight'],2)
    # The cap's little heart is sculpted in rose stone.
    d.rectangle((16,25,48,39),fill='#77607a');d.line((16,26,48,26),fill='#9d8097')
    heart(d,26,27,'#b08a9f',2)
    d.rectangle((15,40,49,44),fill='#a38a9e');d.line((16,40,48,40),fill='#c1a2b1')
    d.rectangle((14,45,50,48),fill='#5b4c66')
    # Angled blocks and broad tiered plinth are part of the same silhouette.
    for poly,color in [([(9,9),(54,9),(60,17),(4,17)],'#a18a9e'), ([(4,17),(60,17),(57,24),(8,24)],'#78647e'), ([(10,1),(53,1),(56,8),(7,8)],'#b69aa9')]: d.polygon(poly,fill=color)
    d.line((10,1,53,1),fill='#d0b3bd',width=2);d.line((8,9,56,9),fill='#c7a9b7',width=2)
    d.line((7,17,57,17),fill='#b198a8',width=2)
    d.rectangle((14,131,50,136),fill='#a68b9e');d.line((15,131,49,131),fill='#c0a3b1')
    d.polygon([(14,137),(50,137),(58,146),(6,146)],fill='#a08a9e')
    d.rectangle((6,146,58,151),fill='#7d6a84')
    d.polygon([(6,151),(58,151),(63,156),(1,156)],fill='#b298a8')
    d.rectangle((1,156,63,159),fill='#7f6a83');d.line((2,156,62,156),fill='#c1a3b2')
    # Delicate flowers grow beside, rather than covering, the stepped base.
    for x,y in [(16,124),(19,128),(46,125),(43,130),(12,129)]:
        d.polygon([(x,y),(x-3,y-4),(x-5,y-3),(x-4,y),(x,y+2)],fill='#6a8256')
        d.polygon([(x,y),(x+4,y-4),(x+6,y-2),(x+3,y+1)],fill='#8a9c64')
    for x,y in [(17,122),(44,124),(11,127)]:
        for dx,dy in [(0,-2),(-2,0),(2,0),(0,2)]:d.rectangle((x+dx,y+dy,x+dx+1,y+dy+1),fill='#c58da4')
        d.point((x,y),fill='#f2ceaa')
    return im

def lintel():
    im=Image.new('RGBA',(256,64));d=ImageDraw.Draw(im)
    shape=[(0,37),(11,31),(48,28),(68,17),(95,13),(161,13),(188,17),(208,28),(244,31),(255,37),(255,63),(243,63),(239,52),(205,48),(183,40),(73,40),(51,48),(16,52),(12,63),(0,63)]
    d.polygon(shape,fill='#66526f')
    d.line(shape[:10],fill='#b499a9',width=5)
    d.line([(1,44),(13,36),(50,33),(71,23),(96,19),(160,19),(185,23),(206,33),(243,36),(254,44)],fill='#d1ad73',width=2)
    d.line([(1,59),(9,59),(14,49),(49,44),(72,36),(184,36),(207,44),(242,49),(247,59),(254,59)],fill='#caa36c',width=2)
    d.line([(1,48),(13,40),(49,37),(72,27),(95,23),(161,23),(184,27),(207,37),(244,40),(254,48)],fill='#88718b')
    heart(d,117,24,P['goldlight'],3.7)
    for x in (29,219):
        d.polygon([(x-4,42),(x,37),(x+5,42),(x,47)],fill='#d8b87d')
        d.polygon([(x-1,41),(x+1,41),(x+1,44),(x-1,44)],fill='#755d78')
    # Mirrored leaf flourishes, finely curled stems and tiny buds.
    for x,sign in [(103,-1),(153,1)]:
        d.line([(x,31),(x+sign*8,33),(x+sign*20,31),(x+sign*24,28),(x+sign*21,26),(x+sign*17,27),(x+sign*19,30)],fill='#dbb77b')
        d.polygon([(x+sign*7,31),(x+sign*10,26),(x+sign*15,27),(x+sign*12,30)],fill='#d2ad71')
        d.polygon([(x+sign*13,33),(x+sign*17,35),(x+sign*22,33)],fill='#b99261')
        d.rectangle((x+sign*28,29,x+sign*28+1,30),fill=P['goldlight'])
    return im

if __name__=='__main__':
    images={f'wall_h{i}':wall(i) for i in range(3)}
    images.update({f'wall_v{i}':wall(i,True) for i in range(2)})
    images.update(wall_h=wall(),wall_v=wall(0,True),pillar=pillar(),gate_top=lintel())
    for name,im in images.items():
        im.save(OUT/f'reference_{name}.png')
        print(f'reference_{name}.png: {im.width}x{im.height}')
