extends RefCounted
## Seeded garden jobs, independent of the flower beds.
const GRASS_COUNT := 20
const BUSH_COUNT := 3
const BASKET_IDS := ["garden_basket","garden_basket_1","garden_basket_2"]
const BASKETS_REQUIRED := 3
const HARVEST_SECONDS := 1.65
const SNIP_AT := [.12, .34, .54]
const BERRY_GROWTH_TIME := 4.0
const TABLE_REACH := 79.0
const TOOLS := ["garden_shears","garden_basket"]
const KINDS := ["garden_grass","garden_bush","garden_shears","garden_basket","garden_table"]
const TASK_SOUNDS := {"garden_rake":"rake","garden_water":"water","garden_harvest":"ui","garden_deposit":"chime"}
const ANCHOR := Vector2(32,54)
const TILE_SIZE := Vector2(64,64)
enum Bush { OVERGROWN, TRIMMED, WATERED, RIPE, PICKED }

var g:Node2D
var art:Texture2D
var atlas_image:Image
var opaque_bounds:Dictionary={}
var icons:Dictionary={}
var outlines:Dictionary={}

func _init(game:Node2D):
	g=game

func state()->Dictionary:
	var saved:Dictionary=g.save_data.garden_chores
	if not saved.has("delivered_baskets"):
		saved.merge({"grass":[],"bushes":{},"filled_baskets":[],"delivered_baskets":[],"held_basket":""})
		# The old reusable basket keeps its original ID and drop location.
		var count:=clampi(int(saved.get("baskets",0)),0,BASKETS_REQUIRED)
		for index in range(count):saved.delivered_baskets.append(BASKET_IDS[BASKETS_REQUIRED-1-index])
		if count<BASKETS_REQUIRED:
			if int(saved.get("load",0))>0:saved.filled_baskets.append(BASKET_IDS[0])
			if g.save_data.held_item=="garden_basket":saved.held_basket=BASKET_IDS[0]
		elif g.save_data.held_item=="garden_basket":
			g.save_data.held_item=""
		saved.erase("load")
		saved.erase("baskets")
		saved.erase("introduced")
	if not saved.has("trimmed_trees"):saved.trimmed_trees=[]
	return saved

func chores_ready()->bool:
	var saved:=state()
	return saved.grass.size()>=GRASS_COUNT and saved.delivered_baskets.size()>=BASKETS_REQUIRED

func ready()->bool:
	return chores_ready() and not g.objects.any(tree_needs_trim)

func mark_trees()->void:
	for obj in g.objects:
		if not obj.solid or obj.kind not in ["tree","tree_apples"]:continue
		var cell:=Vector2i(obj.pos/g.TILE)
		if not g.shadow_floor_cell(cell) or g.corridor_row(cell.y):continue
		obj.garden_trim_id="%d_%d"%[cell.x,cell.y]
		obj.garden_tree_sprite=56+posmod(cell.x*7+cell.y*11+int(g.save_data.seed),4)

func tree_needs_trim(obj:Dictionary)->bool:
	return obj.has("garden_trim_id") and obj.kind in ["tree","tree_apples"] and 5 not in g.save_data.open_gates and obj.garden_trim_id not in state().trimmed_trees

func trim_tree(obj:Dictionary)->void:
	if g.held_item=="garden_shears" and tree_needs_trim(obj):
		g.begin_task("garden_trim_tree:"+obj.garden_trim_id,obj.pos,.8)

func place(grass_only:bool)->void:
	var saved:=state()
	var rng:=RandomNumberGenerator.new()
	rng.seed=int(g.save_data.seed)^(0x47524153 if grass_only else 0x47415244)
	if grass_only:
		place_grass(placement_candidates(rng,true),rng,saved.get("layout",[]))
		saved.layout=[]
		for obj in g.objects:
			if obj.kind in KINDS:
				saved.layout.append({"kind":obj.kind,"id":obj.id,"pos":[obj.pos.x,obj.pos.y],"variant":obj.variant})
		return
	var layout:Array=saved.get("layout",[])
	var previous_bushes:=layout.filter(func(entry):return entry.kind=="garden_bush")
	for entry in layout:
		if entry.kind in ["garden_grass","garden_bush"]:continue
		restore_placement(entry)
	var candidates:=placement_candidates(rng)
	if previous_bushes.size()==BUSH_COUNT:
		for entry in previous_bushes:restore_placement(entry)
	else:
		place_bushes(candidates)
		restore_available_bushes()
	clear_ornamentals_under_bushes()
	place_landmark("garden_table","garden_table",candidates,true)
	for id in BASKET_IDS:place_landmark("garden_basket",id,candidates)
	place_landmark("garden_shears","garden_shears",candidates)

