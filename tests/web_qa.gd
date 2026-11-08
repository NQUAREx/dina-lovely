extends Node
var game
func _ready(): call_deferred("run")
func check(ok: bool, text: String):
	assert(ok,text)
	print("PASS ",text)
func run():
	game=load("res://main.tscn").instantiate();get_tree().root.add_child(game)
	await get_tree().process_frame
	game.new_game();game.clear_modal()
	check(game.player.y>game.grid.size()*48*.6,"maze begins in south")
	game.save_data.letters=["dawn","flower","star"]
	game.next_level()
	await get_tree().create_timer(2.6).timeout
	check(game.level==1 and not game.transition,"north corridor enters battle")
	game.travel(0)
	await get_tree().create_timer(2.6).timeout
	check(game.level==0 and not game.blocked(game.player),"back corridor arrives on walkable tile")
	game.build_level(5)
	game.garden_can=true;game.water=6;game.fertilized=["0"]
	game.plants["0"]={"stage":0,"remaining":-1.0}
	game.begin_task("water:0",Vector2.ZERO,2.2)
	game.update_tasks(2.3)
	check(game.water==5 and game.plants["0"].remaining==12.0,"watering finishes after animation")
	for stage in range(3):
		if stage>0:
			game.plants["0"].remaining=-1.0
			game.begin_task("water:0",Vector2.ZERO,2.2);game.update_tasks(2.3)
		game.update_plants(30)
		check(game.plants["0"].stage==stage+1,"growth stage "+str(stage+1))
	check("0" in game.watered,"third stage completes flower")
	game.persist();game.build_level(5)
	check(game.plants["0"].stage==3,"plant state survives rebuild")
	game.build_level(4);game.clear_modal();game.touch_mode=true
	for weapon in ["sword","rifle","rpg"]:
		game.enemies.clear()
		game.enemies.append({"pos":game.player+Vector2(0,-60),"hp":3,"state":"chase","type":0,"timer":0.0,"cooldown":0.0})
		game.weapon=weapon;game.attack_cd=0;game.attack()
		if weapon=="sword":check(game.enemies[0].hp==1,"sword deals melee damage")
		else:
			check(not game.shots.is_empty(),weapon+" spawns projectile")
			for i in range(10):game.update_shots(.03)
			check(game.enemies.is_empty() if weapon=="rpg" else game.enemies[0].hp<3,weapon+" projectile hits")
	game.save_data.letters=["dawn","flower","star","courage","garden","secret_moon","secret_bench"]
	game.show_journal()
	await get_tree().process_frame
	await get_tree().process_frame
	var sc=game.modal.find_children("*","ScrollContainer",true,false)[0]
	var point: Vector2=sc.global_position+Vector2(100,180)
	var press:=InputEventScreenTouch.new();press.index=7;press.pressed=true;press.position=point;game._input(press)
	var drag:=InputEventScreenDrag.new();drag.index=7;drag.position=point-Vector2(0,120);drag.relative=Vector2(0,-120);game._input(drag)
	check(sc.scroll_vertical>0,"touch drag scrolls journal")
	var release:=InputEventScreenTouch.new();release.index=7;release.pressed=false;release.position=drag.position;game._input(release)
	print("UPGRADE CHECKS COMPLETE")
	JavaScriptBridge.eval('window.qaResult = {"passed":15,"scope":"upgrade"}')
