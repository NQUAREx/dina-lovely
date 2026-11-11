extends RefCounted
## Continuous wall graph, free crown packing and local elastic contacts.
## No tile sprites, baked leaf strips or fixed canopy overlays.
const TILE := 48.0
const BIN := 24.0
var grid: Array[String] = []
var crowns: Array[Dictionary] = []
var chains: Array[PackedVector2Array] = []
var segments: Array[Dictionary] = []
var segment_cells: Dictionary = {}
var bins: Dictionary = {}
var active: Dictionary = {}
var draw_order: Array[int] = []
var trunks: Array[Vector2] = []
var body_texture: ImageTexture
var body_tiles: Dictionary = {}
var last_player := Vector2.INF
var wind_clock:=4.0
var wind_rng:=RandomNumberGenerator.new()
var front_crowns:Dictionary={}
var draw_poses:Dictionary={}
var contact_strength:=0.0
var motion_strength:=0.0
var visible_first:=Vector2i(-9999,-9999)
var visible_last:=Vector2i(-9999,-9999)
var visible_candidates:Array[int]=[]
var rng := RandomNumberGenerator.new()

func build(map: Array[String], seed_value: int, trees: Dictionary, berries: Dictionary, material: Image = null) -> void:
	removed_cells.clear();crowns.clear();chains.clear();segments.clear();segment_cells.clear();bins.clear();active.clear();draw_order.clear();trunks.clear();body_tiles.clear();body_texture=null;last_player=Vector2.INF;contact_strength=0.0;motion_strength=0.0
	grid=map.duplicate();rng.seed=seed_value+38911;wind_rng.randomize();wind_clock=wind_rng.randf_range(4,8)
	visible_first=Vector2i(-9999,-9999);visible_candidates.clear()
	for tree in trees.values():trunks.append(tree.pos)
	var graph:Dictionary={}
	for y in range(grid.size()):
		for x in range(grid[0].length()):
			var cell:=Vector2i(x,y)
			if not wall(cell):continue
			var links:Array[Vector2i]=[]
			for direction in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
				var next:Vector2i=cell+direction
				if wall(next):links.append(next)
			graph[cell]=links
			for next in links:
				if next.x<x or next.y<y:continue
				add_segment((Vector2(cell)+Vector2(.5,.5))*TILE,(Vector2(next)+Vector2(.5,.5))*TILE)
			if links.is_empty():add_segment((Vector2(cell)+Vector2(.5,.5))*TILE,(Vector2(cell)+Vector2(.5,.5))*TILE)
	var visited:Dictionary={}
	for cell in graph:
		if graph[cell].size()==2:continue
		for next in graph[cell]:trace_chain(cell,next,graph,visited)
	for cell in graph:
		for next in graph[cell]:trace_chain(cell,next,graph,visited)
	# Independent, longitudinally jittered streams follow entire wall chains.
	for chain in chains:
		var length:=0.0
		for n in range(1,chain.size()):length+=chain[n].distance_to(chain[n-1])
		for lane in [-9.2,9.2]:
			var distance:=rng.randf_range(-13,-3)
			while distance<length+16:
				var sample:=chain_sample(chain,distance)
				var tangent:Vector2=sample.tangent
				var point:Vector2=sample.pos+tangent.orthogonal()*(lane+rng.randf_range(-1.8,1.8))+tangent*rng.randf_range(-3,3)
				try_crown(point,rng.randf_range(9.5,11.5))
				distance+=rng.randf_range(18.5,21.5)
	# Fill irregular gaps globally. A cell is only a sampling bin, never a unit of artwork.
	for pass_index in range(3):
		for cell in graph:
			for attempt in range(24):
				var point:Vector2=Vector2(cell)*TILE+Vector2(rng.randf_range(3,45),rng.randf_range(3,45))
				try_crown(point,rng.randf_range(6.2,9.2) if pass_index==0 else rng.randf_range(4.5,7.2))
	# Grow into spare space until neighbouring silhouettes nearly touch.
	for pass_index in range(9):
		for node in crowns:
			var radius:float=minf(12.8,float(node.radius)+.35)
			for other_index in near_ids(node.base,32):
				var other:Dictionary=crowns[other_index]
				if other==node:continue
				radius=minf(radius,node.base.distance_to(other.base)-float(other.radius)-.35)
			for trunk in trunks:radius=minf(radius,node.base.distance_to(trunk)-4)
			if radius>float(node.radius) and surface_fits(node.base,radius):node.radius=radius
	for cell in berries:
		var centre:Vector2=(Vector2(cell)+Vector2(.5,.5))*TILE
		var nearby:Array[int]=near_ids(centre,32)
		nearby=nearby.filter(func(index):return Vector2i(crowns[index].base/TILE)==cell)
		nearby.sort_custom(func(a,b):return crowns[a].base.distance_squared_to(centre)<crowns[b].base.distance_squared_to(centre))
		for n in range(mini(2,nearby.size())):crowns[nearby[n]].berry=berries[cell]
	for n in range(crowns.size()):draw_order.append(n)
	draw_order.sort_custom(func(a,b):
		if crowns[a].base.y==crowns[b].base.y:return crowns[a].base.x<crowns[b].base.x
		return crowns[a].base.y<crowns[b].base.y)
	for rank in range(draw_order.size()):crowns[draw_order[rank]].rank=rank
	for node in crowns:node.neighbours=near_ids(node.base,38)
	build_body(material)