func restore_placement(entry:Dictionary)->void:
	add(entry.kind,entry.id,Vector2(entry.pos[0],entry.pos[1]),int(entry.variant),entry.kind in ["garden_bush","garden_table"])

func placement_candidates(rng:RandomNumberGenerator,for_grass:bool=false)->Array[Vector2]:
	var candidates:Array[Vector2]=[]
	if for_grass:
		# Offset independent samples within small squares to reach the grass in
		# narrow pockets between paths, without lining up on the garden tiles.
		for y in range(360,(g.grid.size()-7)*g.TILE,16):
			for x in range(84,g.grid[0].length()*g.TILE-84,16):
				candidates.append(Vector2(x+rng.randi_range(0,7)*2,y+rng.randi_range(0,7)*2))
	else:
		for y in range(8,g.grid.size()-7):
			for x in range(2,g.grid[0].length()-2):
				candidates.append(Vector2(x+.5,y+.5)*g.TILE)
				candidates.append(Vector2(x+1,y+1)*g.TILE)
	for i in range(candidates.size()-1,0,-1):
		var other:=rng.randi_range(0,i)
		var point:=candidates[i]
		candidates[i]=candidates[other]
		candidates[other]=point
	return candidates

func place_bushes(candidates:Array[Vector2])->void:
	# One seeded position per third, with room between adjacent bushes.
	var low:float=8.0*g.TILE
	var band_height:float=((g.grid.size()-7)*g.TILE-low)/BUSH_COUNT
	var planted:Array[Vector2]=[]
	for index in range(BUSH_COUNT):
		var id:="garden_bush_"+str(index)
		var band_start:=low+index*band_height
		var band_end:=band_start+band_height
		for point in candidates:
			if point.y<band_start or point.y>=band_end:continue
			if planted.any(func(other):return point.distance_squared_to(other)<160.0*160.0):continue
			if not place_clear("garden_bush",point,5.0):continue
			add("garden_bush",id,point,index,true)
			planted.append(point)
			break
		if planted.size()<=index:
			place_landmark("garden_bush",id,candidates,true)
			if not g.objects.is_empty() and g.objects.back().id==id:
				planted.append(g.objects.back().pos)
				g.objects.back().variant=index

func restore_available_bushes()->void:
	# Older gardens could lose a harvest to eating; retain enough bushes to finish.
	var saved:=state()
	var remaining:int=BASKETS_REQUIRED-saved.delivered_baskets.size()-saved.filled_baskets.size()
	var picked:Array[String]=[]
	for index in range(BUSH_COUNT):
		var id:="garden_bush_"+str(index)
		if bush_phase(id)==Bush.PICKED:picked.append(id)
	var available_count:=BUSH_COUNT-picked.size()
	for index in range(mini(picked.size(),remaining-available_count)):
		saved.bushes[picked[index]]={"phase":Bush.WATERED,"remaining":BERRY_GROWTH_TIME}

func place_landmark(kind:String,id:String,candidates:Array[Vector2],solid:bool=false)->void:
	if g.objects.any(func(obj):return obj.id==id):return
	for point in candidates:
		if not place_clear(kind,point,8.0):continue
		add(kind,id,point,0,solid)
		return
	assert(false,"Garden requires space for "+id)

func place_grass(candidates:Array[Vector2],rng:RandomNumberGenerator,layout:Array)->void:
	var prior:Dictionary={}
	var placed:Dictionary={}
	for entry in layout:
		if entry.kind!="garden_grass":continue
		prior[entry.id]=entry
		var point:=Vector2(entry.pos[0],entry.pos[1])
		if grass_clear(point):
			restore_placement(entry)
			placed[entry.id]=true
	var palette: Array[int] = [0,1,2,3,4,5]
	var candidate:=0
	for number in range(GRASS_COUNT):
		var id:="garden_grass_"+str(number)
		if placed.has(id):continue
		while candidate<candidates.size() and not grass_clear(candidates[candidate]):candidate+=1
		if candidate==candidates.size():
			assert(false,"Garden requires twenty grass piles off the paths")
			return
		if palette.is_empty():palette.assign([0,1,2,3,4,5])
		var variant:int=int(prior[id].variant) if prior.has(id) else palette.pop_at(rng.randi_range(0,palette.size()-1))
		add("garden_grass",id,candidates[candidate],variant)
		candidate+=1

