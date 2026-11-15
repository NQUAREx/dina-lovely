import json, os, time
from pathlib import Path
from selenium import webdriver
from selenium.webdriver.firefox.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait

opt=webdriver.FirefoxOptions()
opt.binary_location='/usr/bin/firefox-esr'
opt.set_preference('webgl.force-enabled',True)
opt.set_preference('webgl.disabled',False)
opt.set_preference('media.autoplay.default',0)
opt.set_preference('general.useragent.override','Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/153.0 Mobile Safari/537.36')
opt.set_preference('devtools.console.stdout.content',True)
driver=webdriver.Firefox(service=Service('/root/toolchains/geckodriver',log_output='/tmp/love-bloom-geckodriver.log'),options=opt)
wait=WebDriverWait(driver,150)
try:
 driver.set_window_size(480,960)
 driver.get(os.environ.get('TEST_URL','http://127.0.0.1:8788/'))
 wait.until(lambda d:d.find_elements(By.CSS_SELECTOR,'#mobile-gate button'))
 if os.environ.get('SHELL_ONLY'):
  print(json.dumps(driver.execute_script('return {title:document.title,button:document.querySelector("#mobile-gate button").textContent,contentLoaded:!!window.gardenContent,canvas:!!document.getElementById("canvas"),pack:typeof GODOT_CONFIG!=="undefined"?GODOT_CONFIG.mainPack:null}'),ensure_ascii=False),flush=True)
  driver.save_screenshot('/tmp/love-bloom-live-shell.png')
  raise SystemExit(0)
 driver.execute_script('''window.qaErrors=[];addEventListener('error',e=>qaErrors.push(e.message));addEventListener('unhandledrejection',e=>qaErrors.push(String(e.reason)));const old=console.error;console.error=(...a)=>{qaErrors.push(a.map(String).join(' '));old(...a)};''')
 driver.find_element(By.CSS_SELECTOR,'#mobile-gate button').click()
 wait.until(lambda d:d.execute_script('return !document.getElementById("status") && !document.getElementById("garden-loading") || !!document.getElementById("garden-recovery")'))
 time.sleep(3)
 state=driver.execute_script('''return {title:document.title,errors:qaErrors,recovery:document.getElementById('garden-recovery')?.innerText||null,loading:!!document.getElementById('garden-loading'),gate:!!document.getElementById('mobile-gate'),canvas:{width:document.getElementById('canvas').width,height:document.getElementById('canvas').height},boot:gardenBoot};''')
 driver.save_screenshot('/tmp/love-bloom-firefox-menu.png')
 print(json.dumps(state,ensure_ascii=False),flush=True)
 assert not state['errors'],state['errors']
 assert not state['recovery'],state['recovery']
 assert not state['loading'] and not state['gate']
 # The game UI is rendered in the canvas; use the portrait menu coordinates.
 print('PASS Firefox mobile shell, live content, engine load, initial canvas, no captured JS errors',flush=True)
finally:
 driver.quit()
