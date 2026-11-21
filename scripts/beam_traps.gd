extends RefCounted

const LEFT := 48.0
const WIDTH := 432.0
const ROW_OFFSET := 1.8
const SPIKE_COLUMNS := 9
const SPIKE_CLOSED := Rect2(2,0,29,32)
const SPIKE_RAISED := Rect2(32,0,32,32)
const LOG_MIN_LENGTH := 70
const LOG_MAX_LENGTH := 135
const LOG_TILE := Vector2(136,28)
const LOG_COLUMNS := 8

var game:Node2D
var beams:Array[Dictionary]=[]
var spikes:Array[Dictionary]=[]
var clock:=0.0
var spike_art:Texture2D
var log_art:Texture2D

func _init(owner:Node2D)->void:
	game=owner

func reset(rng:RandomNumberGenerator)->void:
	beams.clear()
	spikes.clear()
	clock=0.0
	for row in range(4):
		var width:=rng.randf_range(140,270)
		beams.append({"width":width,"y":(12.0+ROW_OFFSET+row*5+rng.randf_range(-.35,.35))*48,
			"phase":rng.randf_range(0.0,TAU),"period":rng.randf_range(2.7,4.9),
			"warp":rng.randf_range(.62,.84),"rhythm":rng.randf_range(.73,1.05),
			"accent":rng.randf_range(0,TAU)})
	for row in range(3):
		var y:=(14.5+ROW_OFFSET+row*5+rng.randf_range(-.4,.4))*48
		var groups:Array[Dictionary]=[]
		# Four pairs share timing. The ninth tile has its own cycle.
		for group in range((SPIKE_COLUMNS+1)/2):
			groups.append({"phase":rng.randf_range(0,TAU),"period":rng.randf_range(2.0,3.65),
				"warp":rng.randf_range(.40,.68),"rhythm":rng.randf_range(.65,1.05),
				"accent":rng.randf_range(0,TAU),"threshold":rng.randf_range(.03,.31)})
		spikes.append({"rect":Rect2(LEFT,y-22,WIDTH,44),"groups":groups})

func place_gap_obstacles(rng:RandomNumberGenerator)->void:
	# Spaced slots keep routes open between obstacles even at maximum jitter.
	for index in range(spikes.size()):
		var spike:Rect2=spikes[index].rect
		var before:float=(float(beams[index].y)+spike.get_center().y)*.5
		var after:float=(float(beams[index+1].y)+spike.get_center().y)*.5
		var block_right_gap:=rng.randi_range(0,1)
		for side in range(2):
			var slots:Array[int]=[0,1,2,3,4,5]
			var count:=rng.randi_range(2,4)
			var selected:Array[int]=[]
			if side==block_right_gap:
				selected.append(slots.pop_back())
			while selected.size()<count:
				var pick:=rng.randi_range(0,slots.size()-1)
				selected.append(slots[pick])
				slots.remove_at(pick)
			var y:=before if side==0 else after
			for slot in selected:
				var x:=LEFT+28.0+slot*75.2+rng.randf_range(-6,6)
				var kind:="tree" if rng.randf()<.25 else "crate"
				game.objects.append({"kind":kind,"id":"beam_gap_%d_%d_%d"%[index,side,slot],
					"pos":Vector2(x,y+rng.randf_range(-3,3)),"solid":true})

func phase(trap:Dictionary)->float:
	var t:=clock*TAU/float(trap.period)+float(trap.phase)
	return sin(t+sin(t*float(trap.rhythm)+float(trap.accent))*float(trap.warp))

func beam_box(beam:Dictionary)->Rect2:
	var size:=Vector2(float(beam.width),25)
	var center:=Vector2(LEFT+WIDTH*.5+(WIDTH-size.x)*.5*phase(beam),beam.y)
	return Rect2(center-size/2,size)

func spike_height(spike:Dictionary)->float:
	return smoothstep(float(spike.threshold)-.22,float(spike.threshold)+.25,phase(spike))

