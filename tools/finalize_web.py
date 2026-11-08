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
  if(document.getElementById('garden-recovery'))return;
  const box=document.createElement('div');box.id='garden-recovery';
  Object.assign(box.style,{position:'fixed',inset:'0',zIndex:'1000',background:'#242538',color:'#f5e3cf',display:'grid',placeContent:'center',textAlign:'center',padding:'32px',font:'18px sans-serif'});
  const text=document.createElement('p');text.textContent=message;box.append(text);
  const button=document.createElement('button');button.textContent='Вернуться в сад';button.onclick=()=>location.reload();
  Object.assign(button.style,{padding:'16px',background:'#70536e',color:'#f5e3cf',border:'1px solid #e5a6bd',borderRadius:'12px',font:'18px sans-serif'});box.append(button);document.body.append(box);
 }
 canvas.addEventListener('webglcontextlost',()=>recover('Браузер приостановил графику. Перезапусти сад — сохранённые письма останутся с тобой.'));
 const notice=document.getElementById('status-notice');
 if(notice)new MutationObserver(()=>{if(notice.textContent.trim())recover('Не удалось загрузить сад. Проверь соединение и поддержку WebGL 2 в браузере, затем попробуй снова.');}).observe(notice,{childList:true,subtree:true});
})();
</script>
</body>''')
 p.write_text(s)

import json, shutil
root=p.parent.parent
shutil.copyfile(root/'tools/mobile_shell.js',p.parent/'mobile.js')
manifest={"name":"Тебе. От меня.","short_name":"Наш сад","id":"./","start_url":"./","scope":"./","display":"fullscreen","orientation":"portrait","background_color":"#242538","theme_color":"#242538","icons":[{"src":"index.apple-touch-icon.png","sizes":"180x180","type":"image/png"}]}
(p.parent/'manifest.webmanifest').write_text(json.dumps(manifest,ensure_ascii=False))
s=p.read_text()
if 'mobile.js' not in s:
 s=s.replace('</head>','<link rel="manifest" href="manifest.webmanifest"><meta name="apple-mobile-web-app-capable" content="yes"><meta name="apple-mobile-web-app-status-bar-style" content="black-translucent"><script src="mobile.js"></script></head>')
 s=s.replace('engine.startGame({','window.gardenLaunch.then(() => engine.startGame({').replace('}).then(() => {\n\t\t\tsetStatusMode', '})).then(() => {\n\t\t\tsetStatusMode')
 p.write_text(s)

import html
credits=(root/'assets/SFX-CREDITS.md').read_text()
(p.parent/'audio-credits.html').write_text('<!doctype html><html lang="ru"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Sound credits</title><style>body{max-width:740px;margin:40px auto;padding:20px;background:#242538;color:#f5e3cf;font:16px/1.7 sans-serif}pre{white-space:pre-wrap;word-break:break-word}a{color:#e5a6bd}</style><a href="./">Вернуться к игре</a><pre>'+html.escape(credits)+'</pre></html>')
