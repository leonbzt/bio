# Brief 06 — Era transition narrative passage UI

**Suggested agent**: ChatGPT 5.2. Route diff to Claude — narrative-flow + skippable interaction.

Read first:
1. `docs/briefs/phase_12/04_era_system_autoload.md` — `EventBus.era_transition_started(from_era, to_era)` is the trigger.
2. `docs/STORY_AND_TONE.md` § "Era transitions" — the voice + skip behavior.
3. `data/eras/devonian.tres` — its `transition_narrative` is the first passage shown.

## Goal
When `era_transition_started` fires, display a full-screen black overlay with the destination era's `transition_narrative` text fading in slowly. Kingdom-themed music swells (optional — defer if audio system not ready). Player can skip by tapping after a 2-second guard window (so skips are conscious, not accidental).

This is the highest-narrative-weight UI in the game. Treat it accordingly.

## Scene: `scenes/ui/era_transition.tscn`

```
EraTransition (Control, fills parent, z-index high)
├── Backdrop (ColorRect, anchored full, Color(0,0,0,1.0), MOUSE_FILTER_STOP)
├── NarrativeContainer (CenterContainer, anchored full)
│   └── NarrativeLabel (Label, ~280px wide, autowrap, centered)
└── HintLabel (Label, anchored bottom, "Tap to continue", greyed, hidden initially)
```

Theme override: larger font (16) for narrative label; smaller (10) faded for hint.

## Script: `scripts/ui/era_transition.gd`

```gdscript
extends Control

const FADE_IN_TIME: float = 1.5
const GUARD_WINDOW: float = 2.0
const HINT_FADE_IN_TIME: float = 0.8

@onready var _backdrop: ColorRect = $Backdrop
@onready var _narrative_label: Label = $NarrativeContainer/NarrativeLabel
@onready var _hint_label: Label = $HintLabel

var _can_dismiss: bool = false
var _narrative_text: String = ""


func setup(narrative: String) -> void:
    _narrative_text = narrative


func _ready() -> void:
    z_index = 100
    _narrative_label.text = _narrative_text
    _narrative_label.modulate.a = 0.0
    _hint_label.modulate.a = 0.0
    var tween := create_tween()
    tween.tween_property(_narrative_label, "modulate:a", 1.0, FADE_IN_TIME)
    tween.tween_interval(GUARD_WINDOW)
    tween.tween_callback(_enable_dismiss)
    tween.parallel().tween_property(_hint_label, "modulate:a", 0.8, HINT_FADE_IN_TIME)
    gui_input.connect(_on_input)
    # Pause the game during the passage.
    TickClock.pause()


func _enable_dismiss() -> void:
    _can_dismiss = true


func _on_input(event: InputEvent) -> void:
    if not _can_dismiss:
        return
    if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
        _dismiss()
    elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
        _dismiss()


func _dismiss() -> void:
    TickClock.resume()
    var tween := create_tween()
    tween.tween_property(self, "modulate:a", 0.0, 0.4)
    tween.tween_callback(func() -> void: queue_free())
```

## Trigger wiring

Add a listener somewhere (HUDLayer or a new `NarrativeRouter` autoload — simplest is in HUD root):

In `scripts/ui/hud.gd` `_ready`:
```gdscript
EventBus.era_transition_started.connect(_on_era_transition_started)


func _on_era_transition_started(_from_era: StringName, to_era: StringName) -> void:
    var era := EraSystem.get_era(to_era)
    if era == null or era.transition_narrative == "":
        return
    var scene := preload("res://scenes/ui/era_transition.tscn")
    var transition := scene.instantiate()
    transition.setup(era.transition_narrative)
    get_parent().add_child(transition)
```

The transition scene takes itself off-screen on dismiss.

## Music swell (optional)

If `AudioManager` has a `play_music(track_id, fade_in)` method (it should — Phase 7 added per-kingdom music), call it with a track keyed off the destination era:

```gdscript
if AudioManager.has_method("play_music"):
    AudioManager.play_music(StringName("era_%s" % String(to_era)), 2.0)
```

If no era-specific tracks exist yet, skip this — Phase 13's graphics pass also handles per-era audio.

## Acceptance criteria
- [ ] After completing all 3 Cryogenian ecosystems and prestiging, the Devonian transition narrative fades in over 1.5s.
- [ ] Game is paused during display (TickClock.pause).
- [ ] Tap during the first 2 seconds: no dismiss.
- [ ] Tap after 2 seconds: passage fades out + scene frees + TickClock.resume.
- [ ] First Cryogenian load: no passage (era has empty `transition_narrative`).
- [ ] Mobile 360×640: narrative text wraps and is readable.

## Out of scope
- Custom per-era music tracks (Phase 13).
- Per-era visual backgrounds (Phase 13).
- Skippable opening cinematic on first-ever-launch (Phase 13+).
- Mass extinction passage (brief 08 — separate trigger).