func step(delta:float)->bool:
	clock+=delta
	for beam in beams:
		if absf(game.player.y-float(beam.y))>19.5:continue
		if beam_box(beam).grow(7).has_point(game.player):return true
	for spike in spikes:
		var box:Rect2=spike.rect
		if not Rect2(box.position+Vector2(0,4),box.size-Vector2(0,8)).has_point(game.player):continue
		var column:=floori((game.player.x-box.position.x)/48.0)
		if spike_height(spike.groups[column/2])>.56:return true
	return false

func append_renderables(queue:Array[Dictionary])->void:
	for beam in beams:
		var box:=beam_box(beam)
		var variant:=mini(2,floori(float(beam.phase)*3.0/TAU))
		queue.append({"kind":"hall_beam","pos":box.get_center(),"rect":box,"variant":variant})

func draw_log_shadows()->void:
	var view:Rect2=game.get_viewport_rect()
	for beam in beams:
		var box:=beam_box(beam)
		var position:Vector2=game.screen(box.get_center())
		if not Rect2(position-box.size*.5,box.size).intersects(view.grow(32)):continue
		for layer in game.SHADOW_CAST_LAYERS:
			var center:Vector2=position+game.SHADOW_DIRECTION*(15.0+layer.x)
			var radius:=10.0+float(layer.x)*.55
			var half_run:=box.size.x*.5-9.0
			var points:=PackedVector2Array()
			for end in [1,-1]:
				var angle:=0.0 if end==1 else PI
				for segment in range(9):
					var corner:=Vector2.from_angle(angle-PI*.5+segment*PI/8.0)
					points.append(center+Vector2(half_run*end,0)+corner*Vector2(radius,radius*.7))
			var tint:Color=game.SHADOW_TINT
			tint.a=layer.y
			game.draw_colored_polygon(points,tint)

func draw_spikes()->void:
	if spike_art==null:spike_art=load("res://assets/beam_spikes.png")
	for spike in spikes:
		var row:Rect2=spike.rect
		var p:Vector2=game.screen(row.position)
		if not Rect2(p,row.size).intersects(game.get_viewport_rect().grow(24)):continue
		var lift:=0.0
		for column in range(SPIKE_COLUMNS):
			if column%2==0:lift=spike_height(spike.groups[column/2])
			var tile:=Rect2(p+Vector2(column*48,0),Vector2(48,row.size.y))
			game.draw_texture_rect_region(spike_art,tile,SPIKE_CLOSED)
			if lift>.01:
				tile.position.y-=16*lift
				game.draw_texture_rect_region(spike_art,tile,SPIKE_RAISED,Color(1,1,1,clampf(lift*2,0,1)))

func draw(item:Dictionary)->void:
	var box:Rect2=item.rect
	var strip:=Rect2(game.screen(Vector2(LEFT,box.position.y-24)),Vector2(WIDTH,56))
	if not strip.intersects(game.get_viewport_rect()):return
	var p:Vector2=game.screen(box.position)
	var left:Vector2=game.screen(Vector2(LEFT,box.get_center().y))
	game.draw_rect(Rect2(left-Vector2(0,3),Vector2(WIDTH,6)),Color("514350"))
	game.draw_rect(Rect2(left-Vector2(0,3),Vector2(WIDTH,2)),Color("9a7d7b"))
	if log_art==null:log_art=load("res://assets/beam_logs.png")
	var length:=clampi(roundi(box.size.x/2),LOG_MIN_LENGTH,LOG_MAX_LENGTH)
	var index:int=int(item.variant)*(LOG_MAX_LENGTH-LOG_MIN_LENGTH+1)+length-LOG_MIN_LENGTH
	var source:=Rect2(Vector2(index%LOG_COLUMNS,index/LOG_COLUMNS)*LOG_TILE,Vector2(length,LOG_TILE.y))
	var destination:=Rect2(p+Vector2(0,-24),Vector2(box.size.x,LOG_TILE.y*2))
	game.draw_texture_rect_region(log_art,destination,source)
