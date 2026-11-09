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
