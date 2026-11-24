// Resume the Godot-owned context after mobile browsers interrupt page audio.
// Do not create a second context or try to unlock one before it has played.
(()=>{
 let context=null,hasPlayed=false,needsRecovery=false,lastAttempt=-Infinity;
 const wake=(fromGesture=false)=>{
  if(!context||!hasPlayed||!needsRecovery||document.hidden||context.state==='closed')return;
  if(context.state==='running'){needsRecovery=false;return;}
  const now=performance.now();
  if(!fromGesture&&now-lastAttempt<250)return;
  lastAttempt=now;
  try{context.resume()?.catch(()=>{});}catch{}
 };
 const stateChanged=()=>{
  if(!context)return;
  if(context.state==='running'){hasPlayed=true;if(!document.hidden)needsRecovery=false;return;}
  if(hasPlayed&&context.state==='interrupted')needsRecovery=true;
  if(needsRecovery&&!document.hidden&&(context.state==='suspended'||context.state==='interrupted'))wake();
 };
 window.gardenBindAudioContext=next=>{
  if(context===next)return;
  context?.removeEventListener('statechange',stateChanged);
  context=next;hasPlayed=context?.state==='running';needsRecovery=false;lastAttempt=-Infinity;
  context?.addEventListener('statechange',stateChanged);
 };
 document.addEventListener('visibilitychange',()=>{if(document.hidden)needsRecovery=hasPlayed;else wake();});
 window.addEventListener('pagehide',()=>{needsRecovery=hasPlayed;});
 window.addEventListener('pageshow',()=>wake());
 window.addEventListener('focus',()=>wake());
 // Capture the genuine gesture before the game starts its next short sound.
 for(const event of ['pointerdown','touchstart','keydown'])document.addEventListener(event,()=>wake(true),{capture:true,passive:true});
})();

