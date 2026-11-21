extends RefCounted

const TILE_SIZE := Vector2(48,40)
const OFFSET := Vector2(-48,-72)
const COLUMNS := 16
const POSE_COUNT := 40
const FACE_STARTS := [0,4,12,16,24,28,32,36]
const ITEMS := ["gold_brocade","gold_mantle"]
const ClothPanel := preload("res://scripts/brocade_panel.gd")

var texture: Texture2D
var skirt := ClothPanel.new(false)
var mantle := ClothPanel.new(true)
var panels: Array[BrocadePanel] = [skirt, mantle]
var uv_cache: Dictionary = {}
var previous_heading := Vector2.ZERO

func reset() -> void:
	previous_heading = Vector2.ZERO
	skirt.reset()
	mantle.reset()

func update(displacement: Vector2, heading: Vector2, delta: float, wearing_dress: bool = true, wearing_mantle: bool = true) -> void:
	var forward := heading.normalized()
	var turn := 0.0
	if previous_heading != Vector2.ZERO and forward != Vector2.ZERO:
		turn = previous_heading.angle_to(forward)
	previous_heading = forward
	var motion := (displacement / maxf(delta, .001) / 190.0).limit_length(1.5)
	if wearing_dress:
		skirt.advance(motion, turn, delta)
	if wearing_mantle:
		mantle.advance(motion, turn, delta, skirt if wearing_dress else null)

func tile(garment: int, face: int, frame: int) -> Vector2:
	return atlas_cell(garment, face, frame)

func lining_tile(garment: int, face: int, frame: int) -> Vector2:
	return atlas_cell(2+garment, face, frame)

func atlas_cell(bank: int, face: int, frame: int) -> Vector2:
	var index: int = POSE_COUNT * bank + FACE_STARTS[face] + frame
	return Vector2(index%COLUMNS, index/COLUMNS)

func vertices(garment: int) -> PackedVector2Array:
	return panels[garment].projected

func atlas() -> Texture2D:
	if texture == null:
		texture = load("res://assets/royal_cloth.png")
	return texture

func draw(game: Node2D, garment: int, face: int, frame: int, position: Vector2, color: Color) -> void:
	var cloth_texture := atlas()
	var panel := panels[garment]
	var origin := position + OFFSET
	var lining := Rect2(lining_tile(garment,face,frame)*TILE_SIZE, TILE_SIZE)
	game.draw_texture_rect_region(cloth_texture, Rect2(origin,TILE_SIZE*2), lining, color)
	var cell := tile(garment,face,frame)
	if not uv_cache.has(cell):
		var uv := PackedVector2Array()
		for point in panel.rest:
			uv.append((cell*TILE_SIZE + Vector2(point.x,point.y)) / cloth_texture.get_size())
		uv_cache[cell] = uv
	var positions := PackedVector2Array()
	var tints := PackedColorArray()
	positions.resize(panel.COUNT)
	tints.resize(panel.COUNT)
	for i in range(panel.COUNT):
		positions[i] = origin + panel.projected[i]*2.0
		var shade := panel.light[i]
		tints[i] = Color(color.r*shade,color.g*shade,color.b*shade,color.a)
	RenderingServer.canvas_item_add_triangle_array(game.get_canvas_item(), panel.triangles, positions, tints,
		uv_cache[cell], PackedInt32Array(), PackedFloat32Array(), cloth_texture.get_rid())
