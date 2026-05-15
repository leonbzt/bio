extends Node
##
## AudioManager — central audio routing.
##

const MUSIC_BY_KINGDOM := {
	&"plantae": "res://assets/audio/music/plantae_loop.ogg",
	&"fungi": "res://assets/audio/music/fungi_loop.ogg",
	&"symbiosis": "res://assets/audio/music/symbiosis_loop.ogg"
}

var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _active_player: AudioStreamPlayer
var _current_track_path: String = ""


func _ready() -> void:
	_music_a = _make_music_player()
	_music_b = _make_music_player()
	_active_player = _music_a
	EventBus.run_started.connect(_on_run_changed)
	EventBus.run_loaded.connect(_on_run_loaded_for_music)


func play_sfx(_sfx_id: StringName) -> void:
	# TODO Phase 7: SFX system is handled in a separate brief.
	pass


func play_music(_track_id: StringName, _fade_in: float = 0.5) -> void:
	var path: String = ""
	if MUSIC_BY_KINGDOM.has(_track_id):
		path = MUSIC_BY_KINGDOM[_track_id]
	elif String(_track_id).begins_with("res://"):
		path = String(_track_id)
	if path == "":
		return
	play_music_path(path, _fade_in)


func stop_music(fade_out: float = 0.5) -> void:
	_current_track_path = ""
	var tween := create_tween()
	tween.tween_property(_active_player, "volume_db", -80.0, fade_out)
	tween.tween_callback(func() -> void:
		_active_player.stop()
	)


func _make_music_player() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = "Master"
	p.volume_db = -80.0
	add_child(p)
	return p


func _on_run_changed(kingdom_id: StringName) -> void:
	var path: String = MUSIC_BY_KINGDOM.get(kingdom_id, "")
	if path == "":
		stop_music()
		return
	play_music_path(path)


func _on_run_loaded_for_music(_v: int) -> void:
	_on_run_changed(GameState.current_kingdom_id)


func play_music_path(path: String, fade_seconds: float = 1.0) -> void:
	if path == _current_track_path:
		return
	_current_track_path = path

	var stream := load(path) as AudioStream
	if stream == null:
		push_warning("AudioManager: missing music %s" % path)
		return
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true

	var incoming: AudioStreamPlayer = _music_b if _active_player == _music_a else _music_a
	incoming.stream = stream
	incoming.volume_db = -80.0
	incoming.play()

	var outgoing: AudioStreamPlayer = _active_player
	_active_player = incoming

	var tween := create_tween().set_parallel(true)
	tween.tween_property(incoming, "volume_db", 0.0, fade_seconds)
	tween.tween_property(outgoing, "volume_db", -80.0, fade_seconds)
	tween.chain().tween_callback(func() -> void:
		outgoing.stop()
	)
