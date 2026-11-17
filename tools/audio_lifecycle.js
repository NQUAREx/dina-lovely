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