func grass_clear(point:Vector2)->bool:
	if not place_clear("garden_grass",point,4.0):return false
	var pixels:Image=g.path_ground
	if pixels==null:return true
	var area:=layout_bounds("garden_grass",point)
	for y in range(floori(area.position.y/2),ceili(area.end.y/2)):
		for x in range(floori(area.position.x/2),ceili(area.end.x/2)):
			if pixels.get_pixel(x,y).a>0:return false
	return true

func clear_ornamentals_under_bushes()->void:
	var bushes:Array=g.objects.filter(func(obj):return obj.kind=="garden_bush")
	g.objects.assign(g.objects.filter(func(obj):
		return obj.kind not in ["flowers","blueflowers"] or not bushes.any(func(bush):
			return layout_bounds("garden_bush",bush.pos).intersects(Rect2(obj.pos-Vector2(26,38),Vector2(52,41))))))

func add(kind:String,id:String,point:Vector2,variant:int,solid:bool=false)->void:
	g.objects.append({"kind":kind,"id":id,"pos":point,"solid":solid,"variant":variant})

func layout_bounds(kind:String,point:Vector2)->Rect2:
	var size:=Vector2(38,25)
	if kind=="garden_bush":size=Vector2(54,76)
	if kind=="garden_grass":size=Vector2(68,40)
	if kind=="garden_table":size=Vector2(106,72)
	return Rect2(point-Vector2(size.x*.5,size.y-6),size)

func place_clear(kind:String,point:Vector2,margin:float)->bool:
	var grass:=kind=="garden_grass"
	var bounds:=layout_bounds(kind,point).grow(margin)
	var side_margin:=84.0 if grass else 100.0
	if point.x<side_margin or point.x>float(g.grid[0].length())*g.TILE-side_margin:return false
	if point.y<(7.5 if grass else 8)*g.TILE or point.y>float(g.grid.size()-7)*g.TILE:return false
	if not g.valid_ground(point) or g.blocked(point):return false
	# All large objects can be approached from below.
	var approach:=point+Vector2(0,44)
	if not g.valid_ground(approach) or g.blocked(approach):return false
	for obj in g.objects:
		if kind=="garden_bush" and obj.kind in ["flowers","blueflowers"]:continue
		if obj.kind=="sprout" and not obj.get("layout_placed",false):continue
		var other_pos:Vector2=obj.pos
		if absf(other_pos.x-point.x)>160 or absf(other_pos.y-point.y)>175:continue
		var visual:Rect2=layout_bounds(obj.kind,other_pos) if obj.kind in KINDS else g.item_visual_bounds(obj)
		if obj.kind=="sprout":visual=Rect2(other_pos-Vector2(30,74),Vector2(60,84))
		if obj.kind=="doorway":visual=Rect2(other_pos-Vector2(140,90),Vector2(280,145))
		if visual.intersects(bounds) or visual.grow(14).has_point(approach):return false
		if obj.kind in ["garden_bush","garden_table"] and bounds.has_point(other_pos+Vector2(0,44)):return false
	return true

func restore_tools()->void:
	for obj in g.objects:
		if obj.kind not in TOOLS:continue
		var position:Array=g.save_data.tool_positions.get("5:"+str(obj.id),[])
		if position.size()==2:obj.pos=Vector2(position[0],position[1])

func drop(point:Vector2)->void:
	var saved:=state()
	var id:String=saved.held_basket if g.held_item=="garden_basket" else g.held_item
	for obj in g.objects:
		if obj.id!=id:continue
		obj.pos=point
		g.save_data.tool_positions["5:"+str(obj.id)]=[point.x,point.y]
		break
	if g.held_item=="garden_basket":saved.held_basket=""
	g.held_item=""
	g.sync_hands()

