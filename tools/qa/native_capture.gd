extends SceneTree
var game
func _initialize():call_deferred('run')
func shot(path:String):
 await create_timer(.4).timeout
 await RenderingServer.frame_post_draw
 var err=root.get_texture().get_image().save_png(path)
 print('SCREENSHOT ',path,' ',err)
func run():
 game=load('res://main.tscn').instantiate();root.add_child(game)
 await shot('/tmp/bloom-native-menu.png')
 game.new_game();await shot('/tmp/bloom-native-intro.png')
 game.clear_modal();await shot('/tmp/bloom-native-world.png')
 game.build_level(4);game.player=Vector2(650,850);game.camera=game.player
 game.save_data.weapon_crates_opened=['sword','rifle','rpg']
 await shot('/tmp/bloom-native-arena.png')
 quit()
