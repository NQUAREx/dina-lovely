class_name BrocadePanel
extends RefCounted

# Both pieces live in local sprite pixels. X/Y follow the image, positive Z
# points away from the wearer. Adjacent folds can slide over the legs in Z
# without translating the fitted waist or lengthening the hem.
const COLUMNS := 7
const ROWS := 9
const COUNT := COLUMNS * ROWS
const STEP := 1.0 / 60.0
const X_PITCH := 32.0 / (COLUMNS - 1)
var mantle: bool
var top: float
var height: float

var rest := PackedVector3Array()
var points := PackedVector3Array()
var previous := PackedVector3Array()
var mobility := PackedFloat32Array()
var links := PackedVector4Array() # endpoints, minimum and maximum woven length
var triangles := PackedInt32Array()
var projected := PackedVector2Array()
var light := PackedFloat32Array()
var last_motion := Vector2.ZERO
var phase := 0.0
var remainder := 0.0
var pending_turn := 0.0
var idle_time := 0.0
var sleeping := true

func _init(is_mantle: bool = false) -> void:
	mantle = is_mantle
	top = 0.0 if mantle else 20.0
	height = 40.0 - top
	for row in range(ROWS):
		var drop := float(row) / (ROWS - 1)
		for column in range(COLUMNS):
			var x := 8.0 + column * X_PITCH
			var y := top + drop * height
			var pleat := 1.0 + .95 * cos(column * 2.45 + drop * .65)
			var sewn := smoothstep(0.0, .87, drop)
			if mantle:
				# Supported by the crown and both shoulders. Fabric between
				# those supports can twist; the two ends below are free.
				var shoulder := maxf(0.0, 1.0 - absf(y-20.0)/7.0)
				sewn = smoothstep(0.0, .8, drop) * (1.0 - .56 * shoulder)
			rest.append(Vector3(x, y, body_depth(x, y) + drop * pleat))
			mobility.append(sewn)
	for row in range(ROWS):
		for column in range(COLUMNS):
			var i := row * COLUMNS + column
			if column + 1 < COLUMNS:
				add_link(i, i + 1, .91, 1.11)
			if row + 1 < ROWS:
				add_link(i, i + COLUMNS, .90, 1.13)
				if column + 1 < COLUMNS:
					add_link(i, i + COLUMNS + 1, .81, 1.16)
					add_link(i + 1, i + COLUMNS, .81, 1.16)
					triangles.append_array(PackedInt32Array([i, i+1, i+COLUMNS+1, i, i+COLUMNS+1, i+COLUMNS]))
	reset()

func add_link(a: int, b: int, min_ratio: float, max_ratio: float) -> void:
	if mobility[a] + mobility[b] == 0.0:
		return
	var length := rest[a].distance_to(rest[b])
	links.append(Vector4(a, b, length * min_ratio, length * max_ratio))

func body_depth(x: float, y: float) -> float:
	var drop := clampf((y-20.0)/20.0, 0.0, 1.0)
	var radius := lerpf(8.5, 4.0, drop)
	var depth := 4.3 - 1.8 * drop
	if mantle and y < 20.0:
		var dome := sin(PI * clampf(y / 20.0, 0.0, 1.0))
		radius += dome * 2.2
		depth += dome * 2.8
	var side := (x - 24.0) / radius
	return maxf(0.0, 1.0 - side * side) * depth + (2.0 if mantle else 0.0)

# Sample the outer skirt's change in depth under a scarf end. Evaluate in
# physical X/Y; interpolation follows the lateral displacement of each row.
func skirt_billow_at(x: float, y: float) -> float:
	var row_pos := clampf((y-top) * (ROWS-1) / height, 0.0, float(ROWS-1))
	var row := mini(floori(row_pos), ROWS-2)
	return lerpf(row_billow(row, x), row_billow(row+1, x), row_pos - row)

func row_billow(row: int, x: float) -> float:
	var start := row * COLUMNS
	for i in range(start, start+COLUMNS-1):
		var a := points[i]
		var b := points[i+1]
		if a.x <= x and x <= b.x:
			return lerpf(a.z-rest[i].z, b.z-rest[i+1].z, (x-a.x)/maxf(.01,b.x-a.x))
	return 0.0

