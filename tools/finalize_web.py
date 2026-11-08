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
