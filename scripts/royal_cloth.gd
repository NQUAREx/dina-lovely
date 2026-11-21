extends RefCounted

const TILE_SIZE := Vector2(48,40)
const OFFSET := Vector2(-48,-72)
const COLUMNS := 16
const DRESS_FOLDS := 7
const POSE_COUNT := 40
const FACE_STARTS := [0,4,12,16,24,28,32,36]
const ITEMS := ["gold_brocade","gold_mantle"]

var texture:Texture2D
var dress_fold:=0.0
var dress_speed:=0.0
var previous_heading := Vector2.ZERO
var step_distance := 0.0
const FABRIC_COLUMNS := 4
const FABRIC_REST_Y := [3.0,8.0,14.0,21.0,30.0,40.0]
const FABRIC_ANCHOR := 3.0
const FABRIC_BOTTOM := 40.0
var pins:=PackedVector2Array()
var fabric:=PackedVector2Array()
var fabric_previous:=PackedVector2Array()
var previous_motion:=Vector2.ZERO
var bonds:Array[Vector4]=[]

func _init()->void:
	for row in range(FABRIC_REST_Y.size()):
		for column in range(FABRIC_COLUMNS):
			pins.append(Vector2(8.0+column*(32.0/3.0),FABRIC_REST_Y[row]))
	for row in range(FABRIC_REST_Y.size()):
		for column in range(FABRIC_COLUMNS):
			var i:=row*FABRIC_COLUMNS+column
			if column+1<FABRIC_COLUMNS:add_bond(i,i+1,.79)
			if row+1<FABRIC_REST_Y.size():
				add_bond(i,i+FABRIC_COLUMNS,.86)
				if column+1<FABRIC_COLUMNS:add_bond(i,i+FABRIC_COLUMNS+1,.45)
				if column>0:add_bond(i,i+FABRIC_COLUMNS-1,.45)
			if row+2<FABRIC_REST_Y.size():add_bond(i,i+2*FABRIC_COLUMNS,.30)
	reset()

func add_bond(from:int,to:int,stiffness:float)->void:
	var rest:=pins[to]-pins[from]
	var length:=rest.length()
	# Projected folds can compress in the image plane. The woven material
	# resists extension while keeping enough slack for the hem to lift.
	var diagonal:=absf(rest.x)>0.01 and absf(rest.y)>0.01
	var compressed:float=.72 if diagonal else (.84 if absf(rest.y)<.01 else .53)
	bonds.append(Vector4(from,to,length*compressed,length*(1.17 if diagonal else 1.10)*lerpf(1.06,1.0,stiffness)))


func reset()->void:
	dress_fold=0.0
	dress_speed=0.0
	previous_heading=Vector2.ZERO
	step_distance=0.0
	fabric=pins.duplicate()
	fabric_previous=pins.duplicate()
	previous_motion=Vector2.ZERO

