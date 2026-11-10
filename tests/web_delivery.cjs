// Run against docs/ over HTTP. Dependencies: playwright and a Chromium installation.
const {chromium}=require(process.env.PLAYWRIGHT_MODULE||'playwright');
const {readFileSync}=require('fs');const {createHash}=require('crypto');const assert=require('assert');
(async()=>{
 const browser=await chromium.launch({executablePath:process.env.CHROMIUM_PATH||undefined,headless:true,args:['--no-sandbox','--disable-dev-shm-usage']});
 const page=await browser.newPage({viewport:{width:390,height:844},isMobile:true,hasTouch:true});
 await page.goto(process.env.TEST_URL||'http://127.0.0.1:8788/',{waitUntil:'domcontentloaded'});
 await page.waitForFunction(()=>typeof gardenShowLoading==='function');
 const requests=[];page.on('request',r=>requests.push(r.url()));
 const digest=await page.evaluate(async()=>{
  const loader=new Preloader();let count=0;loader.setProgressFunc(()=>count++);const download=loader.loadPromise('index.wasm',39514754,false);requestAnimationFrame(loader.animateProgress);
  const bytes=await download;const digest=await crypto.subtle.digest('SHA-256',bytes);
  return {hash:[...new Uint8Array(digest)].map(x=>x.toString(16).padStart(2,'0')).join(''),count,size:bytes.byteLength};
 });
 assert.equal(digest.hash,createHash('sha256').update(readFileSync('docs/index.wasm')).digest('hex'));assert(digest.count>0);
 assert(requests.some(u=>u.includes('.wasm.gz'))&&!requests.some(u=>u.endsWith('/index.wasm')));
 await page.evaluate(()=>gardenShowLoading());
 const coverage=await page.evaluate(()=>{const r=document.getElementById('garden-loading').getBoundingClientRect();return {bottom:r.bottom,height:innerHeight,bg:getComputedStyle(document.documentElement).backgroundColor,theme:document.querySelector('meta[name=theme-color]').content};});
 assert(coverage.bottom>=coverage.height);assert.equal(coverage.bg,'rgb(36, 37, 56)');assert.equal(coverage.theme,'#242538');
 await page.screenshot({path:'/tmp/loading-safe-area.png'});
 // A truncated successful HTTP response used to leave getTrackedResponse pending forever.
 await page.route('**/*.wasm.gz',r=>r.fulfill({status:200,body:readFileSync('docs/'+requests.find(u=>u.includes('.wasm.gz')).split('/').pop()).subarray(0,1024)}));
 const failed=await page.evaluate(()=>Promise.race([new Preloader().loadPromise('index.wasm',39514754,false).then(()=>false,()=>true),new Promise(r=>setTimeout(()=>r('hung'),5000))]));assert.equal(failed,true);
 // Callback-style WASM initialization must show recovery rather than an endless loading screen.
 await page.evaluate(()=>{const c=new Engine();c.init('index').catch(()=>{});});
 await page.waitForSelector('#garden-recovery',{timeout:10000});assert.equal(await page.locator('#garden-loading').count(),0);
 console.log('PASS gzip byte identity, compressed-only request, progress, loading bottom coverage, truncated stream rejection and WASM recovery',digest);
 await browser.close();
})().catch(e=>{console.error(e);process.exit(1)});