(()=>{
 const motifStyle=document.createElement('style');
 const motifSvg='<svg xmlns="http://www.w3.org/2000/svg" width="120" height="96" viewBox="0 0 120 96"><g fill="none" stroke="#efb5c7" stroke-opacity=".055" stroke-width="2" shape-rendering="crispEdges"><path d="M18 25v-9h6v3h6v-3h6v9h-3v6h-3v3h-3v3h-3v-3h-3v-6h-3z"/><path d="M84 55h3v6h3v3h6v3h-6v3h-3v6h-3v-6h-3v-3h-6v-3h6v-3h3z"/></g></svg>';
 const movieVersion='6d3d65cd2f45';
 motifStyle.textContent='#mobile-gate::before,#portrait-gate::before,#garden-loading::before,#garden-recovery::before{content:"";position:absolute;inset:0;pointer-events:none;background-position:-20px -18px;background-image:url("data:image/svg+xml,'+encodeURIComponent(motifSvg)+'");image-rendering:pixelated}'
  +'#garden-loading::before{background:url("loading-pattern.png?v='+movieVersion+'") 0 0 / 100% 100% no-repeat}';document.head.append(motifStyle);
 const roseStyle=document.createElement('style');
 const shellUI='1c3f96bd907b';
 const ios=/iPhone|iPad|iPod/.test(navigator.userAgent)||(navigator.platform==='MacIntel'&&navigator.maxTouchPoints>1);
 // A sprite fallback is available if the browser disables inline video.
 const iosWalk=ios?new Image():null;
 if(iosWalk){iosWalk.src='loading-heroine.png?v='+shellUI;iosWalk.alt='';iosWalk.className='garden-loading-walk-strip';}
 // Keep decoded poses stationary: only discrete opacity changes run on the compositor.
 // Never crossfade transparent sprites: source-over blending dims every step.
 const loadingHeroes=Array.from({length:ios?0:8},(_,frame)=>{
  const image=new Image();image.src='loading-heroine-'+frame+'.png?v='+shellUI;
  image.alt='';image.decoding='sync';image.className='garden-loading-heroine-image';
  image.style.animationName='garden-loading-pose-'+frame;
  image.style.zIndex=String(frame);
  return image;
 });
 const loadingHeroReady=Promise.all(loadingHeroes.map(image=>image.decode().then(()=>true,()=>false)));
 const loadingHeroFallback="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAADGklEQVR4nO2aX0hTURzHv0vdg0FPRlhUW2s2kqCsqxI9RC9GCIU0+vsQCAqjtjfnSw+9NR+KiRgKQQ8ZwcQMJFhI9JKow1XISjPbosAHoR7CPdTi9nA5d7vzTjfxd85tng8I594d/Z3zPd/f73fvEJBIJBKJRCKRSCQSQajp76qo2DZRgRld/j598z29N7mvZxvvgGb4Al5hsSt5Buvy96mhuxcw/Oydfk9pVvRxZGhMBQDvtVYboKVGsHuU1BncBIgMjamxqRS+LlUVNRcAgt2j1MviUwPYhoDsiccmY4hNpXDCcQoA0Hi+Fv3hCJQmh/b5VAq+gBcO1y7SNZILkLt5QNsYAChNDijNCqafLwHQBACA/burEAw+gS/g1QVhKUGBkCLoC3h1IfJhm+cFqQPyTx/IWns9+sMRANBTgsoF3B0QCl0tae7FtpOEq+HcBgFgeGSioP0LzaeEuwClMDwyQVoAAQ4CNByvL+peOp2hXoopXGpAfCax5udrbX42vkD6omSJdwGRkKaAmdXzYadfkXhquP+3/rI+no0vqEca3OXRBq2GZbpA7onzhNwB8ZlEUakgii2fAmQCLM4lN619URVAwAIOqK4WW4aEC7AelKcPWESAQi6Y+zhPHptM3cW5pFpqB0inMwYxXB4n+TdWwp8DMpk/+thu5x+fLAWs3v8Zwh2Qz6+3DwAAR6/0cPnGmswB/8PpA4IckJv3hYh++Fz0g1TL4YMbdgs3AcZfvgEAdLS34FPyJwDg0Z17q+ZdattR8t9mYm1ECNLnAJfHaXN5nDa2eStCJgDr4QO9j3Ur557+ZrPRNBDaBd7/WDFc3/LdAH5HAQCp8Ul0+q+X94PQ/fBtw/WX+W/c12CJdwHGgUN7ucckdUBu/p8+01jU7yzZW9iIYkmrsJQDgKwL9u2p5RKPVABWxDo6z6HOXQNUVpjOe/1qGnXuGv3nbOsxymUZIK+yuWkAaGKYMTjwwnDNowMAAv5NLl8QM3htHhDYBjvatWI3+DBquNbGy6pt+87ydABDXVle0wm8BJBIJBKJRCLZsvwDe7Hq3xnkLO8AAAAASUVORK5CYII=";
 const loadingWalkFrames=Array.from({length:8},(_,frame)=>{
  const start=frame*12.5,end=(frame+1)*12.5;
  const points=frame===0?[[0,1],[end,0],[100,0]]:
   [[0,0],[start,1],[end,0],...(end<100?[[100,0]]:[])];
  return '@keyframes garden-loading-pose-'+frame+'{'+points.map(([t,o])=>t+'%{opacity:'+o+'}').join('')+'}';
 }).join('');
 roseStyle.textContent=`#mobile-gate,#portrait-gate,#garden-loading,#garden-recovery{isolation:isolate}#mobile-gate::before,#portrait-gate::before,#garden-loading::before,#garden-recovery::before{z-index:-1}
 #mobile-gate button,#garden-recovery button{position:relative;z-index:1;isolation:isolate;opacity:1!important;min-height:76px;box-sizing:border-box;border:12px solid transparent!important;border-image:url('ui-frame-normal.png?v=${shellUI}') 12 fill stretch!important;border-radius:0!important;background:#4f3855!important;background-clip:padding-box!important;box-shadow:none!important;color:#f5e3cf!important;padding:8px 20px!important;image-rendering:pixelated}
 #mobile-gate button:hover,#garden-recovery button:hover{border-image-source:url('ui-frame-hover.png?v=${shellUI}')!important}
 #mobile-gate button:active,#garden-recovery button:active{border-image-source:url('ui-frame-pressed.png?v=${shellUI}')!important}
 #mobile-gate button:focus-visible,#garden-recovery button:focus-visible{outline:2px solid #f4d3a8;outline-offset:4px}
 #mobile-gate button::before,#garden-recovery button::before{content:'';pointer-events:none;position:absolute;left:-14px;right:-14px;top:-26px;height:36px;background:url('ui-flower-left.png?v=${shellUI}') left top/48px 36px no-repeat,url('ui-flower-right.png?v=${shellUI}') right top/48px 36px no-repeat}
 #mobile-gate button::after,#garden-recovery button::after{content:'';pointer-events:none;position:absolute;left:50%;top:-17px;transform:translateX(-50%);width:44px;height:24px;background:url('ui-crest-button.png?v=${shellUI}') center/44px 24px no-repeat}
 #mobile-gate h1{color:#f4d3b4!important;text-shadow:2px 2px #49354f}#garden-loading progress{accent-color:#d49aab}
 #garden-loading .garden-loading-heroine{position:relative;display:block;width:128px;height:128px;margin:0 auto;isolation:isolate;background:transparent!important;border:0!important;border-radius:0!important;box-shadow:none!important}
 #garden-loading .garden-loading-heroine-image{position:absolute;inset:0;display:block;width:128px!important;min-width:128px!important;max-width:128px!important;height:128px!important;min-height:128px!important;max-height:128px!important;object-fit:contain!important;flex:none;image-rendering:pixelated;pointer-events:none;background:transparent!important;border:0!important;border-radius:0!important;box-shadow:none!important;opacity:0;will-change:opacity;animation-duration:.64s;animation-timing-function:step-end;animation-iteration-count:infinite}
 .garden-loading-ios .garden-loading-heroine{overflow:hidden}
 .garden-loading-ios video{display:block;position:absolute;inset:0;width:100%;height:100%;object-fit:fill;background:#242538;pointer-events:none}
 #garden-loading.garden-loading-ios:has(>video)>:not(video){display:none}
 .garden-loading-ios video::-webkit-media-controls{display:none!important}
 .garden-loading-walk-strip{display:block;width:1024px;max-width:none;height:128px;image-rendering:pixelated;will-change:transform;animation:garden-walk-strip .64s steps(8,end) infinite}
 @keyframes garden-walk-strip{from{transform:translate3d(0,0,0)}to{transform:translate3d(-100%,0,0)}}
 .garden-loading-ios #garden-progress{position:relative;width:min(300px,75vw);height:14px;margin:22px auto 0;overflow:hidden;border:1px solid #a07890;border-radius:8px;background:#342c42}
 .garden-loading-meter-fill{position:absolute;inset:0;overflow:hidden;border-radius:inherit;background:linear-gradient(90deg,#a7789b,#efbdd0);transform-origin:left center;will-change:transform;animation:garden-load-decorative 16s ease-out both}
 @keyframes garden-load-decorative{0%{transform:scaleX(.04)}14%,18%{transform:scaleX(.26)}34%,39%{transform:scaleX(.50)}55%,61%{transform:scaleX(.72)}80%,85%{transform:scaleX(.88)}100%{transform:scaleX(.95)}}
 .garden-loading-meter-fill::after{content:'';position:absolute;inset:0 auto 0 0;width:38%;background:linear-gradient(90deg,transparent,#fff0dc60,transparent);will-change:transform;animation:garden-load-glint 3.2s linear infinite}
 @keyframes garden-load-glint{from{transform:translate3d(-100%,0,0)}to{transform:translate3d(270%,0,0)}}
 .garden-loading-tips{height:2.5em;margin-top:.45em;overflow:hidden}
 .garden-loading-tips-track{will-change:transform;animation:garden-loading-tips var(--duration) steps(var(--phrases),end) infinite}
 .garden-loading-tips-track p{height:2.5em;margin:0;display:grid;place-items:center;line-height:1.2}
 @keyframes garden-loading-tips{from{transform:translate3d(0,0,0)}to{transform:translate3d(0,-100%,0)}}
 ${loadingWalkFrames}`;
 document.head.append(roseStyle);
 const frameArtVersion='c57621a051f2';
 // The same room palette also colors browser-owned areas where textures cannot render.
 const roomChromeColors=[[56, 32, 84], [12, 28, 47], [115, 72, 31], [111, 90, 65], [87, 22, 45], [34, 79, 86], [215, 188, 157]];
 let chromeColor=roomChromeColors[0].slice(),chromeAnimation=0;
 const paintChrome=(color,page=true)=>{
  const css='#'+color.map(v=>Math.round(v).toString(16).padStart(2,'0')).join('');
  const pageColor=document.getElementById('garden-loading')?'#242538':css;
  if(page){
   if(document.documentElement.style.backgroundColor!==pageColor)document.documentElement.style.setProperty('background-color',pageColor,'important');
   if(document.body&&document.body.style.backgroundColor!==pageColor)document.body.style.setProperty('background-color',pageColor,'important');
  }
  const theme=document.querySelector('meta[name="theme-color"]');if(theme&&theme.content!==pageColor)theme.content=pageColor;
 };
 const syncChrome=(room,animate=true)=>{
  cancelAnimationFrame(chromeAnimation);const from=chromeColor.slice(),to=roomChromeColors[room],start=performance.now();let painted=-100;
  // The browser bar colour fades every 80 ms; the page background (hidden
  // behind the fixed frame layers) is repainted once, at the end: repainting
  // html/body 14 times during the second after a room change stalled the game.
  const tick=now=>{const t=animate?Math.min(1,(now-start)/1100):1;const eased=t*t*(3-2*t);chromeColor=from.map((v,i)=>v+(to[i]-v)*eased);
   if(now-painted>=80||t===1){paintChrome(chromeColor,t===1);painted=now;}
   if(t<1)chromeAnimation=requestAnimationFrame(tick);
  };tick(start);
 };
 syncChrome(0,false);addEventListener('DOMContentLoaded',()=>paintChrome(chromeColor));
 const boot={stage:'download',since:performance.now(),events:[],loaded:0,total:0,resize:0};
 window.gardenBoot=boot;boot.assets={};boot.transfers={};
 window.gardenAssetBytes=(name,loaded,total)=>{boot.transfers[name]={loaded,total};boot.loaded=Object.values(boot.transfers).reduce((sum,t)=>sum+t.loaded,0);boot.total=Object.values(boot.transfers).reduce((sum,t)=>sum+t.total,0);if(ios)return;const bar=document.getElementById('garden-progress');if(bar)bar.value=boot.total>0?boot.loaded/boot.total:0;};
 window.gardenAssetState=(name,done)=>{boot.assets[name]=done;window.gardenBootStage(Object.values(boot.assets).every(Boolean)?'compile':'download');};
 window.gardenBootStage=stage=>{if(boot.stage!==stage){boot.stage=stage;boot.since=performance.now();boot.events.push({stage,at:Math.round(performance.now())});}};
 addEventListener('resize',()=>boot.resize++);
 const frameAsset=(part,room)=>'frame_'+part+'_'+room+'.png?v='+frameArtVersion;
 // The document background also paints Safari's area outside fixed-position layers.
 const pageField=room=>{document.documentElement.style.setProperty('background-image','url('+frameAsset('field',room)+')','important');document.documentElement.style.backgroundSize='192px 192px';document.documentElement.style.imageRendering='pixelated';document.documentElement.style.minHeight='0';document.documentElement.style.overflow='hidden';};
 pageField(0);
 const safeTint=document.createElement('div');safeTint.setAttribute('aria-hidden','true');safeTint.style.cssText='position:fixed;top:0;left:0;right:0;height:env(safe-area-inset-top,0px);z-index:41;background:rgba(16,18,30,.18);pointer-events:none';document.documentElement.append(safeTint);
 const frameSlots=[0,1].map(index=>{
  const field=document.createElement('div');field.setAttribute('aria-hidden','true');field.style.cssText='position:fixed;inset:calc(-1 * env(safe-area-inset-top,0px)) 0 calc(-1 * env(safe-area-inset-bottom,0px));z-index:0;pointer-events:none;image-rendering:pixelated;background-size:192px 192px;transition:opacity 1.1s ease;opacity:'+Number(index===0);field.style.backgroundImage='url('+frameAsset('field',0)+')';document.documentElement.append(field);
  const borders=['top','bottom'].map(edge=>{const image=document.createElement('img');image.src=frameAsset(edge,0);image.alt='';image.setAttribute('aria-hidden','true');image.style.cssText='position:fixed;z-index:40;pointer-events:none;image-rendering:pixelated;object-fit:fill;transition:opacity 1.1s ease;opacity:'+Number(index===0);document.documentElement.append(image);return image;});
  return {field,borders};
 });
 const layoutFrames=()=>{const canvas=document.getElementById('canvas');if(!canvas)return;canvas.style.zIndex='1';const viewport=window.visualViewport;
  const installedIOS=ios&&(navigator.standalone||matchMedia('(display-mode: standalone)').matches||matchMedia('(display-mode: fullscreen)').matches);
  // iOS standalone can report a visual viewport shorter than the actual screen.
  // Use one screen-sized coordinate system for the page, decorative fields and canvas center.
  const pageHeight=installedIOS?screen.height:innerHeight;
  const pageWidth=installedIOS?screen.width:innerWidth;
  document.documentElement.style.height=pageHeight+'px';
  if(document.body)document.body.style.height=pageHeight+'px';
  frameSlots.forEach(slot=>Object.assign(slot.field.style,{top:'0px',left:'0px',right:'auto',bottom:'auto',width:pageWidth+'px',height:pageHeight+'px'}));
  canvas.style.setProperty('top',(installedIOS?pageHeight/2:(viewport?.offsetTop||0)+(viewport?.height||innerHeight)/2)+'px','important');const r=canvas.getBoundingClientRect(),height=r.width*40/270;frameSlots.forEach(slot=>slot.borders.forEach((image,i)=>Object.assign(image.style,{left:r.left+'px',width:r.width+'px',height:height+'px',top:(i?r.bottom-height*.50:r.top-height*.60)+'px'})));};
 const loadedFrames=new Map();let activeFrame=0,wantedRoom=0,frameRequest=0,frameBusyUntil=0;window.gardenFrameRoom=0;
 const preloadFrame=room=>{if(!loadedFrames.has(room))loadedFrames.set(room,Promise.all(['field','top','bottom'].map(part=>new Promise(resolve=>{const image=new Image();image.onload=()=>resolve(true);image.onerror=()=>resolve(false);image.src=frameAsset(part,room);}))));return loadedFrames.get(room);};
 window.gardenSetRoom=async room=>{room=Math.max(0,Math.min(6,Math.trunc(Number(room)||0)));if(room===wantedRoom)return;wantedRoom=room;const request=++frameRequest;const loaded=await preloadFrame(room);if(request!==frameRequest||!loaded.every(Boolean))return;if(performance.now()<frameBusyUntil)await new Promise(resolve=>setTimeout(resolve,frameBusyUntil-performance.now()+20));if(request!==frameRequest)return;const next=1-activeFrame,slot=frameSlots[next];slot.field.style.backgroundImage='url('+frameAsset('field',room)+')';slot.borders.forEach((image,i)=>image.src=frameAsset(i?'bottom':'top',room));layoutFrames();requestAnimationFrame(()=>{if(request!==frameRequest)return;[slot.field,...slot.borders].forEach(e=>e.style.opacity='1');const old=frameSlots[activeFrame];[old.field,...old.borders].forEach(e=>e.style.opacity='0');activeFrame=next;pageField(room);syncChrome(room);frameBusyUntil=performance.now()+1100;window.gardenFrameRoom=room;});};
 addEventListener('resize',layoutFrames);window.visualViewport?.addEventListener('resize',layoutFrames);window.visualViewport?.addEventListener('scroll',layoutFrames);addEventListener('load',layoutFrames);new ResizeObserver(layoutFrames).observe(document.documentElement);requestAnimationFrame(layoutFrames);preloadFrame(0);
 // Share the pixel-heart burst between the loading screen and DOM buttons.
 document.addEventListener('click',event=>{
  const target=event.target.closest?.('button,#garden-loading');
  if(!target||target.disabled)return;
  const box=target.getBoundingClientRect();
  const pointer=target.id==='garden-loading'||event.detail>0||event.clientX!==0||event.clientY!==0;
  const x=pointer?event.clientX:box.left+box.width/2;
  const y=pointer?event.clientY:box.top+box.height/2;
  for(let i=0;i<12;i++){
   const heart=document.createElement('i'),size=8+Math.random()*8,dx=(Math.random()-.5)*140,dy=-35-Math.random()*80;
   heart.style.cssText='position:fixed;pointer-events:none;z-index:10000;left:'+x+'px;top:'+y+'px;width:'+size+'px;height:'+size+'px;background:'+['#e4a0b7','#efb5c7','#d889a8'][i%3]+';clip-path:polygon(0% 20%,20% 0%,40% 0%,50% 20%,60% 0%,80% 0%,100% 20%,100% 50%,50% 100%,0% 50%)';
   document.body.append(heart);
   const animation=heart.animate([{transform:'translate(-50%,-50%)',opacity:1},{transform:'translate('+dx*.7+'px,'+dy+'px)',opacity:.9,offset:.55},{transform:'translate('+dx+'px,'+(dy+45)+'px)',opacity:0}],{duration:550+Math.random()*250,easing:'ease-out'});
   animation.onfinish=()=>heart.remove();
  }
 },true);
 if(!ios){const manifestLink=document.createElement('link');manifestLink.rel='manifest';manifestLink.href='manifest.webmanifest';document.head.append(manifestLink);}
 const standalone=matchMedia('(display-mode: standalone)').matches||matchMedia('(display-mode: fullscreen)').matches||navigator.standalone;
 const mobile=ios||/Android/.test(navigator.userAgent);
 window.gardenHaptic=ms=>{if(!ios&&typeof navigator.vibrate==='function')navigator.vibrate(ms);};
 const suspend=()=>window.gardenSuspended=document.hidden||matchMedia("(orientation: landscape)").matches;
 addEventListener("resize",suspend);document.addEventListener("visibilitychange",()=>{if(document.hidden)window.gardenSaveNow?.();suspend();});addEventListener("pagehide",()=>window.gardenSaveNow?.());suspend();
 let movieURL='',residentMovieURL='';
 const liveContent=(async()=>{
  const value=new URLSearchParams(location.search).get('key');
  let selected=false;
  if(value){
   const digest=await crypto.subtle.digest('SHA-256',new TextEncoder().encode(value));
   selected=Array.from(new Uint8Array(digest),b=>b.toString(16).padStart(2,'0')).join('')==='80a4109778cf5389682009f04031d6624b8298f150397196e4ffd4c1cab4c58d';
  }
  const ipad=/iPad/.test(navigator.userAgent)||(navigator.platform==='MacIntel'&&navigator.maxTouchPoints>1);
  if(ipad)selected=false;
  if(ipad&&location.pathname.endsWith('/play.html')){location.replace(new URL('./'+location.search,location.href));await new Promise(()=>{});}
  const file=selected?'letters.backup.json':'letters.json';
  if(selected&&!location.pathname.endsWith('/play.html')){location.replace(new URL('play.html'+location.search,location.href));await new Promise(()=>{});}
  if(ios&&standalone){
   movieURL=(selected?'ios-loading-play.mp4':'ios-loading.mp4')+'?v='+movieVersion;
   // A complete local source keeps the loop running even if game downloads saturate the link.
   fetch(movieURL,{signal:AbortSignal.timeout(12000)}).then(async response=>{
    if(response.ok)residentMovieURL=URL.createObjectURL(await response.blob());
   }).catch(()=>{});
  }
  const response=await fetch('https://raw.githubusercontent.com/NQUAREx/dina-lovely/main/content/'+file+'?fresh='+Date.now(),{cache:'no-store',referrerPolicy:'no-referrer',signal:AbortSignal.timeout(8000)});
  if(!response.ok)throw Error(response.status);
  const data=await response.json();
  if(['game_title','recipient','signature','card_title','card_text','photo_caption','app_short_name'].some(key=>typeof data[key]!=='string'))throw Error('Missing content text field');
  if(!Array.isArray(data.letters)||data.letters.some(letter=>['id','title','text'].some(key=>typeof letter[key]!=='string')))throw Error('Missing letter text field');
  const requiredUi=["accessory_black_dress", "accessory_crown", "accessory_daisy_wreath", "accessory_dark_scarf", "accessory_emerald_diadem", "accessory_found", "accessory_gold_beads", "accessory_gold_brocade", "accessory_gold_mantle", "accessory_gold_veil", "accessory_heart_tiara", "accessory_lavender_dress", "accessory_peach_dress", "accessory_pink_watch", "accessory_rose_scarf", "accessory_rose_wreath", "accessory_silver_crown", "accessory_veil", "accessory_white_dress", "accessory_white_scarf", "accessory_white_veil", "accessory_wreath", "ammo_counter", "attack_action", "audio_credits", "back", "begin_room", "boss_announcement", "boss_name", "buried_note_exposed", "buried_note_near", "buried_note_required", "can_location", "can_required", "card_heading", "card_recipient_format", "card_signature_format", "cat_fish_found", "cat_needs_fish", "cat_tamed", "chop_tree", "clean_bed", "collected_letters_prefix", "combat_complete", "combat_note_required", "continue_game", "controls_help", "craft_pickaxe", "craft_pickaxe_requirements", "craft_shovel", "craft_shovel_requirements", "credits_return", "cycle_tools_action", "darkness_notes_required", "death_help", "death_title", "desktop_controls", "desktop_open_phone", "desktop_title", "dig_action", "digging_bounds", "digging_empty", "digging_progress", "drill_action", "drop_item_action", "eat_apple", "eat_berries", "enemy_attack_alert", "feed_cat", "fertilize_bed", "fertilizer_required", "fill_water", "garden_basket_name", "garden_chores_done", "garden_chores_required", "garden_deposit_basket", "garden_harvest_bush", "garden_rake_grass", "garden_take_basket", "garden_trim_bush", "gate_key_action", "gate_key_found", "gate_key_intro", "gate_key_required", "health_full", "insert_rune", "insert_skull", "install_description", "install_done", "install_home_step", "install_mode_step", "install_open_step", "install_share_step", "install_title", "item_apple", "item_axe", "item_bench", "item_berries", "item_branch", "item_broken_shovel", "item_can", "item_cat_fish", "item_cat_hut", "item_chest", "item_drill", "item_fertilizer", "item_final_chest", "item_flashlight", "item_flower", "item_gate", "item_gate_key", "item_hedge", "item_house_door", "item_large_rock", "item_letter", "item_medkit", "item_pebble", "item_pet_cat", "item_pickaxe", "item_puzzle_reset", "item_rake", "item_rock_material", "item_shears", "item_shovel", "item_skull", "item_skull_stand", "item_stats_stone", "item_swing", "item_tree", "item_well", "item_workbench", "journal_count", "journal_empty", "journal_title", "launch_button", "launch_goal", "launch_intro", "launch_ios_sound", "launch_sound_detail", "launch_sound_title", "letter_stack_counter", "loading_bench", "loading_berries", "loading_birds", "loading_card", "loading_chest", "loading_clouds", "loading_enemy", "loading_fireflies", "loading_grass", "loading_hearts", "loading_hedges", "loading_hugs", "loading_lantern", "loading_letters", "loading_moon", "loading_paths", "loading_petals", "loading_progress_label", "loading_rake", "loading_seeds", "loading_skulls", "loading_soil", "loading_swing", "loading_trees", "loading_water", "maze_notes_required", "medkit_spawned", "medkit_used", "meet_cat", "menu_action", "menu_goal", "menu_tagline", "mine_rock", "new_bed_action", "new_game", "new_game_title", "new_game_warning", "obstacle_retry", "open_chest", "open_gate", "open_house_door", "pet_cat_action", "pickup_axe", "pickup_can", "pickup_drill", "pickup_fertilizer", "pickup_flashlight", "pickup_gate_key", "pickup_material", "pickup_prefix", "pickup_rake", "pickup_rune", "pickup_shears", "pickup_shovel", "plant_growing", "plant_wait", "portrait_hint", "press_rune", "puzzle_full_input", "puzzle_notes_missing", "puzzle_reset_action", "puzzle_reset_notice", "puzzle_short_input", "puzzle_symbol_added", "puzzle_wrong_input", "rake_required", "read_book", "read_letter", "read_statistics", "recovery_context_lost", "recovery_load_failed", "recovery_return", "repair_shovel", "replay_card", "reply_body", "reply_browser_only", "reply_close", "reply_close_symbol", "reply_empty", "reply_failed", "reply_limit", "reply_placeholder", "reply_send", "reply_sending", "reply_sent", "reply_title", "reply_unconfigured", "reply_vpn", "reply_vpn_confirm", "retry_action", "retry_room", "return_to_garden", "return_to_menu", "riddle_link_clue", "riddle_note_heading", "riddle_start_clue", "room_combat", "room_darkness", "room_digging", "room_final", "room_garden", "room_maze", "room_obstacles", "rune_all_inserted", "rune_found", "rune_inserted", "rune_need_all", "rune_not_found", "rune_socket_name", "rune_stone_name", "secret_book_name", "secret_book_text", "secret_book_title", "shovel_needs_repair", "sit_action", "skull_collected", "skull_missing", "snip_plant", "stand_action", "start_intro", "start_new_story", "stats_body", "stats_cat_no", "stats_cat_yes", "stats_time_line", "stats_time_unknown", "stats_title", "stone_dig_near", "stone_unearthed", "storage_unavailable", "swing_action", "symbol_drop", "symbol_flower", "symbol_heart", "symbol_leaf", "symbol_moon", "symbol_star", "symbol_sun", "take_fish", "take_skull", "uproot_flower", "use_medkit", "water_action", "water_empty", "water_filled", "wave_announcement", "weapon_rifle", "weapon_rpg", "weapon_sword", "wear_accessory", "workbench_ready", "write_reply"];
  if(requiredUi.some(key=>typeof data.ui?.[key]?.text!=='string'))throw Error('Missing UI key in content');
  if(data.schema_version!==2||!Array.isArray(data.letters)||data.puzzle?.symbols?.length!==7||data.puzzle?.room_letters?.length!==7||!data.ui?.read_letter||typeof data.ui.read_letter.text!=='string')throw Error('Invalid content schema');
  if(selected){
   const link=document.querySelector('link[rel="manifest"]');
   if(link){
    try{
     const manifest=await fetch('manifest.webmanifest',{cache:'no-store',signal:AbortSignal.timeout(3000)}).then(r=>r.json());
     const base=new URL('./',location.href);
     manifest.name=data.game_title;manifest.short_name=data.app_short_name;
     manifest.id=new URL('?v='+file,base).href;
     manifest.start_url=location.href.split('#')[0];
     manifest.scope=base.href;
     manifest.icons=manifest.icons.map(icon=>({...icon,src:new URL(icon.src,base).href}));
     link.href=URL.createObjectURL(new Blob([JSON.stringify(manifest)],{type:'application/manifest+json'}));
    }catch{link.remove();}
   }
  }
  window.gardenContent=data;
  let appleTitle=document.querySelector('meta[name="apple-mobile-web-app-title"]');
  if(!appleTitle){appleTitle=document.createElement('meta');appleTitle.name='apple-mobile-web-app-title';document.head.append(appleTitle);}
  appleTitle.content=data.game_title;
  return data;
 })().catch(()=>null);
 let launch;window.gardenLaunch=new Promise(r=>launch=r);
 const style=document.createElement('style');style.textContent=`@font-face{font-family:GardenLetter;src:url('letter-body.ttf?v=2053bce4ba63') format('truetype');font-display:swap}@font-face{font-family:GardenLetterTitle;src:url('letter-title.ttf?v=2053bce4ba63') format('truetype');font-display:swap}html,body{margin:0;background:#242538;overscroll-behavior:none;height:100%;touch-action:none}#mobile-gate,#portrait-gate{position:fixed;inset:0;bottom:calc(-1 * env(safe-area-inset-bottom,0px));box-sizing:border-box;z-index:2000;background:radial-gradient(ellipse at top,#55435d,#242538 75%);color:#f5e3cf;display:grid;place-content:center;padding:max(28px,env(safe-area-inset-top)) 28px max(28px,env(safe-area-inset-bottom));text-align:center;font:17px/1.6 GardenLetter,sans-serif}#mobile-gate h1{font-size:28px;line-height:1.3;color:#f5e3cf}#mobile-gate p,#mobile-gate li{font:18px/1.5 GardenLetter,sans-serif;color:#f5e3cf;margin:8px 0}#mobile-gate button{padding:18px 28px;border:1px solid #df9eb9;border-radius:18px;color:#fff0dc;background:#76556f;font:30px GardenLetter,sans-serif;margin-top:24px}#mobile-gate ol{text-align:left;max-width:340px}#portrait-gate{display:none;font-size:24px;z-index:3000}@media(orientation:landscape){#portrait-gate{display:grid}}canvas{touch-action:none}`;document.head.append(style);
 addEventListener('DOMContentLoaded',async()=>{
  const loaded=await liveContent;
  if(document.getElementById('garden-recovery'))return;
  if(!loaded){window.dispatchEvent(new Event('garden-asset-error'));return;}
  const t=key=>loaded.ui?.[key]?.text||'';
  window.gardenOpenReply=(options={})=>{
   if(document.getElementById('reply-letter'))return;
   window.gardenReplyResult='';
   const copy=key=>window.gardenContent?.ui?.[key]?.text||t(key);
   const canvas=document.getElementById('canvas');const r=canvas?.getBoundingClientRect()||{left:0,top:0,width:innerWidth,height:innerWidth*960/540};
   const scale=r.width/540;const start=options.start||[270,480],hand=options.hand||[280,448];
   const left=r.left+38*scale,top=r.top+150*scale;
   const startX=r.left+(start[0]-15)*scale,startY=r.top+(start[1]-65)*scale;
   const draftKey=window.gardenContent?.demo_mode?'garden-reply-draft-demo':'garden-reply-draft';
   const shade=document.createElement('section');shade.id='reply-letter';shade.dataset.phase='opening';shade.style.cssText='position:fixed;inset:0;z-index:2500;background:rgba(8,10,20,.58);touch-action:pan-y;font:20px/1.45 GardenLetter,sans-serif;color:#45394f';
   const envelope=document.createElement('img');envelope.src='reply-envelope.png';envelope.alt='';envelope.style.cssText='position:fixed;image-rendering:pixelated;pointer-events:none;z-index:1';shade.append(envelope);
   const placeEnvelope=(x,y,zoom)=>{Object.assign(envelope.style,{left:(x-32*scale*zoom)+'px',top:(y-86*scale*zoom)+'px',width:64*scale*zoom+'px',height:96*scale*zoom+'px'});};
   placeEnvelope(r.left+start[0]*scale,r.top+start[1]*scale,1);
   const paper=document.createElement('form');paper.style.cssText=`box-sizing:border-box;position:fixed;left:${left}px;top:${top}px;width:464px;height:660px;padding:0;background:url('reply-paper.png') 0 0 / 464px 660px no-repeat;box-shadow:8px 12px 0 #0004;border:0;transform-origin:0 0;transform:scale(${scale});z-index:2`;shade.append(paper);
   const title=document.createElement('h2');title.textContent=copy('reply_title');title.style.cssText='position:absolute;left:30px;top:38px;width:370px;height:90px;margin:0;font-size:25px;font-family:GardenLetterTitle,serif;font-weight:normal';paper.append(title);
   const content=document.createElement('div');content.style.cssText='position:absolute;left:30px;top:140px;width:404px;height:440px;overflow:auto;touch-action:pan-y;scrollbar-width:thin';paper.append(content);
   const add=(tag,key)=>{const e=document.createElement(tag);e.textContent=copy(key);content.append(e);return e;};
   const intro=add('p','reply_body');intro.style.cssText='margin:0 0 12px;font-size:17px';
   const text=document.createElement('textarea');text.maxLength=3500;text.placeholder=copy('reply_placeholder');text.rows=6;text.disabled=true;text.style.cssText='box-sizing:border-box;width:100%;height:174px;resize:none;padding:0 3px;color:#45394f;background:transparent;border:0;outline:none;font:22px/29px GardenLetter,sans-serif;touch-action:pan-y';
   try{text.value=localStorage.getItem(draftKey)||'';}catch{}
   text.addEventListener('input',()=>{try{localStorage.setItem(draftKey,text.value)}catch{}});content.append(text);add('small','reply_limit').style.fontSize='15px';
   add('p','reply_vpn').style.cssText='font-size:16px;margin:10px 0';const checkLabel=document.createElement('label');checkLabel.style.cssText='display:flex;gap:12px;align-items:center;font-size:17px';const vpn=document.createElement('input');vpn.type='checkbox';vpn.style.cssText='width:22px;height:22px;accent-color:#8d627f';checkLabel.append(vpn,document.createTextNode(copy('reply_vpn_confirm')));content.append(checkLabel);
   const status=add('p','');status.setAttribute('role','status');status.setAttribute('aria-live','polite');status.style.cssText='min-height:27px;font-size:16px;margin:10px 0';
   const send=document.createElement('button');send.textContent=copy('reply_send');send.type='submit';send.disabled=true;send.style.cssText='position:absolute;left:30px;bottom:26px;width:404px;height:44px;border:0;border-bottom:1px solid #d8c6b1;background:transparent;color:#45394f;font:26px GardenLetter,sans-serif';paper.append(send);
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
    let endpoint;
    try{endpoint=new URL(window.gardenContent?.reply_delivery?.endpoint)}catch{}
    if(endpoint?.protocol!=='https:'||endpoint.hostname==='api.telegram.org'){status.textContent=copy('reply_unconfigured');content.scrollTop=content.scrollHeight;return;}
    busy=true;send.disabled=true;close.disabled=true;text.disabled=true;status.textContent=copy('reply_sending');content.scrollTop=content.scrollHeight;
    const controller=new AbortController();const timer=setTimeout(()=>controller.abort(),20000);
    try{
     const response=await fetch(endpoint,{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded;charset=UTF-8'},body:new URLSearchParams({text:text.value.trim()}),signal:controller.signal,credentials:'omit'});
     const result=await response.json();if(!response.ok||result.ok!==true)throw Error('delivery');
     sent=true;status.textContent=copy('reply_sent');try{localStorage.removeItem(draftKey)}catch{}
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
  let loadProgress=0;window.gardenLoadProgress=(current,total)=>{if(Object.keys(boot.transfers).length)return;boot.loaded=current;boot.total=total;if(ios)return;const bar=document.getElementById('garden-progress');if(!bar)return;if(total>0)loadProgress=Math.max(loadProgress,Math.min(.99,current/total));bar.value=loadProgress;};
  window.gardenRoomProgress=value=>{window.gardenBootStage('rooms');if(ios)return;const bar=document.getElementById('garden-progress');if(bar)bar.value=value;};
  let movie=null,loadingReady=null,cancelMovieStart=null;
  const startMovie=async screen=>{
   if(!movie){
    movie=document.createElement('video');
    movie.muted=true;movie.defaultMuted=true;movie.loop=true;movie.playsInline=true;
    movie.setAttribute('muted','');movie.setAttribute('playsinline','');movie.setAttribute('webkit-playsinline','');
    movie.disablePictureInPicture=true;movie.disableRemotePlayback=true;movie.preload='auto';
    movie.poster='ios-loading-poster.png?v='+movieVersion;
    movie.setAttribute('aria-hidden','true');
    movie.addEventListener('error',()=>{movie.remove();cancelMovieStart?.();});
   }
   movie.src=residentMovieURL||movieURL;
   screen.append(movie);
   window.gardenLoadingCanBuild=false;
   return new Promise(resolve=>{
    let frameCallback=null;
    const finish=(usable=true)=>{
     clearTimeout(timeout);
     if(frameCallback!==null)movie.cancelVideoFrameCallback?.(frameCallback);
     movie.removeEventListener('timeupdate',timeAdvanced);
     movie.removeEventListener('error',failed);
     cancelMovieStart=null;
     if(!usable){movie.pause();movie.remove();}
     window.gardenLoadingCanBuild=true;
     resolve();
    };
    const failed=()=>{if(cancelMovieStart===failed)finish(false);};
    const timeAdvanced=()=>{if(movie.currentTime>0&&!movie.paused)finish();};
    const sawFrame=(_now,frame)=>{
     if(frame.mediaTime>0)finish();
     else frameCallback=movie.requestVideoFrameCallback(sawFrame);
    };
    // Unsupported media, autoplay refusal or a broken transfer must still allow entry.
    const timeout=setTimeout(failed,5000);
    cancelMovieStart=failed;
    movie.addEventListener('error',failed,{once:true});
    if(movie.requestVideoFrameCallback)frameCallback=movie.requestVideoFrameCallback(sawFrame);
    else movie.addEventListener('timeupdate',timeAdvanced);
    try{Promise.resolve(movie.play()).catch(failed);}catch{failed();}
   });
  };
  const resumeMovie=()=>{
   if(!document.hidden&&movie?.isConnected&&movie.paused)movie.play().catch(()=>{movie.remove();cancelMovieStart?.();});
  };
  document.addEventListener('visibilitychange',resumeMovie);
  addEventListener('pageshow',resumeMovie);
  window.gardenHideLoading=()=>{
   cancelMovieStart?.();loadingReady=null;
   movie?.pause();movie?.remove();
   clearInterval(loadingTimer);document.getElementById('garden-loading')?.remove();paintChrome(chromeColor);
  };
  window.gardenShowLoading=()=>{
   if(document.getElementById('garden-loading'))return loadingReady;
   const screen=document.createElement('section');screen.id='garden-loading';
   screen.style.cssText='position:fixed;inset:0;box-sizing:border-box;z-index:1900;background:radial-gradient(ellipse at top,#3b3249,#242538 75%);display:grid;place-content:center;text-align:center;padding:32px;color:#f5e3cf;font:20px/1.6 GardenLetter,sans-serif';
   const sprout=document.createElement('div');sprout.className='garden-loading-heroine';sprout.setAttribute('aria-hidden','true');screen.append(sprout);
   if(ios){
    screen.className='garden-loading-ios';screen.setAttribute('role','status');screen.setAttribute('aria-label',t('loading_progress_label'));
    if(iosWalk.complete&&iosWalk.naturalWidth)sprout.append(iosWalk);
    else{
     const fallback=new Image();fallback.src=loadingHeroFallback;fallback.alt='';fallback.width=128;fallback.height=128;fallback.style.imageRendering='pixelated';sprout.append(fallback);
     if(!iosWalk.complete)iosWalk.addEventListener('load',()=>{if(sprout.isConnected)fallback.replaceWith(iosWalk);},{once:true});
    }
    const meter=document.createElement('div');meter.id='garden-progress';meter.setAttribute('aria-hidden','true');
    const fill=document.createElement('div');fill.className='garden-loading-meter-fill';meter.append(fill);screen.append(meter);
    const keys=loaded.loading_phrases||[];
    if(keys.length){
     const tips=document.createElement('div');tips.className='garden-loading-tips';tips.setAttribute('aria-hidden','true');
     const track=document.createElement('div');track.className='garden-loading-tips-track';track.style.setProperty('--phrases',keys.length);track.style.setProperty('--duration',keys.length*1.8+'s');
     const first=Math.floor(Math.random()*keys.length);
     for(let i=0;i<keys.length;i++){const phrase=document.createElement('p');phrase.textContent=t(keys[(first+i)%keys.length]);track.append(phrase);}
     tips.append(track);screen.append(tips);
    }
    document.body.append(screen);paintChrome(chromeColor);
    loadingReady=startMovie(screen).catch(()=>{
     movie?.remove();
     cancelMovieStart=null;
     window.gardenLoadingCanBuild=true;
    });
    return loadingReady;
   }
   for(const pose of loadingHeroes)sprout.append(pose);
   const progress=document.createElement('progress');progress.id='garden-progress';progress.max=1;progress.value=loadProgress;progress.style.cssText='width:min(300px,75vw);height:14px;accent-color:#e5a6bd;border:1px solid #a07890;border-radius:8px;margin:22px auto 0;background:#342c42';progress.setAttribute('aria-label',t('loading_progress_label'));screen.append(progress);const phrase=document.createElement('p');screen.append(phrase);const keys=loaded.loading_phrases||[];let index=Math.floor(Math.random()*keys.length);
   const update=()=>{phrase.textContent=t(keys[index++%keys.length]);};update();loadingTimer=setInterval(update,1300);document.body.append(screen);paintChrome(chromeColor);
  };
  const animation=document.createElement('style');animation.textContent='#garden-progress{appearance:none;-webkit-appearance:none;overflow:hidden}#garden-progress::-webkit-progress-bar{background:#342c42;border-radius:8px}#garden-progress::-webkit-progress-value{background:linear-gradient(90deg,#a7789b,#efbdd0);border-radius:8px}#garden-progress::-moz-progress-bar{background:#e5a6bd}';document.head.append(animation);
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
    if(ios){
     // Keep the video attached inside the gesture. Engine downloads can begin
     // while the first frame is pending; room generation still waits for it.
     gate.remove();
     try{window.gardenShowLoading();}finally{launch();}
     return;
    }
    gate.remove();
    window.gardenShowLoading();
    launch();
    try{screen.orientation?.lock?.('portrait').catch(()=>{});}catch{}
    // Cosmetic assets must never keep the engine waiting.
    const decoded=await loadingHeroReady;
    const visibleLoading=document.querySelector('#garden-loading');
    if(!visibleLoading)return;
    if(decoded.some(ok=>!ok)){
     for(let i=0;i<loadingHeroes.length;i++)if(!decoded[i])loadingHeroes[i].remove();
     for(const pose of loadingHeroes){pose.style.animation='none';pose.style.opacity='0';}
     const fallback=loadingHeroes.find((_,i)=>decoded[i]);
     if(fallback)fallback.style.opacity='1';
     else{
      const emergency=new Image();emergency.src=loadingHeroFallback;emergency.alt='';emergency.className='garden-loading-heroine-image';emergency.style.animation='none';emergency.style.opacity='1';
      visibleLoading.querySelector('.garden-loading-heroine')?.append(emergency);
     }
    }
    const walkers=[...visibleLoading.querySelectorAll('.garden-loading-heroine-image')];
    const animations=walkers.flatMap(image=>image.getAnimations?.()||[]);
    await Promise.all(animations.map(animation=>animation.ready));
    const walkStart=document.timeline.currentTime;
    for(const animation of animations)animation.startTime=walkStart;
   };
  }
  const credits=add('a','audio_credits');credits.href='audio-credits.html';credits.target='_blank';credits.rel='noopener';credits.style.cssText='color:#c3a7b8;font:12px GardenLetter,sans-serif;margin-top:24px';
  document.title=loaded.game_title;document.body.append(gate);
  const rotate=document.createElement('div');rotate.id='portrait-gate';rotate.textContent=t('portrait_hint');if(!mobile)rotate.style.display='none';document.body.append(rotate);
 });
 addEventListener('pointerdown',()=>{if(mobile&&!ios&&!document.fullscreenElement&&document.documentElement.requestFullscreen)document.documentElement.requestFullscreen().catch(()=>{});},{passive:true});
})();
