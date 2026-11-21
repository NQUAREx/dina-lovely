extends RefCounted
## Lily motion and marks use pond-local coordinates so the same water draws
## from either side of the room.
const BOUNDS := Rect2(528,624,432,624)
const PLATFORM_COUNT := 10
const LEAF_SCALE := Vector2(72.0/52.0,60.0/52.0)
const SWIMMING_AREA := Rect2(528,637,432,598)
# The retaining stones occupy eight pixels at each bank. Keep a strip of
# water visible beyond them, with an extra pixel for sprite rounding.
const LEAF_INSET := 13.0
const LILY_REGION := Vector2(72,60)
const RIPPLE := Color("#a0b7a7")

var game:Node2D
var water:Texture2D
var lilies:Texture2D
var lily_pixels:Image
var prints:Array[Dictionary]=[]
var pads:Array[Dictionary]=[]
var seconds:=0.0
var motion_rng:=RandomNumberGenerator.new()
var riding:=-1
var hop:=0.0

func _init(owner:Node2D)->void:
	game=owner

func reset(rng:RandomNumberGenerator)->void:
	seconds=0.0
	motion_rng.seed=rng.randi()
	riding=-1
	hop=0.0
	pads.clear()
	prints.clear()
	for index in range(PLATFORM_COUNT):
		var diameter:=rng.randf_range(65.0,69.0)
		var bank_offset:=floorf(diameter*.5)+LEAF_INSET-3.0
		var y:=lerpf(BOUNDS.position.y+bank_offset,BOUNDS.end.y-bank_offset,float(index)/(PLATFORM_COUNT-1))
		var artwork:=Vector2.ONE*diameter*LEAF_SCALE
		var sweep:=BOUNDS.size.x*.5-ceilf(artwork.x*.5)-LEAF_INSET
		var velocity:=motion_rng.randf_range(.64,1.48)
		pads.append({
			"center": Vector2(BOUNDS.get_center().x,y),
			"diameter": diameter,
			"sweep": sweep,
			"phase": rng.randf_range(0.0,TAU),
			"velocity": velocity,
			"target_velocity": velocity,
			"change_in": rng.randf_range(.4,2.4),
			"variant": rng.randi_range(0,5),
		})

func pad_position(index:int)->Vector2:
	var pad:=pads[index]
	return pad.center+Vector2(sin(pad.phase)*pad.sweep,0)

func leaf_size(index:int)->Vector2:
	return Vector2.ONE*float(pads[index].diameter)*LEAF_SCALE

func support_box(index:int)->Rect2:
	var square:=Vector2.ONE*float(pads[index].diameter)
	return Rect2(pad_position(index)-square*.5,square)

func advance_pads(delta:float)->void:
	for pad in pads:
		pad.change_in-=delta
		if pad.change_in<=0:
			pad.change_in=motion_rng.randf_range(.40,1.85)
			var sign_change:float=-1.0 if motion_rng.randf()<.19 else 1.0
			pad.target_velocity=signf(pad.target_velocity)*sign_change*motion_rng.randf_range(.35,1.72)
		pad.velocity=move_toward(pad.velocity,pad.target_velocity,delta*4.0)
		pad.phase=fposmod(pad.phase+pad.velocity*delta,TAU)

func support(foot:Vector2)->int:
	var best:=-1
	var nearest:=INF
	for index in range(pads.size()):
		var square:=support_box(index)
		if not square.has_point(foot):continue
		# Prefer the current support near the middle of a shared edge so
		# the direction of carry does not flicker from frame to frame.
		var normalized:Vector2=(foot-square.get_center())/(square.size.x*.5)
		var weight:=normalized.length_squared()-(.13 if index==riding else 0.0)
		if weight<nearest:
			best=index
			nearest=weight
	return best

func step(delta:float)->bool:
	var foot:Vector2=game.player
	var afloat:=SWIMMING_AREA.has_point(foot)
	var next_platform:=support(foot) if afloat else -1
	var previous_center:=pad_position(next_platform) if next_platform>=0 else Vector2.ZERO
	if next_platform!=riding and (next_platform>=0 or not afloat):hop=.24
	advance_pads(delta)
	var carry:=pad_position(next_platform)-previous_center if next_platform>=0 else Vector2.ZERO
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

