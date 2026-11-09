(()=>{
 const ios=/iPhone|iPad|iPod/.test(navigator.userAgent)||(navigator.platform==='MacIntel'&&navigator.maxTouchPoints>1);
 const standalone=matchMedia('(display-mode: standalone)').matches||matchMedia('(display-mode: fullscreen)').matches||navigator.standalone;
 const mobile=ios||/Android/.test(navigator.userAgent);
 window.gardenHaptic=ms=>{if(!ios&&typeof navigator.vibrate==='function')navigator.vibrate(ms);};
 const suspend=()=>window.gardenSuspended=document.hidden||matchMedia("(orientation: landscape)").matches;
 addEventListener("resize",suspend);document.addEventListener("visibilitychange",suspend);suspend();
 const liveContent=fetch('https://raw.githubusercontent.com/NQUAREx/dina-lovely/main/content/letters.json?fresh='+Date.now(),{cache:'no-store',signal:AbortSignal.timeout(8000)}).then(r=>{if(!r.ok)throw Error(r.status);return r.json()}).then(d=>{if(d.schema_version!==2||!Array.isArray(d.letters)||d.puzzle?.symbols?.length!==7||d.puzzle?.room_letters?.length!==7||!d.ui?.read_letter||typeof d.ui.read_letter.text!=='string')throw Error('Invalid content schema');window.gardenContent=d;return d;}).catch(()=>null);
 let launch;window.gardenLaunch=new Promise(r=>launch=r);
 const style=document.createElement('style');style.textContent=`html,body{margin:0;background:#242538;overscroll-behavior:none;height:100%;touch-action:none}#mobile-gate,#portrait-gate{position:fixed;inset:0;z-index:2000;background:radial-gradient(ellipse at top,#55435d,#242538 75%);color:#f5e3cf;display:grid;place-content:center;padding:max(28px,env(safe-area-inset-top)) 28px max(28px,env(safe-area-inset-bottom));text-align:center;font:17px/1.6 Georgia,serif}#mobile-gate h1{font-size:32px;line-height:1.2;color:#edbdce}#mobile-gate button{padding:18px 28px;border:1px solid #df9eb9;border-radius:18px;color:#fff0dc;background:#76556f;font:18px Georgia;margin-top:24px}#mobile-gate ol{text-align:left;max-width:340px}#portrait-gate{display:none;font-size:24px;z-index:3000}@media(orientation:landscape){#portrait-gate{display:grid}}canvas{touch-action:none}`;document.head.append(style);
 addEventListener('DOMContentLoaded',async()=>{
  const loaded=await liveContent;
  if(!loaded){const retry=document.createElement('button');retry.textContent='↻';retry.style.cssText='position:fixed;left:45%;top:45%;font-size:48px;background:transparent;color:#edbdce;border:0';retry.onclick=()=>location.reload();document.body.append(retry);return;}
  const t=key=>loaded.ui?.[key]?.text||'';
  let loadingTimer=null;
  window.gardenHideLoading=()=>{clearInterval(loadingTimer);document.getElementById('garden-loading')?.remove();};
  window.gardenShowLoading=()=>{
   window.gardenHideLoading();const screen=document.createElement('section');screen.id='garden-loading';
   screen.style.cssText='position:fixed;inset:0;z-index:1900;background:radial-gradient(ellipse at top,#55435d,#242538 75%);display:grid;place-content:center;text-align:center;padding:32px;color:#f5e3cf;font:20px/1.6 Georgia';
   const sprout=document.createElement('div');sprout.textContent='✦';sprout.style.cssText='font-size:52px;color:#e5a6bd;animation:garden-pulse 1.2s ease-in-out infinite alternate';screen.append(sprout);
   const phrase=document.createElement('p');screen.append(phrase);const keys=loaded.loading_phrases||[];let index=Math.floor(Math.random()*keys.length);
   const update=()=>{phrase.textContent=t(keys[index++%keys.length]);};update();loadingTimer=setInterval(update,1300);document.body.append(screen);
  };
  const animation=document.createElement('style');animation.textContent='@keyframes garden-pulse{to{transform:scale(1.2) rotate(20deg);opacity:.5}}';document.head.append(animation);
  const gate=document.createElement('section');gate.id='mobile-gate';
  const add=(tag,key,parent=gate)=>{const node=document.createElement(tag);node.textContent=t(key);parent.append(node);return node;};
  if(!mobile){add('h1','desktop_title');add('p','desktop_open_phone');add('p','desktop_controls');}
  else if(ios&&!standalone){
   add('h1','install_title');add('p','install_description');const list=document.createElement('ol');gate.append(list);
   for(const key of ['install_share_step','install_home_step','install_mode_step','install_open_step'])add('li',key,list);
   add('p','install_done');
  }else{
   const heading=document.createElement('h1');heading.textContent=loaded.game_title;gate.append(heading);
   for(const key of ['launch_intro','launch_goal','launch_sound_title','launch_sound_detail','launch_ios_sound'])add('p',key);
   const button=add('button','launch_button');button.onclick=async()=>{
    try{if(!document.fullscreenElement&&document.documentElement.requestFullscreen)await document.documentElement.requestFullscreen();}catch(e){}
    try{if(screen.orientation?.lock)await screen.orientation.lock('portrait');}catch(e){}
    gate.remove();window.gardenShowLoading();launch();
   };
  }
  const credits=add('a','audio_credits');credits.href='audio-credits.html';credits.target='_blank';credits.rel='noopener';credits.style.cssText='color:#c3a7b8;font:12px sans-serif;margin-top:24px';
  document.title=loaded.game_title;document.body.append(gate);
  const rotate=document.createElement('div');rotate.id='portrait-gate';rotate.textContent=t('portrait_hint');if(!mobile)rotate.style.display='none';document.body.append(rotate);
 });
 addEventListener('pointerdown',()=>{if(mobile&&!ios&&!document.fullscreenElement&&document.documentElement.requestFullscreen)document.documentElement.requestFullscreen().catch(()=>{});},{passive:true});
})();