func bush_phase(id:String)->int:
	var bush:Dictionary=state().bushes.get(id,{})
	return int(bush.get("phase",Bush.OVERGROWN))

func visible(obj:Dictionary)->bool:
	if obj.kind=="garden_grass":return obj.id not in state().grass
	if obj.kind=="garden_basket":
		var saved:=state()
		return obj.id not in saved.delivered_baskets and (g.held_item!="garden_basket" or obj.id!=saved.held_basket)
	return obj.kind not in TOOLS or g.held_item!=obj.kind

func basket_filled(id:String)->bool:
	return id in state().filled_baskets

func nearby_table()->int:
	return g.objects.find_custom(func(obj):return obj.kind=="garden_table" and obj.pos.distance_squared_to(g.player)<TABLE_REACH*TABLE_REACH)

func can_eat_basket()->bool:
	return g.level==5 and g.held_item=="garden_basket" and basket_filled(state().held_basket) and nearby_table()<0

func eat_basket()->void:
	if g.paused or g.transition or g.task_time>0 or not can_eat_basket():return
	state().filled_baskets.erase(state().held_basket)
	restore_available_bushes()
	g.eat_fruit("berries")
	g.find_nearest()
	g.update_hud()

func icon_needed(obj:Dictionary)->String:
	match obj.kind:
		"garden_grass":return "rake"
		"garden_bush":
			match bush_phase(obj.id):
				Bush.OVERGROWN:return "shears"
				Bush.TRIMMED,Bush.PICKED:return "water"
				Bush.RIPE:return "basket"
		"garden_table":
			return "basket" if state().delivered_baskets.size()<BASKETS_REQUIRED else ""
		"garden_shears":return "shears"
		"garden_basket":return "basket"
	return ""

func available(obj:Dictionary)->bool:
	if not visible(obj):return false
	if obj.kind in TOOLS:return true
	match icon_needed(obj):
		"rake":return g.held_item=="rake"
		"shears":return g.held_item=="garden_shears"
		"water":return g.held_item=="can"
		"basket":
			var id:String=state().held_basket
			return g.held_item=="garden_basket" and id in BASKET_IDS and basket_filled(id)==(obj.kind=="garden_table")
	return false

func item_name(obj:Dictionary)->String:
	match obj.kind:
		"garden_shears":return g.tx("item_shears")
		"garden_basket":return g.tx("garden_basket_name")
	return ""

func action_text(obj:Dictionary)->String:
	match obj.kind:
		"garden_grass":return g.tx("garden_rake_grass")
		"garden_shears":return g.tx("pickup_shears")
		"garden_basket":return g.tx("garden_take_basket")
		"garden_table":return g.tx("garden_deposit_basket")
		"garden_bush":
			match bush_phase(obj.id):
				Bush.OVERGROWN:return g.tx("garden_trim_bush")
				Bush.RIPE:return g.tx("garden_harvest_bush")
				_:return g.tx("water_action")
	return ""

func interact(obj:Dictionary)->void:
	if not available(obj):return
	if obj.kind in TOOLS:
		g.equip_tool(obj.kind)
		if obj.kind=="garden_basket":state().held_basket=obj.id
		g.sfx("ui")
		g.find_nearest()
		g.update_hud()
		g.persist()
		return
	var job:="garden_rake"
	if obj.kind=="garden_table":job="garden_deposit"
	elif obj.kind=="garden_bush":
		match bush_phase(obj.id):
			Bush.OVERGROWN:job="garden_trim"
			Bush.RIPE:job="garden_harvest"
			_:
				if g.water<=0:
					g.notify(g.tx("water_empty"))
					return
				job="garden_water"
	var duration:float={"garden_water":.9,"garden_trim":.66,"garden_harvest":HARVEST_SECONDS}.get(job,.55)
	g.begin_task(job+":"+str(obj.id),obj.pos,duration)

func is_trimming(task:String)->bool:
	return task.begins_with("garden_trim:") or task.begins_with("garden_trim_tree:")

func update_snips(previous:float,current:float)->void:
	for closing in SNIP_AT:
		if previous<closing and current>=closing:
			g.sfx("shears")
			break

