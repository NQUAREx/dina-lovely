// GitHub Pages cannot configure Content-Encoding. Decode a versioned gzip stream locally.
(()=>{
 const compressedWasm='engine.8032306d52d5.wasm.gz';
 window.gardenFetchAsset=async file=>{
  const compressed=String(file).endsWith('.wasm')&&typeof DecompressionStream==='function';
  window.gardenAssetState?.(file,false);
  const controller=new AbortController();let timer;
  const arm=()=>{clearTimeout(timer);timer=setTimeout(()=>controller.abort(new Error('Asset download stalled')),25000);};
  arm();let response;
  try{
   response=await fetch(compressed?compressedWasm:file,{signal:controller.signal});
   if(compressed&&!response.ok)response=await fetch(file,{signal:controller.signal});
   else if(compressed&&response.ok){
    const tracked=watch(response.body);
    return new Response(tracked.pipeThrough(new DecompressionStream('gzip')),{headers:{'Content-Type':'application/wasm'}});
   }
   if(!response.ok){clearTimeout(timer);return response;}
   return new Response(watch(response.body),{status:response.status,headers:response.headers});
  }catch(error){clearTimeout(timer);throw error;}
  function watch(body){
   const reader=body.getReader();
   return new ReadableStream({async pull(stream){
    try{const item=await reader.read();if(item.done){clearTimeout(timer);window.gardenAssetState?.(file,true);stream.close();}else{arm();stream.enqueue(item.value);}}
    catch(error){clearTimeout(timer);stream.error(error);}
   },cancel(reason){clearTimeout(timer);controller.abort();return reader.cancel(reason);}});
  }
 };
})();
