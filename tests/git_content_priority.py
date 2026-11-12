"""Exercise content protection in disposable Git repositories, never the live checkout."""
from pathlib import Path
import tempfile,subprocess,json,importlib.util
root=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('sync_letters',root/'tools/sync_letters.py');sync=importlib.util.module_from_spec(spec);spec.loader.exec_module(sync)
def run(path,*args):return subprocess.run(['git',*args],cwd=path,check=True,capture_output=True,text=True)
def write(path,value):
 path.parent.mkdir(parents=True,exist_ok=True);path.write_text(json.dumps({'ui':{'sample':{'text':value,'_comment':'test'}}}))
with tempfile.TemporaryDirectory() as directory:
 base=Path(directory);remote=base/'remote.git';run(base,'init','--bare',str(remote))
 local=base/'local';run(base,'clone',str(remote),str(local));run(local,'checkout','-b','main')
 for path in [local]:run(path,'config','user.email','fixture@example.invalid');run(path,'config','user.name','Fixture')
 for name in sync.FILES:write(local/name,'base')
 run(local,'add','.');run(local,'commit','-m','base');run(local,'push','-u','origin','main')
 cloud=base/'cloud';run(base,'clone','-b','main',str(remote),str(cloud));run(cloud,'config','user.email','fixture@example.invalid');run(cloud,'config','user.name','Fixture')
 for name in sync.FILES:write(cloud/name,'cloud')
 run(cloud,'add','.');run(cloud,'commit','-m','cloud edit');run(cloud,'push')
 sync.ROOT=local
 for name in sync.FILES:write(local/name,'wrong local value')
 sync.sync()
 for name in sync.FILES:assert json.loads((local/name).read_text())['ui']['sample']['text']=='cloud'
 run(local,'update-index','--no-skip-worktree','--',*sync.FILES);run(local,'reset','--hard','origin/main');sync.setup()
 for name in sync.FILES:write(local/name,'accidental local edit')
 run(local,'add','-A');assert not run(local,'diff','--cached','--name-only','--',*sync.FILES).stdout
 run(local,'update-index','--no-skip-worktree','--',*sync.FILES);run(local,'add','--',*sync.FILES)
 try:sync.guarded('staged')
 except SystemExit:pass
 else:raise AssertionError('Staged content was not blocked')
 run(local,'commit','--no-verify','-m','simulate unsafe commit')
 try:sync.guarded('push')
 except SystemExit:pass
 else:raise AssertionError('Outgoing content was not blocked')
 print('PASS cloud content wins; skip-worktree excludes local changes from add -A; staged and outgoing overwrites blocked')
