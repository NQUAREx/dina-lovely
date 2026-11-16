const {chromium}=require(process.env.PLAYWRIGHT_MODULE||'/root/.local/share/love-bloom-qa/node_modules/playwright');
const crypto=require('crypto'),fs=require('fs'),path=require('path'),os=require('os'),{spawnSync}=require('child_process');
// Serve the repository root locally before running. This verifies compositor
// motion/visibility during blocked JavaScript, not actual Safari hardware.
const base=process.env.TEST_URL||'http://127.0.0.1:8874/';
(async()=>{
 const b=await chromium.launch({headless:true,executablePath:'/root/.cache/ms-playwright/chromium-1248/chrome-linux-arm64/chrome',args:['--no-sandbox','--disable-dev-shm-usage','--autoplay-policy=no-user-gesture-required']});
 const p=await b.newPage({viewport:{width:240,height:240}});
 await p.goto(base);
 const source=fs.readFileSync(path.join(__dirname,'../mobile_shell.js'),'utf8');
 const expression=source.slice(source.indexOf(' const loadingWalkFrames=')+' const loadingWalkFrames='.length,source.indexOf(" }).join('');",source.indexOf(' const loadingWalkFrames='))+" }).join('');".length-1);
 const loadingWalkFrames=Function('return '+expression)();
 const css=source.match(/#garden-loading \.garden-loading-heroine\{[^`]+?(?=`;)/)[0].replace('${loadingWalkFrames}',loadingWalkFrames);
 const images=Array.from({length:8},(_,i)=>`<img class="garden-loading-heroine-image" style="animation-name:garden-loading-pose-${i};z-index:${i}" src="${base}assets/loading_heroine_${i}.png">`).join('');
 await p.setContent(`<style>${css}</style><body style="margin:0;background:#242538"><section id="garden-loading"><div class="garden-loading-heroine">${images}</div></section>`,{waitUntil:'domcontentloaded'});
 await p.locator('img').evaluateAll(images=>Promise.all(images.map(v=>v.decode())));
 await p.waitForTimeout(700);
 const c=await p.context().newCDPSession(p),frames=[];
 c.on('Page.screencastFrame',e=>{frames.push({t:e.metadata.timestamp,data:e.data,h:crypto.createHash('sha256').update(e.data).digest('hex')});c.send('Page.screencastFrameAck',{sessionId:e.sessionId});});
 await c.send('Page.startScreencast',{format:'png',maxWidth:240,maxHeight:240,everyNthFrame:1});
 const start=Date.now();
 await p.evaluate(()=>{const until=performance.now()+3000;while(performance.now()<until){};});
 const end=Date.now();
 await c.send('Page.stopScreencast');
 const folder=fs.mkdtempSync(path.join(os.tmpdir(),'bloom-resident-poses-'));
 frames.forEach((f,i)=>fs.writeFileSync(path.join(folder,String(i)+'.png'),Buffer.from(f.data,'base64')));
 const visibility=spawnSync('python3',['-c',`import json,sys\nfrom PIL import Image\nfrom pathlib import Path\ncounts=[]\nfor p in Path(sys.argv[1]).glob('*.png'):\n im=Image.open(p).convert('RGB')\n counts.append(sum(1 for r,g,b in im.getdata() if r>150 and g>140 and b>130))\nprint(json.dumps({'minVisiblePixels':min(counts) if counts else 0,'maxVisiblePixels':max(counts) if counts else 0,'blankFrames':sum(n<300 for n in counts)}))`,folder],{encoding:'utf8'});
 if(visibility.status!==0)throw new Error(visibility.stderr);
 const visible=JSON.parse(visibility.stdout);
 const poses=await p.locator('img').evaluateAll(images=>images.map(v=>({complete:v.complete,width:v.naturalWidth,height:v.naturalHeight})));
 console.log(JSON.stringify({blockedMs:end-start,frames:frames.length,distinct:new Set(frames.map(x=>x.h)).size,...visible,poses}));
 await p.screenshot({path:'/tmp/bloom-resident-loader.png'});await b.close();
 fs.rmSync(folder,{recursive:true,force:true});
 if(frames.length<4||new Set(frames.map(x=>x.h)).size<4||visible.blankFrames||visible.minVisiblePixels<300||poses.some(x=>!x.complete||x.width!==64))process.exitCode=1;
})().catch(e=>{console.error(e);process.exit(1)});
