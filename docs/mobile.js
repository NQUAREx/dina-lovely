(()=>{
 const frameArtVersion='c57621a051f2';
 // The same room palette also colors browser-owned areas where textures cannot render.
 const roomChromeColors=[[56, 32, 84], [12, 28, 47], [115, 72, 31], [111, 90, 65], [87, 22, 45], [34, 79, 86], [215, 188, 157]];
 let chromeColor=roomChromeColors[0].slice(),chromeAnimation=0;
 const paintChrome=color=>{
  const css='#'+color.map(v=>Math.round(v).toString(16).padStart(2,'0')).join('');
  const pageColor=document.getElementById('garden-loading')?'#242538':css;
  if(document.documentElement.style.backgroundColor!==pageColor)document.documentElement.style.setProperty('background-color',pageColor,'important');
  document.body?.style.setProperty('background-color',pageColor,'important');
  const theme=document.querySelector('meta[name="theme-color"]');if(theme&&theme.content!==pageColor)theme.content=pageColor;
 };
 const syncChrome=(room,animate=true)=>{
  cancelAnimationFrame(chromeAnimation);const from=chromeColor.slice(),to=roomChromeColors[room],start=performance.now();let painted=-100;
  const tick=now=>{const t=animate?Math.min(1,(now-start)/1100):1;const eased=t*t*(3-2*t);chromeColor=from.map((v,i)=>v+(to[i]-v)*eased);
   if(now-painted>=80||t===1){paintChrome(chromeColor);painted=now;}
   if(t<1)chromeAnimation=requestAnimationFrame(tick);
  };tick(start);
 };
 syncChrome(0,false);addEventListener('DOMContentLoaded',()=>paintChrome(chromeColor));
 const boot={stage:'download',since:performance.now(),events:[],loaded:0,total:0,resize:0};
 window.gardenBoot=boot;boot.assets={};boot.transfers={};
 window.gardenAssetBytes=(name,loaded,total)=>{boot.transfers[name]={loaded,total};boot.loaded=Object.values(boot.transfers).reduce((sum,t)=>sum+t.loaded,0);boot.total=Object.values(boot.transfers).reduce((sum,t)=>sum+t.total,0);const bar=document.getElementById('garden-progress');if(bar)bar.value=boot.total>0?boot.loaded/boot.total:0;};
 window.gardenAssetState=(name,done)=>{boot.assets[name]=done;window.gardenBootStage(Object.values(boot.assets).every(Boolean)?'compile':'download');};
 window.gardenBootStage=stage=>{if(boot.stage!==stage){boot.stage=stage;boot.since=performance.now();boot.events.push({stage,at:Math.round(performance.now())});}};
 addEventListener('resize',()=>boot.resize++);
 const frameAsset=(part,room)=>'frame_'+part+'_'+room+'.png?v='+frameArtVersion;
 // The document background also paints Safari's area outside fixed-position layers.
 const pageField=room=>{document.documentElement.style.setProperty('background-image','url('+frameAsset('field',room)+')','important');document.documentElement.style.backgroundSize='192px 192px';document.documentElement.style.imageRendering='pixelated';document.documentElement.style.minHeight='calc(100dvh + env(safe-area-inset-top,0px) + env(safe-area-inset-bottom,0px))';};
 pageField(0);
 const safeTint=document.createElement('div');safeTint.setAttribute('aria-hidden','true');safeTint.style.cssText='position:fixed;top:0;left:0;right:0;height:env(safe-area-inset-top,0px);z-index:41;background:rgba(16,18,30,.18);pointer-events:none';document.documentElement.append(safeTint);
 const frameSlots=[0,1].map(index=>{
  const field=document.createElement('div');field.setAttribute('aria-hidden','true');field.style.cssText='position:fixed;inset:calc(-1 * env(safe-area-inset-top,0px)) 0 calc(-1 * env(safe-area-inset-bottom,0px));z-index:0;pointer-events:none;image-rendering:pixelated;background-size:192px 192px;transition:opacity 1.1s ease;opacity:'+Number(index===0);field.style.backgroundImage='url('+frameAsset('field',0)+')';document.documentElement.append(field);
  const borders=['top','bottom'].map(edge=>{const image=document.createElement('img');image.src=frameAsset(edge,0);image.alt='';image.setAttribute('aria-hidden','true');image.style.cssText='position:fixed;z-index:40;pointer-events:none;image-rendering:pixelated;object-fit:fill;transition:opacity 1.1s ease;opacity:'+Number(index===0);document.documentElement.append(image);return image;});
  return {field,borders};
 });
 const layoutFrames=()=>{const canvas=document.getElementById('canvas');if(!canvas)return;canvas.style.zIndex='1';const r=canvas.getBoundingClientRect(),height=r.width*40/270;frameSlots.forEach(slot=>slot.borders.forEach((image,i)=>Object.assign(image.style,{left:r.left+'px',width:r.width+'px',height:height+'px',top:(i?r.bottom-height*.50:r.top-height*.60)+'px'})));};
 const loadedFrames=new Map();let activeFrame=0,wantedRoom=0,frameRequest=0,frameBusyUntil=0;window.gardenFrameRoom=0;
 const preloadFrame=room=>{if(!loadedFrames.has(room))loadedFrames.set(room,Promise.all(['field','top','bottom'].map(part=>new Promise(resolve=>{const image=new Image();image.onload=()=>resolve(true);image.onerror=()=>resolve(false);image.src=frameAsset(part,room);}))));return loadedFrames.get(room);};
 window.gardenSetRoom=async room=>{room=Math.max(0,Math.min(6,Math.trunc(Number(room)||0)));if(room===wantedRoom)return;wantedRoom=room;const request=++frameRequest;const loaded=await preloadFrame(room);if(request!==frameRequest||!loaded.every(Boolean))return;if(performance.now()<frameBusyUntil)await new Promise(resolve=>setTimeout(resolve,frameBusyUntil-performance.now()+20));if(request!==frameRequest)return;const next=1-activeFrame,slot=frameSlots[next];slot.field.style.backgroundImage='url('+frameAsset('field',room)+')';slot.borders.forEach((image,i)=>image.src=frameAsset(i?'bottom':'top',room));layoutFrames();requestAnimationFrame(()=>{if(request!==frameRequest)return;[slot.field,...slot.borders].forEach(e=>e.style.opacity='1');const old=frameSlots[activeFrame];[old.field,...old.borders].forEach(e=>e.style.opacity='0');activeFrame=next;pageField(room);syncChrome(room);frameBusyUntil=performance.now()+1100;window.gardenFrameRoom=room;});};
 addEventListener('resize',layoutFrames);window.visualViewport?.addEventListener('resize',layoutFrames);addEventListener('load',layoutFrames);new ResizeObserver(layoutFrames).observe(document.documentElement);requestAnimationFrame(layoutFrames);preloadFrame(0);
 const ios=/iPhone|iPad|iPod/.test(navigator.userAgent)||(navigator.platform==='MacIntel'&&navigator.maxTouchPoints>1);
 const standalone=matchMedia('(display-mode: standalone)').matches||matchMedia('(display-mode: fullscreen)').matches||navigator.standalone;
 const mobile=ios||/Android/.test(navigator.userAgent);
 window.gardenHaptic=ms=>{if(!ios&&typeof navigator.vibrate==='function')navigator.vibrate(ms);};
 const suspend=()=>window.gardenSuspended=document.hidden||matchMedia("(orientation: landscape)").matches;
 addEventListener("resize",suspend);document.addEventListener("visibilitychange",()=>{if(document.hidden)window.gardenSaveNow?.();suspend();});addEventListener("pagehide",()=>window.gardenSaveNow?.());suspend();
 const liveContent=fetch('https://raw.githubusercontent.com/NQUAREx/dina-lovely/main/content/letters.json?fresh='+Date.now(),{cache:'no-store',signal:AbortSignal.timeout(8000)}).then(r=>{if(!r.ok)throw Error(r.status);return r.json()}).then(d=>{if(d.schema_version!==2||!Array.isArray(d.letters)||d.puzzle?.symbols?.length!==7||d.puzzle?.room_letters?.length!==7||!d.ui?.read_letter||typeof d.ui.read_letter.text!=='string')throw Error('Invalid content schema');window.gardenContent=d;return d;}).catch(()=>null);
 let launch;window.gardenLaunch=new Promise(r=>launch=r);
 const style=document.createElement('style');style.textContent=`@font-face{font-family:GardenLetter;src:url('letter-body.ttf') format('truetype');font-display:swap}@font-face{font-family:GardenLetterTitle;src:url('letter-title.ttf') format('truetype');font-display:swap}html,body{margin:0;background:#242538;overscroll-behavior:none;height:100%;touch-action:none}#mobile-gate,#portrait-gate{position:fixed;inset:0;bottom:calc(-1 * env(safe-area-inset-bottom,0px));box-sizing:border-box;z-index:2000;background:radial-gradient(ellipse at top,#55435d,#242538 75%);color:#f5e3cf;display:grid;place-content:center;padding:max(28px,env(safe-area-inset-top)) 28px max(28px,env(safe-area-inset-bottom));text-align:center;font:17px/1.6 Georgia,serif}#mobile-gate h1{font-size:32px;line-height:1.2;color:#edbdce}#mobile-gate button{padding:18px 28px;border:1px solid #df9eb9;border-radius:18px;color:#fff0dc;background:#76556f;font:18px Georgia;margin-top:24px}#mobile-gate ol{text-align:left;max-width:340px}#portrait-gate{display:none;font-size:24px;z-index:3000}@media(orientation:landscape){#portrait-gate{display:grid}}canvas{touch-action:none}`;document.head.append(style);
 addEventListener('DOMContentLoaded',async()=>{
  const loaded=await liveContent;
  if(!loaded){const retry=document.createElement('button');retry.textContent='↻';retry.style.cssText='position:fixed;left:45%;top:45%;font-size:48px;background:transparent;color:#edbdce;border:0';retry.onclick=()=>location.reload();document.body.append(retry);return;}
  const t=key=>loaded.ui?.[key]?.text||'';
  window.gardenOpenReply=(options={})=>{
   if(document.getElementById('reply-letter'))return;
   window.gardenReplyResult='';
   const copy=key=>window.gardenContent?.ui?.[key]?.text||t(key);
   const canvas=document.getElementById('canvas');const r=canvas?.getBoundingClientRect()||{left:0,top:0,width:innerWidth,height:innerWidth*960/540};
   const scale=r.width/540;const start=options.start||[270,480],hand=options.hand||[280,448];
   const left=r.left+38*scale,top=r.top+150*scale;
   const startX=r.left+(start[0]-15)*scale,startY=r.top+(start[1]-65)*scale;
   const shade=document.createElement('section');shade.id='reply-letter';shade.dataset.phase='opening';shade.style.cssText='position:fixed;inset:0;z-index:2500;background:rgba(8,10,20,.58);touch-action:pan-y;font:20px/1.45 GardenLetter,sans-serif;color:#45394f';
   const envelope=document.createElement('img');envelope.src='reply-envelope.png';envelope.alt='';envelope.style.cssText='position:fixed;image-rendering:pixelated;pointer-events:none;z-index:1';shade.append(envelope);
   const placeEnvelope=(x,y,zoom)=>{Object.assign(envelope.style,{left:(x-32*scale*zoom)+'px',top:(y-86*scale*zoom)+'px',width:64*scale*zoom+'px',height:96*scale*zoom+'px'});};
   placeEnvelope(r.left+start[0]*scale,r.top+start[1]*scale,1);
   const paper=document.createElement('form');paper.style.cssText=`box-sizing:border-box;position:fixed;left:${left}px;top:${top}px;width:464px;height:660px;padding:0;background:url('reply-paper.png') 0 0 / 464px 660px no-repeat;box-shadow:8px 12px 0 #0004;border:0;transform-origin:0 0;transform:scale(${scale});z-index:2`;shade.append(paper);
   const title=document.createElement('h2');title.textContent=copy('reply_title');title.style.cssText='position:absolute;left:30px;top:38px;width:370px;height:90px;margin:0;font-size:25px;font-family:GardenLetterTitle,serif;font-weight:normal';paper.append(title);
   const content=document.createElement('div');content.style.cssText='position:absolute;left:30px;top:140px;width:404px;height:440px;overflow:auto;touch-action:pan-y;scrollbar-width:thin';paper.append(content);
   const add=(tag,key)=>{const e=document.createElement(tag);e.textContent=copy(key);content.append(e);return e;};
   const intro=add('p','reply_body');intro.style.cssText='margin:0 0 12px;font-size:17px';
   const text=document.createElement('textarea');text.maxLength=3500;text.placeholder=copy('reply_placeholder');text.rows=6;text.disabled=true;text.style.cssText='box-sizing:border-box;width:100%;height:174px;resize:none;padding:0 3px;color:#45394f;background:transparent;border:0;outline:none;font:20px/29px GardenLetter,sans-serif;touch-action:pan-y';
   try{text.value=localStorage.getItem('garden-reply-draft')||'';}catch{}
   text.addEventListener('input',()=>{try{localStorage.setItem('garden-reply-draft',text.value)}catch{}});content.append(text);add('small','reply_limit').style.fontSize='15px';
   add('p','reply_vpn').style.cssText='font-size:16px;margin:10px 0';const checkLabel=document.createElement('label');checkLabel.style.cssText='display:flex;gap:12px;align-items:center;font-size:17px';const vpn=document.createElement('input');vpn.type='checkbox';vpn.style.cssText='width:22px;height:22px;accent-color:#8d627f';checkLabel.append(vpn,document.createTextNode(copy('reply_vpn_confirm')));content.append(checkLabel);
   const status=add('p','');status.setAttribute('role','status');status.setAttribute('aria-live','polite');status.style.cssText='min-height:27px;font-size:16px;margin:10px 0';
   const send=document.createElement('button');send.textContent=copy('reply_send');send.type='submit';send.disabled=true;send.style.cssText='position:absolute;left:30px;bottom:26px;width:404px;height:44px;border:0;border-bottom:1px solid #d8c6b1;background:transparent;color:#45394f;font:20px GardenLetter,sans-serif';paper.append(send);
   const close=document.createElement('button');close.textContent=copy('reply_close_symbol');close.type='button';close.disabled=true;close.style.cssText='position:absolute;right:10px;top:10px;width:38px;height:38px;padding:0;border:0;background:transparent;color:#45394f;font:28px GardenLetter,sans-serif';close.setAttribute('aria-label',copy('reply_close'));paper.append(close);
   let busy=false,sent=false,packing=false,opening=true;
   const oldBodyTouch=document.body.style.touchAction,oldHtmlTouch=document.documentElement.style.touchAction;document.body.style.touchAction='pan-y';document.documentElement.style.touchAction='pan-y';
   const finish=()=>{shade.remove();document.body.style.touchAction=oldBodyTouch;document.documentElement.style.touchAction=oldHtmlTouch};
   close.onclick=()=>{if(!busy&&!packing&&!opening)finish()};
   const packLetter=async()=>{
    if(!shade.isConnected)return;packing=true;shade.dataset.phase='folding';close.disabled=true;text.blur();
    await new Promise(resolve=>setTimeout(resolve,350));
    const cx=left+232*scale,cy=top+450*scale;
    envelope.src='reply-envelope-open.png';envelope.style.zIndex='3';placeEnvelope(cx,cy,3);
    const foldedX=cx-left-62*scale,foldedY=cy-top-130*scale;
    await paper.animate([{transform:`scale(${scale})`,opacity:1},{offset:.45,transform:`translate(${foldedX}px,${foldedY}px) scale(${scale*.27},${scale*.3})`,opacity:1},{transform:`translate(${foldedX}px,${cy-top-35*scale}px) scale(${scale*.27},${scale*.025})`,opacity:0}],{duration:1000,easing:'ease-in-out',fill:'forwards'}).finished;
    const flap=document.createElement('div');flap.style.cssText=`position:fixed;left:${cx-66*scale}px;top:${cy-105*scale}px;width:${132*scale}px;height:${42*scale}px;background:#e8c8b8;clip-path:polygon(0 0,100% 0,50% 100%);transform-origin:50% 0;z-index:4`;shade.append(flap);
    await flap.animate([{transform:'rotateX(-170deg)'},{transform:'rotateX(0deg)'}],{duration:350,fill:'forwards'}).finished;
    envelope.src='reply-envelope.png';flap.remove();shade.dataset.phase='envelope';
    const hx=r.left+hand[0]*scale,hy=r.top+hand[1]*scale;
    shade.animate([{background:'rgba(8,10,20,.58)'},{background:'rgba(8,10,20,0)'}],{duration:650,fill:'forwards'});
    await envelope.animate([{left:(cx-96*scale)+'px',top:(cy-258*scale)+'px',width:192*scale+'px',height:288*scale+'px'},{left:(hx-16*scale)+'px',top:(hy-43*scale)+'px',width:32*scale+'px',height:48*scale+'px'}],{duration:650,easing:'ease-in-out',fill:'forwards'}).finished;
    window.gardenReplyResult='sent';finish();
   };
   paper.onsubmit=async event=>{
    event.preventDefault();if(busy||sent||opening)return;
    if(!text.value.trim()){status.textContent=copy('reply_empty');text.focus();return;}
    if(!vpn.checked){status.textContent=copy('reply_vpn');content.scrollTop=content.scrollHeight;return;}
    const endpoint=window.gardenContent?.reply_delivery?.endpoint||'';
    if(!/^https:\/\//.test(endpoint)){status.textContent=copy('reply_unconfigured');content.scrollTop=content.scrollHeight;return;}
    busy=true;send.disabled=true;close.disabled=true;text.disabled=true;status.textContent=copy('reply_sending');content.scrollTop=content.scrollHeight;
    const controller=new AbortController();const timer=setTimeout(()=>controller.abort(),20000);
    try{
     const response=await fetch(endpoint,{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded;charset=UTF-8'},body:new URLSearchParams({chat_id:String(window.gardenContent?.reply_delivery?.chat_id||''),text:text.value.trim()}),signal:controller.signal,credentials:'omit'});
     const result=await response.json();if(!response.ok||result.ok!==true)throw Error('delivery');
     sent=true;status.textContent=copy('reply_sent');try{localStorage.removeItem('garden-reply-draft')}catch{}
     setTimeout(()=>packLetter(),450);
    }catch{status.textContent=copy('reply_failed');content.scrollTop=content.scrollHeight;}
    finally{clearTimeout(timer);busy=false;close.disabled=sent;text.disabled=sent;send.disabled=sent;}
   };
   document.body.append(shade);
   const openedAt=performance.now();
   const smooth=value=>{value=Math.max(0,Math.min(1,value));return value*value*(3-2*value)};
   const openFrame=now=>{
    const age=(now-openedAt)/1000,progress=smooth((age-.7)/.8);
    const x=(startX-left)*(1-progress),y=(startY-top)*(1-progress),zoom=scale*(.065+.935*progress);
    paper.style.transform=`translate(${x}px,${y}px) rotate(${-Math.sin(progress*Math.PI)*.1}rad) scale(${zoom})`;
    paper.style.opacity=Math.max(0,Math.min(1,(age-.28)/.2));
    shade.style.background=`rgba(8,10,20,${.58*progress})`;
    envelope.src=age>.25?'reply-envelope-open.png':'reply-envelope.png';
    for(const node of [title,content,send,close])node.style.opacity=Math.max(0,Math.min(1,(age-1.25)*5));
    if(age<1.5)requestAnimationFrame(openFrame);else{opening=false;shade.dataset.phase='writing';text.disabled=false;send.disabled=false;close.disabled=false;}
   };
   requestAnimationFrame(openFrame);
  };

  let loadingTimer=null;
  let loadProgress=0;window.gardenLoadProgress=(current,total)=>{if(Object.keys(boot.transfers).length)return;boot.loaded=current;boot.total=total;const bar=document.getElementById('garden-progress');if(!bar)return;if(total>0)loadProgress=Math.max(loadProgress,Math.min(.99,current/total));bar.value=loadProgress;};
  window.gardenRoomProgress=value=>{window.gardenBootStage('rooms');const bar=document.getElementById('garden-progress');if(bar)bar.value=value;};
  window.gardenHideLoading=()=>{clearInterval(loadingTimer);document.getElementById('garden-loading')?.remove();paintChrome(chromeColor);};
  window.gardenShowLoading=()=>{
   window.gardenHideLoading();const screen=document.createElement('section');screen.id='garden-loading';
   screen.style.cssText='position:fixed;inset:0;bottom:calc(-1 * env(safe-area-inset-bottom,0px));box-sizing:border-box;z-index:1900;background:radial-gradient(ellipse at top,#55435d,#242538 75%);display:grid;place-content:center;text-align:center;padding:32px;color:#f5e3cf;font:20px/1.6 Georgia';
   const sprout=document.createElement('div');sprout.textContent='✦';sprout.style.cssText='font-size:52px;color:#e5a6bd;animation:garden-pulse 1.2s ease-in-out infinite alternate';screen.append(sprout);
   const progress=document.createElement('progress');progress.id='garden-progress';progress.max=1;progress.value=loadProgress;progress.style.cssText='width:min(300px,75vw);height:14px;accent-color:#e5a6bd;border:1px solid #a07890;border-radius:8px;margin:22px auto 0;background:#342c42';progress.setAttribute('aria-label','%');screen.append(progress);const phrase=document.createElement('p');screen.append(phrase);const keys=loaded.loading_phrases||[];let index=Math.floor(Math.random()*keys.length);
   const update=()=>{phrase.textContent=t(keys[index++%keys.length]);};update();loadingTimer=setInterval(update,1300);document.body.append(screen);paintChrome(chromeColor);
  };
  const animation=document.createElement('style');animation.textContent='#garden-progress{appearance:none;-webkit-appearance:none;overflow:hidden}#garden-progress::-webkit-progress-bar{background:#342c42;border-radius:8px}#garden-progress::-webkit-progress-value{background:linear-gradient(90deg,#a7789b,#efbdd0);border-radius:8px}#garden-progress::-moz-progress-bar{background:#e5a6bd}@keyframes garden-pulse{to{transform:scale(1.2) rotate(20deg);opacity:.5}}';document.head.append(animation);
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
