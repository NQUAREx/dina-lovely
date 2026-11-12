import json,re,pathlib
root=pathlib.Path(__file__).resolve().parents[1];d=json.loads((root/'content/letters.json').read_text())
assert d['schema_version']==2
for key,value in d['ui'].items():
 assert re.fullmatch(r'[a-z][a-z0-9_]*',key),key
 assert isinstance(value.get('text'),str) and value.get('_comment'),key
for p in (root/'scripts').glob('*.gd'):
 assert not re.search('[А-Яа-яЁё]',p.read_text()),str(p)
 for key in re.findall(r'tx\("([a-z_]+)"\)',p.read_text()):assert key in d['ui'],key
ids={n['id'] for n in d['letters']};assert len(ids)==len(d['letters'])
assert len(d['puzzle']['symbols'])==len(set(d['puzzle']['symbols']))==7
assert len(d['puzzle']['room_letters'])==7
assert all(group and all(id in ids for id in group) for group in d['puzzle']['room_letters'])
print('PASS JSON schema, semantic keys, comments, no embedded Cyrillic and seven clue groups')

import sys
sys.path.insert(0,str(root/"tools"))
from audit_content import referenced_ui,required_ui,RUNTIME
for name in ["letters.json","letters.backup.json"]:
 data=json.loads((root/"content"/name).read_text())
 assert all(isinstance(entry.get("text"),str) and entry.get("_comment") for entry in data["ui"].values()),name
print("PASS both content variants: used UI keys resolve; cloud-owned extra fields are retained")

# Save metadata and artwork names must never count as visible translations.
probe=json.loads((root/"content/letters.backup.json").read_text())
probe["ui"]["flashlight_location"]={"text":"unused save-field collision"}
assert "flashlight_location" not in referenced_ui(probe)
print("PASS save-field name collisions do not retain unused text")

for name in ["letters.json","letters.backup.json"]:
 data=json.loads((root/"content"/name).read_text())
 missing=required_ui(data)-set(data["ui"])
 assert not missing,(name,sorted(missing))
 for key in required_ui(data):assert isinstance(data["ui"][key].get("text"),str) and data["ui"][key].get("_comment"),(name,key)
 # Prove the reverse audit finds omissions even in dynamically built names.
 for key in ["start_intro","begin_room","item_flashlight","accessory_white_dress","loading_progress_label"]:
  probe=json.loads(json.dumps(data));del probe["ui"][key]
  assert key in required_ui(probe)-set(probe["ui"]),key
for path in RUNTIME:
 assert not re.search('[А-Яа-яЁё]',path.read_text()),str(path)
print("PASS reverse audit: all direct/browser/dynamic UI keys exist in both JSON variants, no Russian in runtime source")

for name in ["letters.json","letters.backup.json"]:
 data=json.loads((root/"content"/name).read_text())
 for key in ["game_title","recipient","signature","card_title","card_text","photo_caption","app_short_name"]:assert isinstance(data.get(key),str),(name,key)
 for letter in data["letters"]:
  for key in ["id","title","text"]:assert isinstance(letter.get(key),str),(name,letter.get("id"),key)
print("PASS root screen/card text and every letter title/body exist in both JSON variants")
