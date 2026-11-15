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
 var x:=floorf(size.x/2)
 var heart:=PackedVector2Array([Vector2(-9,3),Vector2(-5,0),Vector2(0,4),Vector2(5,0),Vector2(9,3),Vector2(9,7),Vector2(0,15),Vector2(-9,7)])
 var badge:=PackedVector2Array([Vector2(x-35,2),Vector2(x-25,14),Vector2(x+25,14),Vector2(x+35,2)])
 draw_colored_polygon(badge,Color("6f4c65"))
 for i in range(heart.size()):heart[i]+=Vector2(x,2)
 draw_colored_polygon(heart,Color("efb5be"))
 draw_line(Vector2(x-21,5),Vector2(x-14,5),Color("e9c29e"),2)
 draw_line(Vector2(x+14,5),Vector2(x+21,5),Color("e9c29e"),2)