func simulate_mantle(motion:Vector2,turn:float,stride:float,pace:float,delta:float)->void:
	var acceleration:=(motion-previous_motion)*minf(120.0,1.0/maxf(delta,.001))
	previous_motion=motion
	var steps:=maxi(1,ceili(minf(delta,.08)*120.0))
	var dt:=minf(delta,.08)/steps
	for step in range(steps):
		for i in range(FABRIC_COLUMNS,pins.size()):
			var rest:=pins[i]
			var point:=fabric[i]
			var velocity:=(point-fabric_previous[i])*.967
			var depth:=sqrt((rest.y-FABRIC_ANCHOR)/(FABRIC_BOTTOM-FABRIC_ANCHOR))
			var side:=(rest.x-24.0)/16.0
			var billow:=Vector2(-430.0*motion.x+side*pace*(185.0+stride*100.0),-pace*(115.0+stride*55.0+side*motion.y*55.0))
			var driving:=billow+Vector2(-acceleration.x*17.0,-absf(acceleration.y)*6.0)
			fabric_previous[i]=point
			fabric[i]=point+velocity+((rest-point)*42.0+driving*depth)*dt*dt
			if step==0:fabric[i]+=Vector2(-turn*1.42, -absf(turn)*.67*(1.0+side*signf(turn)*.48))*depth
		for iteration in range(5):
			for bond in bonds:
				var from:=int(bond.x)
				var to:=int(bond.y)
				var difference:=fabric[to]-fabric[from]
				var distance:=difference.length()
				if distance<=.0001:continue
				var limit:=clampf(distance,bond.z,bond.w)
				if is_equal_approx(distance,limit):continue
				var correction:=difference*((distance-limit)/distance*.72)
				if from<FABRIC_COLUMNS:
					fabric[to]-=correction
				else:
					fabric[from]+=correction*.5
					fabric[to]-=correction*.5
			for i in range(FABRIC_COLUMNS,pins.size()):
				var above:=fabric[i-FABRIC_COLUMNS]
				var left:=fabric[i-1].x+3.0 if i%FABRIC_COLUMNS!=0 else 1.0
				var rest:=pins[i]
				var lateral_limit:=lerpf(1.4,9.0,smoothstep(FABRIC_ANCHOR,FABRIC_BOTTOM-4.0,rest.y))
				var upper_lift:=lerpf(.8,8.0,smoothstep(FABRIC_ANCHOR,FABRIC_BOTTOM,rest.y))
				fabric[i]=Vector2(
					clampf(fabric[i].x,maxf(left,rest.x-lateral_limit),minf(47.0,rest.x+lateral_limit)),
					clampf(fabric[i].y,maxf(above.y+2.0,rest.y-upper_lift),rest.y))

func mantle_vertices()->PackedVector2Array:
	var result:=PackedVector2Array()
	for point in fabric:result.append(point.round())
	return result

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
	simulate_mantle(motion,turn,stride,pace,delta)
	# The heavier skirt bends more slowly with a fitted base silhouette.
	var target:=clampf(-motion.x*.86+stride*.47*pace,-1.0,1.0)
	dress_speed-=turn*3.8
	var remaining:=minf(delta,.1)
	while remaining>0.00001:
		var dt:=minf(remaining,1.0/120.0)
		dress_speed+=((target-dress_fold)*82.0-dress_speed*11.0)*dt
		dress_fold+=dress_speed*dt
		remaining-=dt

func tile(garment:int,face:int,frame:int)->Vector2:
	var pose:int=FACE_STARTS[face]+frame
	var index:=POSE_COUNT*DRESS_FOLDS+pose
	if garment==0:
		var fold:=roundi((clampf(dress_fold,-1.0,1.0)+1.0)*3.0)
		index=pose*DRESS_FOLDS+fold
	return Vector2(index%COLUMNS,index/COLUMNS)

func atlas()->Texture2D:
	if texture==null:texture=load("res://assets/royal_cloth.png")
	return texture

func draw(game:Node2D,garment:int,face:int,frame:int,position:Vector2,color:Color)->void:
	var texture_atlas:=atlas()
	var source:=Rect2(tile(garment,face,frame)*TILE_SIZE,TILE_SIZE)
	if garment==0:
		game.draw_texture_rect_region(texture_atlas,Rect2(position+OFFSET,TILE_SIZE*2),source,color)
		return
	var origin:=position+OFFSET
	var fixed_size:=Vector2(TILE_SIZE.x,FABRIC_ANCHOR)
	game.draw_texture_rect_region(texture_atlas,Rect2(origin,fixed_size*2),Rect2(source.position,fixed_size),color)
	var vertices:=mantle_vertices()
	var atlas_size:=texture_atlas.get_size()
	var tint:=PackedColorArray([color])
	for row in range(FABRIC_REST_Y.size()-1):
		for column in range(FABRIC_COLUMNS-1):
			var index:=row*FABRIC_COLUMNS+column
			for triangle in [[index,index+1,index+FABRIC_COLUMNS+1],[index,index+FABRIC_COLUMNS+1,index+FABRIC_COLUMNS]]:
				var points:=PackedVector2Array()
				var uv:=PackedVector2Array()
				for vertex in triangle:
					points.append(origin+vertices[vertex]*2)
					uv.append((source.position+pins[vertex])/atlas_size)
				game.draw_primitive(points,tint,uv,texture_atlas)
