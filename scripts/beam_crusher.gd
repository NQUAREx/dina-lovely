extends RefCounted
## A timed masonry shuttle crossing a three-tile channel between alternating refuges.

const TILE := 48.0
const FIRST_ROW := 9
const LAST_ROW := 26
const LEFT := 24
const RIGHT := 27
const REFUGES := [11, 14, 17, 20, 23]
const SHAFT := Rect2(LEFT*TILE,FIRST_ROW*TILE,(RIGHT-LEFT)*TILE,(LAST_ROW-FIRST_ROW)*TILE)
const PLAYER_PAD := Vector2(8,7)
const BLOCK := preload("res://assets/beam_crusher_block.png")
const RAIL := preload("res://assets/beam_crusher_rail.png")
const NICHE := preload("res://assets/beam_crusher_niche.png")

var g:Node2D
var rng:=RandomNumberGenerator.new()
var elapsed:=0.0
var period:=0.0
var stroke:=0.0
var depth:=0.0
var modulation:=0.0
var phase:=0.0

func _init(game:Node2D)->void:
	g=game

func build_walls()->void:
	# Rows in the room builder precede the five rows of corridor padding.
	for row in range(FIRST_ROW,LAST_ROW):
		for column in [21,22,23,27,28,29]:
			g.set_cell(column,row-5,"#")
	for index in range(REFUGES.size()):
		var column:=23 if index%2==0 else 27
		var row:int=REFUGES[index]-5
		g.set_cell(column,row-1,".")
		g.set_cell(column,row,".")

func prepare()->void:
	if period>0.0:return
	rng.randomize()
	choose_stroke()
	elapsed=rng.randf_range(0.0,period)

func choose_stroke()->void:
	var walking:float=g.movement_speed()
	var travel_speed:=walking*rng.randf_range(3.5,4.15)
	depth=rng.randf_range(78.0,110.0)
	modulation=rng.randf_range(.05,.12)
	phase=rng.randf_range(0.0,TAU)
	var hop:=Vector2(177.6,3*TILE).length()
	# The next leading edge arrives sooner as the heroine runs towards it.
	# Include the clearance for both the hop and the shuttle's footprint.
	period=(hop+rng.randf_range(18.0,23.0))/walking+(depth+2*PLAYER_PAD.y+3*TILE)/travel_speed
	stroke=(SHAFT.size.y+depth)/travel_speed

func footprint()->Rect2:
	if period<=0.0 or elapsed>=stroke:return Rect2()
	var t:=elapsed/stroke
	# The start and end positions stay fixed while acceleration varies.
	var wave:float=(sin(TAU*t+phase)-sin(phase))/(TAU)
	var travelled:=t+modulation*wave
	var body:=Rect2(SHAFT.position+Vector2(0,-depth+(SHAFT.size.y+depth)*travelled),Vector2(SHAFT.size.x,depth))
	return body.intersection(SHAFT)

func tick(delta:float,previous_player:Vector2)->bool:
	prepare()
	var before:=footprint()
	elapsed+=delta
	if elapsed>=period:
		elapsed-=period
		choose_stroke()
		before=Rect2()
	var after:=footprint()
	var swept:=after
	if before.has_area():swept=before.merge(after) if after.has_area() else before
	if not swept.has_area():return false
	var rect:=Rect2(swept.position-PLAYER_PAD,swept.size+PLAYER_PAD*2)
	var point:Vector2=g.player
	if rect.has_point(point) or rect.has_point(previous_player):return true
	for edge in [[rect.position,Vector2(rect.end.x,rect.position.y)],
			[Vector2(rect.end.x,rect.position.y),rect.end],
			[rect.end,Vector2(rect.position.x,rect.end.y)],
			[Vector2(rect.position.x,rect.end.y),rect.position]]:
		if Geometry2D.segment_intersects_segment(previous_player,point,edge[0],edge[1])!=null:return true
	return false

func draw_track()->void:
	var viewport:Rect2=g.get_viewport_rect().grow(52)
	for row in range(FIRST_ROW,LAST_ROW):
		var rail:=Rect2(g.screen(Vector2(SHAFT.position.x,row*TILE)),Vector2(SHAFT.size.x,TILE))
		if rail.intersects(viewport):g.draw_texture_rect(RAIL,rail,false)
	for index in range(REFUGES.size()):
		var column:=23 if index%2==0 else 27
		var area:=Rect2(g.screen(Vector2(column,REFUGES[index]-1)*TILE),Vector2(TILE,TILE*2))
		if area.intersects(viewport):g.draw_texture_rect(NICHE,area,false)

func drawable()->Dictionary:
	var body:=footprint()
	if not body.has_area():return {}
	return {"kind":"beam_crusher","id":"","pos":Vector2(body.get_center().x,body.end.y)}

func draw_block()->void:
	var body:=footprint()
	if not body.has_area():return
	var opacity:=minf(1.0,body.size.y/24.0)
	var rise:=minf(24.0,body.size.y*.7)
	var visual:=Rect2(g.screen(body.position-Vector2(0,rise)),Vector2(body.size.x,body.size.y+rise))
	if not visual.intersects(g.get_viewport_rect().grow(48)):return
	var contact:=Rect2(g.screen(body.position+Vector2(0,4)),body.size)
	g.draw_rect(contact,Color(.12,.08,.17,opacity*.22))
	g.draw_texture_rect(BLOCK,visual,false,Color(1,1,1,opacity))