func wall(cell: Vector2i) -> bool:
	return cell.x>=0 and cell.y>=0 and cell.y<grid.size() and cell.x<grid[0].length() and grid[cell.y][cell.x]=="#"

func edge_key(a: Vector2i, b: Vector2i) -> String:
	return str(a)+":"+str(b) if a.x<b.x or (a.x==b.x and a.y<b.y) else str(b)+":"+str(a)

func trace_chain(first: Vector2i, second: Vector2i, graph: Dictionary, visited: Dictionary) -> void:
	if visited.has(edge_key(first,second)):return
	var points:=PackedVector2Array([(Vector2(first)+Vector2(.5,.5))*TILE])
	var previous:=first;var current:=second
	while true:
		visited[edge_key(previous,current)]=true
		points.append((Vector2(current)+Vector2(.5,.5))*TILE)
		var links:Array=graph[current]
		if links.size()!=2:break
		var next:Vector2i=links[1] if links[0]==previous else links[0]
		if visited.has(edge_key(current,next)):break
		previous=current;current=next
	chains.append(points)

func chain_sample(chain: PackedVector2Array, distance: float) -> Dictionary:
	var tangent:Vector2=(chain[1]-chain[0]).normalized()
	if distance<0:return {"pos":chain[0]+tangent*distance,"tangent":tangent}
	for n in range(1,chain.size()):
		var length:=chain[n].distance_to(chain[n-1])
		tangent=(chain[n]-chain[n-1]).normalized()
		if distance<=length:return {"pos":chain[n-1]+tangent*distance,"tangent":tangent}
		distance-=length
	return {"pos":chain[-1]+tangent*distance,"tangent":tangent}

func surface_fits(point: Vector2, radius: float) -> bool:
	if point.x-radius<1 or point.y-radius<1 or point.x+radius>grid[0].length()*TILE-1 or point.y+radius>grid.size()*TILE-1:return false
	for normal in [Vector2.ZERO,Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN,Vector2(-.707,-.707),Vector2(.707,-.707),Vector2(-.707,.707),Vector2(.707,.707)]:
		if not wall(Vector2i((point+normal*(radius-1))/TILE)):return false
	return true

func try_crown(point: Vector2, radius: float) -> void:
	if not surface_fits(point,radius):return
	for trunk in trunks:
		if trunk.distance_to(point)<radius+4:return
	for index in near_ids(point,26):
		var other:Dictionary=crowns[index]
		if point.distance_squared_to(other.base)<pow(radius+float(other.radius)+.35,2):return
	var index:=crowns.size()
	crowns.append({"base":point,"offset":Vector2.ZERO,"velocity":Vector2.ZERO,"radius":radius,"variant":rng.randi_range(0,11),"berry":"","press":0.0,"depression":0.0,"depression_velocity":0.0,"released":false,"sway":0.0,"sway_velocity":0.0,"last_pressure":0.0})
	var bin:=Vector2i(point/BIN)
	if not bins.has(bin):bins[bin]=[]
	bins[bin].append(index)

func near_ids(point: Vector2, radius: float) -> Array[int]:
	var result:Array[int]=[]
	var first:=Vector2i((point-Vector2.ONE*radius)/BIN)
	var last:=Vector2i((point+Vector2.ONE*radius)/BIN)
	for y in range(first.y,last.y+1):
		for x in range(first.x,last.x+1):
			for index in bins.get(Vector2i(x,y),[]):result.append(index)
	return result

