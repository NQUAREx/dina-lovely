extends Node
## State-machine regression test. Run with isolated XDG_DATA_HOME.
var game
var checks := 0
func check(value: bool, message: String) -> void:
	if not value:
		push_error("FAIL: " + message)
		get_tree().quit(1)
		assert(value,message)
	checks += 1
	print("PASS: ",message)
func _ready() -> void:
	call_deferred("run")
func use(id: String) -> void:
	game.clear_modal()
	for obj in game.objects:
		if obj.id==id:
			game.player=obj.pos+Vector2(0,40)
			game.find_nearest()
			check(game.nearest>=0,"interaction available: "+id)
			game.interact()
			return
	check(false,"object exists: "+id)
func run() -> void:
	game=load("res://main.tscn").instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	game.new_game()
	game.clear_modal()
	# Every corridor and objective is reachable, not just connected visually.
	var seen := {Vector2i(1,1):true}
	var queue: Array[Vector2i] = [Vector2i(1,1)]
	while not queue.is_empty():
		var p: Vector2i = queue.pop_front()
		for d in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]:
			var q: Vector2i=p+d
			if q.x>=0 and q.y>=0 and q.y<game.grid.size() and q.x<game.grid[0].length() and game.grid[q.y][q.x]=="." and not seen.has(q):
				seen[q]=true
				queue.append(q)
	for obj in game.objects:
		if not obj.id.is_empty(): check(seen.has(Vector2i(obj.pos/game.TILE)),"maze reachable: "+obj.id)
	use("exit")
	check(game.level==0,"exit locks before letters")
	for id in ["dawn","flower","star","secret_moon","secret_bench"]: use(id)
	check(game.save_data.letters.size()==5,"all maze letters and secrets collected")
	use("exit")
	check(game.level==1,"transition to battle")
	game.clear_modal()
	# Verify damage, invulnerability and retry preserving letters.
	game.invincible=0
	game.hurt()
	check(game.health==7,"damage applies")
	game.hurt()
	check(game.health==7,"damage grace period")
	game.health=1
	game.invincible=0
	game.hurt()
	check(game.paused,"death opens retry")
	game.build_level(1)
	game.clear_modal()
	check(game.health==8 and game.save_data.letters.size()==5,"retry preserves letters")
	game.touch_mode=true
	var iterations := 0
	while not game.combat_done and iterations<12000:
		game.update_combat(.05)
		if not game.enemies.is_empty():
			var enemy: Dictionary=game.enemies[0]
			game.player=enemy.pos+Vector2(0,72)
			game.attack_cd=0
			game.attack()
		iterations+=1
	check(game.combat_done and game.wave==3,"three complete combat waves")
	use("courage")
	use("exit")
	check(game.level==2,"transition to garden")
	use("0")
	check(game.watered.is_empty(),"watering requires can")
	use("can")
	for i in range(6):
		if i%3==0: use("well")
		use(str(i))
	check(game.watered.size()==6 and game.water==0,"six plants consume two cans")
	for id in game.bloom_times: game.bloom_times[id]=1.0
	use("garden")
	use("exit")
	check(game.level==3,"transition to finale")
	use("star")
	check(game.puzzle.is_empty(),"wrong puzzle sequence safely resets")
	for id in ["sun","flower","star"]: use(id)
	check(game.puzzle==["sun","flower","star"],"puzzle solved")
	use("final")
	check(game.save_data.finished,"final chest persists completion")
	await get_tree().create_timer(2.4).timeout
	check(game.paused and is_instance_valid(game.modal),"card opens")
	game.show_journal()
	game.load_save()
	check(game.save_data.finished and game.save_data.letters.size()==7 and game.save_data.watered.size()==6,"save round trip preserves all progress")
	game.build_level(2)
	check(game.garden_can and game.watered.size()==6,"garden restores")
	game.build_level(1)
	check(game.combat_done,"completed battle restores")
	game.show_card()
	JavaScriptBridge.eval("window.qaResult = " + JSON.stringify({"passed":checks,"finished":game.save_data.finished,"letters":game.save_data.letters.size()}))
