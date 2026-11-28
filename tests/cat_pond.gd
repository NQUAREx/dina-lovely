extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var g:Node2D=load("res://main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g.set_physics_process(false)
	g.save_data=g.default_save()
	g.save_data.seed=723
	await g.build_level(2)
	g.clear_modal()
	g.playing=true
	g.sound_on=false
	g.moving=true
	g.save_data.cat_tamed=true
	var cat=g.companion
	var pond=g.beam_pond
	var rng:=RandomNumberGenerator.new()
	var water:Rect2=pond.SWIMMING_AREA
	for seed_value in range(30):
		for toward in [-1,1]:
			rng.seed=seed_value
			pond.reset(rng)
			var bank:=water.end.y+6 if toward<0 else water.position.y-6
			cat.position=Vector2(water.get_center().x,bank)
			cat.pond_pad=-1
			cat.pond_route=0
			assert(not g.blocked(cat.position))
			g.player=Vector2(water.get_center().x,water.position.y-60 if toward<0 else water.end.y+60)
			cat.trail.assign([{"pos":Vector2(water.get_center().x,bank+toward*80),"time":cat.clock-1},{"pos":g.player,"time":cat.clock-1}])
			cat.follow_trail(.06)
			assert(cat.pond_route==toward)
			var visited:Dictionary={}
			var ticks:=0
			while ticks<5400 and cat.pond_route!=0:
				pond.advance_pads(.85/60.0)
				cat.carry_on_pond()
				if water.has_point(cat.position):assert(pond.support(cat.position)>=0,"lost support on carry")
				cat.follow_pond(1.0/60.0)
				if cat.pond_pad>=0:visited[cat.pond_pad]=true
				if water.has_point(cat.position):
					assert(cat.pond_pad>=0 and pond.support(cat.position)>=0,"lost support while stepping")
					assert(cat.position.distance_to(pond.pad_position(cat.pond_pad))<=float(pond.pads[cat.pond_pad].diameter)*.5+1.0,"cat stepped beyond the visible leaf")
				ticks+=1
			assert(cat.pond_route==0 and visited.size()==10,"seed %d (%d), stuck at %d in %s; visited %d"%[seed_value,toward,cat.pond_pad,cat.position,visited.size()])
	print("PASS 60 cat crossings on moving lilies, with continuous support")
	quit()
