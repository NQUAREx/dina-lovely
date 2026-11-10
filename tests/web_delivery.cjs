// Run against docs/ over HTTP. Dependencies: playwright and a Chromium installation.
const {chromium}=require(process.env.PLAYWRIGHT_MODULE||'playwright');
const {readFileSync}=require('fs');const {createHash}=require('crypto');const assert=require('assert');
(async()=>{
 const browser=await chromium.launch({executablePath:process.env.CHROMIUM_PATH||undefined,headless:true,args:['--no-sandbox','--disable-dev-shm-usage']});
 const page=await browser.newPage({viewport:{width:390,height:844},isMobile:true,hasTouch:true});
 await page.goto(process.env.TEST_URL||'http://127.0.0.1:8788/',{waitUntil:'domcontentloaded'});
 await page.waitForFunction(()=>typeof gardenShowLoading==='function');
 const requests=[];let ranged=false;page.on('request',r=>requests.push(r.url()));page.on('response',r=>{if(r.status()===206)ranged=true;});
 console.log('phase initial');
 const digest=await page.evaluate(async()=>{
  const loader=new Preloader();let count=0;loader.setProgressFunc(()=>count++);const download=loader.loadPromise('index.wasm',39514754,false);requestAnimationFrame(loader.animateProgress);
  const bytes=await download;const digest=await crypto.subtle.digest('SHA-256',bytes);
  return {hash:[...new Uint8Array(digest)].map(x=>x.toString(16).padStart(2,'0')).join(''),count,size:bytes.byteLength};
 });
 assert.equal(digest.hash,createHash('sha256').update(readFileSync('docs/index.wasm')).digest('hex'));assert(digest.count>0);
 assert(requests.some(u=>u.includes('.wasm.gz'))&&!requests.some(u=>u.endsWith('/index.wasm')));
 console.log('phase cache');
 await page.evaluate(()=>gardenFlushAssetCache());
 if(ranged){
  requests.length=0;
  const again=await page.evaluate(async()=>{const r=await gardenFetchAsset('index.wasm');return (await r.arrayBuffer()).byteLength;});
  assert.equal(again,digest.size);assert.equal(requests.length,0,'cached engine must not hit network');
  // Keep two complete chunks, imitating a closed app during a slow download.
  await page.evaluate(async()=>{const c=await caches.open('garden-assets-v1');for(const key of await c.keys())if(!/[?&]chunk=[01]$/.test(key.url))await c.delete(key);});
  console.log('phase resume');
 const ranges=[];page.on('request',r=>{if(r.url().includes('.wasm.gz'))ranges.push(r.headers().range);});
  await page.evaluate(async()=>{const r=await gardenFetchAsset('index.wasm');await r.arrayBuffer();});
  assert(ranges.length>1&&ranges.every(r=>Number(r.match(/bytes=(\d+)/)[1])>=1048576),'resume must skip cached first MB');
 }
 const transfer=await page.evaluate(()=>({loaded:gardenBoot.loaded,total:gardenBoot.total}));
 assert(transfer.total<11000000&&transfer.loaded===transfer.total,'show transport bytes, not 39.5 MB expanded bytes');
 console.log('phase broken stream');
 await page.evaluate(()=>gardenShowLoading());
 const coverage=await page.evaluate(()=>{const r=document.getElementById('garden-loading').getBoundingClientRect();return {bottom:r.bottom,height:innerHeight,bg:getComputedStyle(document.documentElement).backgroundColor,theme:document.querySelector('meta[name=theme-color]').content};});
 assert(coverage.bottom>=coverage.height);assert.equal(coverage.bg,'rgb(36, 37, 56)');assert.equal(coverage.theme,'#242538');
 await page.screenshot({path:'/tmp/loading-safe-area.png'});
 await page.evaluate(async()=>{const c=await caches.open('garden-assets-v1');for(const key of await c.keys())await c.delete(key);});
 // A truncated successful HTTP response used to leave getTrackedResponse pending forever.
 await page.route('**/*.wasm.gz*',r=>r.fulfill({status:200,body:Buffer.from([31,139,8,0])}));
 const failed=await page.evaluate(()=>Promise.race([new Preloader().loadPromise('index.wasm',39514754,false).then(()=>false,()=>true),new Promise(r=>setTimeout(()=>r('hung'),5000))]));assert.equal(failed,true);
 // Callback-style WASM initialization must show recovery rather than an endless loading screen.
 await page.evaluate(()=>{const c=new Engine();c.init('index').catch(()=>{});});
 await page.waitForSelector('#garden-recovery',{timeout:10000});assert.equal(await page.locator('#garden-loading').count(),0);
 console.log('PASS gzip identity, real transfer size, parallel ranges, complete cache reuse, partial resume, loading coverage and broken-stream recovery',digest,'range server:',ranged);
 await browser.close();
})().catch(e=>{console.error(e);process.exit(1)});
