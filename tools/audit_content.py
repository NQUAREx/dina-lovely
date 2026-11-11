"""Find unused UI copy, including runtime-built names and browser recovery copy."""
from pathlib import Path
import json
import re
ROOT=Path(__file__).resolve().parents[1]
RUNTIME=list((ROOT/'scripts').glob('*.gd'))+[ROOT/'tools/mobile_shell.js',ROOT/'tools/finalize_web.py',ROOT/'tools/asset_loader.js']
def referenced_ui(data):
 text='\n'.join(path.read_text() for path in RUNTIME)
 keys=set(data['ui'])
 # Property access in generated browser recovery HTML is a real reference too.
 used={key for key in keys if re.search(r'(?<![a-zA-Z0-9_])'+re.escape(key)+r'(?![a-zA-Z0-9_])',text)}
 literals=set(re.findall(r'''["']([a-z][a-z0-9_]*)["']''',text))
 for prefix in ['item_','pickup_','weapon_','symbol_','accessory_']:
  used.update((prefix+part) for part in literals|set(data['puzzle']['symbols']) if prefix+part in keys)
 used.update(data.get('loading_phrases',[]))
 return used
if __name__=='__main__':
 for name in ['letters.json','letters.backup.json']:
  data=json.loads((ROOT/'content'/name).read_text())
  unused=set(data['ui'])-referenced_ui(data)
  print(name, 'unused:',len(unused),', '.join(sorted(unused)))