func update(delta: float, player: Vector2) -> void:
	delta=minf(delta,1.0/30.0)
	last_player=player;contact_strength=0.0;motion_strength=0.0
	wind_clock-=delta
	if wind_clock<=0:
		wind_clock=wind_rng.randf_range(4.0,9.0)
		var candidates:=near_ids(player,380)
		if not candidates.is_empty():
			var chosen:int=candidates[wind_rng.randi_range(0,candidates.size()-1)]
			var gust:=wind_rng.randf_range(8,13)*(1 if wind_rng.randf()>.5 else -1)
			var gust_count:=0
			for index in near_ids(crowns[chosen].base,42):
				if crowns[index].get("hidden",false):continue
				crowns[index].sway_velocity+=gust*1.7;active[index]=true;gust_count+=1
				if gust_count>=8:break
	for index in near_ids(player,38):
		if not crowns[index].get("hidden",false) and crowns[index].base.distance_squared_to(player)<36*36:active[index]=true
	var done:Array[int]=[]
	for index in active:
		var node:Dictionary=crowns[index]
		var previous_offset:Vector2=node.offset
		var previous_depression:float=node.depression
		var away:Vector2=node.base-player
		if away.length()>44:node.released=false
		var pressure:=clampf((36-away.length())/18,0,1)
		var required_drop:=maxf(0,ceilf(player.y-28+roundf(node.radius*1.48))-((node.base+node.offset).round().y-16))
		node.released=pressure>0 and required_drop>22
		if pressure>.005 and node.last_pressure<=.005:
			node.sway_velocity+=(1.0 if away.x>=0 else -1.0)*(64+pressure*20)
		node.last_pressure=pressure
		node.sway_velocity+=(-node.sway*45-node.sway_velocity*3.4)*delta
		node.sway=clampf(node.sway+node.sway_velocity*delta,-8.0,8.0)
		if absf(node.sway)<.025 and absf(node.sway_velocity)<.1:node.sway=0.0;node.sway_velocity=0.0
		contact_strength=maxf(contact_strength,pressure)
		if pressure==0 and node.press==0 and node.offset==Vector2.ZERO and node.velocity==Vector2.ZERO and node.depression==0:
			if node.sway==0 and node.sway_velocity==0:done.append(index)
			continue
		node.press=move_toward(float(node.press),pressure,delta*5)
		var target:=away.normalized()*11.0*pressure
		node.velocity+=(target-node.offset)*145*delta-node.velocity*8.0*delta
		var desired:Vector2=node.offset+node.velocity*delta
		desired=desired.limit_length(9)
		# Sweep each crown against its neighbours: it can bend but cannot overlap them.
		var next:Vector2=node.base+desired
		var own_radius:float=node.radius*(1-node.press*.07)
		var neighbours:Array[int]=node.neighbours
		var valid:=surface_fits(next,own_radius*.75)
		for other_index in neighbours:
			if other_index==index or crowns[other_index].get("hidden",false):continue
			var other:Dictionary=crowns[other_index]
			var other_radius:float=other.radius*(1-other.press*.07)
			if next.distance_squared_to(other.base+other.offset)<pow(own_radius+other_radius+.1,2):valid=false;break
		if valid:node.offset=desired
		else:
			node.velocity*=.25
			# The saved rest packing is always collision free.
			var trial:Vector2=node.offset.lerp(Vector2.ZERO,minf(1,delta*10))
			var clear:=true
			for other_index in neighbours:
				if other_index==index or crowns[other_index].get("hidden",false):continue
				var other:Dictionary=crowns[other_index]
				if (node.base+trial).distance_squared_to(other.base+other.offset)<pow(own_radius+float(other.radius)*(1-float(other.press)*.07)+.1,2):clear=false;break
			if clear or pressure==0:node.offset=trial
		var leaf_radius:=roundf(node.radius*1.48*(1-node.press*.07))
		if node.press>.01 and not node.released and away.length_squared()<42*42:
			node.depression=minf(22,maxf(0,ceilf(player.y-28+leaf_radius)-((node.base+node.offset).round().y-16)))
			node.depression_velocity=0.0
		else:
			node.depression_velocity+=(-node.depression*130-node.depression_velocity*8.0)*delta
			node.depression=clampf(node.depression+node.depression_velocity*delta,-1.5,22)
			if absf(node.depression)<.03 and absf(node.depression_velocity)<.1:node.depression=0.0;node.depression_velocity=0.0

		motion_strength=maxf(motion_strength,maxf(node.offset.distance_to(previous_offset),absf(node.depression-previous_depression))/maxf(delta,.001))
		if pressure==0 and node.depression==0 and node.offset.length()<.04 and node.velocity.length()<.1 and node.press==0 and node.sway==0 and node.sway_velocity==0:
			node.offset=Vector2.ZERO;node.velocity=Vector2.ZERO;done.append(index)
	for index in done:active.erase(index)

