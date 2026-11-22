extends SceneTree
# Garden growth and other per-frame timers must not depend on what is on
# screen: a bed far outside the viewport keeps growing through all stages.
var g
func _initialize():call_deferred('run')
func run():
	g=load('res://main.tscn').instantiate();root.add_child(g);await process_frame
	g.new_game();g.clear_modal();g.sound_on=false
	g.activate_cached_room(5);g.playing=true;g.paused=false
	var beds:Array=g.objects.filter(func(o):return o.kind=="sprout")
	assert(beds.size()>=2)
	# Heroine and camera at one end of the garden, the watched bed far away.
	beds.sort_custom(func(a,b):return a.pos.y<b.pos.y)
	var far:Dictionary=beds[0]
	g.player=Vector2(13.5*48,(g.grid.size()-8)*48);g.camera=g.camera_target()
	var view:Rect2=g.get_viewport_rect();view.position=g.camera-view.size/2
	assert(not view.grow(200).has_point(far.pos),"bed should be far off screen")
	g.plants[far.id]={"stage":0,"remaining":1.0,"dry_in":g.SPROUT_DRY_TIME}
	for stage in range(1,g.FLOWER_STAGE_FULL+1):
		for i in 90:await process_frame
		g.update_plants(1.2)
		if int(g.plants[far.id].stage)<g.FLOWER_STAGE_FULL:g.plants[far.id].remaining=1.0
	assert(int(g.plants[far.id].stage)==g.FLOWER_STAGE_FULL,"off-screen bed stopped growing: "+str(g.plants[far.id]))
	# The real _process path also advances it while off screen.
	g.plants[far.id]={"stage":0,"remaining":.5,"dry_in":g.SPROUT_DRY_TIME}
	var before:=Time.get_ticks_msec()
	while int(g.plants[far.id].stage)==0 and Time.get_ticks_msec()-before<20000:await process_frame
	assert(int(g.plants[far.id].stage)==1,"_process did not advance an off-screen bed")
	print('PASS off-screen garden beds keep growing through every stage')
	g.queue_free();await process_frame;quit()
