from pathlib import Path
from PIL import Image
import json,hashlib
root=Path(__file__).resolve().parents[1];a=root/'assets'
ids=json.loads((a/'atlas.json').read_text());atlas=Image.open(a/'atlas.png').convert('RGBA')
for base in ['tree','tree_apples']:
 forms=[]
 for n in range(6):
  i=ids[f'{base}_variant{n}'];s=atlas.crop((i%16*32,i//16*48,i%16*32+32,i//16*48+48))
  forms.append(hashlib.sha256(s.getchannel('A').tobytes()).digest())
 assert len(set(forms))==6,'Tree variants need different silhouettes'
for base in ['hedge_tree','hedge_tree_apples']:
 assert all((a/f'{base}_variant{n}.png').exists() for n in range(6))
i=ids['gate_ajar'];s=atlas.crop((i%16*32,i//16*48+16,i%16*32+32,i//16*48+48))
assert not any(c[3] and c[:3]==(80,62,86) for c in s.getdata()),'Opaque backing between open gate bars'
assert sum(c[3]==0 for c in s.getdata())>800
print('PASS six unique tree silhouettes, integrated variants and transparent open gate')
