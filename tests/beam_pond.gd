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
		assert(pond.pads.size()==10)
		for tick in range(36):
			pond.advance_pads(.14)
			for index in range(pond.pads.size()):
				var middle:Vector2=pond.pad_position(index)
				var square:Rect2=pond.support_box(index)
				assert(square.get_center().is_equal_approx(middle))
				var leaf_diameter:Vector2=pond.leaf_size(index)/pond.LEAF_SCALE
				assert(square.size.is_equal_approx(leaf_diameter+Vector2.ONE*6.0))
				assert(pond.BOUNDS.grow(-6).encloses(square))
			var top:Vector2=pond.pad_position(0)
			var last:int=pond.pads.size()-1
			var bottom:Vector2=pond.pad_position(last)
			assert(pond.support(Vector2(top.x,pond.SWIMMING_AREA.position.y+.4))==0)
			assert(pond.support(Vector2(bottom.x,pond.SWIMMING_AREA.end.y-.4))==last)
		var reversals:=0
		for tick in range(600):
			var before:float=pond.pads[0].velocity
			pond.advance_pads(.05)
			var after:float=pond.pads[0].velocity
			assert(absf(after)<=1.10+.00001)
			assert(absf(after-before)<=2.10*.05+.00001)
			if signf(before)!=signf(after):reversals+=1
		assert(reversals>0)
	rng.seed=17
	pond.reset(rng)
	# Isolate a platform to prove the corners support feet independently
	# of neighbours, without allowing a footprint on the transparent art.
	pond.pads.assign([pond.pads[4]])
	var square:Rect2=pond.support_box(0)
	for corner in [Vector2.ONE,Vector2(-1,1),Vector2(1,-1),-Vector2.ONE]:
		var inside:Vector2=square.get_center()+corner*(square.size.x*.5-.1)
		walker.player=inside
		assert(pond.support(inside)==0)
		assert(pond.support(inside+corner*.2)==-1)
		pond.record_print(inside,0.0)
	assert(pond.prints.is_empty())
	pond.reset(rng)
	walker.player=pond.pad_position(4)
	var before:=walker.player
	assert(not pond.step(.1) and pond.riding==4)
	assert(walker.player.is_equal_approx(pond.pad_position(4)) and walker.player!=before)
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
	var first_world:Vector2=pond.pad_position(mark.pad)+mark.offset
	pond.step(.1)
	assert(pond.pad_position(mark.pad)+mark.offset!=first_world)
	pond.age_prints(7.0)
	assert(pond.prints.is_empty())
	walker.player=Vector2(pond.BOUNDS.position.x+4,pond.BOUNDS.get_center().y)
	assert(pond.step(.02))
	walker.player=pond.BOUNDS.position-Vector2(0,4)
	assert(not pond.step(.02))
	var dock:Vector2=pond.pad_position(0)
	walker.player=Vector2(dock.x,pond.SWIMMING_AREA.position.y+.5)
	assert(not pond.step(.02) and pond.riding==0 and pond.lift()>0)
	pond.hop=0
	walker.player.y=pond.SWIMMING_AREA.position.y-.5
	assert(not pond.step(.02) and pond.riding==-1 and pond.lift()>0)
	walker.free()
	print("PASS square lily support and clear bank artwork across 80 seeds; carried footprints, expiry and drowning")
	quit()
