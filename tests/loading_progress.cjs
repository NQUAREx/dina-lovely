const assert = require('node:assert/strict');
const fs = require('node:fs');
const http = require('node:http');
const {chromium} = require('/root/termux-remote-access/tools/node_modules/playwright');
const content = JSON.parse(fs.readFileSync('content/letters.json'));
const server = http.createServer((req, res) => {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.end('<!doctype html><meta name="viewport" content="width=device-width,initial-scale=1"><script>' + fs.readFileSync('tools/mobile_shell.js', 'utf8') + '</script>');
});
(async () => {
  await new Promise(resolve => server.listen(8778, '127.0.0.1', resolve));
  const browser = await chromium.launch({executablePath:'/root/.cache/ms-playwright/chromium-1243/chrome-linux-arm64/chrome', headless:true, args:['--no-sandbox','--disable-dev-shm-usage']});
  try {
    const page = await browser.newPage({viewport:{width:390,height:844},isMobile:true,hasTouch:true,userAgent:'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/153.0 Mobile Safari/537.36'});
    await page.route('https://raw.githubusercontent.com/**', route => route.fulfill({json:content}));
    await page.goto('http://127.0.0.1:8778/');
    await page.getByRole('button', {name:content.ui.launch_button.text, exact:true}).tap();
    await page.evaluate(() => window.gardenLoadProgress(25,100));
    assert.equal(await page.locator('#garden-progress').evaluate(el => el.value), .25);
    await page.evaluate(() => window.gardenLoadProgress(10,100));
    assert.equal(await page.locator('#garden-progress').evaluate(el => el.value), .25);
    assert.match(await page.locator('#garden-loading').innerText(), /✦/);
    await page.screenshot({path:'/tmp/details-loading.png'});
    await page.evaluate(() => window.gardenHideLoading());
    assert.equal(await page.locator('#garden-loading').count(), 0);
    assert.match(fs.readFileSync('docs/index.html','utf8'), /gardenLoadProgress\?\.\(current,total\)/);
    console.log('PASS mobile Chromium: star, byte progress, monotonic bar, overlay cleanup and export callback');
  } finally {await browser.close();server.close();}
})().catch(error => {console.error(error);server.close();process.exitCode=1;});
