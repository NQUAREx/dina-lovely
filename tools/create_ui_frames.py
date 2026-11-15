"""Original embossed pixel UI with native-size floral ornaments, never image crops."""
from pathlib import Path
from PIL import Image, ImageDraw
A=Path(__file__).resolve().parents[1]/'assets'/'ui'
def generate():
 A.mkdir(exist_ok=True)
 for state,base,edge,hi in [('normal','#543b59','#c38aa5','#f4c4bc'),('hover','#694863','#e4aaa9','#ffe5bb'),('pressed','#403047','#a77894','#dbabb5'),('disabled','#463c4c','#806b83','#ab91a4'),('panel','#49354f','#c28ba5','#f1c5bf'),('paper','#fff4df','#ba879a','#f4d8bd'),('focus','#543b59','#dfb88d','#ffe2b4')]:
  im=Image.new('RGBA',(64,64));d=ImageDraw.Draw(im)
  def shape(i,c,fill):
   a=i;b=63-i;d.polygon([(a+c,a),(b-c,a),(b,a+c),(b,b-c),(b-c,b),(a+c,b),(a,b-c),(a,a+c)],fill=fill)
  # Raised outer lip, dark recessed channel and a second illuminated inner rim.
  for args in [(0,8,'#322638'),(1,7,'#875f7f'),(2,6,edge),(3,6,hi),(4,5,'#a27492'),(5,5,'#533b59'),(6,4,'#b27c99'),(7,4,'#ddb0b8'),(8,3,base)]:shape(*args)
  d.line([(10,2),(53,2),(60,9)],fill=hi);d.line([(2,11),(2,51)],fill='#d5a0af')
  d.line([(10,61),(53,61),(61,53)],fill='#62445f',width=2)
  d.line([(60,11),(60,51)],fill='#76516d')
  d.line([(11,8),(52,8)],fill='#b1849e' if state!='paper' else '#e3bcb9')
  d.line([(9,55),(54,55)],fill='#3b2c43' if state!='paper' else '#cda5ad')
  # Corner inlays are entirely within the non-stretching 12px corner patch.
  for x,y in [(8,8),(55,55)]:
   d.line([(x-4,y+3),(x-4,y),(x,y-4),(x+3,y-4)],fill=hi)
   d.point((x-1,y-1),fill='#ffe0c2');d.point((x+1,y+1),fill='#916581')
  im.save(A/f'frame_{state}.png')
 # Large original floral spray, with curled stems, two-tone leaves and layered petals.
 im=Image.new('RGBA',(60,44));d=ImageDraw.Draw(im)
 d.line([(4,42),(3,34),(5,23),(12,15),(24,10),(36,10),(47,17),(56,15)],fill='#364636',width=3)
 d.line([(4,40),(4,33),(6,23),(13,16),(25,11),(36,11),(47,18),(56,16)],fill='#a5aa6d',width=1)
 d.line([(7,25),(17,22),(23,15)],fill='#6d8450',width=2)
 d.line([(33,10),(41,5),(50,5),(54,8),(52,11)],fill='#91a368',width=2)
 d.line([(6,32),(12,33),(15,29),(14,26)],fill='#8fa264',width=1)
 for x,y,dx,dy in [(5,36,7,-5),(4,29,-3,-7),(9,23,8,-1),(16,16,-2,-8),(25,11,2,-7),(35,10,4,-7),(43,15,8,-2),(47,18,4,7),(54,16,4,-5),(11,32,6,2)]:
  d.polygon([(x,y),(x+dx-2,y+dy),(x+dx,y+dy-2),(x+dx+2,y+dy),(x+dx,y+dy+2)],fill='#41563a')
  d.polygon([(x,y),(x+dx-1,y+dy-1),(x+dx,y+dy-2),(x+dx+1,y+dy)],fill='#849b55')
  d.line((x,y,x+dx,y+dy),fill='#c3c77f')
 for x,y,r in [(12,16,5),(25,9,5),(38,14,4)]:
  # Eight petals with pixel highlights and a warm, recessed flower center.
  for dx,dy in [(-r,0),(r,0),(0,-r),(0,r),(-r+1,-r+1),(r-1,-r+1),(-r+1,r-1),(r-1,r-1)]:
   px=x+dx;py=y+dy
   d.polygon([(px-2,py-2),(px+1,py-3),(px+3,py-1),(px+2,py+2),(px,py+3),(px-2,py+1)],fill='#8d5d79')
   d.polygon([(px-2,py-2),(px+1,py-2),(px+2,py),(px+1,py+1),(px-1,py+1)],fill='#e8a8b8')
   d.line((px-1,py-2,px+1,py-2),fill='#ffe4d4');d.point((px-2,py-1),fill='#f5ced0')
  d.rectangle((x-2,y-2,x+2,y+2),fill='#ad805f');d.rectangle((x-1,y-2,x+1,y+1),fill='#f6d294');d.point((x-1,y-2),fill='#fff0bd');d.point((x+2,y+1),fill='#6f6045')
 for x,y in [(3,12),(48,2),(57,25)]:
  d.line((x-2,y,x+2,y),fill='#f4d59f');d.line((x,y-2,x,y+2),fill='#fff0c9')
 im.save(A/'flower_corner.png')
 for name,w,h in [('button',44,22),('panel',104,30)]:
  im=Image.new('RGBA',(w,h));d=ImageDraw.Draw(im);cx=w//2
  if name=='panel':
   for inset,fill in [(0,'#76516b'),(1,'#edb7bc'),(3,'#986880'),(5,'#60405b')]:
    i=inset;d.polygon([(i,9),(12+i,i),(w-13-i,i),(w-1-i,9),(w-13-i,h-1-i),(12+i,h-1-i)],fill=fill)
   d.line((18,4,w-19,4),fill='#ffe0c5')
   for x in [16,w-17]:d.polygon([(x,12),(x+3,15),(x,18),(x-3,15)],fill='#c997a7');d.point((x,13),fill='#f6c5bd')
  y=4 if name=='button' else 7
  pts=[(cx-10,y+1),(cx-6,y-2),(cx-2,y-1),(cx,y+2),(cx+3,y-1),(cx+7,y-2),(cx+11,y+1),(cx+11,y+6),(cx,y+17),(cx-10,y+6)]
  d.polygon(pts,fill='#7d516c');d.polygon([(x,yy-1) for x,yy in pts],fill='#e9a2b0');d.polygon([(cx-8,y+1),(cx-6,y-1),(cx-2,y),(cx-1,y+4),(cx-7,y+8)],fill='#f6c6c6');d.line([(cx-8,y),(cx-6,y-2),(cx-3,y-1)],fill='#ffe6d0')
  im.save(A/f'crest_{name}.png')
 print('Generated embossed UI rails, detailed floral sprays and dimensional heart crests')
if __name__=='__main__':generate()
