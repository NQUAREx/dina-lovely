from pathlib import Path
exec(Path(__file__).with_name('firefox_qa.py').read_text().split('try:')[0])
from selenium.webdriver.common.actions.pointer_input import PointerInput
out=Path(__file__).parent/'screenshots'
try:
 d.set_window_size(960,620)
 load('http://127.0.0.1:8766/love-in-bloom/docs/')
 def tap(x,y):
  a=ActionBuilder(d,mouse=PointerInput('touch','finger'));a.pointer_action.move_to_location(x,y);a.pointer_action.pointer_down();a.pointer_action.pause(.12);a.pointer_action.pointer_up();a.perform();time.sleep(1)
 tap(480,257);shot('touch_intro');tap(480,381)
 a=ActionBuilder(d,mouse=PointerInput('touch','finger'));a.pointer_action.move_to_location(100,420);a.pointer_action.pointer_down();a.pointer_action.move_to_location(150,420);a.pointer_action.pause(.8);a.perform();shot('touch_joystick')
 a=ActionBuilder(d,mouse=PointerInput('touch','finger'));a.pointer_action.pointer_up();a.perform()
 ActionChains(d).reset_actions();time.sleep(2)
 tap(875,40);shot('touch_menu')
 d.set_window_size(540,960);time.sleep(1);shot('touch_portrait')
 print('Touch UI and joystick sequence completed',flush=True)
finally:d.quit()
