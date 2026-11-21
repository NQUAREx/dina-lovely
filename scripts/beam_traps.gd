extends RefCounted

const LEFT := 48.0
const WIDTH := 432.0
const SPIKE_CLOSED := Rect2(0,0,32,32)
const SPIKE_RAISED := Rect2(32,0,32,32)

var game:Node2D
var beams:Array[Dictionary]=[]
var spikes:Array[Dictionary]=[]
var clock:=0.0
var spike_art:Texture2D

func _init(owner:Node2D)->void:
	game=owner

func reset(rng:RandomNumberGenerator)->void:
	beams.clear()
	spikes.clear()
	clock=0.0
	for row in range(4):
		var width:=rng.randf_range(140,270)
		beams.append({"width":width,"y":(12.0+row*5+rng.randf_range(-.35,.35))*48,
			"phase":rng.randf_range(0.0,TAU),"period":rng.randf_range(2.7,4.9),
			"warp":rng.randf_range(.20,.61),"amp":(WIDTH-width)*rng.randf_range(.37,.49)})
	for row in range(3):
		var y:=(14.5+row*5+rng.randf_range(-.4,.4))*48
		for col in range(7):
			var center:=Vector2(LEFT+30+col*62+rng.randf_range(-6,6),y+rng.randf_range(-12,12))
			var size:=Vector2(rng.randf_range(37,54),rng.randf_range(34,47))
			spikes.append({"rect":Rect2(center-size/2,size),"phase":rng.randf_range(0,TAU),
				"period":rng.randf_range(2.0,3.65),"warp":rng.randf_range(.25,.58),
				"threshold":rng.randf_range(-.15,.31)})

func phase(trap:Dictionary)->float:
	var t:=clock*TAU/float(trap.period)+float(trap.phase)
	return sin(t+sin(t*.51+float(trap.phase))*float(trap.warp))

func beam_box(beam:Dictionary)->Rect2:
	var size:=Vector2(float(beam.width),25)
	var center:=Vector2(LEFT+WIDTH*.5+float(beam.amp)*phase(beam),beam.y)
	return Rect2(center-size/2,size)

func spike_height(spike:Dictionary)->float:
	return smoothstep(float(spike.threshold)-.22,float(spike.threshold)+.25,phase(spike))

func step(delta:float)->bool:
	clock+=delta
	for beam in beams:
		if beam_box(beam).grow(7).has_point(game.player):return true
	for spike in spikes:
		var box:Rect2=spike.rect
		if spike_height(spike)>.56 and box.grow(-4).has_point(game.player):return true
	return false

func append_renderables(queue:Array[Dictionary])->void:
	for beam in beams:
		var box:=beam_box(beam)
		queue.append({"kind":"hall_beam","pos":box.get_center(),"rect":box})
	for spike in spikes:
		var box:Rect2=spike.rect
		queue.append({"kind":"hall_spike","pos":box.get_center(),"rect":box,"height":spike_height(spike)})

func draw(item:Dictionary)->void:
	var box:Rect2=item.rect
	var p:Vector2=game.screen(box.position)
	if item.kind=="hall_beam":
		var left:Vector2=game.screen(Vector2(LEFT+8,box.get_center().y))
		game.draw_rect(Rect2(left-Vector2(0,3),Vector2(WIDTH-16,6)),Color("514350"))
		game.draw_rect(Rect2(left-Vector2(0,3),Vector2(WIDTH-16,2)),Color("9a7d7b"))
		var count:=ceili(box.size.x/40.0)
		for index in range(count):
			game.draw_sprite("moving_bar",p+Vector2(box.size.x/count*(index+.5),26),Color.WHITE,box.size.x/count/40.0)
		return
	if spike_art==null:spike_art=load("res://assets/beam_spikes.png")
	game.draw_texture_rect_region(spike_art,Rect2(p,box.size),SPIKE_CLOSED)
	var lift:float=item.height
	if lift>.01:
		game.draw_texture_rect_region(spike_art,Rect2(p-Vector2(0,16*lift),box.size),SPIKE_RAISED,Color(1,1,1,clampf(lift*2,0,1)))
