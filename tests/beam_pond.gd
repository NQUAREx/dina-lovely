extends SceneTree

class Walker extends Node2D:
	var player:=Vector2.ZERO

func _initialize()->void:
	var walker:=Walker.new()
	var pond=preload("res://scripts/beam_pond.gd").new(walker)
	var rng:=RandomNumberGenerator.new()
	# The leaf images stay inside the retaining stones, while an edge
	# transfer remains possible from either bank.
	for seed_value in range(80):
		rng.seed=seed_value
		pond.reset(rng)
		for tick in range(13):
			pond.seconds=float(tick)*2.5
			for index in range(pond.pads.size()):
				var middle:Vector2=pond.pad_position(index,pond.seconds)
				var size:Vector2=pond.pads[index].radius*pond.LEAF_SCALE
				assert(pond.BOUNDS.encloses(Rect2(middle-size*.5,size)))
			var top:Vector2=pond.pad_position(0,pond.seconds)
			var last:int=pond.pads.size()-1
			var bottom:Vector2=pond.pad_position(last,pond.seconds)
			assert(pond.support(Vector2(top.x,pond.BOUNDS.position.y+.5))==0)
			assert(pond.support(Vector2(bottom.x,pond.BOUNDS.end.y-.5))==last)
		var rates:Dictionary={}
		for pad in pond.pads:rates[pad.rate]=true
		assert(rates.size()==pond.pads.size())
	rng.seed=17
	pond.reset(rng)
	walker.player=pond.pad_position(4,0)
	var before:=walker.player
	assert(not pond.step(.1) and pond.riding==4)
	assert(walker.player.is_equal_approx(pond.pad_position(4,.1)) and walker.player!=before)
	var stamp_found:=false
	for x in range(-9,10,3):
		for y in range(-9,10,3):
			pond.record_print(walker.player+Vector2(x,y),0.0)
			if not pond.prints.is_empty():
				stamp_found=true
				break
		if stamp_found:break
	assert(stamp_found and pond.prints.front().pad==4)
	var mark:Dictionary=pond.prints.front()
	var first_world:Vector2=pond.pad_position(mark.pad,pond.seconds)+mark.offset
	pond.step(.1)
	assert(pond.pad_position(mark.pad,pond.seconds)+mark.offset!=first_world)
	pond.age_prints(7.0)
	assert(pond.prints.is_empty())
	walker.player=Vector2(pond.BOUNDS.position.x+4,pond.BOUNDS.get_center().y)
	assert(pond.step(.02))
	walker.player=pond.BOUNDS.position-Vector2(0,4)
	assert(not pond.step(.02))
	walker.free()
	print("PASS independent lily rates and in-bounds docks across 80 seeds; carried footprints, expiry and drowning")
	quit()
