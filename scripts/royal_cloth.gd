extends RefCounted

const TILE_SIZE := Vector2(68,48)
const OFFSET := Vector2(-68,-72)
const COLUMNS := 60
const SWAY_STEPS := 9
const SPREAD_STEPS := 7
const POSE_COUNT := 40
const FACE_STARTS := [0,4,12,16,24,28,32,36]
const ITEMS := ["gold_brocade","gold_mantle"]

var texture:Texture2D
var offset := [Vector2.ZERO,Vector2.ZERO]
var speed := [Vector2.ZERO,Vector2.ZERO]
var previous_heading := Vector2.ZERO
var step_distance := 0.0

func reset()->void:
	offset.fill(Vector2.ZERO)
	speed.fill(Vector2.ZERO)
	previous_heading=Vector2.ZERO
	step_distance=0.0

func update(displacement:Vector2,heading:Vector2,delta:float)->void:
	var forward:=heading.normalized()
	var turn:=0.0
	if previous_heading!=Vector2.ZERO and forward!=Vector2.ZERO:
		turn=clampf(previous_heading.angle_to(forward),-1.8,1.8)
	previous_heading=forward
	var motion:=displacement/maxf(delta,.001)/190.0
	var pace:=minf(motion.length(),1.0)
	step_distance=fposmod(step_distance+displacement.length(),72.0)
	var stride:=sin(step_distance*TAU/72.0)
	for garment in range(ITEMS.size()):
		# The long train lags behind each step and keeps unfurling through turns.
		var train:=garment==0
		var sway:=clampf(-motion.x*(.94 if train else .88)+stride*(.58 if train else .22)*pace,-1.0,1.0)
		var spread:=pace*((.52+.30*(stride+1.0)) if train else (.36+.22*(stride+1.0)))
		spread+=maxf(0.0,motion.y)*.13
		var target:=Vector2(sway,clampf(spread,0.0,1.0))
		var stiffness:=104.0 if train else 83.0
		var damping:=7.7 if train else 10.5
		speed[garment]+=Vector2(-turn*(6.4 if train else 4.4),absf(turn)*(5.8 if train else 3.5))
		var remaining:=minf(delta,.1)
		while remaining>0.00001:
			var dt:=minf(remaining,1.0/120.0)
			speed[garment]+=((target-offset[garment])*stiffness-speed[garment]*damping)*dt
			offset[garment]+=speed[garment]*dt
			remaining-=dt

func tile(garment:int,face:int,frame:int)->Vector2:
	var bend:Vector2=offset[garment]
	var sway:=roundi((clampf(bend.x,-1.0,1.0)+1.0)*4.0)
	var spread:=roundi(clampf(bend.y,0.0,1.0)*6.0)
	var pose:int=FACE_STARTS[face]+frame
	var index:=((garment*POSE_COUNT+pose)*SPREAD_STEPS+spread)*SWAY_STEPS+sway
	return Vector2(index%COLUMNS,index/COLUMNS)

func atlas()->Texture2D:
	if texture==null:texture=load("res://assets/royal_cloth.png")
	return texture

func draw(game:Node2D,garment:int,face:int,frame:int,position:Vector2,color:Color)->void:
	var source:=Rect2(tile(garment,face,frame)*TILE_SIZE,TILE_SIZE)
	game.draw_texture_rect_region(atlas(),Rect2(position+OFFSET,TILE_SIZE*2),source,color)
