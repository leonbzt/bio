# Brief 03 — Layer toggle HUD button

**Suggested agent**: ChatGPT 5.2 via Copilot.

Read first:
1. `scenes/ui/hud.tscn` — current layout (Menu button top-left, ToxinBloom bottom-right).
2. `scripts/ui/hud.gd` — current subscriptions and reactive update pattern.
3. `scripts/autoloads/game_state.gd` — `placement_target`, `current_kingdom_id`.

## Goal
A new button on the HUD that appears **only in symbiosis runs**. Tapping it swaps `GameState.placement_target` between `&"plantae"` and `&"fungi"`. The button's label and color reflect the current target.

## Outputs (modify)
- `scenes/ui/hud.tscn` — add `LayerToggle` button.
- `scripts/ui/hud.gd` — wiring.

## Layout

```
LayerToggle (Button, anchored bottom-left, offset_left=8, offset_top=-56, offset_right=120, offset_bottom=-16)
  text = "Layer: Plant"   (or "Layer: Fungi")
  visible = false           (default; shown only in symbiosis runs)
```

Position is bottom-left, balancing the bottom-right ToxinBloom button.

## Behavior

### `hud.gd` additions

```gdscript
@onready var _layer_toggle: Button = $LayerToggle


func _ready() -> void:
    # ... existing _ready content ...
    _layer_toggle.pressed.connect(_on_layer_toggle_pressed)
    EventBus.placement_target_changed.connect(_on_placement_target_changed)
    EventBus.run_started.connect(_on_run_started)
    EventBus.run_loaded.connect(_on_run_loaded_for_layer)
    _refresh_layer_toggle_visibility()
    _refresh_layer_toggle_label()


func _on_run_started(_kingdom_id: StringName) -> void:
    _refresh_layer_toggle_visibility()
    _refresh_layer_toggle_label()


func _on_run_loaded_for_layer(_save_version: int) -> void:
    _refresh_layer_toggle_visibility()
    _refresh_layer_toggle_label()


func _refresh_layer_toggle_visibility() -> void:
    _layer_toggle.visible = (GameState.current_kingdom_id == &"symbiosis")


func _on_layer_toggle_pressed() -> void:
    if GameState.current_kingdom_id != &"symbiosis":
        return
    var next: StringName = &"fungi" if GameState.placement_target == &"plantae" else &"plantae"
    GameState.placement_target = next
    EventBus.placement_target_changed.emit(next)


func _on_placement_target_changed(_target: StringName) -> void:
    _refresh_layer_toggle_label()


func _refresh_layer_toggle_label() -> void:
    if GameState.placement_target == &"fungi":
        _layer_toggle.text = "Layer: Fungi"
        _layer_toggle.modulate = Color(0.78, 0.55, 0.85)    # violet hint
    else:
        _layer_toggle.text = "Layer: Plant"
        _layer_toggle.modulate = Color(0.55, 0.85, 0.55)    # green hint
```

## Acceptance criteria
- [ ] Plantae run: LayerToggle button is hidden.
- [ ] Fungi run: LayerToggle button is hidden.
- [ ] Symbiosis run: LayerToggle button visible; label and modulate match current `placement_target`.
- [ ] Tapping the button flips `placement_target` and updates the label / modulate.
- [ ] `placement_target_changed` fires once per tap.
- [ ] After kill-and-relaunch mid-symbiosis-run: button state matches the loaded `placement_target` (which must persist — see brief 02 + the load path).

## Note on `placement_target` persistence
`placement_target` is not currently persisted in `run_save`. If you want it to survive kill-and-relaunch, add it to the save dict — but that's an additional contract change. For Phase 6 MVP it's acceptable to reset to `&"plantae"` on every load in symbiosis runs; the player just taps the toggle again if needed.

If you want persistence: SaveSystem `_build_default_save()` adds `"placement_target": ""` to run, brief 02 hydrates it on `run_loaded`. Either approach is fine; pick one and document it inline.

## Out of scope
- A radial menu / multi-layer toggle. The two-state button is enough.
- Animation polish. Phase 7.
