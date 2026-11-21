extends SceneTree

func _initialize() -> void:
	var outfit := preload("res://scripts/royal_cloth.gd").new()
	var headings := [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2(1,1).normalized(), Vector2.DOWN]
	var rest_dress := outfit.skirt.projected.duplicate()
	var rest_mantle := outfit.mantle.projected.duplicate()
	var curve := PackedFloat32Array([0.0, 0.0])
	var separation := 0.0
	for tick in range(420):
		var heading: Vector2 = headings[mini(tick/24, headings.size()-1)]
		outfit.update(heading*190.0/60.0 if tick<120 else Vector2.ZERO, heading, 1.0/60)
		for garment in range(2):
			var panel := outfit.panels[garment]
			var rest := rest_dress if garment==0 else rest_mantle
			for col in range(panel.COLUMNS):
				assert(panel.projected[col]==rest[col], "The fitted seam slipped")
			var column := panel.COLUMNS/2
			var waist := column+2*panel.COLUMNS
			var middle := column+5*panel.COLUMNS
			var end := column+8*panel.COLUMNS
			var upper := (panel.projected[middle]-rest[middle]) - (panel.projected[waist]-rest[waist])
			var lower := (panel.projected[end]-rest[end]) - (panel.projected[middle]-rest[middle])
			curve[garment] = maxf(curve[garment], (lower-upper).length())
			if tick==120:
				assert(panel.projected[end].distance_to(rest[end])>.3, "Inertia disappeared at release")
			for i in range(0, panel.triangles.size(), 3):
				var a := panel.projected[panel.triangles[i]]
				var b := panel.projected[panel.triangles[i+1]]
				var c := panel.projected[panel.triangles[i+2]]
				assert((b-a).cross(c-a)>.01, "A visible triangle turned inside out")
			for p in panel.points:
				assert(p.z >= panel.body_depth(p.x,p.y)-.001, "The cloth entered the body")
		var last := outfit.skirt.COUNT-4
		separation = maxf(separation, outfit.skirt.projected[last].distance_to(outfit.mantle.projected[last]))
	assert(curve[0]>1.0 and curve[1]>1.0 and separation>1.0, "The two fabrics must bend independently")
	assert(outfit.skirt.sleeping and outfit.mantle.sleeping, "The costume must settle at rest")
	assert(outfit.skirt.projected==rest_dress and outfit.mantle.projected==rest_mantle)
	print("PASS sewn seams, independent bends, inertia, body contact, mesh orientation and settling")
	quit()