func record_print(position:Vector2,rotation:float)->void:
	var index:=support(game.player)
	if index<0:return
	var pad:=pads[index]
	var offset:=position-pad_position(index)
	if lily_pixels==null:
		var art:Texture2D=load("res://assets/beam_lilies.png")
		lily_pixels=art.get_image()
	var size:=leaf_size(index)
	# Check the whole stamp, including the leaf notch. A mark whose edges
	# would overhang is skipped, even where the stepping area is generous.
	var region_start:=Vector2(float(pad.variant)*LILY_REGION.x,0)
	for y in range(-8,9):
		for x in range(-5,6):
			var point:=offset+Vector2(x,y).rotated(rotation)
			var uv:=point/size+Vector2(.5,.5)
			if not Rect2(Vector2.ZERO,Vector2.ONE).has_point(uv):return
			var pixel:=Vector2i(region_start+uv*LILY_REGION)
			var surface:=lily_pixels.get_pixelv(pixel)
			if surface.a<.92 or surface.g<.30:return
	prints.append({"pad":index,"offset":offset,"rotation":rotation,"life":6.75})
	if prints.size()>72:prints.pop_front()

func age_prints(delta:float)->void:
	for index in range(prints.size()-1,-1,-1):
		prints[index].life-=delta
		if prints[index].life<=0:prints.remove_at(index)

func draw_ground()->void:
	var origin:Vector2=game.screen(BOUNDS.position)
	var pool:=Rect2(origin,BOUNDS.size)
	var view:Rect2=game.get_viewport_rect()
	if not pool.intersects(view):return
	if water==null:
		water=load("res://assets/beam_pond.png")
		lilies=load("res://assets/beam_lilies.png")
	game.draw_texture_rect(water,pool,false)
	# Short bands sample the underlying pixel texture at slightly different
	# positions. The retaining stones and pool edges stay fixed.
	for y in range(12,int(pool.size.y)-12,12):
		if origin.y+y+12<=view.position.y or origin.y+y>=view.end.y:continue
		var shift:=roundf(1.45*sin(y*.071-seconds*2.4)+.50*sin(y*.14+seconds*3.1))
		var size:=Vector2(pool.size.x-12,12)
		var position:=Vector2(6,y)
		game.draw_texture_rect_region(water,Rect2(origin+position,size),
			Rect2(position*.5+Vector2(shift,0),size*.5))
	for index in range(26):
		var x:=fposmod(index*127.4+seconds*4.0,BOUNDS.size.x-34)+14
		var y:=fposmod(index*153.0,BOUNDS.size.y-28)+14
		var crest:=origin+Vector2(roundf(x*.5)*2,roundf(y*.5)*2)
		if not view.intersects(Rect2(crest,Vector2(14,2))):continue
		var glint:=RIPPLE
		glint.a=.13+.12*sin(seconds*2.4+index)
		game.draw_rect(Rect2(crest,Vector2(8+index%4*2,2)),glint)
	for index in range(pads.size()):
		var pad:=pads[index]
		var center:Vector2=game.screen(pad_position(index))
		var size:=leaf_size(index)
		var leaf:=Rect2((center-size*.5).round(),size)
		if not leaf.intersects(view):continue
		var source:=Rect2(Vector2(pad.variant*LILY_REGION.x,0),LILY_REGION)
		game.draw_texture_rect_region(lilies,leaf,source)
		draw_prints(index,leaf.get_center())

func draw_prints(index:int,center:Vector2)->void:
	if prints.is_empty():return
	var id:int=game.sprites["footprint"]
	var source:=Rect2(Vector2(id%16*32+12,id/16*48+32),Vector2(8,14))
	for mark in prints:
		if mark.pad!=index:continue
		game.draw_set_transform(center+Vector2(mark.offset),float(mark.rotation))
		var tint:=Color("294d42")
		tint.a=.58*minf(1.0,float(mark.life)/2)
		game.draw_texture_rect_region(game.atlas,Rect2(Vector2(-4,-7),Vector2(8,14)),source,tint)
	game.draw_set_transform(Vector2.ZERO)
