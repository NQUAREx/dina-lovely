(()=>{
 const ios=/iPhone|iPad|iPod/.test(navigator.userAgent)||(navigator.platform==='MacIntel'&&navigator.maxTouchPoints>1);
 const standalone=matchMedia('(display-mode: standalone)').matches||matchMedia('(display-mode: fullscreen)').matches||navigator.standalone;
 const mobile=ios||/Android/.test(navigator.userAgent);
 window.gardenHaptic=ms=>{if(!ios&&typeof navigator.vibrate==='function')navigator.vibrate(ms);};
 const suspend=()=>window.gardenSuspended=document.hidden||matchMedia("(orientation: landscape)").matches;
 addEventListener("resize",suspend);document.addEventListener("visibilitychange",suspend);suspend();
 let launch;window.gardenLaunch=new Promise(r=>launch=r);
 const style=document.createElement('style');style.textContent=`html,body{margin:0;background:#242538;overscroll-behavior:none;height:100%;touch-action:none}#mobile-gate,#portrait-gate{position:fixed;inset:0;z-index:2000;background:radial-gradient(ellipse at top,#55435d,#242538 75%);color:#f5e3cf;display:grid;place-content:center;padding:max(28px,env(safe-area-inset-top)) 28px max(28px,env(safe-area-inset-bottom));text-align:center;font:17px/1.6 Georgia,serif}#mobile-gate h1{font-size:32px;line-height:1.2;color:#edbdce}#mobile-gate button{padding:18px 28px;border:1px solid #df9eb9;border-radius:18px;color:#fff0dc;background:#76556f;font:18px Georgia;margin-top:24px}#mobile-gate ol{text-align:left;max-width:340px}#portrait-gate{display:none;font-size:24px;z-index:3000}@media(orientation:landscape){#portrait-gate{display:grid}}canvas{touch-action:none}`;document.head.append(style);
 addEventListener('DOMContentLoaded',()=>{
  const gate=document.createElement('section');gate.id='mobile-gate';
  if(!mobile)gate.innerHTML='<h1>Этот сад — в твоём телефоне</h1><p>Открой эту же ссылку на смартфоне.<br>Игра создана для вертикального экрана и касаний.</p>';
  else if(ios&&!standalone)gate.innerHTML='<h1>Сохрани наш сад</h1><p>Открой его как маленькое приложение — без панелей Safari.</p><ol><li>Нажми «Поделиться» в Safari.</li><li>Выбери «На экран Домой».</li><li>Включи «Открывать как веб-приложение», если этот переключатель показан.</li><li>Открой сад через новую иконку.</li></ol><p>После этого начнётся путешествие.</p>';
  else {
   gate.innerHTML='<h1>Тебе. От меня.</h1><p>Я оставил здесь несколько записок.<br>Осталось их найти.</p><button>Войти в сад</button>';
   gate.querySelector('button').onclick=async()=>{
    try{if(!document.fullscreenElement&&document.documentElement.requestFullscreen)await document.documentElement.requestFullscreen();}catch(e){}
    try{if(screen.orientation?.lock)await screen.orientation.lock('portrait');}catch(e){}
    gate.remove();launch();
   };
  }
  document.body.append(gate);
  const rotate=document.createElement('div');rotate.id='portrait-gate';rotate.textContent='↻ Верни телефон вертикально';if(!mobile)rotate.style.display='none';document.body.append(rotate);
 });
 addEventListener('pointerdown',()=>{if(mobile&&!ios&&!document.fullscreenElement&&document.documentElement.requestFullscreen)document.documentElement.requestFullscreen().catch(()=>{});},{passive:true});
})();