func complete(task:String,point:Vector2)->bool:
	if not task.begins_with("garden_"):return false
	var parts:=task.split(":",false,1)
	var saved:=state()
	match parts[0]:
		"garden_rake":
			if parts[1] not in saved.grass:
				saved.grass.append(parts[1])
				g.garden_lawn.begin_growth(parts[1])
			g.world_tools.cut_particles(point)
		"garden_trim":
			saved.bushes[parts[1]]={"phase":Bush.TRIMMED}
			g.world_tools.cut_particles(point)
		"garden_trim_tree":
			if parts[1] not in saved.trimmed_trees:saved.trimmed_trees.append(parts[1])
			g.world_tools.cut_particles(point+Vector2(0,-34))
		"garden_water":
			g.water-=1
			g.save_data.water=g.water
			g.stats.add(g,"waterings")
			saved.bushes[parts[1]]={"phase":Bush.WATERED,"remaining":BERRY_GROWTH_TIME}
			g.burst(point,7,Color("9fdce1"))
		"garden_harvest":
			if g.held_item!="garden_basket" or saved.held_basket not in BASKET_IDS or basket_filled(saved.held_basket):return true
			saved.bushes[parts[1]]={"phase":Bush.PICKED}
			saved.filled_baskets.append(saved.held_basket)
		"garden_deposit":
			if g.held_item!="garden_basket" or not basket_filled(saved.held_basket):return true
			saved.filled_baskets.erase(saved.held_basket)
			saved.delivered_baskets.append(saved.held_basket)
			g.save_data.tool_positions.erase("5:"+str(saved.held_basket))
			saved.held_basket=""
			g.held_item=""
			g.sync_hands()
			g.burst(point,9,Color("dda5aa"))
	g.garden_goal_advanced()
	return true

func update(delta:float)->void:
	var saved:=state()
	var changed:=false
	for bush in saved.bushes.values():
		if int(bush.phase)!=Bush.WATERED:continue
		bush.remaining=maxf(0.0,float(bush.remaining)-delta)
		if bush.remaining==0.0:
			bush.phase=Bush.RIPE
			changed=true
	if changed:g.persist()

func sprite_index(obj:Dictionary)->int:
	var variant:=int(obj.variant)
	match obj.kind:
		"garden_grass":return variant
		"garden_bush":return [8,16,24,32,36][bush_phase(obj.id)]+variant
		"garden_shears":return 40
		"garden_basket":return 47 if basket_filled(obj.id) else 45
		"garden_table":return 48+mini(state().delivered_baskets.size(),BASKETS_REQUIRED)
	return 0

func warm_up()->void:
	if atlas_image==null:atlas_image=texture().get_image()
	for kind in ["basket","shears"]:icon(kind)

func texture()->Texture2D:
	if art==null:art=load("res://assets/garden_quest.png")
	return art

func region(index:int)->Rect2:
	return Rect2(Vector2(index%8,index/8)*TILE_SIZE,TILE_SIZE)

func used_rect(index:int)->Rect2:
	if not opaque_bounds.has(index):
		if atlas_image==null:atlas_image=texture().get_image()
		opaque_bounds[index]=Rect2(atlas_image.get_region(Rect2i(region(index))).get_used_rect())
	return opaque_bounds[index]

func bounds(obj:Dictionary)->Rect2:
	var index:int=obj.garden_tree_sprite if tree_needs_trim(obj) else sprite_index(obj)
	var used:=used_rect(index)
	return Rect2(Vector2(obj.pos)+(used.position-ANCHOR)*2.0,used.size*2.0)

func icon(kind:String)->Texture2D:
	if not icons.has(kind):
		if kind in ["basket","shears"]:
			var index:=45 if kind=="basket" else 40
			var result:=AtlasTexture.new()
			result.atlas=texture()
			var used:=used_rect(index)
			result.region=Rect2(region(index).position+used.position,used.size)
			icons[kind]=result
		else:
			icons[kind]=load("res://assets/ui/action_"+kind+".png")
	return icons[kind]

