extends RefCounted
## Seeded garden jobs, independent of the flower beds. The basket is reusable.
const GRASS_COUNT := 20
const BUSH_COUNT := 4
const BASKETS_REQUIRED := 3
const BUSH_SPACING := 64.0
const BERRY_GROWTH_TIME := 4.0
const TOOLS := ["garden_shears","garden_basket"]
const KINDS := ["garden_grass","garden_bush","garden_shears","garden_basket","garden_table"]
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
	if saved.is_empty():
		saved.merge({"grass":[],"bushes":{},"load":0,"baskets":0})
	return saved

func ready()->bool:
	var saved:=state()
	return saved.grass.size()>=GRASS_COUNT and int(saved.baskets)>=BASKETS_REQUIRED

func place(grass_only:bool)->void:
	var saved:=state()
	if saved.has("layout"):
		for entry in saved.layout:
			if (entry.kind=="garden_grass")!=grass_only:continue
			g.objects.append({"kind":entry.kind,"id":entry.id,"pos":Vector2(entry.pos[0],entry.pos[1]),
				"solid":entry.kind in ["garden_bush","garden_table"],"variant":int(entry.variant)})
		if not grass_only:clear_ornamentals_under_row()
		return
	var rng:=RandomNumberGenerator.new()
	rng.seed=int(g.save_data.seed)^(0x47524153 if grass_only else 0x47415244)
	var candidates:Array[Vector2]=[]
	for y in range(8,g.grid.size()-7):
		for x in range(2,g.grid[0].length()-2):
			candidates.append(Vector2(x+.5,y+.5)*g.TILE)
	# A second staggered grid makes room for a row even in a busy seed.
	for y in range(9,g.grid.size()-8):
		for x in range(2,g.grid[0].length()-2):
			candidates.append(Vector2(x+1,y+.5)*g.TILE)
	for i in range(candidates.size()-1,0,-1):
		var other:=rng.randi_range(0,i)
		var point:=candidates[i]
		candidates[i]=candidates[other]
		candidates[other]=point
	if grass_only:
		place_grass(candidates,rng)
		saved.layout=[]
		for obj in g.objects:
			if obj.kind in KINDS:
				saved.layout.append({"kind":obj.kind,"id":obj.id,"pos":[obj.pos.x,obj.pos.y],"variant":obj.variant})
		return
	place_landmarks(candidates)

func place_landmarks(candidates:Array[Vector2])->void:
	var placed_row:=false
	for center in candidates:
		var row:Array[Vector2]=[]
		for index in range(BUSH_COUNT):
			row.append(center+Vector2((index-(BUSH_COUNT-1)*.5)*BUSH_SPACING,0))
		if not row.all(func(point):return place_clear("garden_bush",point,5.0)):continue
		for index in range(BUSH_COUNT):
			add("garden_bush",str(index),row[index],index,true)
		clear_ornamentals_under_row()
		placed_row=true
		break
	assert(placed_row,"Garden requires a reachable row of four bushes")
	for kind in ["garden_table","garden_basket","garden_shears"]:
		for point in candidates:
			if not place_clear(kind,point,8.0):continue
			add(kind,"",point,0,kind=="garden_table")
			break

func place_grass(candidates:Array[Vector2],rng:RandomNumberGenerator)->void:
	var next:=0
	var palette: Array[int] = [0,1,2,3,4,5]
	for point in candidates:
		if not place_clear("garden_grass",point,7.0):continue
		if palette.is_empty():palette.assign([0,1,2,3,4,5])
		var index:=rng.randi_range(0,palette.size()-1)
		add("garden_grass",str(next),point,palette.pop_at(index))
		next+=1
		if next==GRASS_COUNT:break
	assert(next==GRASS_COUNT,"Garden requires twenty grass piles")

func clear_ornamentals_under_row()->void:
	var row:Array=g.objects.filter(func(obj):return obj.kind=="garden_bush")
	g.objects.assign(g.objects.filter(func(obj):
		return obj.kind not in ["flowers","blueflowers"] or not row.any(func(bush):
			return layout_bounds("garden_bush",bush.pos).intersects(Rect2(obj.pos-Vector2(26,38),Vector2(52,41))))))