func add_segment(a: Vector2, b: Vector2) -> void:
	var index:=segments.size();segments.append({"a":a,"b":b})
	for cell in [Vector2i(a/TILE),Vector2i(b/TILE)]:
		if not segment_cells.has(cell):segment_cells[cell]=[]
		if index not in segment_cells[cell]:segment_cells[cell].append(index)

func closest_on_segment(point: Vector2, segment: Dictionary) -> Vector2:
	var direction:Vector2=segment.b-segment.a
	if direction.length_squared()<.001:return segment.a
	return segment.a+direction*clampf((point-segment.a).dot(direction)/direction.length_squared(),0,1)

func blocks(point: Vector2) -> bool:
	var cell:=Vector2i(point/TILE)
	for y in range(cell.y-1,cell.y+2):
		for x in range(cell.x-1,cell.x+2):
			for index in segment_cells.get(Vector2i(x,y),[]):
				var closest:=closest_on_segment(point,segments[index])
				if not wall(Vector2i(closest/TILE)):continue
				var offset:Vector2=(point-closest)/Vector2(18,15)
				if offset.length_squared()<1:return true
	return false

func foreground(player: Vector2) -> bool:
	var cell:=Vector2i(player/TILE);var nearest:=INF;var normal:=Vector2.ZERO
	for y in range(cell.y-2,cell.y+3):
		for x in range(cell.x-2,cell.x+3):
			for index in segment_cells.get(Vector2i(x,y),[]):
				var away:Vector2=player-closest_on_segment(player,segments[index])
				var distance:=away.length_squared()
				if distance<nearest:nearest=distance;normal=away
	return normal.y<=absf(normal.x)

func crown_in_contact(index: int, player: Vector2) -> bool:
	var node:Dictionary=crowns[index]
	return not node.released and node.press>.01 and node.base.distance_squared_to(player)<42*42

func crown_pose(index: int, player: Vector2) -> Vector3:
	var node:Dictionary=crowns[index]
	var radius:=roundf(node.radius*1.48*(1-node.press*.07))
	var centre:Vector2=(node.base+node.offset+Vector2(float(node.get("sway",0)),0)).round()-Vector2(0,16)+Vector2(0,roundf(node.depression))
	# Bend the whole contacting crown down to leg height, never slice its texture.
	if crown_in_contact(index,player):centre.y=maxf(centre.y,minf(ceilf(player.y-28+radius),node.base.round().y+6))
	return Vector3(centre.x,centre.y,radius)

func crown_behind_hero(index: int, player: Vector2) -> bool:
	if crowns[index].released:return true
	if crown_in_contact(index,player):return false
	# Non-contact crowns retain their fixed painter order.
	return crowns[index].base.y<=player.y+13

func visible_ids(bounds: Rect2) -> PackedInt32Array:
	var first:=Vector2i((bounds.position/BIN).floor())
	var last:=Vector2i((bounds.end/BIN).floor())
	if first!=visible_first or last!=visible_last:
		visible_first=first;visible_last=last;visible_candidates.clear()
		for y in range(first.y,last.y+1):
			for x in range(first.x,last.x+1):
				for index in bins.get(Vector2i(x,y),[]):visible_candidates.append(index)
		visible_candidates.sort_custom(func(a,b):return crowns[a].rank<crowns[b].rank)
	var result:=PackedInt32Array()
	for index in visible_candidates:
		if not crowns[index].get("hidden",false) and bounds.has_point(crowns[index].base):result.append(index)
	return result

