extends RefCounted
## Reveals the garden's usual baked grass stamps as the piles are cleared.
const CHUNK := 64
const PAINT_INTERVAL := .075
const GROWTH_TIME := .58

var texture:ImageTexture
var base:Image
var canvas:Image
var chunks:Dictionary={}
var plots:Dictionary={}
var active:Dictionary={}
var finished:=0
var clock:=0.0

func prepare(ground:Image,stamps:Array[Dictionary],piles:Array,cleared:Array)->ImageTexture:
	base=ground
	canvas=ground.duplicate()
	chunks.clear();plots.clear();active.clear();finished=0;clock=0
	var dry_art:Dictionary={}
	var used_bounds:Dictionary={}
	var canvas_bounds:=Rect2i(Vector2i.ZERO,canvas.get_size())
	for pile in piles:plots[pile.id]={"pos":pile.pos/2,"stamps":[],"reach":0.0}
	var plot_list:=plots.values()
	var centers:=PackedVector2Array()
	for plot in plot_list:centers.append(plot.pos)
	for stamp in stamps:
		var nearest:=INF
		var owner_index:=-1
		var root:=Vector2(stamp.root)
		for index in range(centers.size()):
			var distance:=centers[index].distance_squared_to(root)
			if distance<nearest:
				nearest=distance
				owner_index=index
		if owner_index<0:continue
		var owner:Dictionary=plot_list[owner_index]
		stamp.distance=sqrt(nearest)
		owner.reach=maxf(owner.reach,stamp.distance)
		owner.stamps.append(stamp)
		stamp.visible_rows=0
		stamp.dry=null
		var source:Image=stamp.art
		if not used_bounds.has(source):used_bounds[source]=source.get_used_rect()
		var source_bounds:Rect2i=used_bounds[source]
		stamp.bounds=Rect2i(stamp.pos+source_bounds.position,source_bounds.size)
		stamp.source=source_bounds.position
		stamp.chunks=[]
		var rect:Rect2i=stamp.bounds.intersection(canvas_bounds)
		if rect.has_area():
			var first:=rect.position/CHUNK
			var last:=(rect.end-Vector2i.ONE)/CHUNK
			for y in range(first.y,last.y+1):
				for x in range(first.x,last.x+1):
					var cell:=Vector2i(x,y)
					if not chunks.has(cell):chunks[cell]=[]
					chunks[cell].append(stamp)
					stamp.chunks.append(cell)
	for id in plots:
		var plot:Dictionary=plots[id]
		var restored:bool=id in cleared
		if restored:finished+=1
		for stamp in plot.stamps:
			stamp.delay=1.8*stamp.distance/maxf(plot.reach,90)
			if restored:
				stamp.visible_rows=stamp.bounds.size.y
			elif stamp.blades:
				var source:Image=stamp.art
				if not dry_art.has(source):dry_art[source]=dry_blades(source)
				stamp.dry=dry_art[source]
	for cell in chunks:paint_chunk(cell)
	texture=ImageTexture.create_from_image(canvas)
	return texture

func dry_blades(source:Image)->Image:
	var art:Image=source.duplicate()
	var shadow:=Color("746046")
	var light:=Color("c2a56a")
	for y in range(art.get_height()):
		for x in range(art.get_width()):
			var pixel:=art.get_pixel(x,y)
			if pixel.a<=0:continue
			var warmth:=clampf((pixel.g-.28)*5,0,1)
			var color:=shadow.lerp(light,warmth)
			color.a=pixel.a
			art.set_pixel(x,y,color)
	return art

func begin_growth(id:String)->void:
	if plots.has(id) and not active.has(id):active[id]=0.0

func complete()->bool:
	return not plots.is_empty() and finished==plots.size()

func update(delta:float)->void:
	if active.is_empty():return
	clock+=delta
	if clock<PAINT_INTERVAL:return
	var elapsed:=clock
	clock=0.0
	var dirty:Dictionary={}
	for id in active.keys():
		active[id]+=elapsed
		var age:float=active[id]
		var done:=true
		for stamp in plots[id].stamps:
			var height:int=stamp.bounds.size.y
			if stamp.visible_rows==height:continue
			var progress:=smoothstep(0,GROWTH_TIME,age-float(stamp.delay))
			var rows:=roundi(height*progress)
			if rows<height:done=false
			if rows==stamp.visible_rows:continue
			stamp.visible_rows=rows
			stamp.dry=null
			for cell in stamp.chunks:dirty[cell]=true
		if done:active.erase(id);finished+=1
	for cell in dirty:paint_chunk(cell)
	if not dirty.is_empty():texture.update(canvas)

func paint_chunk(cell:Vector2i)->void:
	var chunk:=Rect2i(cell*CHUNK,Vector2i(CHUNK,CHUNK)).intersection(Rect2i(Vector2i.ZERO,canvas.get_size()))
	canvas.blit_rect(base,chunk,chunk.position)
	for stamp in chunks[cell]:
		var art:Image=stamp.dry if stamp.visible_rows==0 else stamp.art
		if art==null:continue
		var revealed:Rect2i=stamp.bounds
		if stamp.visible_rows>0:
			revealed.position.y=revealed.end.y-stamp.visible_rows
			revealed.size.y=stamp.visible_rows
		var part:=revealed.intersection(chunk)
		if part.has_area():
			var from:=Rect2i(part.position-stamp.bounds.position+stamp.source,part.size)
			canvas.blend_rect(art,from,part.position)