func add(kind:String,suffix:String,point:Vector2,variant:int,solid:bool=false)->void:
	var id:=kind if suffix.is_empty() else kind+"_"+suffix
	g.objects.append({"kind":kind,"id":id,"pos":point,"solid":solid,"variant":variant})

func layout_bounds(kind:String,point:Vector2)->Rect2:
	var size:=Vector2(38,25)
	if kind=="garden_bush":size=Vector2(68,84)
	if kind=="garden_table":size=Vector2(106,72)
	return Rect2(point-Vector2(size.x*.5,size.y-6),size)

func place_clear(kind:String,point:Vector2,margin:float)->bool:
	var bounds:=layout_bounds(kind,point).grow(margin)
	if point.x<100 or point.x>float(g.grid[0].length())*g.TILE-100:return false
	if point.y<8*g.TILE or point.y>float(g.grid.size()-7)*g.TILE:return false
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
	for obj in g.objects:
		if obj.kind!=g.held_item:continue
		obj.pos=point
		g.save_data.tool_positions["5:"+str(obj.id)]=[point.x,point.y]
		break
	g.held_item=""
	g.sync_hands()

func bush_phase(id:String)->int:
	var bush:Dictionary=state().bushes.get(id,{})
	return int(bush.get("phase",Bush.OVERGROWN))

func visible(obj:Dictionary)->bool:
	if obj.kind=="garden_grass":return obj.id not in state().grass
	if obj.kind=="garden_basket" and int(state().baskets)>=BASKETS_REQUIRED:return false
	return obj.kind not in TOOLS or g.held_item!=obj.kind

func icon_needed(obj:Dictionary)->String:
	match obj.kind:
		"garden_grass":return "rake"
		"garden_bush":
			match bush_phase(obj.id):
				Bush.OVERGROWN:return "shears"
				Bush.TRIMMED,Bush.PICKED:return "water"
				Bush.RIPE:return "basket"
		"garden_table":
			return "basket" if int(state().baskets)<BASKETS_REQUIRED else ""
		"garden_shears":return "shears"
		"garden_basket":return "basket"
	return ""

func available(obj:Dictionary)->bool:
	if not visible(obj):return false
	if obj.kind in TOOLS:return true
	if obj.kind=="garden_table":
		return g.held_item=="garden_basket" and int(state().load)>=BUSH_COUNT
	var needed:=icon_needed(obj)
	return (needed=="rake" and g.held_item=="rake") or (needed=="shears" and g.held_item=="garden_shears") or (needed=="water" and g.held_item=="can") or (needed=="basket" and g.held_item=="garden_basket" and int(state().load)<BUSH_COUNT)

func item_name(obj:Dictionary)->String:
	match obj.kind:
		"garden_grass":return g.tx("garden_grass_name")
		"garden_bush":return g.tx("garden_bush_name")
		"garden_shears":return g.tx("item_shears")
		"garden_basket":return g.tx("garden_basket_name")
		"garden_table":return g.tx("garden_table_count").format({"count":state().baskets,"goal":BASKETS_REQUIRED})
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
		g.sfx("garden_pickup")
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
	g.begin_task(job+":"+str(obj.id),obj.pos,.9 if job=="garden_water" else .55)

func complete(task:String,point:Vector2)->bool:
	if not task.begins_with("garden_"):return false
	var parts:=task.split(":",false,1)
	var saved:=state()
	match parts[0]:
		"garden_rake":
			if parts[1] not in saved.grass:saved.grass.append(parts[1])
			g.world_tools.cut_particles(point)
		"garden_trim":
			saved.bushes[parts[1]]={"phase":Bush.TRIMMED}
			g.world_tools.cut_particles(point)
		"garden_water":
			g.water-=1
			g.save_data.water=g.water
			g.stats.add(g,"waterings")
			saved.bushes[parts[1]]={"phase":Bush.WATERED,"remaining":BERRY_GROWTH_TIME}
			g.burst(point,7,Color("9fdce1"))
		"garden_harvest":
			saved.bushes[parts[1]]={"phase":Bush.PICKED}
			saved.load=int(saved.load)+1
			g.notify(g.tx("garden_basket_count").format({"count":saved.load,"goal":BUSH_COUNT}))
		"garden_deposit":
			saved.load=0
			saved.baskets=int(saved.baskets)+1
			if int(saved.baskets)>=BASKETS_REQUIRED:
				g.held_item=""
				g.sync_hands()
			g.burst(point,9,Color("dda5aa"))
	g.garden_goal_advanced()
	return true

