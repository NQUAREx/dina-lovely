// Versioned, resumable static downloads; no service worker or server headers required.
(()=>{
 const compressedWasm='engine.8032306d52d5.wasm.gz',sizes={"engine.8032306d52d5.wasm.gz": 10054758, "index.wasm": 39514754, "game.6c56d24f2a37.pck": 3161544},chunkSize=512*1024,parallel=4;
 const cacheName='garden-assets-v1',writes=new Set();
 window.gardenFlushAssetCache=()=>Promise.all([...writes]);
 const cachePromise=typeof caches==='undefined'?Promise.resolve(null):caches.open(cacheName).catch(()=>null);
 cachePromise.then(async cache=>{if(!cache)return;try{for(const key of await cache.keys()){const name=new URL(key.url).pathname.split('/').pop();if(!Object.prototype.hasOwnProperty.call(sizes,name))await cache.delete(key);}}catch{}});
 const report=(file,loaded,total)=>window.gardenAssetBytes?.(file,loaded,total);
 async function request(url,range){
  const controller=new AbortController();let timer;
  const arm=()=>{clearTimeout(timer);timer=setTimeout(()=>controller.abort(new Error('Asset download stalled')),25000);};arm();
  try{
   const target=new URL(url,location.href);if(range)target.searchParams.set('range',range.slice(6));
   const response=await fetch(target.href,{cache:'force-cache',signal:controller.signal,headers:range?{Range:range}:{}});
   return {response,arm,finish:()=>clearTimeout(timer),abort:()=>{clearTimeout(timer);controller.abort();}};
  }catch(error){clearTimeout(timer);throw error;}
 }
 async function bytes(job,progress){
  const reader=job.response.body.getReader(),chunks=[];let size=0;
  try{for(;;){const item=await reader.read();if(item.done)break;job.arm();chunks.push(item.value);size+=item.value.length;progress(size);}}
  finally{job.finish();}
  const result=new Uint8Array(size);let offset=0;for(const part of chunks){result.set(part,offset);offset+=part.length;}return result;
 }
 async function download(file,url,total){
  const cache=await cachePromise,parts=Math.ceil(total/chunkSize),received=new Array(parts).fill(0);
  const controllers=new Set();let cancelled=false;
  const update=(index,n)=>{received[index]=n;report(file,received.reduce((a,b)=>a+b,0),total);};
  const key=index=>new URL(url+'?chunk='+index,location.href).href;
  const cached=async(index)=>{
   const hit=await cache?.match(key(index)).catch(()=>null);if(!hit)return null;
   const data=new Uint8Array(await hit.arrayBuffer());if(data.length!==Math.min(chunkSize,total-index*chunkSize))return null;
   update(index,data.length);return data;
  };
  const save=(index,data)=>{if(!cache)return;const task=cache.put(key(index),new Response(data)).catch(()=>{});writes.add(task);task.finally(()=>writes.delete(task));};
  // Probe support once. A server ignoring Range must not download the full file four times.
  let first=await cached(0),probe;
  if(!first){
   probe=await request(url,'bytes=0-'+(Math.min(chunkSize,total)-1));
   if(!probe.response.ok){probe.finish();return probe.response;}
   if(probe.response.status!==206){
    const reader=probe.response.body.getReader();let loaded=0;
    return new Response(new ReadableStream({async pull(stream){try{const item=await reader.read();if(item.done){probe.finish();stream.close();}else{probe.arm();loaded+=item.value.length;report(file,loaded,total);stream.enqueue(item.value);}}catch(error){probe.finish();stream.error(error);}},cancel(){probe.abort();return reader.cancel();}}),{headers:probe.response.headers});
   }
   validate(probe.response,0);first=await bytes(probe,n=>update(0,n));
   if(first.length!==Math.min(chunkSize,total))throw Error('Truncated asset range');save(0,first);
  }
  function validate(response,index){
   const start=index*chunkSize,end=Math.min(total,start+chunkSize)-1;
   if(response.status!==206||response.headers.get('Content-Range')!==`bytes ${start}-${end}/${total}`)throw Error('Invalid asset range');
  }
  async function part(index){
   const hit=await cached(index);if(hit)return hit;
   for(let attempt=0;attempt<3;attempt++){
    if(cancelled)throw Error('Download cancelled');let job;
    try{
     const start=index*chunkSize;job=await request(url,`bytes=${start}-${Math.min(total,start+chunkSize)-1}`);controllers.add(job);validate(job.response,index);
     const data=await bytes(job,n=>update(index,n));controllers.delete(job);
     if(data.length!==Math.min(chunkSize,total-start))throw Error('Truncated asset range');save(index,data);return data;
    }catch(error){job?.abort();controllers.delete(job);update(index,0);if(attempt===2)throw error;}
   }
  }
  const pending=new Map();let next=1,index=0;
  const fill=()=>{while(next<parts&&pending.size<parallel){const n=next++;const task=part(n);task.catch(()=>{});pending.set(n,task);}};fill();
  return new Response(new ReadableStream({async pull(stream){try{
   if(index===0){stream.enqueue(first);first=null;index++;return;}
   if(index>=parts){stream.close();return;}
   const data=await pending.get(index);pending.delete(index++);fill();stream.enqueue(data);
  }catch(error){cancelled=true;controllers.forEach(job=>job.abort());stream.error(error);}},cancel(){cancelled=true;controllers.forEach(job=>job.abort());}}));
 }
 window.gardenFetchAsset=async file=>{
  // Reuse the original engine URL from releases before gzip was introduced.
  // only-if-cached is essential: never start another 39 MB download on a miss.
  if(String(file).endsWith('.wasm')){
   try{
    const old=await fetch(file,{cache:'only-if-cached',mode:'same-origin'});
    if(old.status===200&&Number(old.headers.get('Content-Length'))===sizes[file]){
     window.gardenAssetState?.(file,false);report(file,sizes[file],sizes[file]);
     window.gardenAssetState?.(file,true);return old;
    }
   }catch{}
  }
  const compressed=String(file).endsWith('.wasm')&&typeof DecompressionStream==='function';
  window.gardenAssetState?.(file,false);
  let url=compressed?compressedWasm:file,total=sizes[url]||sizes[file];report(file,0,total);
  let response=await download(file,url,total);
  if(compressed&&!response.ok){url=file;total=sizes[file];report(file,0,total);response=await download(file,url,total);}
  else if(compressed&&response.ok)response=new Response(response.body.pipeThrough(new DecompressionStream('gzip')),{headers:{'Content-Type':'application/wasm'}});
  if(!response.ok)return response;
  const reader=response.body.getReader();
  return new Response(new ReadableStream({async pull(stream){try{const item=await reader.read();if(item.done){window.gardenAssetState?.(file,true);stream.close();}else stream.enqueue(item.value);}catch(error){stream.error(error);}},cancel(reason){return reader.cancel(reason);}}),{headers:response.headers});
 };
})();
