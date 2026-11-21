extends CanvasLayer
var game:Node
var panel:PanelContainer
var output:TextEdit
var status:Label
var timer:Timer
var sliders:Dictionary={}
var scroll:ScrollContainer
var toggle:Button
var copy_button:Button
var reset_button:Button
var gestures:Dictionary={}

const FIELDS=[
 ["opacity","Темнота",0.0,.65,.01], ["fade_start","Начало fade",-15.0,-1.0,.5],
 ["fade_end","Конец fade",0.0,7.0,.5], ["offset_x","Сдвиг вправо",10.0,18.0,.5],
 ["offset_y","Сдвиг вниз",12.0,20.0,.5], ["width","Ширина",6.0,12.0,.5],
 ["height","Высота",7.0,13.0,.5], ["rounding","Округление",1.0,6.0,.5],
 ["ripple_x","Неровность X",0.0,2.0,.1], ["ripple_y","Неровность Y",0.0,2.0,.1],
 ["red","Затемнение R",0.0,1.0,.01], ["green","Затемнение G",0.0,1.0,.01], ["blue","Затемнение B",0.0,1.0,.01]]
func _ready():
 layer=150
 toggle=Button.new();toggle.text="Тени ⚙";toggle.position=Vector2(390,270);toggle.size=Vector2(140,48);add_child(toggle)
 panel=PanelContainer.new();panel.position=Vector2(38,322);panel.size=Vector2(464,560);add_child(panel)
 var style:=StyleBoxFlat.new();style.bg_color=Color("282433");style.border_color=Color("ca9bae");style.set_border_width_all(3);style.set_corner_radius_all(8);style.set_content_margin_all(12);panel.add_theme_stylebox_override("panel",style)
 var vertical:=VBoxContainer.new();panel.add_child(vertical)
 var header:=Label.new();header.text="Тени кустов • настройки";header.add_theme_font_size_override("font_size",20);vertical.add_child(header)
 scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;vertical.add_child(scroll)
 var list:=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(list)
 for field in FIELDS:
  var line:=HBoxContainer.new();list.add_child(line)
  var label:=Label.new();label.text=field[1];label.custom_minimum_size=Vector2(135,38);label.add_theme_font_size_override("font_size",15);line.add_child(label)
  var slider:=HSlider.new();slider.min_value=field[2];slider.max_value=field[3];slider.step=field[4];slider.value=game.hedge_shadow_settings[field[0]];slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL;slider.custom_minimum_size=Vector2(120,38);line.add_child(slider)
  var number:=Label.new();number.custom_minimum_size=Vector2(52,38);number.add_theme_font_size_override("font_size",15);number.text=str(slider.value);line.add_child(number)
  slider.value_changed.connect(func(value):number.text=str(value);game.hedge_shadow_settings[field[0]]=value;timer.start())
  sliders[field[0]]=slider
 var actions:=HBoxContainer.new();vertical.add_child(actions)
 copy_button=Button.new();copy_button.text="Скопировать параметры";copy_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;copy_button.custom_minimum_size.y=44;actions.add_child(copy_button)
 reset_button=Button.new();reset_button.text="Сброс";reset_button.custom_minimum_size.y=44;actions.add_child(reset_button)
 status=Label.new();status.text="Изменения применяются к лабиринту";status.add_theme_font_size_override("font_size",14);vertical.add_child(status)
 output=TextEdit.new();output.custom_minimum_size.y=58;output.editable=false;output.visible=false;vertical.add_child(output)
 toggle.pressed.connect(func():panel.visible=not panel.visible;toggle.text="Свернуть ✕" if panel.visible else "Тени ⚙")
 reset_button.pressed.connect(func():
  var defaults={"opacity":.31,"fade_start":-7.0,"fade_end":5.0,"offset_x":16.0,"offset_y":19.0,"width":10.0,"height":8.0,"rounding":4.0,"ripple_x":.45,"ripple_y":.45,"red":.84,"green":.78,"blue":.70}
  for key in defaults:sliders[key].value=defaults[key]
 )
 copy_button.pressed.connect(copy_settings)
 timer=Timer.new();timer.one_shot=true;timer.wait_time=.2;timer.timeout.connect(game.refresh_debug_hedge_shadow);add_child(timer)
 toggle.text="Свернуть ✕"
func copy_settings():
 var result="Параметры теней кустов Love in Bloom:\n"+JSON.stringify(game.hedge_shadow_settings,"  ")
 DisplayServer.clipboard_set(result)
 # Also show selectable text, so copying remains possible when iOS denies clipboard.
 output.text=result;output.visible=true;output.select_all();status.text="Параметры готовы: если не скопированы, выделите текст ниже"

# Explicit touch routing: ScrollContainer otherwise captures drags intended for
# HSlider on mobile. Capture the finger until release, including outside panel.
func handle_touch(event:InputEvent)->bool:
 if event is InputEventScreenTouch:
  if event.pressed:
   var pos:Vector2=event.position
   var kind:=""
   var target:Control
   if toggle.get_global_rect().has_point(pos):kind="button";target=toggle
   elif panel.visible and panel.get_global_rect().has_point(pos):
    if copy_button.get_global_rect().has_point(pos):kind="button";target=copy_button
    elif reset_button.get_global_rect().has_point(pos):kind="button";target=reset_button
    elif scroll.get_global_rect().has_point(pos):
     for slider in sliders.values():
      if slider.is_visible_in_tree() and slider.get_global_rect().intersection(scroll.get_global_rect()).has_point(pos):
       kind="slider";target=slider;break
     if kind=="":kind="scroll"
    else:kind="panel"
   if kind=="":return false
   gestures[event.index]={"kind":kind,"target":target,"last":pos}
   if kind=="slider":set_slider_from_touch(target,pos)
   return true
  if gestures.has(event.index):
   var gesture:Dictionary=gestures[event.index];gestures.erase(event.index)
   if gesture.kind=="button" and is_instance_valid(gesture.target) and gesture.target.get_global_rect().has_point(event.position):gesture.target.pressed.emit()
   return true
 elif event is InputEventScreenDrag and gestures.has(event.index):
  var gesture:Dictionary=gestures[event.index]
  if gesture.kind=="slider":set_slider_from_touch(gesture.target,event.position)
  elif gesture.kind=="scroll":scroll.scroll_vertical-=int(event.position.y-gesture.last.y)
  gesture.last=event.position
  return true
 return false

func set_slider_from_touch(slider:HSlider,pos:Vector2)->void:
 var rect:=slider.get_global_rect()
 var fraction:=clampf((pos.x-rect.position.x)/rect.size.x,0.0,1.0)
 slider.value=lerpf(slider.min_value,slider.max_value,fraction)
