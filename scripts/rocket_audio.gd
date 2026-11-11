extends RefCounted
## Launch and impact have their own voices. Flight ducks immediately at each event.
var game: Node2D
var launch_voices: Array[AudioStreamPlayer] = []
var impact_voices: Array[AudioStreamPlayer] = []
var launch_cursor := 0
var impact_cursor := 0
var duck_left := 0.0

func _init(owner_game: Node2D) -> void:
    game = owner_game

func setup() -> void:
    for name in ["rpg_launch", "rpg_explosion"]:
        for index in range(4):
            var voice := AudioStreamPlayer.new()
            voice.stream = preload("res://scripts/audio_bank.gd").STREAMS[name]
            if OS.has_feature("web"):
                voice.playback_type = AudioServer.PLAYBACK_TYPE_SAMPLE
            game.add_child(voice)
            if name=="rpg_launch":
                launch_voices.append(voice)
            else:
                impact_voices.append(voice)

func event(name: String, position: Vector2) -> void:
    var distance: float = game.player.distance_to(position)
    if distance>1400:
        return
    duck_left = maxf(duck_left, 1.2 if name=="rpg_explosion" else .35)
    game.rocket_voice.volume_db = minf(game.rocket_voice.volume_db, -58)
    if name=="rpg_explosion":
        game.rocket_voice.stop()
        # The launch reference contains a short flight tail; do not let it survive impact.
        for launch in launch_voices:
            launch.stop()
    if not game.sound_on or DisplayServer.get_name()=="headless":
        return
    var voices := impact_voices if name=="rpg_explosion" else launch_voices
    var index := impact_cursor if name=="rpg_explosion" else launch_cursor
    var voice: AudioStreamPlayer = voices[index % voices.size()]
    for candidate in voices:
        if not candidate.playing:
            voice = candidate
            break
    if name=="rpg_explosion":
        impact_cursor += 1
    else:
        launch_cursor += 1
    voice.volume_db = (-2.0 if name=="rpg_explosion" else -6.0) - linear_to_db(1.0 + distance/(650.0 if name=="rpg_explosion" else 180.0))
    voice.pitch_scale = 1.0
    voice.play()

func update(delta: float) -> void:
    duck_left = maxf(0, duck_left-delta)
    var distance := INF
    for shot in game.shots:
        if shot.kind in ["rpg", "enemy_rocket"] and float(shot.get("age", 0))>.14:
            distance = minf(distance, game.player.distance_to(shot.pos))
    if not game.sound_on or not game.playing or game.paused or distance>=1400:
        game.rocket_voice.stop()
        return
    var target := -12.0 - 20*log(1+distance/420)/log(10.0)
    if duck_left>0:
        target -= 26
    game.rocket_voice.volume_db = lerpf(game.rocket_voice.volume_db, target, minf(1, delta*12))
    if not game.rocket_voice.playing:
        game.rocket_voice.play()
