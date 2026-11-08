"""Real Firefox WebGL preview and isolated browser state-machine regression."""
from selenium import webdriver
from selenium.webdriver.firefox.service import Service
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.common.actions.action_builder import ActionBuilder
from pathlib import Path
import time,json
out=Path(__file__).parent/'screenshots'
opt=webdriver.FirefoxOptions();opt.binary_location='/usr/bin/firefox-esr';opt.set_preference('webgl.force-enabled',True)
d=webdriver.Firefox(service=Service('/root/toolchains/geckodriver'),options=opt)
def shot(name):d.save_screenshot(str(out/(name+'.png')))
def click(x,y):
 a=ActionBuilder(d);a.pointer_action.move_to_location(x,y);a.pointer_action.click();a.perform();time.sleep(.7)
def load(url):
 d.get(url);WebDriverWait(d,120).until(lambda d:d.execute_script('return !document.getElementById("status")'));time.sleep(2)
try:
 d.set_window_size(960,620)
 load('http://127.0.0.1:8766/love-in-bloom/docs/')
 shot('web_menu');click(480,257);shot('web_intro');click(480,381)
 shot('web_maze_before')
 ActionChains(d).key_down('d').pause(.8).key_up('d').perform();shot('web_maze_after')
 time.sleep(2)
 saves=d.execute_async_script('''const done=arguments[0];let q=indexedDB.open('/userfs');q.onsuccess=()=>{let db=q.result;let tx=db.transaction('FILE_DATA','readonly'),s=tx.objectStore('FILE_DATA'),c=s.openCursor(),a=[];c.onsuccess=()=>{let r=c.result;if(!r){done(a);return;}if(String(r.key).endsWith('garden_save_v1.json'))a.push(new TextDecoder().decode(r.value.contents));r.continue();};};''')
 print('RELEASE_SAVE',saves,flush=True)
 assert saves and json.loads(saves[0])['started']
 load('http://127.0.0.1:8766/love-in-bloom/docs/');shot('web_continue_menu')
 d.set_window_size(540,960);time.sleep(2);shot('web_portrait');d.set_window_size(960,620)
 load('http://127.0.0.1:8766/love-browser-qa/docs/')
 result=WebDriverWait(d,120).until(lambda d:d.execute_script('return window.qaResult || null'))
 print('BROWSER_PLAYTHROUGH',result,flush=True)
 assert result['finished'] and result['letters']==7 and result['passed']==51
 shot('web_card')
 (Path(__file__).parent/'firefox-results.json').write_text(json.dumps(result,indent=2))
finally:d.quit()