func build_body(material: Image) -> void:
	var size:=Vector2i(grid[0].length()*24,grid.size()*24)
	var mask:=PackedByteArray();mask.resize(size.x*size.y)
	var points:=PackedVector2Array()
	for node in crowns:
		var point:Vector2=node.base/2;points.append(point)
		var radius:float=node.radius*.63
		for y in range(maxi(0,int(point.y-radius-1)),mini(size.y,int(point.y+radius+2))):
			for x in range(maxi(0,int(point.x-radius-1)),mini(size.x,int(point.x+radius+2))):
				if Vector2(x+.5,y+.5).distance_squared_to(point)<=radius*radius:mask[y*size.x+x]=1
	# Short neighbouring triangles close the interior; corridor-spanning triangles are rejected.
	var triangles:=Geometry2D.triangulate_delaunay(points)
	for n in range(0,triangles.size(),3):
		var ia:int=triangles[n];var ib:int=triangles[n+1];var ic:int=triangles[n+2]
		var a:=points[ia];var b:=points[ib];var c:=points[ic]
		if a.distance_to(b)>(float(crowns[ia].radius)+float(crowns[ib].radius))*.75+4:continue
		if b.distance_to(c)>(float(crowns[ib].radius)+float(crowns[ic].radius))*.75+4:continue
		if c.distance_to(a)>(float(crowns[ic].radius)+float(crowns[ia].radius))*.75+4:continue
		if not wall(Vector2i((a+b+c)*2/3/TILE)):continue
		var area:float=(b-a).cross(c-a)
		if absf(area)<.01:continue
		for y in range(maxi(0,int(minf(a.y,minf(b.y,c.y)))),mini(size.y,int(maxf(a.y,maxf(b.y,c.y)))+2)):
			for x in range(maxi(0,int(minf(a.x,minf(b.x,c.x)))),mini(size.x,int(maxf(a.x,maxf(b.x,c.x)))+2)):
				var p:=Vector2(x+.5,y+.5)
				if (b-p).cross(c-p)/area>=-.001 and (c-p).cross(a-p)/area>=-.001 and (a-p).cross(b-p)/area>=-.001:mask[y*size.x+x]=1
	var depth:=7
	var image:=Image.create(size.x,size.y+depth,false,Image.FORMAT_RGBA8)
	var palette:Array[Color]=[Color("416b48"),Color("345e40"),Color("284f3a"),Color("1f4435"),Color("173c35")]
	for y in range(size.y+depth):
		for x in range(size.x):
			var drop:=0
			if y>=size.y or mask[y*size.x+x]==0:
				drop=-1
				for d in range(1,depth+1):
					if y-d>=0 and y-d<size.y and mask[(y-d)*size.x+x]!=0:drop=d;break
			if drop<0:continue
			var color:=Color("355f46") if drop==0 else palette[mini(4,int(float(drop)/depth*4))]
			if material!=null and drop>0:
				var sample:=material.get_pixel(posmod(x,32),mini(45,33+int(float(drop)/depth*11)))
				if sample.a>.5:color=sample
			image.set_pixel(x,y,color)
			body_tiles[Vector2i(x/16,y/16)]=true
	body_texture=ImageTexture.create_from_image(image)

func body_offset(point: Vector2) -> Vector2:
	if active.is_empty() or point.distance_squared_to(last_player)>100*100:return Vector2.ZERO
	var offset:=Vector2.ZERO;var weight:=0.0
	for index in near_ids(point,48):
		if not active.has(index):continue
		var node:Dictionary=crowns[index]
		var w:=maxf(0,1-node.base.distance_to(point)/48)
		offset+=node.offset*w;weight+=w
	return offset/maxf(1,weight)*.65

var removed_cells:Dictionary={}
func remove_cell(cell:Vector2i)->void:
	if removed_cells.has(cell):return
	removed_cells[cell]=true
	grid[cell.y]=grid[cell.y].substr(0,cell.x)+"."+grid[cell.y].substr(cell.x+1)
	for index in near_ids((Vector2(cell)+Vector2(.5,.5))*TILE,52):
		if Vector2i(crowns[index].base/TILE)==cell:crowns[index].hidden=true;active.erase(index)
	if body_texture!=null:
		var image:=body_texture.get_image()
		for y in range(cell.y*24,mini(image.get_height(),cell.y*24+31)):
			if y>=(cell.y+1)*24 and wall(cell+Vector2i.DOWN):continue
			for x in range(cell.x*24,mini(image.get_width(),(cell.x+1)*24)):image.set_pixel(x,y,Color.TRANSPARENT)
		body_texture.update(image)

func prepare_draw(indices:PackedInt32Array,player:Vector2)->void:
	front_crowns.clear();draw_poses.clear()
	# Preserve painter order across the hero split: a later overlapping crown follows
	# an earlier foreground crown into the same pass. No leaf can jump above its neighbour.
	var foreground_bins:Dictionary={}
	for index in indices:
		var pose:=crown_pose(index,player);draw_poses[index]=pose
		var centre:=Vector2(pose.x,pose.y);var bin:=Vector2i((centre/48).floor())
		var front:=not crown_behind_hero(index,player)
		if not front:
			for y in range(bin.y-1,bin.y+2):
				for x in range(bin.x-1,bin.x+2):
					for other in foreground_bins.get(Vector2i(x,y),[]):
						var earlier:Vector3=draw_poses[other]
						if centre.distance_squared_to(Vector2(earlier.x,earlier.y))<pow(pose.z+earlier.z,2):front=true;break
		if front:
			front_crowns[index]=true
			if not foreground_bins.has(bin):foreground_bins[bin]=[]
			foreground_bins[bin].append(index)
