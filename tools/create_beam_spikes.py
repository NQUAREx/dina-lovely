"""Original pixel pressure plate and retracting steel tips for the beam hall."""
from pathlib import Path
from PIL import Image, ImageDraw

art = Image.new("RGBA", (64, 32))
draw = ImageDraw.Draw(art)
draw.polygon([(4,5),(27,5),(30,8),(30,25),(26,29),(5,29),(2,26),(2,9)], fill="#352d3d")
draw.polygon([(5,6),(26,6),(28,9),(28,24),(25,26),(5,26),(4,24),(4,9)], fill="#716274")
draw.line([(5,9),(7,7),(26,7),(28,9)], fill="#a48a90")
for y in (11,20):
    for x in (7,15,23):
        draw.rectangle((x-2,y-1,x+2,y+2), fill="#45404d")
        draw.point((x-2,y+2), fill="#9b8496")
        x += 32
        y2 = y + 10
        draw.polygon([(x-3,y2+2),(x,y2-10),(x+3,y2+2),(x+1,y2+4),(x-2,y2+4)], fill="#695968")
        draw.polygon([(x-2,y2+1),(x,y2-9),(x,y2+2)], fill="#c8bac4")
        draw.line([(x,y2-8),(x,y2-4)], fill="#eee0d2")
art.save(Path(__file__).resolve().parents[1] / "assets/beam_spikes.png")
