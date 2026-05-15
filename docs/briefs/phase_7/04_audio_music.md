# Brief 04 — Audio: Music tracks + crossfade

**Suggested agent**: ChatGPT 5.2 via Copilot for the implementation.

Read first:
1. `scripts/autoloads/audio_manager.gd` (post brief 03).
2. Where `run_started` / `run_loaded` fire (to know what triggers a track change).

## Goal
Implement `AudioManager.play_music()` and `stop_music()`. Crossfade between tracks on kingdom change. Three music tracks — one per kingdom — looping in the background during gameplay.

## Outputs (modify + create)
- `scripts/autoloads/audio_manager.gd` — add music subsystem.
- `assets/audio/music/*.ogg` — three loopable tracks.
- Subscribe AudioManager to `run_started` and `run_loaded` to swap tracks automatically.

## AudioManager music implementation

```gdscript
const MUSIC_BY_KINGDOM := {
    &"plantae":   "res://assets/audio/music/plantae_loop.ogg",
    &"fungi":     "res://assets/audio/music/fungi_loop.ogg",
    &"symbiosis": "res://assets/audio/music/symbiosis_loop.ogg",
}

var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _active_player: AudioStreamPlayer
var _current_track_path: String = ""


func _ready() -> void:
    # ... existing sfx setup ...
    _music_a = _make_music_player()
    _music_b = _make_music_player()
    _active_player = _music_a
    EventBus.run_started.connect(_on_run_changed)
    EventBus.run_loaded.connect(_on_run_loaded_for_music)


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
    tween.chain().tween_callback(func(): outgoing.stop())


func stop_music(fade_seconds: float = 1.0) -> void:
    _current_track_path = ""
    var tween := create_tween()
    tween.tween_property(_active_player, "volume_db", -80.0, fade_seconds)
    tween.tween_callback(func(): _active_player.stop())
```

## Sourcing music
Three loopable ambient tracks, ~30–60s each, that feel different per kingdom:
- **Plantae**: warm, organic, maybe a soft strings or wooden flute loop.
- **Fungi**: darker, more mineral, low pads or muted percussion.
- **Symbiosis**: blends the two — combine the harmonic palette with cross-rhythms.

Recommended free sources:
- **incompetech.com** — Kevin MacLeod, CC-BY. Good for "ambient" or "drone".
- **freemusicarchive.org** — filter by CC license + genre.
- **OpenGameArt.org** — search "ambient loop" or "fantasy ambient".

Critical: ensure tracks **loop seamlessly**. Test in Godot: stream.loop must be true, and the end of the file should match the beginning (or have a fade).

## Acceptance criteria
- [ ] Three .ogg files at the spec'd paths.
- [ ] Starting a plantae run plays plantae_loop.ogg. Track loops without a gap.
- [ ] Prestiging into fungi crossfades from plantae to fungi music over ~1s.
- [ ] Symbiosis run plays symbiosis_loop.ogg.
- [ ] Returning to main menu (or `_reset_run_state`) fades music out.
- [ ] No errors in logcat about loop or stream issues.

## Out of scope
- Music ducking during SFX. Phase 8 if ever.
- Dynamic music layers (e.g. tense layer during herbivore wave). Phase 8.
- Adaptive volume per resource scale. Skip.