func update(delta:float)->void:
	var saved:=state()
	if not saved.get("introduced",false) and g.inside_main_room() and not g.door_is_open("exit"):
		saved.introduced=true
		g.notify(g.tx("garden_chores_required"))
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
		"garden_basket":return 45+basket_stage()
		"garden_table":return 48+clampi(int(state().baskets),0,BASKETS_REQUIRED)
	return 0

func basket_stage()->int:
	var amount:=int(state().load)
	if amount>=BUSH_COUNT:return 2
	return 1 if amount>0 else 0

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
	var used:=used_rect(sprite_index(obj))
	return Rect2(Vector2(obj.pos)+(used.position-ANCHOR)*2.0,used.size*2.0)

func icon(kind:String)->Texture2D:
	if not icons.has(kind):
		if kind=="basket":
			var result:=AtlasTexture.new()
			result.atlas=texture()
			var used:=used_rect(45)
			result.region=Rect2(region(45).position+used.position,used.size)
			icons[kind]=result
		else:
			icons[kind]=load("res://assets/ui/action_"+kind+".png")
	return icons[kind]

func draw_object(obj:Dictionary,pos:Vector2,highlighted:bool)->void:
	var index:=sprite_index(obj)
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
	for obj in g.objects:
		if obj.kind not in ["garden_grass","garden_bush","garden_table"] or not visible(obj):continue
		var range_px:=116.0 if obj.kind=="garden_grass" else 156.0
		if obj.pos.distance_squared_to(g.player)>range_px*range_px:continue
		if g.task_time>0 and g.task_target==obj.pos:continue
		var needed:=icon_needed(obj)
		if needed.is_empty():continue
		var world_box:=bounds(obj)
		var point:Vector2=g.screen(Vector2(obj.pos.x,world_box.position.y-20)).round()
		var badge:=Rect2(point-Vector2(13,14),Vector2(26,23))
		g.draw_rect(badge,Color("46364c"))
		g.draw_rect(badge,Color("b391a7"),false,1)
		var art_icon:=icon(needed)
		g.draw_texture_rect(art_icon,badge.grow(-3),false)

func held_pose()->Dictionary:
	var shears:bool=g.held_item=="garden_shears"
	var anchor:=Vector2(29,49) if shears else Vector2(32,39)
	var scale_factor:=1.35 if shears else 1.25
	var origin:Vector2=g.screen(g.right_hand_position())
	var toward:Vector2=g.walk_facing
	if g.task_time>0:toward=(g.task_target-g.player).normalized()
	var flip:=Vector2(-1,1) if shears and toward.x<-.1 else Vector2.ONE
	var rotation:=0.0
	if shears:
		rotation=toward.angle()-(Vector2(13,-2)*flip).angle()
		if g.task_time>0 and g.task_kind.begins_with("garden_trim:"):rotation+=sin(g.time*23)*.18
	else:
		# The basket stays vertical as the right wrist moves.
		rotation=sin(g.time*12)*.10 if g.moving else 0.0
	var index:=42+basket_stage()
	if shears:
		index=52 if g.task_time>0 and g.task_kind.begins_with("garden_trim:") and int(g.time*10)%2==0 else 41
	return {"origin":origin,"rotation":rotation,"flip":flip,
		"box":Rect2(-anchor*scale_factor,TILE_SIZE*scale_factor),
		"source":region(index)}

func draw_held()->void:
	var pose:=held_pose()
	g.draw_set_transform(pose.origin,pose.rotation,pose.flip)
	g.draw_texture_rect_region(texture(),pose.box,pose.source)
	g.draw_set_transform(Vector2.ZERO)
