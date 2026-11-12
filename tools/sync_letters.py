"""Keep GitHub-managed content authoritative and guard ordinary local publishing."""
from pathlib import Path
import argparse,json,os,subprocess,sys
ROOT=Path(__file__).resolve().parents[1]
FILES=['content/letters.json','content/letters.backup.json']
def git(*args,check=True):
 return subprocess.run(['git',*args],cwd=ROOT,text=True,capture_output=True,check=check)
def guarded(mode):
 if os.environ.get('GARDEN_CONTENT_SCHEMA_UPDATE')=='1':return
 if mode=='push':git('fetch','origin')
 if mode=='staged':changed=git('diff','--cached','--name-only','--',*FILES).stdout.splitlines()
 else:changed=git('diff','--name-only','origin/main','HEAD','--',*FILES).stdout.splitlines()
 if changed:raise SystemExit('Blocked local letters update. Edit cloud content on GitHub, then run python3 tools/sync_letters.py. Explicit schema updates require GARDEN_CONTENT_SCHEMA_UPDATE=1.')
def setup():
 git('config','core.hooksPath','.githooks')
 git('update-index','--skip-worktree','--',*FILES)
 print('Git hooks enabled; tracked letters protected from ordinary local staging.')
def sync(add_missing=False):
 templates={name:json.loads((ROOT/name).read_text()) for name in FILES} if add_missing else {}
 git('fetch','origin')
 # Fetch all files successfully before changing either working copy.
 cloud={name:json.loads(git('show','origin/main:'+name).stdout) for name in FILES}
 for name,data in cloud.items():
  if add_missing:
   for key,value in templates[name]['ui'].items():data['ui'].setdefault(key,value)
 git('update-index','--no-skip-worktree','--',*FILES)
 for name,data in cloud.items():(ROOT/name).write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
 if not add_missing:git('update-index','--skip-worktree','--',*FILES)
 print('Latest cloud letters copied locally. Existing cloud values preserved.')
if __name__=='__main__':
 parser=argparse.ArgumentParser(description=__doc__)
 parser.add_argument('--setup',action='store_true')
 parser.add_argument('--add-missing-ui',action='store_true',help='Explicit schema maintenance: only add absent UI keys from local templates.')
 parser.add_argument('--check-staged',action='store_true')
 parser.add_argument('--check-push',action='store_true')
 args=parser.parse_args()
 if args.check_staged:guarded('staged')
 elif args.check_push:guarded('push')
 elif args.setup:setup()
 else:sync(args.add_missing_ui)
