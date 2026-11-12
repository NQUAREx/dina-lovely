"""Audit displayed UI copy, separating translations from save fields and artwork IDs."""
from pathlib import Path
import json
import re
ROOT=Path(__file__).resolve().parents[1]
RUNTIME=list((ROOT/'scripts').glob('*.gd'))+[ROOT/'tools/mobile_shell.js',ROOT/'tools/finalize_web.py',ROOT/'tools/asset_loader.js']
STRINGS=re.compile(r'''"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*' ''',re.X)
def literals(text):
 return {match.group()[1:-1] for match in STRINGS.finditer(text)}
def calls(text):
 """Read complete tx arguments, including conditionals and nested expressions."""
 for match in re.finditer(r'\btx\s*\(',text):
  start=match.end();i=start;depth=1
  while i<len(text) and depth:
   string=STRINGS.match(text,i)
   if string:i=string.end();continue
   if text[i]=='(':depth+=1
   elif text[i]==')':depth-=1
   i+=1
  yield text[start:i-1]
def required_ui(data):
 used=set()
 for path in RUNTIME:
  text=path.read_text()
  if path.suffix=='.gd':
   # Property access such as save_data.flashlight_location is not UI usage.
   for expression in calls(text):used.update(key for key in literals(expression) if re.fullmatch(r"[a-z][a-z0-9_]*",key) and not key.endswith("_"))
   for titles in re.findall(r'const TITLES\s*:?=\s*(\[[^\]]*\])',text):used.update(literals(titles))
  else:
   # Browser copy includes t/copy/add, loading arrays, recovery callbacks and credits HTML.
   used.update(re.findall(r"\b(?:t|copy|recover)\(\s*['\"]([a-z][a-z0-9_]+)['\"]",text))
   used.update(re.findall(r"\badd\(\s*['\"][a-z0-9]+['\"]\s*,\s*['\"]([a-z][a-z0-9_]+)['\"]",text))
   for values in re.findall(r'for\(const key of (\[[^\]]*\])\)add',text):used.update(literals(values))
   used.update(re.findall(r'\.ui\?\.([a-z_]+)',text))
   used.update(re.findall(r"content\[['\"]ui['\"]\]\[['\"]([a-z_]+)['\"]\]",text))
 # Enumerate the actual domains of dynamic lookups, not every literal in the codebase.
 domains={
  'item_':['can','rake','fertilizer','shovel','flashlight','well','axe','shears','drill','cat_hut','cat_fish','pet_cat','stats_stone'],
  'pickup_':['axe','shears','drill'],
  'weapon_':['sword','rifle','rpg'],
  'symbol_':data['puzzle']['symbols'],
 }
 game=(ROOT/'scripts/game.gd').read_text()
 slots=re.search(r'const ACCESSORY_SLOTS\s*:?=\s*(\{[^\n]+\})',game)
 domains['accessory_']=re.findall(r'"([a-z_]+)"\s*:',slots.group(1))
 for prefix,values in domains.items():used.update(prefix+value for value in values)
 used.update(data.get('loading_phrases',[]))
 return used

def referenced_ui(data):return required_ui(data)&set(data["ui"])
if __name__=='__main__':
 for name in ['letters.json','letters.backup.json']:
  data=json.loads((ROOT/'content'/name).read_text())
  unused=set(data['ui'])-referenced_ui(data)
  missing=required_ui(data)-set(data['ui'])
  print(name,'unused:',len(unused),', '.join(sorted(unused)),'missing:',sorted(missing))
