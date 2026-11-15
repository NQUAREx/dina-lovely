extends Control
## Border-only pixel ornaments; never receives input or changes container sizing.
var panel:Control
func _ready()->void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 clip_contents=true
 panel.resized.connect(fit_panel)
 call_deferred("fit_panel")
 resized.connect(queue_redraw)
func fit_panel()->void:
 position=Vector2.ZERO
 size=panel.size
func _draw()->void:
 var texture:Texture2D=preload("res://assets/ui/crest_button.png") if panel is Button else preload("res://assets/ui/crest_panel.png")
 var target:=Vector2(36,20) if panel is Button else Vector2(100,26)
 draw_texture_rect(texture,Rect2(Vector2((size.x-target.x)/2,0),target),false)
