"""Extract user-supplied reference borders, removing baked labels and symbols."""
from pathlib import Path
from PIL import Image,ImageDraw
R=Path(__file__).resolve().parents[1];A=R/'assets/ui'
s=Image.open(R/'tools/art_source/ui_reference.jpg').convert('RGBA')
# Wide native frames retain their original flower and bevel proportions.
for name,box in [('normal',(106,119,376,198)),('hover',(106,201,376,281)),('pressed',(106,282,376,355)),('disabled',(106,359,376,432)),('panel',(24,478,452,652))]:
 im=s.crop(box);w,h=im.size;d=ImageDraw.Draw(im)
 color=im.getpixel((w//2, h//2+12))
 # Sample clean inner fill away from baked lettering.
 color=im.getpixel((40,35 if name!='panel' else 65))
 d.rectangle((34,22,w-35,h-16),fill=color)
 # Replace central title/heart area with copied plain top rail; crest is separate.
 start=80 if name=='panel' else 55
 sample=120 if name=='panel' else 55
 rail=im.crop((sample,0,sample+10,27)).resize((w-start*2,27))
 im.paste(rail,(start,0))
 if name=='panel':d.rectangle((36,35,w-37,h-23),fill=color)
 # Outside background stays transparent, while the entire interior is opaque.
 mask=Image.new('L',im.size,0);md=ImageDraw.Draw(mask)
 md.polygon([(18,4),(w-19,4),(w-3,22),(w-3,h-18),(w-18,h-3),(18,h-3),(3,h-18),(3,22)],fill=255)
 # Preserve flowers protruding at the upper corners.
 md.rectangle((4,3,55,38),fill=255);md.rectangle((w-56,3,w-4,38),fill=255)
 im.putalpha(mask);im.save(A/f'frame_{name}.png')
# Preserve existing pale paper and focus overlay; real crest copied at native aspect.
s.crop((219,119,269,146)).save(A/'crest_button.png')
s.crop((181,481,304,513)).save(A/'crest_panel.png')
