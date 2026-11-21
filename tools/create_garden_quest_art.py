"""Draw the garden quest sprites at the game's two-screen-pixel scale."""

from pathlib import Path
from random import Random

from PIL import Image, ImageColor, ImageDraw


ASSETS = Path(__file__).resolve().parents[1] / "assets"
CELL = 64
COLUMNS = 8

SOIL_RIM = "#765d50"
SOIL = "#544746"
GREEN_EDGE = "#244b45"
GREEN_TOP = "#5b8964"
GREEN_LIGHT = "#7ca06c"
WOOD_EDGE = "#47383d"
WOOD_SHADE = "#664b45"
WOOD_MID = "#886351"
WOOD_TOP = "#af8762"
WOOD_LIGHT = "#cfab7b"
WICKER_EDGE = "#594349"
WICKER_DARK = "#84604b"
WICKER_MID = "#ad805a"
WICKER_LIT = "#d1a676"
WICKER_HIGHLIGHT = "#e7c58d"


def canvas():
    sprite = Image.new("RGBA", (CELL, CELL))
    return sprite, ImageDraw.Draw(sprite)


def shape(draw, points, color, x=0, y=0):
    draw.polygon([(x + px, y + py) for px, py in points], fill=color)


def grass_pile(variant):
    sprite, d = canvas()
    silhouettes = [
        [(16,51),(19,48),(22,48),(20,43),(26,46),(29,44),(28,39),(33,43),(36,42),(39,46),(45,47),(44,50),(48,53),(45,55),(39,56),(26,56),(20,54)],
        [(16,53),(19,49),(23,49),(24,45),(27,47),(32,44),(37,46),(44,43),(42,48),(48,51),(47,54),(40,56),(25,56),(21,54)],
        [(17,51),(21,47),(24,47),(25,42),(29,44),(32,37),(34,43),(37,43),(39,47),(43,47),(47,50),(47,54),(42,56),(24,56),(19,54)],
        [(16,52),(20,49),(25,47),(24,43),(29,44),(32,48),(37,46),(42,46),(44,49),(48,52),(46,55),(38,56),(27,56),(21,54)],
        [(16,52),(19,50),(21,47),(25,48),(29,46),(33,48),(36,44),(41,47),(46,47),(44,50),(48,52),(46,55),(29,56),(22,55)],
        [(16,52),(20,49),(22,45),(26,47),(28,43),(30,45),(35,41),(36,45),(42,46),(44,49),(48,50),(47,54),(43,56),(23,56)],
    ]
    base, shade, body, light, straw = [
        ("#3a4938", "#57603d", "#79834c", "#a9a766", "#c3b883"),
        ("#414931", "#605e3e", "#84794e", "#aea66c", "#c9b784"),
        ("#334c3b", "#4c6b48", "#688657", "#91a46c", "#b6bd82"),
        ("#414b37", "#606945", "#838759", "#a8ac73", "#cbbb88"),
        ("#364d3f", "#567153", "#738963", "#a1ae76", "#c1c38e"),
        ("#3e4a34", "#627046", "#818a53", "#aeb36e", "#cdbf8b"),
    ][variant]
    silhouette = silhouettes[variant]
    d.polygon(silhouette, fill=base)
    d.polygon([(x + (1 if x < 32 else -1), y - (2 if y >= 53 else 0))
               for x, y in silhouette], fill=shade)
    strands = [
        [(19,49,28,51),(21,46,30,50),(27,47,36,42),(30,43,37,49),(35,50,42,47),(41,51,47,52)],
        [(17,51,31,49),(21,52,32,47),(26,48,37,45),(31,51,43,48),(37,52,45,52),(36,48,43,44)],
        [(20,49,29,51),(24,46,31,41),(30,48,33,40),(32,49,39,45),(35,50,44,49),(40,52,46,53)],
        [(18,51,27,48),(23,46,31,49),(24,52,33,50),(30,49,39,47),(34,53,42,49),(40,52,46,52)],
        [(18,50,28,49),(21,52,31,48),(27,51,37,46),(32,52,39,50),(38,51,45,48),(40,53,47,53)],
        [(18,51,28,47),(22,52,31,48),(29,49,36,43),(33,51,42,48),(37,53,46,51),(41,51,46,50)],
    ][variant]
    for n, segment in enumerate(strands):
        d.line(segment, fill=body, width=3)
        x0, y0, x1, y1 = segment
        start = (x0 + (x1-x0)//3, y0 + (y1-y0)//3)
        d.line((*start,x1,y1), fill=straw if n in (1,3) else light)
        d.point((x1,y1+1), fill=body)
    for x, y in [(18,54),(20,56),(24,54),(35,54),(41,55),(46,55)]:
        if sprite.getpixel((x,y))[3]:
            d.point((x,y), fill=body)
    return sprite


def shoot_leaves(d, x, y, side, palette):
    """A paired, serrated leaf tip at the end of a small twig."""
    dark, middle, lit = palette
    shape(d, [(0,0),(side,-2),(3*side,-2),(5*side,-4),
              (5*side,-1),(3*side,1),(side,1)], dark, x, y)
    shape(d, [(side,-1),(3*side,-1),(4*side,-3),(4*side,-1),
              (2*side,0)], middle, x, y)
    d.point((x+4*side,y-2), fill=lit)


def leaf_spray(d, x, y, side, colors):
    shadow, mid, face, lit = colors
    points = [(0,0),(-2,-1),(-3,-3),(-3,-6),(-1,-7),(0,-9),
              (2,-8),(4,-8),(4,-6),(6,-5),(5,-3),(6,-2),
              (3,0),(2,2)]
    shape(d, [(dx*side,dy) for dx,dy in points], shadow, x, y)
    points = [(-2,-4),(-2,-6),(0,-7),(1,-8),(4,-7),(4,-6),(5,-5),
              (4,-3),(5,-2),(2,-1),(2,1),(0,0),(-1,-1)]
    shape(d, [(dx*side,dy) for dx,dy in points], mid, x, y)
    points = [(-1,-5),(1,-6),(1,-7),(3,-7),(3,-5),(4,-4),(1,-3),
              (0,-1),(-1,-2)]
    shape(d, [(dx*side,dy) for dx,dy in points], face, x, y)
    d.line((x-side,y-4,x+side,y-5), fill=lit)
    d.point((x+2*side,y-6), fill=lit)

def berry(d, x, y, style, small=False):
    dark, medium, highlight = {
        "ripe": ("#863e5b", "#d86388", "#ffb5b0"),
        "unripe": ("#45694a", "#a0a85f", "#c6c17a"),
    }[style]
    if small:
        d.point((x, y + 1), fill=dark)
        d.point((x + 1, y), fill=dark)
        d.point((x, y), fill=highlight)
    else:
        shape(d, [(-1, -1), (1, -1), (2, 0), (2, 1), (1, 2), (-1, 2), (-2, 1), (-2, 0)], dark, x, y)
        d.rectangle((x - 1, y - 1, x + 1, y + 1), fill=medium)
        d.point((x - 1, y), fill=highlight)


def bush(variant, stage):
    sprite, d = canvas()
    wild, wet = stage == "wild", stage == "watered"
    soil_rim = "#54605a" if wet else SOIL_RIM
    soil_body = "#434b47" if wet else SOIL
    shape(d, [(-9,1),(-10,-1),(-6,-3),(5,-3),(9,-1),(10,1),(6,2),(-6,2)], soil_body,32,54)
    d.line((25,54,28,55,33,55), fill=soil_rim)
    d.line((37,55,40,54), fill=soil_rim)
    # Bark fans from the root collar: the picked bush still has woody stems.
    branches = [
        [(28,54),(28,48),(26,43),(23,39)],
        [(31,54),(32,49),(31,42),(30,35)],
        [(34,54),(35,49),(38,44),(41,40)],
        [(30,53),(30,48),(34,44),(34,40)],
    ]
    for branch in branches:
        d.line(branch, fill=WOOD_EDGE, width=2)
        d.line(branch, fill=WOOD_TOP if wild else WOOD_MID)
    d.point((28,53), fill=WOOD_LIGHT)
    d.point((31,53), fill=WOOD_LIGHT)
    if wild:
        shoots = [
            [[(25,45),(22,40),(23,36),(21,31)],[(33,43),(34,37),(32,32),(34,25)]],
            [[(27,46),(26,42),(28,36),(26,28)],[(39,44),(42,40),(42,35),(43,27)]],
            [[(25,46),(24,39),(21,36),(23,26)],[(33,43),(34,37),(39,32),(38,29)]],
            [[(24,45),(22,39),(21,35),(22,30)],[(38,45),(37,39),(39,34),(42,25)]],
        ][variant]
        for branch in shoots:
            d.line(branch, fill=WOOD_SHADE, width=2)
            d.line(branch, fill="#99916b")
            for x,y in branch[1:]:
                side = 1 if x < 31 else -1
                shoot_leaves(d,x,y,side,(GREEN_EDGE,GREEN_TOP,GREEN_LIGHT))
    # Leaf sprays grow at different angles. Dark pockets between them let the
    # wood and irregular crown read as a berry shrub rather than a clipped dome.
    sprays = [
        [(24,46,1),(29,42,-1),(40,47,-1),(36,42,1),(36,48,-1),(29,49,1)],
        [(25,45,1),(30,42,-1),(41,45,-1),(35,43,1),(38,48,-1),(29,49,1)],
        [(25,46,1),(29,42,-1),(41,47,-1),(35,42,1),(35,48,-1),(30,49,1)],
        [(24,47,1),(30,42,-1),(41,45,-1),(35,42,1),(38,48,-1),(30,49,1)],
    ][variant]
    if wild:
        sprays = [*sprays[:4],(28+variant,38,-1),(39-variant,36,1),*sprays[4:]]
    elif stage != "picked":
        sprays = [*sprays[:4],(32+variant%2,41,1),*sprays[4:]]
    leaf_colors = [
        (GREEN_EDGE,"#41694f","#61895e","#82a473"),
        (GREEN_EDGE,"#416c57","#5d8c6a","#83aa7b"),
        (GREEN_EDGE,"#4a6e50","#729361","#91a56d"),
        (GREEN_EDGE,"#43694e","#63875d","#88a474"),
    ]
    for i,(x,y,side) in enumerate(sprays):
        palette=leaf_colors[(variant+i//2)%len(leaf_colors)]
        leaf_spray(d,x,y,side,palette)
    if wet:
        for x,y in [(24,42),(34,39),(40,42),(29,46),(38,47)]:
            d.line((x,y+1,x+1,y+1), fill="#5b9489")
            d.point((x+1,y), fill="#b7d3c1")
        d.line((36,54,39,54), fill="#8aafa0")
    if stage in ["ripe", "picked"]:
        berry_sites = [
            [(26,43),(33,40),(39,45),(31,48)],
            [(26,42),(35,40),(39,44),(30,48)],
            [(26,43),(31,38),(40,45),(34,48)],
            [(26,44),(31,39),(39,43),(34,47)],
        ][variant]
        for n,(x,y) in enumerate(berry_sites):
            shift=-2 if n%2 else 2
            d.line((x+1,y-4,x+1,y-2,x,y-1), fill="#b0b17d")
            d.line((x+1,y-2,x+shift,y), fill="#89955c")
            if stage == "ripe":
                berry(d,x,y,"ripe")
                berry(d,x+shift,y+2,"ripe",small=True)
                d.point((x+shift-1,y+2), fill="#bc4d76")
            elif n in (0,2):
                berry(d,x,y+1,"unripe",small=True)
            else:
                d.point((x,y-1), fill=WOOD_LIGHT)
    bounds=sprite.getbbox()
    assert bounds[0]>=19 and bounds[2]<=46 and bounds[2]-bounds[0]<=26, (variant,stage,bounds)
    return sprite


def overgrown_tree(variant):
    sprite, d = canvas()
    rng = Random(3137 + variant)
    forks, clusters = [
        ([(32,52),(32,43),(28,34),(21,28),(17,20)],
         [(17,21,9,11),(24,26,10,9),(34,29,10,12),(27,35,10,8),(15,34,7,6),(37,19,5,6)]),
        ([(32,52),(32,41),(36,34),(42,30),(43,20)],
         [(24,27,8,10),(37,22,11,11),(45,28,8,8),(34,35,11,8),(45,40,7,6),(30,15,5,6)]),
        ([(32,52),(31,44),(35,34),(30,27),(31,18)],
         [(33,17,10,11),(23,23,8,9),(37,27,10,9),(31,36,10,9),(44,31,7,6),(18,34,6,8)]),
        ([(32,52),(32,44),(25,38),(24,30),(14,28)],
         [(16,25,9,7),(27,22,9,10),(42,28,10,9),(30,34,13,8),(16,35,7,5),(46,37,6,6)]),
    ][variant]
    dark, shade, middle, face, light = [
        ("#284b42", "#385e4e", "#4c7559", "#608665", "#88a174"),
        ("#294d44", "#3a6353", "#507b62", "#62886b", "#8ba676"),
        ("#29483e", "#3d6149", "#537954", "#668968", "#93a879"),
        ("#284b43", "#41634d", "#53775d", "#63886b", "#849e73"),
    ][variant]
    face_pixel = ImageColor.getcolor(face, "RGBA")
    # A crooked stem and two exposed forks remain visible below the canopy.
    branch_tips = [((39,18),(14,39)),((28,16),(46,40)),((18,37),(46,26)),((44,23),(15,40))]
    for tip in branch_tips[variant]:
        branch = [forks[1], ((tip[0]+forks[2][0])//2, forks[2][1]), tip]
        d.line(branch, fill=WOOD_EDGE, width=4)
        d.line(branch, fill=WOOD_MID, width=2)
    d.line(forks, fill=WOOD_EDGE, width=8, joint="curve")
    d.line([(x - 1, y) for x, y in forks], fill=WOOD_SHADE, width=6, joint="curve")
    d.line([(x - 2, y) for x, y in forks], fill="#96735d", width=3, joint="curve")
    shape(d, [(-7,0),(-4,-2),(-3,-6),(3,-6),(5,-2),(7,0),(4,1),(-5,1)], WOOD_EDGE, 32, 53)
    shape(d, [(-5,0),(-3,-2),(-2,-6),(2,-6),(3,-1),(4,0)], WOOD_MID, 32, 53)
    d.line((30,48,30,51,28,53), fill="#a78667")

    for n, (cx, cy, rx, ry) in enumerate(clusters):
        # Rounded lobes with small stepped nicks, lit from the top left.
        rim = [(-rx,0),(-rx+1,-ry//2),(-rx//2,-ry+1),(-2,-ry+1),(0,-ry),
               (rx//2,-ry+1),(rx-2,-ry//2-1),(rx-1,-3),(rx,-2),(rx,2),
               (rx-2,ry//2),(rx//2,ry-1),(2,ry),(-1,ry-1),(-rx//2,ry-1),(-rx+2,ry//2)]
        shape(d, rim, dark, cx, cy)
        shape(d, [(x+(1 if x<0 else -1), y+(1 if y<0 else -1)) for x,y in rim], shade, cx, cy-1)
        shape(d, [(round(x*.86)-1,round(y*.80)-2) for x,y in rim], middle, cx, cy)
        shape(d, [(round(x*.68)-2,round(y*.57)-3) for x,y in rim], face, cx, cy)
        d.line((cx-rx//2,cy-ry//2,cx-rx//3,cy-ry//2-1,cx+1,cy-ry//2-1), fill=light)
        for _ in range(7):
            x, y = cx+rng.randrange(-(rx//2), rx//2+1), cy+rng.randrange(-(ry//2), ry//2+1)
            if sprite.getpixel((x, y)) == face_pixel:
                d.line((x,y,x+rng.randrange(2),y), fill=light if rng.randrange(3)==0 else middle)
        if n in (0, 3, 5):
            side = -1 if cx < 32 else 1
            x, y = cx+(rx-2)*side, cy-ry//2
            d.line((x,y,x+side*2,y-2,x+side*2,y-5), fill=dark)
            shape(d, [(0,0),(side,-2),(side*4,-3),(side*3,0),(side,1)], middle, x+side*2, y-4)
            d.point((x+side*4,y-6), fill=light)
    return sprite


def shears(on_ground, opened=False):
    sprite, d = canvas()
    # Curved bypass blade and short solid grips, centered on the hand pivot.
    shape(d, [(29,47),(26,46),(20,42 if opened else 44),(19,44),(24,48),(28,50)], "#4a3941")
    shape(d, [(29,48),(26,49),(21,53 if opened else 50),(22,55 if opened else 52),(29,51),(31,49)], "#4a3941")
    d.line([(21,44 if opened else 45),(26,47),(29,48)], fill="#af7365")
    d.line([(23,53 if opened else 51),(27,50),(29,49)], fill="#956050")
    shape(d, [(28,47),(33,43),(39,39 if opened else 43),(41,39 if opened else 43),
              (40,42 if opened else 46),(34,48),(30,50)], "#414c55")
    d.line([(31,47),(35,44),(39,40 if opened else 44)], fill="#d5dcd1")
    shape(d, [(29,47),(34,47),(40,50 if opened else 46),(40,52 if opened else 48),
              (36,52 if opened else 49),(29,50)], "#748885")
    d.rectangle((29,47,30,48), fill="#e1c397")
    if on_ground:
        piece = sprite.crop(sprite.getbbox()).rotate(47, resample=Image.Resampling.NEAREST, expand=True)
        piece = piece.crop(piece.getbbox())
        sprite = Image.new("RGBA", (CELL, CELL))
        sprite.paste(piece, (32-piece.width//2, 55-piece.height))
    return sprite


def basket(d, x, y, fill, small=False):
    """The basket rim is at y=0 and the grip at y=-6."""
    w = 6 if small else 7
    height = 5 if small else 7
    handle = [(x - w + 2, y), (x - w + 2, y - 3), (x - 3, y - 6),
              (x + 3, y - 6), (x + w - 2, y - 3), (x + w - 2, y)]
    d.line(handle, fill=WICKER_EDGE, width=2)
    d.line([(hx, hy - 1) for hx, hy in handle], fill=WICKER_LIT)
    d.line((x - 3, y - 7, x + 1, y - 7), fill=WICKER_HIGHLIGHT)
    shape(d, [(-w, -1), (-w + 2, -3), (w - 2, -3), (w, -1),
              (w, 2), (w - 2, height - 1), (w - 4, height),
              (-w + 4, height), (-w + 2, height - 1), (-w, 2)], WICKER_EDGE, x, y)
    shape(d, [(-w + 1, 1), (w - 1, 1), (w - 2, 4), (w - 4, height - 1),
              (-w + 4, height - 1), (-w + 2, 4)], WICKER_MID, x, y)
    d.line((x - w + 2, y + 4, x + w - 3, y + 4), fill=WICKER_DARK)
    if not small:
        d.line((x - 3, y + 5, x + 3, y + 5), fill=WICKER_LIT)
    d.ellipse((x - w + 1, y - 2, x + w - 1, y + 2), fill="#6b4b42")
    d.line((x - w + 3, y, x + w - 3, y), fill="#ac7955")
    if fill:
        berries = [(-3, -1), (0, -2), (3, -1)]
        if fill == 2:
            berries = [(-4, -2), (-2, -4), (1, -4), (4, -2), (-1, -1), (2, -1)]
        for bx, by in berries:
            berry(d, x + bx, y + by, "ripe", small=small)
    d.line((x - w + 1, y + 2, x + w - 1, y + 2), fill=WICKER_LIT)
    d.line((x - w + 2, y + 2, x - 1, y + 2), fill=WICKER_HIGHLIGHT)
    for offset, dy in [(-4, 3), (-2, 4), (0, 3), (2, 4), (4, 3)]:
        d.point((x + offset, y + dy), fill=WICKER_HIGHLIGHT if offset < 2 else WICKER_DARK)


def basket_sprite(fill, on_ground):
    sprite, d = canvas()
    basket(d, 32, 47 if on_ground else 45, fill)
    return sprite


def display_table(delivered):
    sprite, d = canvas()
    # Back legs and a stretcher beneath the top.
    for x in (12, 46):
        d.rectangle((x, 35, x + 4, 46), fill=WOOD_EDGE)
        d.line((x + 1, 36, x + 1, 45), fill=WOOD_SHADE)
    d.rectangle((15, 46, 48, 50), fill=WOOD_EDGE)
    d.line((17, 47, 46, 47), fill=WOOD_TOP)
    d.line((20, 48, 29, 48), fill=WOOD_MID)
    # Joinery and the front legs terminate at the ground anchor.
    for x in (13, 45):
        shape(d, [(0, 0), (6, 0), (6, 12), (4, 14), (0, 14)], WOOD_EDGE, x, 41)
        d.rectangle((x + 1, 42, x + 4, 53), fill=WOOD_MID)
        d.line((x + 1, 43, x + 1, 52), fill=WOOD_TOP)
    shape(d, [(7, 32), (11, 28), (52, 28), (57, 32), (57, 42), (54, 45),
              (9, 45), (7, 43)], WOOD_EDGE)
    shape(d, [(9, 33), (12, 29), (51, 29), (55, 33),
              (55, 38), (9, 38)], WOOD_TOP)
    d.rectangle((9, 39, 55, 42), fill=WOOD_MID)
    d.line((10, 39, 54, 39), fill=WOOD_LIGHT)
    d.line((10, 42, 54, 42), fill=WOOD_SHADE)
    d.line((14, 30, 49, 30), fill=WOOD_LIGHT)
    d.line((11, 36, 53, 36), fill="#765546")
    d.line((13, 34, 21, 34), fill="#d0a578")
    d.line((43, 34, 51, 34), fill="#946c51")
    # Folded runner visible both before and after delivery, with brass tacks.
    shape(d, [(12, 32), (14, 29), (50, 29), (53, 32), (50, 37), (13, 37)], "#5f555e")
    shape(d, [(14, 32), (16, 30), (49, 30), (51, 32), (49, 35), (15, 35)], "#8a6e78")
    d.line((15, 32, 50, 32), fill="#b38b91")
    d.line((15, 35, 48, 35), fill="#ac8a8c")
    d.point((11, 40), fill="#dfba81")
    d.point((53, 40), fill="#dfba81")
    d.rectangle((28, 40, 35, 41), fill=WOOD_EDGE)
    d.line((30, 40, 33, 40), fill="#e4ba79")
    # Numbered spaces are shown by three stitched diamonds, then real baskets.
    for index, x in enumerate((17, 32, 47)):
        if index < delivered:
            basket(d, x, 29, 2, small=True)
        else:
            d.point((x, 33), fill="#d8ad99")
            d.point((x + 1, 34), fill="#bd9496")
            d.point((x - 1, 34), fill="#bd9496")
            d.point((x, 35), fill="#664f61")
    return sprite


def main():
    sprites = {variant: grass_pile(variant) for variant in range(6)}
    for first, stage in [(8, "wild"), (16, "pruned"), (24, "watered"),
                         (32, "ripe"), (36, "picked")]:
        for variant in range(4):
            sprites[first + variant] = bush(variant, stage)
    sprites[40] = shears(on_ground=True)
    sprites[41] = shears(on_ground=False)
    for fill in range(3):
        sprites[42 + fill] = basket_sprite(fill, on_ground=False)
        sprites[45 + fill] = basket_sprite(fill, on_ground=True)
    for delivered in range(4):
        sprites[48 + delivered] = display_table(delivered)
    sprites[52] = shears(on_ground=False, opened=True)
    for variant in range(4):
        sprites[56+variant] = overgrown_tree(variant)
    rows = max(sprites) // COLUMNS + 1
    atlas = Image.new("RGBA", (CELL * COLUMNS, CELL * rows))
    for index, sprite in sprites.items():
        atlas.paste(sprite, (index % COLUMNS * CELL, index // COLUMNS * CELL))
    atlas.save(ASSETS / "garden_quest.png")


if __name__ == "__main__":
    main()