func reset() -> void:
	points = rest.duplicate()
	previous = rest.duplicate()
	projected.resize(COUNT)
	light.resize(COUNT)
	for i in range(COUNT):
		projected[i] = Vector2(rest[i].x, rest[i].y)
		light[i] = 1.0
	last_motion = Vector2.ZERO
	phase = 0.0
	remainder = 0.0
	pending_turn = 0.0
	idle_time = 0.0
	sleeping = true

func advance(motion: Vector2, turn: float, delta: float, skirt: BrocadePanel = null) -> void:
	if motion.is_zero_approx() and absf(turn) < .0001:
		if sleeping:
			return
		idle_time += delta
	else:
		idle_time = 0.0
		sleeping = false
	pending_turn += turn
	remainder += minf(delta, .10)
	while remainder + .000001 >= STEP:
		remainder = maxf(0.0, remainder - STEP)
		simulate(motion, clampf(pending_turn, -PI, PI), skirt)
		pending_turn = 0.0
	if idle_time > 1.0 and at_rest():
		reset()
	else:
		project_surface()

func simulate(motion: Vector2, turn: float, skirt: BrocadePanel) -> void:
	var pace := minf(motion.length(), 1.0)
	var acceleration := (motion - last_motion).limit_length(2.0)
	last_motion = motion
	phase = fposmod(phase + STEP * pace * TAU * 2.35, TAU)
	var stride := sin(phase)
	# All curvature forces use the same previous state, so disturbance can
	# travel in either direction along the weave independently of loop order.
	var overlap := PackedFloat32Array()
	overlap.resize(COUNT)
	var source := points
	points = source.duplicate()
	for i in range(COLUMNS, COUNT):
		var row := i / COLUMNS
		var column := i % COLUMNS
		var drop := float(row) / (ROWS - 1)
		var side := float(column - 3) / 3.0
		var weight := mobility[i]
		var offset := source[i] - rest[i]
		var velocity := (source[i] - previous[i]) * (.933 if mantle else .923)
		var bend := Vector3.ZERO
		if row + 1 < ROWS:
			bend += (source[i-COLUMNS]-rest[i-COLUMNS] + source[i+COLUMNS]-rest[i+COLUMNS]) * .5 - offset
		if column > 0 and column + 1 < COLUMNS:
			bend += (source[i-1]-rest[i-1] + source[i+1]-rest[i+1]) * .5 - offset
		# Air catches the trailing panel. The leading half hangs close to the
		# advancing leg; only the loose edge streams back at a steady walk.
		var trailing := clampf(.5 - side * motion.x * .85, 0.0, 1.0)
		var flow: Vector3
		var step_force: Vector3
		var recoil: Vector3
		if mantle:
			# Shoulder roll excites the upper sheet first. Changes in speed
			# and rotation travel down each side, catching the trailing end.
			var shoulder_wave := sin(phase + .65) * maxf(0.0, 1.0-absf(drop-.47)*3.0) * pace
			step_force = Vector3(shoulder_wave * 155.0, -shoulder_wave * side * 85.0, shoulder_wave * side * 195.0)
			flow = Vector3(-motion.x*(140.0+160.0*trailing) + side*pace*83.0,
				-pace*(7.0+37.0*trailing*trailing), (58.0+82.0*trailing-45.0*motion.y)*pace)
			recoil = Vector3(-acceleration.x*32.0-turn*(19.0+2.0*rest[i].z),
				-absf(turn)*(2.0+3.0*side*signf(turn)), -acceleration.y*18.0+turn*side*37.0)
			if skirt != null and source[i].y > 20.0 and absf(source[i].x-24.0) < 12.0:
				overlap[i] = maxf(0.0, skirt.skirt_billow_at(source[i].x, source[i].y)-.7)
		else:
			# A passing knee pushes the near panel out, then releases it. The
			# impulse enters above the hem; yarn tension transmits it to the edge.
			var knee := maxf(0.0, 1.0 - absf(drop - .57) * 3.9)
			var foot := stride * side
			var contact := knee * maxf(0.0, foot) * pace
			flow = Vector3(-motion.x * (95.0 + 125.0 * trailing) + side * pace * 49.0,
				-pace * (3.0 + 19.0 * trailing * trailing + 16.0 * foot),
				(25.0 + 62.0 * trailing - motion.y * 26.0) * pace)
			step_force = Vector3(stride * (95.0 + 70.0 * absf(motion.y)) * knee * pace,
				-contact * 140.0, contact * 480.0)
			recoil = Vector3(-acceleration.x * 28.0 - turn * (10.0 + rest[i].z),
				-absf(turn) * (1.0 + 3.0 * maxf(0.0, side * signf(turn))),
				-acceleration.y * 14.0 + turn * side * 25.0)
		var suspension := lerpf(146.0, 30.0 if mantle else 34.0, weight)
		var force := -offset * suspension + bend * (200.0 if mantle else 265.0) + (flow + step_force) * weight
		points[i] = source[i] + velocity + recoil * (weight * STEP) + force * (STEP * STEP)
	previous = source
	for iteration in range(3):
		for link in links:
			var a := int(link.x)
			var b := int(link.y)
			var gap := points[b] - points[a]
			var distance := gap.length()
			if distance >= link.z and distance <= link.w:
				continue
			var correction := gap * ((distance - clampf(distance, link.z, link.w)) / maxf(.001, distance))
			var share := mobility[a] / (mobility[a] + mobility[b])
			points[a] += correction * share
			points[b] -= correction * (1.0 - share)
		for i in range(COLUMNS, COUNT):
			var p := points[i]
			p.y = minf(p.y, minf(rest[i].y + 1.3, 40.0))
			var drop := clampf((p.y - 20.0) / 20.0, 0.0, 1.0)
			# Project back to the outside of the hips and swinging legs. The
			# front leg alternates every half stride. Z lets folds lift and slide.
			var leg := clampf((p.x - 24.0) / 5.0, -1.0, 1.0) * stride
			var knee_band := maxf(0.0, 1.0 - absf(drop - .57) * 4.0)
			var support := maxf(0.0, leg) * knee_band * pace * 2.5
			p.z = maxf(p.z, body_depth(p.x, p.y) + maxf(support, overlap[i]))
			points[i] = p

