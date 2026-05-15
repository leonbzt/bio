# Brief 06 — HUD ability button + event toast

**Suggested agent**: ChatGPT 5.2 via Copilot. Visual polish (colors, spacing) → Kilo if you want.

Read first:
1. `scripts/ui/hud.gd` — current shape.
2. `scenes/ui/hud.tscn` — current node tree.
3. `scripts/systems/ability_system.gd` (brief 05).
4. `docs/ARCHITECTURE.md` § 3 — `event_started`, `event_resolved`, `input_mode_changed`, `resource_changed`.

## Goal
Two HUD additions:
1. **Toxin Bloom button** — bottom-right corner. Shows cost. Greys out when unaffordable. Highlights when in targeting mode. Calls `AbilitySystem.request_toxin_bloom()` on tap.
2. **Event toast** — top-center. Slides in on `event_started`, displays `display_name` + `description`, slides out on `event_resolved` or after a few seconds (whichever first).

## Outputs (modify)
- `scenes/ui/hud.tscn` — add ToxinBloomButton (bottom-right, anchored), EventToast (top-center, anchored, hidden by default).
- `scripts/ui/hud.gd` — wire signals.
- `scripts/data/event_data.gd` — already has `display_name` + `description`, no schema change needed.

## ToxinBloomButton

Scene node:
```
ToxinBloomButton (Button, anchored bottom-right, offset_left = -120, offset_top = -56, offset_right = -16, offset_bottom = -16)
```
Text: dynamically set in `_ready` to `"Toxin Bloom (%d %s)" % [cost, "Biomass"]` using `AbilitySystem.get_toxin_bloom_cost()`.

Behavior:
- `pressed` signal → `AbilitySystem.request_toxin_bloom()`.
- Subscribe to `EventBus.resource_changed` (or just to `BIOMASS` updates): if biomass < cost, set `disabled = true`, else `disabled = false`.
- Subscribe to `EventBus.input_mode_changed`: if mode == `&"target_toxin_bloom"`, modulate the button (e.g. `modulate = Color(1.5, 1.0, 1.0)`); else reset to `Color(1, 1, 1)`.

## EventToast

Scene node:
```
EventToast (PanelContainer, anchored top-center, anchor_left/right = 0.5, custom_minimum_size = (280, 56))
└── VBoxContainer
    ├── TitleLabel (Label, large)
    └── BodyLabel (Label, smaller)
```
Hidden by default (`visible = false`).

Behavior in `hud.gd`:
- Subscribe to `EventBus.event_started.connect(_on_event_started)`.
- Subscribe to `EventBus.event_resolved.connect(_on_event_resolved)`.
- On `event_started`: look up the EventData by id (load from `data/events/_index.tres` once and cache the dict). Set title + body text. Show. Tween modulate alpha from 0 → 1 over 0.2s.
- After 4 seconds OR on `event_resolved` for the same id: tween alpha to 0, hide. Use `create_tween()` with `tween_callback(func(): visible = false)`.
- If a second `event_started` arrives before the toast hides, replace contents (don't queue).

## Event lookup helper
Add to hud.gd or a small util:
```gdscript
const EVENT_INDEX_PATH := "res://data/events/_index.tres"
var _events_by_id: Dictionary[StringName, EventData] = {}

func _build_event_index() -> void:
    var index: EventIndex = load(EVENT_INDEX_PATH) as EventIndex
    if index == null:
        return
    for ev in index.events:
        _events_by_id[ev.id] = ev
```
Call from `_ready`.

## Acceptance criteria
- [ ] Button appears bottom-right and shows the cost.
- [ ] Button is disabled when biomass < 50.
- [ ] Tapping the button enters targeting mode (button modulates brighter); tapping again cancels.
- [ ] Tapping a tile in targeting mode spends biomass and exits targeting mode (button returns to normal).
- [ ] When EcologicalPressure fires herbivore_wave, the toast appears at top-center with title "Herbivore Wave" and description text from the .tres.
- [ ] Toast dismisses after 4s or on `event_resolved`.
- [ ] HUD's existing resource labels and tick pulse are unaffected.

## Out of scope
- Animation polish, sound. Phase 7.
- Configurable toast duration in `.tres`. Inline 4s is fine.
- Multiple simultaneous toasts. EcologicalPressure already enforces one event at a time.
