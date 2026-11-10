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
 window.addEventListener('garden-asset-error',()=>recover('recovery_load_failed'));
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
import hashlib
frame_hash=hashlib.sha256(b''.join((root/'assets'/f'frame_{part}_{room}.png').read_bytes() for room in range(7) for part in ['field','top','bottom'])).hexdigest()[:12]
from PIL import Image, ImageStat
# Sample the actual decorative field, rather than maintaining a separate palette.
frame_colors=[]
for room in range(7):
 with Image.open(root/'assets'/f'frame_field_{room}.png') as field:
  frame_colors.append([round(c) for c in ImageStat.Stat(field.convert('RGB')).mean])
(p.parent/'mobile.js').write_text((root/'tools/mobile_shell.js').read_text().replace('__FRAME_ART_HASH__',frame_hash).replace('__FRAME_COLORS__',json.dumps(frame_colors)))
shutil.copyfile(root/'assets/body.ttf',p.parent/'letter-body.ttf')
shutil.copyfile(root/'assets/title.ttf',p.parent/'letter-title.ttf')
from PIL import Image, ImageDraw
paper_image=Image.new("RGBA",(464,660))
paper_draw=ImageDraw.Draw(paper_image)
paper_draw.polygon([(0,4),(456,0),(464,656),(4,660)],fill="#fffaf1")
paper_draw.rectangle((15,16,449,644),outline="#d8c6b1",width=2)
paper_lines=Image.new("RGBA",paper_image.size)
line_draw=ImageDraw.Draw(paper_lines)
for y in range(145,580,29):line_draw.line((29,y,435,y),fill=(140,140,153,26),width=1)
paper_image=Image.alpha_composite(paper_image,paper_lines)
paper_image.save(p.parent/"reply-paper.png")
atlas_sprites=json.loads((root/'assets/atlas.json').read_text())
with Image.open(root/'assets/atlas.png') as atlas_image:
 for sprite_name,file_name in [('note','reply-envelope.png'),('note_open','reply-envelope-open.png')]:
  sprite_id=atlas_sprites[sprite_name];x=sprite_id%16*32;y=sprite_id//16*48
  atlas_image.crop((x,y,x+32,y+48)).save(p.parent/file_name)
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

# Forward measured download bytes to the mobile loading overlay, once.
s=p.read_text()
callback="window.gardenLoadProgress?.(current,total);"
s=re.sub(r"(?:\s*window\.gardenLoadProgress\?\.\(current,total\);)+", "\n\t\t\t\t"+callback, s)
if callback not in s:
 s=s.replace("'onProgress': function (current, total) {", "'onProgress': function (current, total) {\n\t\t\t\t"+callback)
p.write_text(s)

for frame_asset in ["frame_top.png","frame_bottom.png"] + [f"frame_{part}_{room}.png" for room in range(7) for part in ["top","bottom","field"]]:
 shutil.copyfile(root/"assets"/frame_asset,p.parent/frame_asset)

# Extend the existing decorative fields beneath the iOS status bar / sensor housing.
s=p.read_text()
s=re.sub(r'(<meta name="viewport" content=")[^"]*(")',r'\1width=device-width, user-scalable=no, initial-scale=1.0, viewport-fit=cover\2',s)
p.write_text(s)

# Lossless transport compression: all mechanics and WASM bytes remain identical.
import gzip
from patch_web_loader import patch_loader
wasm=p.parent/'index.wasm'
compressed=gzip.compress(wasm.read_bytes(),compresslevel=9,mtime=0)
wasm_name='engine.'+hashlib.sha256(compressed).hexdigest()[:12]+'.wasm.gz'
for old in p.parent.glob('engine.*.wasm.gz'):
 if old.name!=wasm_name:old.unlink()
(p.parent/wasm_name).write_bytes(compressed)
loader=(root/'tools/asset_loader.js').read_text().replace('__WASM_GZIP__',wasm_name)
(p.parent/'asset-loader.js').write_text(loader)
patch_loader(p.parent/'index.js')
s=p.read_text()
loader_version=hashlib.sha256(loader.encode()).hexdigest()[:12]
if 'asset-loader.js' not in s:
 s=s.replace('<script src="index.js"', '<script src="asset-loader.js?v='+loader_version+'"></script><script src="index.js"')
# Cache-bust the patched engine JS too; existing installed apps must not retain its old loader.
engine_version=hashlib.sha256((p.parent/'index.js').read_bytes()).hexdigest()[:12]
s=re.sub(r'<script src="index.js(?:\?[^"]*)?"', '<script src="index.js?v='+engine_version+'"',s)
p.write_text(s)
print('WASM transport:',wasm.stat().st_size,'->',len(compressed),'bytes')
