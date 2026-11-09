from pathlib import Path
p=Path(__file__).resolve().parents[1]/'docs/index.html'
s=p.read_text()
marker='<!-- garden-recovery -->'
if marker not in s:
 s=s.replace('</body>', '''<!-- garden-recovery -->
<script>
(()=>{
 const canvas=document.getElementById('canvas');
 function recover(message){
  window.gardenHideLoading?.();
  if(document.getElementById('garden-recovery'))return;
  const box=document.createElement('div');box.id='garden-recovery';
  Object.assign(box.style,{position:'fixed',inset:'0',zIndex:'1000',background:'#242538',color:'#f5e3cf',display:'grid',placeContent:'center',textAlign:'center',padding:'32px',font:'18px sans-serif'});
  const text=document.createElement('p');text.textContent=window.gardenContent?.ui?.[message]?.text||'';box.append(text);
  const button=document.createElement('button');button.textContent=window.gardenContent?.ui?.recovery_return?.text||' ';button.onclick=()=>location.reload();
  Object.assign(button.style,{padding:'16px',background:'#70536e',color:'#f5e3cf',border:'1px solid #e5a6bd',borderRadius:'12px',font:'18px sans-serif'});box.append(button);document.body.append(box);
 }
 canvas.addEventListener('webglcontextlost',()=>recover('recovery_context_lost'));
 const notice=document.getElementById('status-notice');
 if(notice)new MutationObserver(()=>{if(notice.textContent.trim())recover('recovery_load_failed');}).observe(notice,{childList:true,subtree:true});
})();
</script>
</body>''')
 p.write_text(s)

import json, shutil
root=p.parent.parent
content=json.loads((root/'content/letters.json').read_text())
shutil.copyfile(root/'tools/mobile_shell.js',p.parent/'mobile.js')
manifest={"name":content["game_title"],"short_name":content["app_short_name"],"id":"./","start_url":"./","scope":"./","display":"fullscreen","orientation":"portrait","background_color":"#242538","theme_color":"#242538","icons":[{"src":"index.apple-touch-icon.png","sizes":"180x180","type":"image/png"}]}
(p.parent/'manifest.webmanifest').write_text(json.dumps(manifest,ensure_ascii=False))
s=p.read_text()
if 'mobile.js' not in s:
 s=s.replace('</head>','<link rel="manifest" href="manifest.webmanifest"><meta name="apple-mobile-web-app-capable" content="yes"><meta name="apple-mobile-web-app-status-bar-style" content="black-translucent"><script src="mobile.js"></script></head>')
 s=s.replace('engine.startGame({','window.gardenLaunch.then(() => engine.startGame({').replace('}).then(() => {\n\t\t\tsetStatusMode', '})).then(() => {\n\t\t\tsetStatusMode')
 p.write_text(s)

import html
credits=(root/'assets/SFX-CREDITS.md').read_text()
(p.parent/'audio-credits.html').write_text('<!doctype html><html lang="ru"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(content['ui']['audio_credits']['text'])+'</title><style>body{max-width:740px;margin:40px auto;padding:20px;background:#242538;color:#f5e3cf;font:16px/1.7 sans-serif}pre{white-space:pre-wrap;word-break:break-word}a{color:#e5a6bd}</style><a href="./">'+html.escape(content['ui']['credits_return']['text'])+'</a><pre>'+html.escape(credits)+'</pre></html>')

# Fit the canvas itself, leaving the page-colored area outside Godot.
s=p.read_text().replace('"canvasResizePolicy":2','"canvasResizePolicy":0')
s=s.replace('<canvas id="canvas"','<canvas width="540" height="960" id="canvas"')
s=s.replace('</head>','<style>html,body{background:#242538!important}#status-splash{display:none!important}#canvas{position:fixed!important;left:50%!important;top:50%!important;transform:translate(-50%,-50%);width:min(100vw,56.25dvh)!important;height:min(100dvh,177.777778vw)!important;margin:0!important;display:block}</style></head>')
p.write_text(s)

# Do not flash a baked title while live content is loading.
import re
p.write_text(re.sub(r"<title>.*?</title>","<title></title>",p.read_text(),flags=re.S))

# Versioned entrypoints prevent mixing a new JSON schema with an old cached game.
import hashlib
pack=p.parent/'index.pck'
version=hashlib.sha256(pack.read_bytes()).hexdigest()[:12]
name='game.'+version+'.pck'
for old in p.parent.glob('game.*.pck'):
 if old.name!=name:old.unlink()
shutil.copyfile(pack,p.parent/name)
s=p.read_text()
match=re.search(r'const GODOT_CONFIG = (\{.*?\});',s)
config=json.loads(match.group(1));config['mainPack']=name;config['fileSizes'][name]=pack.stat().st_size
s=s[:match.start(1)]+json.dumps(config,separators=(',',':'))+s[match.end(1):]
js_version=hashlib.sha256((p.parent/'mobile.js').read_bytes()).hexdigest()[:12]
s=re.sub(r'<script src="mobile\.js(?:\?[^"]*)?"></script>','<script src="mobile.js?v='+js_version+'"></script>',s)
p.write_text(s)