func hint_source(kind:String)->Image:
	var index:=45 if kind=="basket" else 40
	var used:=used_rect(index)
	var sprite:=atlas_image.get_region(Rect2i(region(index).position+used.position,used.size))
	# Follow the proportions and transparent margins of the bed badges.
	var scale_factor:=minf(1.0,minf(21.0/used.size.x,18.0/used.size.y))
	var size:=Vector2i((used.size*scale_factor).round())
	if sprite.get_size()!=size:sprite.resize(size.x,size.y,Image.INTERPOLATE_NEAREST)
	var frame:=Image.create(24,28,false,Image.FORMAT_RGBA8)
	frame.blit_rect(sprite,Rect2i(Vector2i.ZERO,size),Vector2i((24-size.x)/2,15-size.y/2))
	return frame

func draw_object(obj:Dictionary,pos:Vector2,highlighted:bool)->void:
	var index:int=obj.garden_tree_sprite if tree_needs_trim(obj) else sprite_index(obj)
	var box:=Rect2(pos-ANCHOR*2.0,TILE_SIZE*2.0)
	var source:=region(index)
	if highlighted:
		if not outlines.has(index):
			if atlas_image==null:atlas_image=texture().get_image()
			var tile:=atlas_image.get_region(Rect2i(source))
			var border:=Image.create(66,66,false,Image.FORMAT_RGBA8)
			for y in range(64):
				for x in range(64):
					if tile.get_pixel(x,y).a<.2:continue
					for offset in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
						border.set_pixelv(Vector2i(x+1,y+1)+offset,Color("fff3a6"))
			outlines[index]=ImageTexture.create_from_image(border)
		g.draw_pickup_outline_border(outlines[index],box.grow(2))
	g.draw_texture_rect_region(texture(),box,source)

func draw_hints()->void:
	var origin:Vector2=g.screen(Vector2.ZERO)
	var hint_view:Rect2=g.get_viewport_rect().grow(46.0)
	# A badge can sit above the visible crown, but never more than the
	# sprite anchor plus the badge offset and its three-pixel bob.
	var candidate_view:=Rect2(hint_view.position-origin,
		hint_view.size+Vector2(0,ANCHOR.y*2+45.0))
	for obj in g.objects:
		if not candidate_view.has_point(obj.pos):continue
		var tree:=tree_needs_trim(obj)
		if not tree and (obj.kind not in ["garden_grass","garden_bush","garden_table"] or not visible(obj)):continue
		if obj.kind!="garden_bush":
			var range_px:=116.0 if obj.kind=="garden_grass" else 156.0
			if obj.pos.distance_squared_to(g.player)>range_px*range_px:continue
		if g.task_time>0 and g.task_target==obj.pos:continue
		var needed:="shears" if tree else icon_needed(obj)
		if needed.is_empty():continue
		var world_box:=bounds(obj)
		var top:=world_box.position.y-42+sin(g.time*2.2+float(obj.get("variant",0)))*3
		g.draw_garden_need(needed,(Vector2(obj.pos.x,top)+origin).round())

func held_pose()->Dictionary:
	var shears:bool=g.held_item=="garden_shears"
	var anchor:=Vector2(29,48) if shears else Vector2(32,39)
	var scale_factor:=1.0 if shears else 1.25
	var origin:Vector2=g.screen(g.right_hand_position())
	var toward:Vector2=g.walk_facing
	if g.task_time>0:toward=(g.task_target-g.player).normalized()
	var flip:=Vector2(-1,1) if shears and toward.x<-.1 else Vector2.ONE
	var trimming:bool=g.task_time>0 and is_trimming(g.task_kind)
	var rotation:=0.0
	if shears:
		rotation=toward.angle()-(Vector2(2,-16)*flip).angle()
		if trimming:rotation+=sin(g.time*23)*.18
	else:
		# The basket stays vertical as the right wrist moves.
		rotation=sin(g.time*12)*.10 if g.moving else 0.0
	var index:=44 if not shears and basket_filled(state().held_basket) else 42
	if shears:
		var elapsed:float=g.task_duration-g.task_time
		index=52 if trimming and SNIP_AT.any(func(closing):return elapsed>=closing and elapsed<closing+.09) else 41
	return {"origin":origin,"rotation":rotation,"flip":flip,
		"box":Rect2(-anchor*scale_factor,TILE_SIZE*scale_factor),
		"source":region(index)}

func draw_held()->void:
	var pose:=held_pose()
	g.draw_set_transform(pose.origin,pose.rotation,pose.flip)
	g.draw_texture_rect_region(texture(),pose.box,pose.source)
	g.draw_set_transform(Vector2.ZERO)