func project_surface() -> void:
	for i in range(COUNT):
		var delta := points[i] - rest[i]
		var depth := delta.z
		var offset := Vector2(delta.x, delta.y - depth * (.48 if mantle else .40))
		var low := Vector2(maxf(-8.0, -rest[i].x), maxf(-6.0, top-rest[i].y))
		var high := Vector2(minf(8.0, 48.0-rest[i].x), minf(1.3, 40.0-rest[i].y))
		if mantle:
			# The face opening follows the fitted hood. Only its edge shifts
			# across the cheeks; most of the available ease is below the chin.
			var ease := smoothstep(7.0, 34.0, rest[i].y)
			var slack := Vector2(lerpf(.9, 8.0, ease), lerpf(.6, 6.0, ease))
			low = low.max(-slack)
			high = high.min(slack)
		# Keep the projected triangles ordered. Limit local shear, not the
		# angle of the whole garment; successive rows can bend opposite ways.
		if i >= COLUMNS:
			var above := projected[i-COLUMNS] - Vector2(rest[i-COLUMNS].x, rest[i-COLUMNS].y)
			low = low.max(above - Vector2(2.0, 1.15))
			high = high.min(above + Vector2(2.0, 1.15))
		if i % COLUMNS > 0:
			var left := projected[i-1] - Vector2(rest[i-1].x, rest[i-1].y)
			low = low.max(left - Vector2(2.0, 1.15))
			high = high.min(left + Vector2(2.0, 1.15))
		projected[i] = Vector2(rest[i].x, rest[i].y) + offset.clamp(low, high)
		var l := i-1 if i%COLUMNS > 0 else i
		var r := i+1 if i%COLUMNS < COLUMNS-1 else i
		var slope := ((points[r].z-rest[r].z) - (points[l].z-rest[l].z)) / (rest[r].x-rest[l].x)
		light[i] = clampf(1.0 - slope * .26, .77, 1.12)

func at_rest() -> bool:
	for i in range(COLUMNS, COUNT):
		if points[i].distance_squared_to(rest[i]) > .0025 or points[i].distance_squared_to(previous[i]) > .000025:
			return false
	return true
