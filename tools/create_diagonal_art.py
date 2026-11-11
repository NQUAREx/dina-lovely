"""Original eight-direction character additions, preserving existing cardinal artwork."""
from pathlib import Path
from PIL import Image, ImageDraw
import ast, json, math
R=Path(__file__).resolve().parents[1];A=R/'assets'
# Reuse the established accessory palettes and headpiece designs, not their poses.
source=ast.parse((R/'tools/create_assets.py').read_text())
keep={'ACCESSORIES','HEAD_ITEMS','DRESS_PALETTES','SCARF_PALETTES'}
ns={'Image':Image,'ImageDraw':ImageDraw,'math':math}
for node in source.body:
 if isinstance(node,ast.FunctionDef) and node.name in ['tiny_heart','head_piece'] or isinstance(node,ast.Assign) and any(isinstance(t,ast.Name) and t.id in keep for t in node.targets):
  exec(compile(ast.Module(body=[node],type_ignores=[]),'accessory_art','exec'),ns)
atlas=Image.open(A/'atlas.png').convert('RGBA');names=json.loads((A/'atlas.json').read_text())
def save(name,im):
 global atlas
 index=names.setdefault(name,len(names));bottom=(index//16+1)*48
 if bottom>atlas.height:
  grown=Image.new('RGBA',(512,bottom));grown.paste(atlas,(0,0));atlas=grown
 box=(index%16*32,index//16*48);atlas.paste(im,box)
def face_shape(face,b):
 sign=1 if face in [5,7] else -1
 # Three-quarter oval stays behind the front rim of the scarf.
 points=[(16,16),(20,16),(22,18),(23,21),(22,25),(20,27),(16,27),(14,25),(13,21),(14,18)]
 return [(x if sign>0 else 32-x,y+b) for x,y in points]

def hero(face,frame):
 im=Image.new('RGBA',(32,48));d=ImageDraw.Draw(im)
 right=face in [5,7];front=face in [6,7];sign=1 if right else -1
 b=[0,1,0,1][frame];sway=[0,1,0,-1][frame]*sign;step=[0,2,0,-2][frame]
 # Far sleeve/foot, asymmetric skirt and folds make a three-quarter silhouette.
 d.rectangle((11-sign*2+step//2,41,15-sign*2+step//2,45),fill='#29293f')
 d.rectangle((17+sign*2-step//2,41,21+sign*2-step//2,44),fill='#403c58')
 d.polygon([(10,24+b),(22,24+b),(26+sway,43),(8+sway,44),(6+sway,42)],fill='#302d48')
 d.polygon([(12+sign,25+b),(20+sign,26+b),(23+sway,42),(11+sway,43)],fill='#55516c')
 d.line((12-sign,29+b,11+sway,40,10+sway,42),fill='#77718a')
 d.line((20+sign,28+b,21+sway,35,24+sway,42),fill='#403c58',width=2)
 d.line((8+sway,43,16+sway,44,25+sway,42),fill='#bd9eaf')
 # Back of hood is broader; the face is shifted toward travel, never a side flip.
 d.rounded_rectangle((6,7+b,26,29+b),8,fill='#65576d')
 d.polygon([(7,16+b),(24,15+b),(27+sign,33+b),(17-sign,30+b),(5+sign,32+b)],fill='#8e7c90')
 d.line((8+sign,13+b,15+sign,9+b,22+sign,12+b),fill='#c7b0be',width=2)
 d.line((9-sign,19+b,8-sign,26+b,7,29+b),fill='#65576d')
 if front:
  d.polygon(face_shape(face,b),fill='#d6a383',outline='#8e7c90')
 else:
  # Small cheek on the far edge and a hood seam distinguish NW/NE from north.
  x=24 if sign>0 else 7
  d.line((x,19+b,x,25+b),fill='#d6a383',width=2)
  d.line((15+sign,14+b,17+sign,27+b),fill='#b29baa')
  d.line((12+sign,30+b,15+sign,33+b,17+sign,38+b),fill='#77718a')
 near_x=23 if sign>0 else 6;far_x=7 if sign>0 else 23
 d.rectangle((far_x,29+b-step//2,far_x+2,33+b-step//2),fill='#4a435d')
 d.rectangle((near_x,30+b+step//2,near_x+3,35+b+step//2),fill='#4a435d')
 d.point((23+sign,12+b),fill='#f3d19c')
 return im

def wear(item,face,frame,base):
 im=Image.new('RGBA',(32,48));d=ImageDraw.Draw(im);b=frame%2;sign=1 if face in [5,7] else -1;front=face in [6,7]
 palette=ns['DRESS_PALETTES'].get(item) or ns['SCARF_PALETTES'].get(item)
 if palette:
  palette={tuple(bytes.fromhex(k)):tuple(bytes.fromhex(v)) for k,v in palette.items()}
  for y in range(48):
   for x in range(32):
    c=base.getpixel((x,y))
    if c[3] and c[:3] in palette:im.putpixel((x,y),palette[c[:3]]+(255,))
 elif item in ['veil','white_veil']:
  color='#d3cedb' if item=='white_veil' else '#4e4057'
  if front:
   d.polygon(face_shape(face,b),fill=color)
   left,right=(15,21) if sign>0 else (11,17)
   for x in [left,right-2]:d.rectangle((x,19+b,x+2,20+b),fill=(0,0,0,0))
  else:
   x=24 if sign>0 else 6;d.rectangle((x,19+b,x+1,26+b),fill=color)
 elif item in ns['HEAD_ITEMS']:
  tmp=Image.new('RGBA',(32,48));ns['head_piece'](ImageDraw.Draw(tmp),item,b)
  # Dedicated projected headpiece: narrowed around the turned hood, shifted one pixel.
  for y in range(24):
   for x in range(32):
    c=tmp.getpixel((x,y))
    if c[3]:im.putpixel((round(16+(x-16)*.88)+sign, y+(1 if x*sign<16*sign else 0)),c)
 elif item=='pink_watch':
  x=24 if sign>0 else 7;y=33+b+[0,1,0,-1][frame]
  d.rectangle((x-1,y,x+2,y+1),fill='#b36c94');d.rectangle((x,y-1,x+1,y+2),fill='#f0b1cc');d.point((x,y),fill='#fff1e5')
 return im

def cat(face,frame,idle=False):
 im=Image.new('RGBA',(32,48));d=ImageDraw.Draw(im)
 sign=1 if face in [5,7] else -1;front=face in [6,7]
 b=(frame%2) if not idle else 0;step=0 if idle else [0,2,0,-2][frame]
 outline='#574754';fur='#c9996e';light='#e7bf91';cream='#f4dcc0';stripe='#98684f'
 hx=16+sign*4;hy=(32 if front else 28)+b;bx=16-sign*2;by=34 if front else 36
 tx=bx-sign*7
 d.line((tx,by+2,tx-sign*3,by-1,tx-sign*2,by-7-b,tx+sign,by-9),fill=outline,width=3)
 d.line((tx,by+1,tx-sign*2,by-2,tx-sign,by-6-b),fill=fur,width=2)
 # Four separately placed paws alternate along the diagonal stride.
 for x,y,offset in [(bx-5,40,step),(bx+4,41,-step),(hx-4,41,-step),(hx+3,42,step)]:
  yy=y+offset//2;d.line((max(bx-4,min(bx+4,x)),by+1,x+1,yy-1),fill=fur,width=2);d.rectangle((x,yy-3,x+2,yy),fill=outline);d.rectangle((x,yy-2,x+2,yy-1),fill=cream)
 d.ellipse((bx-7,by-7-b,bx+7,by+6),fill=outline)
 d.ellipse((bx-6,by-7-b,bx+6,by+4),fill=fur)
 d.arc((bx-5,by-5,bx+5,by+4),10,160,fill=light,width=2)
 for x in [bx-3,bx+1]:d.line((x,by-6-b,x+sign,by-3-b),fill=stripe,width=2)
 d.polygon([(hx-6,hy-3),(hx-6,hy-10),(hx-2,hy-7),(hx+3,hy-7),(hx+6,hy-10),(hx+6,hy-2)],fill=outline)
 d.ellipse((hx-6,hy-7,hx+6,hy+5),fill=outline);d.ellipse((hx-5,hy-7,hx+5,hy+3),fill=light)
 d.polygon([(hx-5,hy-7),(hx-5,hy-9),(hx-2,hy-6)],fill='#da9f9f');d.polygon([(hx+3,hy-7),(hx+5,hy-9),(hx+5,hy-6)],fill='#da9f9f')
 d.line((hx-sign,hy-6,hx,hy-3),fill=stripe)
 if front:
  d.ellipse((hx-2+sign,hy,hx+3+sign,hy+3),fill=cream)
  for x in [hx-2+sign,hx+3+sign]:
   if idle and frame==2:d.line((x,hy-1,x+1,hy-1),fill=outline)
   else:d.point((x,hy-1),fill='#37473e');d.point((x,hy-2),fill='#fff1d2')
  d.point((hx+sign,hy+1),fill='#c57c8e');d.line((hx-6,hy,hx-3,hy+1),fill=cream);d.line((hx+4,hy+1,hx+7,hy),fill=cream)
 else:
  d.line((hx-3,hy-3,hx-1,hy-1),fill=stripe);d.line((hx+2,hy-3,hx+3,hy-1),fill=stripe)
 return im
for face in range(4,8):
 for frame in range(4):
  base=hero(face,frame);save(f'hero{face}_{frame}',base)
  for item in ns['ACCESSORIES']:save(f'wear_{item}_{face}_{frame}',wear(item,face,frame,base))
  save(f'cat_walk{face}_{frame}',cat(face,frame))
 for frame in range(3):save(f'cat_idle{face}_{frame}',cat(face,frame,True))
atlas.save(A/'atlas.png');(A/'atlas.json').write_text(json.dumps(names))
