extends SceneTree
const Field=preload("res://scripts/hedge_field.gd")
func _initialize() -> void:
	var map:Array[String]=[]
	for y in range(22):map.append(".".repeat(22))
	for n in range(3,19):
		map[n]=map[n].substr(0,10)+"#"+map[n].substr(11)
	map[10]="..."+"#".repeat(16)+"..."
	var field=Field.new();field.build(map,541,{}, {})
	var centre:=Vector2(10.5,10.5)*48
	for n in range(16):
		var player:=centre+Vector2.from_angle(n*TAU/16)*23
		for step in range(24):field.update(.016,player)
		for index in field.draw_order:
			var node:Dictionary=field.crowns[index]
			if field.crown_in_contact(index,player):assert(not field.crown_behind_hero(index,player),"Contacting crown went behind heroine")
			if not field.crown_behind_hero(index,player):
				var pose:Vector3=field.crown_pose(index,player)
				assert(pose.y-pose.z>=player.y-28,"Whole foreground crown extends above waist")
		var bounds:=Rect2(player-Vector2(200,300),Vector2(400,600))
		var expected:=PackedInt32Array()
		for index in field.draw_order:
			if bounds.has_point(field.crowns[index].base):expected.append(index)
		assert(field.visible_ids(bounds)==expected,"Spatial visibility cache changed painter order")
	field.build(map,541,{}, {})
	field.update(.016,centre+Vector2(23,0))
	for node in field.crowns:
		if node.base.distance_to(centre+Vector2(23,0))>52:assert(node.offset==Vector2.ZERO)
	print("PASS whole-crown waist layering at 16 angles, stable spatial visibility order, local physics")
	quit()
