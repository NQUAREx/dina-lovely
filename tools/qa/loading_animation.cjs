const {chromium}=require(process.env.PLAYWRIGHT_MODULE||'/root/.local/share/love-bloom-qa/node_modules/playwright');
const crypto=require('crypto');
// Serve the repository root locally before running. Browser-level long-task
// regression only; this does not emulate actual iOS/WebKit image scheduling.
const base=process.env.TEST_URL||'http://127.0.0.1:8874/';
(async()=>{
 const b=await chromium.launch({headless:true,executablePath:'/root/.cache/ms-playwright/chromium-1248/chrome-linux-arm64/chrome',args:['--no-sandbox','--disable-dev-shm-usage','--autoplay-policy=no-user-gesture-required']});
 const p=await b.newPage({viewport:{width:240,height:240}});
 await p.goto(base);
 await p.setContent(`<body style="margin:0;background:#242538"><img style="width:128px;height:128px;image-rendering:pixelated" src="${base}assets/loading_heroine.gif">`,{waitUntil:'domcontentloaded'});
 await p.locator('img').evaluate(v=>v.decode());
 await p.waitForTimeout(700);
 const c=await p.context().newCDPSession(p),frames=[];
 c.on('Page.screencastFrame',e=>{frames.push({t:e.metadata.timestamp,h:crypto.createHash('sha256').update(e.data).digest('hex')});c.send('Page.screencastFrameAck',{sessionId:e.sessionId});});
 await c.send('Page.startScreencast',{format:'png',maxWidth:240,maxHeight:240,everyNthFrame:1});
 const start=Date.now();
 await p.evaluate(()=>{const until=performance.now()+3000;while(performance.now()<until){};});
 const end=Date.now();
 await c.send('Page.stopScreencast');
 console.log(JSON.stringify({blockedMs:end-start,frames:frames.length,distinct:new Set(frames.map(x=>x.h)).size,image:await p.locator('img').evaluate(v=>({complete:v.complete,width:v.naturalWidth,height:v.naturalHeight}))}));
 await p.screenshot({path:'/tmp/bloom-gif-loader.png'});await b.close();
 if(frames.length<4||new Set(frames.map(x=>x.h)).size<4)process.exitCode=1;
})().catch(e=>{console.error(e);process.exit(1)});
