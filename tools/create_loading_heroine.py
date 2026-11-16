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
 # Native animated images do not need video autoplay, seek at every loop,
 # CSS stepping, or an opaque media surface. Reserve one transparent index
 # in one shared palette so the original wallpaper remains visible.
 palette=strip.convert('RGB').quantize(colors=255,method=Image.Quantize.MEDIANCUT)
 frames=[]
 for frame in range(8):
  rgba=strip.crop((frame*64,0,(frame+1)*64,64)).resize((128,128),Image.Resampling.NEAREST)
  tile=rgba.convert('RGB').quantize(palette=palette,dither=Image.Dither.NONE)
  alpha=rgba.getchannel('A')
  tile.paste(255,mask=alpha.point(lambda value:255 if value<128 else 0))
  tile.info['transparency']=255
  frames.append(tile)
 frames[0].save(A/'loading_heroine.gif',save_all=True,append_images=frames[1:],
                duration=80,loop=0,transparency=255,disposal=2,optimize=False)
 (A/'loading_heroine.mp4').unlink(missing_ok=True)
 print('Generated eight side-walk frames: white dress/veil/scarf, silver crown, sword')
if __name__=='__main__':generate()
