"""Game-native button icons: existing atlas art on a strict 2px UI grid."""
from pathlib import Path
import json
from PIL import Image, ImageDraw
from create_ui_frames import generate
ROOT=Path(__file__).resolve().parents[1]
A=ROOT/'assets'/'ui';A.mkdir(exist_ok=True)
generate()
ATLAS=Image.open(ROOT/'assets/atlas.png').convert('RGBA')
IDS=json.loads((ROOT/'assets/atlas.json').read_text())
# Every semantic action keeps its resource name, while the drawing comes from
# the same items that the player sees in the world. No smooth vector symbols.
SOURCES={
 'dig':'shovel','axe':'axe','pickaxe':'pickaxe','craft':'quest_bench',
 'repair':'shovel_broken','water':'can','fill':'can','rake':'rake',
 'fertilizer':'fertilizer','grow':'bloom0','seed':'seedling0_plant',
 'shears':'shears','drill':'drill','letter':'note','book':'secret_book',
 'stats':'stats_stone','key':'gate_key','gate':'gate_panel','chest':'chest',
 'rune':'rune_sun','reset':'rune_reset','wear':'accessory_silver_crown',
 'sit':'bench','stand':'hero3_0','swing':'swing','apple':'tree_apples',
 'berries':'berries','fish':'cat_fish','feed':'cat_fish','pet':'cat_paw',
 'cat':'cat_sit0','skull':'skull_relic','insert_skull':'skull_stand_full',
 'write':'note_open','medkit':'medkit','take':'reply_hand_white_dress',
 'flashlight':'flashlight','attack':'weapon_sword','material':'quest_branch'}
def tile(name):
 i=IDS[name]
 return ATLAS.crop((i%16*32,i//16*48,i%16*32+32,i//16*48+48))
def apple():
 # Actual fruit pixels taken from the former game apple canopy, without leaves.
 # The source snapshot is stable while tree perspective is being redesigned.
 p=ROOT/'tools/art_source/tree_palette/atlas_hedge_tree_apples.png'
 im=Image.open(p).convert('RGBA') if p.exists() else tile('tree_apples')
 mask=Image.new('L',im.size)
 for y in range(im.height):
  for x in range(im.width):
   r,g,b,a=im.getpixel((x,y))
   if a and r>g*1.12 and r>b*1.04 and r>115:mask.putpixel((x,y),255)
 # Pick a whole connected fruit cluster, not the union of dispersed apples.
 points={(x,y) for y in range(im.height) for x in range(im.width) if mask.getpixel((x,y))}
 clusters=[]
 while points:
  seed=points.pop();todo=[seed];component=[seed]
  while todo:
   x,y=todo.pop()
   for q in [(x-1,y),(x+1,y),(x,y-1),(x,y+1)]:
    if q in points:points.remove(q);todo.append(q);component.append(q)
  clusters.append(component)
 if not clusters:return tile('berries')
 c=max(clusters,key=len);xs=[p[0] for p in c];ys=[p[1] for p in c]
 box=(max(0,min(xs)-1),max(0,min(ys)-1),min(im.width,max(xs)+2),min(im.height,max(ys)+2))
 result=Image.new('RGBA',im.size)
 for q in c:result.putpixel(q,im.getpixel(q))
 return result.crop(box)
def icon(source,name):
 art=apple() if name=='apple' else tile(source)
 box=art.getbbox()
 if box:art=art.crop(box)
 # 16 source UI pixels, displayed as32. All final opaque pixel clusters are2x2.
 limit=14
 ratio=min(limit/art.width,limit/art.height)
 size=(max(1,round(art.width*ratio)),max(1,round(art.height*ratio)))
 art=art.resize(size,Image.Resampling.NEAREST)
 im=Image.new('RGBA',(16,16));im.alpha_composite(art,((16-art.width)//2,(16-art.height)//2))
 d=ImageDraw.Draw(im)
 if name=='fill':
  # Water is the only semantic addition: three square drops above the game can.
  for x,y in [(3,1),(6,0),(9,1)]:d.rectangle((x,y,x,y+1),fill='#aac8c8')
 elif name=='feed':d.line((2,14,13,14),fill='#d3b9a0',width=1)
 elif name=='pet':
  d.polygon([(9,1),(10,0),(12,1),(13,0),(14,1),(14,3),(12,5),(9,3)],fill='#d5a5b3')
 return im.resize((32,32),Image.Resampling.NEAREST)
for name,source in SOURCES.items():icon(source,name).save(A/f'action_{name}.png')
print('Generated',len(SOURCES),'game-atlas action icons on a2px grid')
