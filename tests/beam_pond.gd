extends SceneTree

class Walker extends Node2D:
	var player:=Vector2.ZERO

func _initialize()->void:
	var walker:=Walker.new()
	var pond=preload("res://scripts/beam_pond.gd").new(walker)
	var rng:=RandomNumberGenerator.new()
	# The individual rhythms vary, but every neighbouring pair must offer
	# a safe overlap long enough to transfer within one pair of half-cycles.
	for seed_value in range(80):
		rng.seed=seed_value
		pond.reset(rng)
		# Both shore leaves reach dry ground throughout their oscillation.
		for tick in range(12):
			var time:=float(tick)*.5
			var last:int=pond.pads.size()-1
			var top:Vector2=pond.pad_position(0,time)
			var bottom:Vector2=pond.pad_position(last,time)
			assert(top.y-pond.pads[0].radius.y<pond.BOUNDS.position.y)
			assert(bottom.y+pond.pads[last].radius.y>pond.BOUNDS.end.y)
		for index in range(pond.pads.size()-1):
			var contiguous:=0
			var longest:=0
			for tick in range(360):
				var time:=float(tick)/60.0
				var first:Vector2=pond.pad_position(index,time)
				var second:Vector2=pond.pad_position(index+1,time)
				var middle:=first.lerp(second,.5)
				var a:Vector2=(middle-first)/pond.pads[index].radius
				var b:Vector2=(middle-second)/pond.pads[index+1].radius
				if a.length_squared()<.94 and b.length_squared()<.94:contiguous+=1
				else:contiguous=0
				longest=maxi(longest,contiguous)
			assert(longest>=12,"seed %d, lily %d only overlaps for %d ticks"%[seed_value,index,longest])
			var made_crossing:=false
			for tick in range(0,360,4):
				pond.seconds=float(tick)/60.0
				pond.riding=index
				walker.player=pond.pad_position(index,pond.seconds)+Vector2(0,28)
				for step in range(19):
					walker.player.y+=150.0/60.0
					if pond.step(1.0/60.0):break
					if pond.riding!=index+1:continue
					made_crossing=true
					break
				if made_crossing:break
			assert(made_crossing,"seed %d, lily %d cannot be crossed at walking speed"%[seed_value,index])
	rng.seed=17
	pond.reset(rng)
	walker.player=pond.pad_position(4,0)
	var before:=walker.player
	assert(not pond.step(.1) and pond.riding==4)
	assert(walker.player.is_equal_approx(pond.pad_position(4,.1)) and walker.player!=before)
	walker.player=Vector2(pond.BOUNDS.position.x+4,pond.BOUNDS.get_center().y)
	assert(pond.step(.02))
	walker.player=pond.BOUNDS.position-Vector2(0,4)
	assert(not pond.step(.02))
	walker.free()
	print("PASS pond routes across 80 seeds, platform carry, safe shore and drowning")
	quit()
