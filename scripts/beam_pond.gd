extends RefCounted
## Inward-moving neighbours cross twice in every base cycle. Their varying
## phases and secondary oscillators change when and where the crossings occur.
const BOUNDS := Rect2(528,672,432,576)
const PLATFORM_COUNT := 9
const BASE_RATE := 1.12
const LILY_REGION := Vector2(72,60)
const RIPPLE := Color("#a0b7a7")

var game:Node2D
var water:Texture2D
var lilies:Texture2D
var pads:Array[Dictionary]=[]
var seconds:=0.0
var riding:=-1
var hop:=0.0

func _init(owner:Node2D)->void:
	game=owner

func reset(rng:RandomNumberGenerator)->void:
	seconds=0.0
	riding=-1
	hop=0.0
	pads.clear()
	var phase:=rng.randf_range(0.0,TAU)
	for index in range(PLATFORM_COUNT):
		pads.append({
			"center": Vector2(
				BOUNDS.get_center().x+rng.randf_range(-24,24),
				lerpf(BOUNDS.position.y+33,BOUNDS.end.y-33,float(index)/(PLATFORM_COUNT-1))),
			"radius": Vector2(rng.randf_range(50,62),rng.randf_range(44,51)),
			"amplitude": rng.randf_range(97,124),
			"bob": rng.randf_range(2,4),
			"phase": phase+index*PI+rng.randf_range(-.27,.27),
			"drift": rng.randf_range(.15,.38),
			"rhythm": rng.randf_range(.48,1.07),
			"accent": rng.randf_range(0,TAU),
			"variant": rng.randi_range(0,5),
		})

func pad_position(index:int,clock:float)->Vector2:
	var pad:=pads[index]
	var irregular:float=clock*pad.rhythm+pad.accent
	var angle:float=clock*BASE_RATE+pad.phase+sin(irregular)*pad.drift
	return pad.center+Vector2(
		sin(angle)*pad.amplitude+sin(irregular*.53)*9.0,
		sin(irregular*.8)*pad.bob)

func support(foot:Vector2)->int:
	var best:=-1
	var margin:=1.0
	for index in range(pads.size()):
		var normalized:Vector2=(foot-pad_position(index,seconds))/pads[index].radius
		var distance:=normalized.length_squared()
		if distance>1.0:continue
		# Keep the original support in the overlap until the feet are clearly
		# over the next pad, so the carry direction cannot flicker.
		var weight:=distance-(.13 if index==riding else 0.0)
		if weight<margin:
			best=index
			margin=weight
	return best

func step(delta:float)->bool:
	var foot:Vector2=game.player
	var afloat:=BOUNDS.has_point(foot)
	var next_platform:=support(foot) if afloat else -1
	var carry:=Vector2.ZERO
	if next_platform>=0:
		carry=pad_position(next_platform,seconds+delta)-pad_position(next_platform,seconds)
		if riding>=0 and next_platform!=riding:hop=.24
	riding=next_platform
	seconds+=delta
	hop=maxf(0.0,hop-delta)
	if riding>=0:
		var carried:=foot+carry
		carried.x=clampf(carried.x,BOUNDS.position.x+10,BOUNDS.end.x-10.01)
		game.player=carried
		return false
	return afloat

func lift()->float:
	return sin(hop*PI/.24)*14.0

func draw_ground()->void:
	var origin:Vector2=game.screen(BOUNDS.position)
	var pool:=Rect2(origin,BOUNDS.size)
	if not pool.intersects(game.get_viewport_rect()):return
	if water==null:
		water=load("res://assets/beam_pond.png")
		lilies=load("res://assets/beam_lilies.png")
	game.draw_texture_rect(water,pool,false)
	for index in range(26):
		var x:=fposmod(index*127.4+seconds*4.0,BOUNDS.size.x-34)+14
		var y:=fposmod(index*153.0,BOUNDS.size.y-28)+14
		var crest:=origin+Vector2(roundf(x*.5)*2,roundf(y*.5)*2)
		var glint:=RIPPLE
		glint.a=.13+.12*sin(seconds*2.4+index)
		game.draw_rect(Rect2(crest,Vector2(8+index%4*2,2)),glint)
	for index in range(pads.size()):
		var pad:=pads[index]
		var center:Vector2=game.screen(pad_position(index,seconds))
		var size:Vector2=Vector2(2.18,2.31)*pad.radius
		var leaf:=Rect2((center-size*.5).round(),size.round())
		# Docking leaves hang over the stone lip instead of being cut in half.
		var horizontal_limit:=Rect2(pool.position.x,leaf.position.y,pool.size.x,leaf.size.y)
		var visible:=leaf.intersection(horizontal_limit)
		if not visible.has_area():continue
		var scale:=LILY_REGION/leaf.size
		var source:=Rect2(Vector2(pad.variant*LILY_REGION.x,0)+(visible.position-leaf.position)*scale,visible.size*scale)
		game.draw_texture_rect_region(lilies,visible,source)
