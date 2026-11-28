const assert = require('node:assert/strict');
const fs = require('node:fs');
const http = require('node:http');
const path = require('node:path');
const { chromium } = require(process.env.PLAYWRIGHT_PATH || 'playwright');

const docs = path.resolve(__dirname, '../docs');
const content = fs.readFileSync(path.resolve(__dirname, '../content/letters.json'));
const fullContent = fs.readFileSync(path.resolve(__dirname, '../content/letters.backup.json'));
const types = { '.js': 'text/javascript', '.mp4': 'video/mp4', '.png': 'image/png', '.ttf': 'font/ttf' };
const server = http.createServer((req, res) => {
  const name = path.basename(new URL(req.url, 'http://localhost').pathname);
  if (!name) {
    res.setHeader('Content-Type', 'text/html');
    return res.end('<meta name="viewport" content="width=device-width,initial-scale=1"><script src="mobile.js"></script><canvas id="canvas"></canvas>');
  }
  const file = path.join(docs, name);
  if (!fs.existsSync(file)) {res.writeHead(404); return res.end();}
  res.setHeader('Content-Type', types[path.extname(name)] || 'application/octet-stream');
  fs.createReadStream(file).pipe(res);
});

async function check(browser, ios, failVideo = false, stallFrames = false, full = false) {
  const page = await browser.newPage({viewport:{width:390,height:844},isMobile:true,hasTouch:true,
    userAgent:ios ? 'Mozilla/5.0 (iPhone) AppleWebKit/605.1.15 Mobile Safari/604.1' : 'Mozilla/5.0 (Linux; Android 14) Chrome/153 Mobile'});
  try {
    if (ios) await page.addInitScript(() => Object.defineProperty(navigator,'standalone',{value:true}));
    if (stallFrames) await page.addInitScript(() => {
      HTMLImageElement.prototype.decode = () => new Promise(() => {});
    });
    if (failVideo) await page.route('**/*.mp4*', route => route.abort());
    await page.route('https://raw.githubusercontent.com/**', route => route.fulfill({contentType:'application/json',body:route.request().url().includes('/letters.backup.json') ? fullContent : content}));
    await page.goto('http://127.0.0.1:' + server.address().port);
    if (full) {
      const password = page.locator('#garden-edition-password');
      await password.fill('wrong-password');
      await password.press('Enter');
      await page.locator('#garden-password-error').waitFor();
      assert.equal(await page.locator('#garden-loading').count(), 0);
      assert.equal(await page.evaluate(() => window.gardenContent.demo_mode), true);
      await password.fill('love-in-bloom');
      await password.press('Enter');
    } else {
      await page.locator('#garden-play-demo').tap();
    }
    await page.waitForFunction(() => Promise.race([
      window.gardenLaunch.then(() => true), new Promise(resolve => setTimeout(() => resolve(false), 100)),
    ]));
    assert.equal(Boolean(await page.evaluate(() => window.gardenContent.demo_mode)), !full);
    if (ios) {
      await page.waitForFunction(() => window.gardenLoadingCanBuild === true);
      const movie = page.locator('#garden-loading video');
      if (failVideo) {
        assert.equal(await movie.count(), 0);
        assert.equal(await page.locator('.garden-loading-walk-strip').count(), 1);
      } else {
        const time = await movie.evaluate(video => video.currentTime);
        assert.ok(time > 0);
        await page.waitForFunction(t => document.querySelector('video').currentTime > t + .15, time);
        await page.evaluate(() => {window.gardenHideLoading(); return window.gardenShowLoading();});
        assert.ok(await movie.evaluate(video => video.loop && video.muted && video.playsInline && !video.paused && video.currentTime > 0));
      }
    } else {
      await page.evaluate(() => {window.gardenLoadProgress(25,100);window.gardenLoadProgress(10,100);});
      assert.equal(await page.locator('#garden-progress').evaluate(el => el.value), .25);
    }
    await page.evaluate(() => {
      document.querySelector('#garden-loading').dispatchEvent(new MouseEvent('click', {
        bubbles:true, clientX:17, clientY:62,
      }));
      const burst=[...document.body.querySelectorAll(':scope > i')].slice(-12);
      if (burst.length!==12 || burst.some(heart=>heart.style.left!=='17px'||heart.style.top!=='62px')) {
        throw new Error('The loading screen did not spawn hearts at the click position');
      }
    });
    await page.evaluate(() => window.gardenHideLoading());
    assert.equal(await page.locator('#garden-loading').count(), 0);
  } finally {await page.close();}
}

(async () => {
  await new Promise(resolve => server.listen(0,'127.0.0.1',resolve));
  const browser = await chromium.launch({executablePath:process.env.CHROMIUM_EXECUTABLE, args:['--no-sandbox','--disable-dev-shm-usage']});
  try {
    await check(browser,true);
    await check(browser,true,true);
    await check(browser,false);
    await check(browser,false,false,true);
    await check(browser,true,false,false,true);
    console.log('PASS password validation and edition selection, iOS playback, second launch, media fallback, Android byte progress and startup with stalled animations');
  } finally {await browser.close();server.close();}
})().catch(error => {console.error(error);server.close();process.exitCode=1;});
