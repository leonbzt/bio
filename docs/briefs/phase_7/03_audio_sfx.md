# Brief 03 — Audio: SFX system + initial sound effects

**Suggested agent**: ChatGPT 5.2 via Copilot for the wiring. Sourcing the actual .wav/.ogg files is on you (see "Sourcing audio" below).

Read first:
1. `scripts/autoloads/audio_manager.gd` — currently stubs.
2. `docs/ARCHITECTURE.md` § 3 (`AudioManager` contract).

## Goal
Implement `AudioManager.play_sfx()` and wire 6 key gameplay events to SFX. The system should pool AudioStreamPlayer nodes to handle overlapping sounds without stuttering.

## Outputs (modify + create)
- `scripts/autoloads/audio_manager.gd` — implement.
- `assets/audio/sfx/*.ogg` — six audio files (see list below).
- Modifications to call sites in colonization, ability, herbivore, event handlers.

## AudioManager implementation

```gdscript
extends Node

const POOL_SIZE: int = 8
const SFX_PATHS := {
    &"tile_colonize_plant": "res://assets/audio/sfx/tile_colonize_plant.ogg",
    &"tile_colonize_fungi": "res://assets/audio/sfx/tile_colonize_fungi.ogg",
    &"tile_lost":           "res://assets/audio/sfx/tile_lost.ogg",
    &"toxin_bloom":         "res://assets/audio/sfx/toxin_bloom.ogg",
    &"event_started":       "res://assets/audio/sfx/event_started.ogg",
    &"prestige":            "res://assets/audio/sfx/prestige.ogg",
}

var _streams: Dictionary[StringName, AudioStream] = {}
var _pool: Array[AudioStreamPlayer] = []
var _next_player: int = 0


func _ready() -> void:
    for sfx_id in SFX_PATHS.keys():
        var stream := load(SFX_PATHS[sfx_id]) as AudioStream
        if stream == null:
            push_warning("AudioManager: missing %s" % SFX_PATHS[sfx_id])
            continue
        _streams[sfx_id] = stream
    for _i in range(POOL_SIZE):
        var p := AudioStreamPlayer.new()
        p.bus = "Master"
        add_child(p)
        _pool.append(p)


func play_sfx(sfx_id: StringName) -> void:
    if not _streams.has(sfx_id):
        return
    var p := _pool[_next_player]
    _next_player = (_next_player + 1) % POOL_SIZE
    p.stream = _streams[sfx_id]
    p.play()
```

The round-robin pool prevents one sound from cutting another off mid-tap; eight slots is plenty for this game.

## Wire SFX into gameplay

| Event | SFX id | Where to call |
|---|---|---|
| Plant surface colonization | `tile_colonize_plant` | `plant_colonization.gd` after `_territory.add_surface(...)` succeeds |
| Fungi subsurface colonization | `tile_colonize_fungi` | `fungi_colonization.gd` after `_territory.add_subsurface(...)` succeeds |
| Tile lost (herbivore eats) | `tile_lost` | `territory_system.gd` in `remove_surface` after emitting `tile_lost` |
| Toxin Bloom fires | `toxin_bloom` | `ability_system.gd` after emitting `ability_used` |
| Event toast appears | `event_started` | `hud.gd` `_on_event_started` (after the toast becomes visible) |
| Prestige confirmed | `prestige` | `prestige_system.gd` after emitting `prestige_triggered` |

One-liner per site: `AudioManager.play_sfx(&"tile_colonize_plant")`.

## Sourcing audio
You need 6 short (≤2s) sound effects. Options:
- **freesound.org** — search "blip", "thump", "swarm", "pop", "magic chime", "level up". Filter by CC0 / CC-BY license. Convert to .ogg with `ffmpeg -i input.wav output.ogg` if needed.
- **sfxr / bfxr** (web tool: jfxr.frozenfractal.com) — generate retro 8-bit blips. Free, perfect for the project's vibe.
- **Placeholders OK for now**: any short .ogg files in those slots. Brief 04 covers music; final polish is iterative.

Naming must match the path in `SFX_PATHS` exactly.

## Acceptance criteria
- [ ] Six .ogg files exist at the spec'd paths and import cleanly.
- [ ] Each event triggers its mapped SFX without delay.
- [ ] Spam-tapping during colonization doesn't cut off the previous tile's sound (pool works).
- [ ] No errors in `logcat` about missing audio buses or streams.
- [ ] Toggling the device's media volume to 0 silences the game (no separate mute).

## Out of scope
- Volume sliders / mute button. Phase 7 future-polish if there's time.
- Per-kingdom different colonize sounds beyond plant/fungi. Two is fine.
- Audio for events that don't toast (e.g. spore infection's silent spread). Skip.
