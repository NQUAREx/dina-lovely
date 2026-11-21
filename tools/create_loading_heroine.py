"""Browser loading walk from the exact eight-frame game wardrobe and hand grips."""
from pathlib import Path
from PIL import Image
import json
R=Path(__file__).resolve().parents[1];A=R/'assets'
def generate():
 atlas=Image.open(A/'atlas.png').convert('RGBA');ids=json.loads((A/'atlas.json').read_text());grips=json.loads((A/'hand_grips.json').read_text())
 def sprite(name):
  i=ids[name];return atlas.crop((i%16*32,i//16*48,i%16*32+32,i//16*48+48))
 strip=Image.new('RGBA',(64*8,64))
 for frame in range(8):
  tile=Image.new('RGBA',(64,64));origin=(16,8)
  for name in [f'hero3_{frame}',f'wear_white_dress_3_{frame}',f'wear_white_scarf_3_{frame}',f'wear_white_veil_3_{frame}',f'wear_silver_crown_3_{frame}']:
   tile.alpha_composite(sprite(name),origin)
  # Same weapon art/grip as the game, displayed at .6 of body source scale.
  sword=sprite('weapon_sword').resize((19,29),Image.Resampling.NEAREST).transpose(Image.Transpose.ROTATE_270)
  hand=grips[f'3:{frame}'];tile.alpha_composite(sword,(round(origin[0]+hand[0]-5),round(origin[1]+hand[1]-9)))
  strip.alpha_composite(tile,(frame*64,0))
 strip.save(A/'loading_heroine.png')
 # Resident frame images avoid WebKit culling a strip translated out of its clip.
 for frame in range(8):
  strip.crop((frame*64,0,(frame+1)*64,64)).save(A/f'loading_heroine_{frame}.png')
 print('Generated eight side-walk frames: white dress/veil/scarf, silver crown, sword')
if __name__=='__main__':generate()
