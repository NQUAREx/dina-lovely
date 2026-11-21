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
				var size:Vector2=pond.leaf_size(index)
				var artwork:=Rect2((middle-size*.5).round(),size)
				assert(pond.BOUNDS.grow(-12).encloses(artwork))
				var square:Rect2=pond.support_box(index)
				assert(square.size.x==square.size.y)
				assert(square.encloses(Rect2(middle-size*.5,size)))
			var top:Vector2=pond.pad_position(0,pond.seconds)
			var last:int=pond.pads.size()-1
			var bottom:Vector2=pond.pad_position(last,pond.seconds)
			assert(pond.pad_position(1,pond.seconds).y-top.y>=78)
			assert(bottom.y-pond.pad_position(last-1,pond.seconds).y>=78)
			for side in [-1.0,1.0]:
				assert(pond.support(Vector2(top.x+side*42.0,pond.BOUNDS.position.y+.5))==0)
				assert(pond.support(Vector2(bottom.x+side*42.0,pond.BOUNDS.end.y-.5))==last)
		if seed_value<8:
			for index in range(pond.pads.size()):
				var pad:Dictionary=pond.pads[index]
				var edge:float=ceilf(pad.radius.x*pond.LEAF_SCALE.x*.5)+pond.LEAF_INSET
				var minimum:=INF
				var maximum:=-INF
				for tick in range(480):
					var x:float=pond.pad_position(index,tick*.04).x
					minimum=minf(minimum,x)
					maximum=maxf(maximum,x)
				assert(absf(minimum-(pond.BOUNDS.position.x+edge))<.2)
				assert(absf(maximum-(pond.BOUNDS.end.x-edge))<.2)
		var rates:Dictionary={}
		for pad in pond.pads:rates[pad.rate]=true
		assert(rates.size()==pond.pads.size())
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
	print("PASS square lily support and clear bank artwork across 80 seeds; carried footprints, expiry and drowning")
	quit()
