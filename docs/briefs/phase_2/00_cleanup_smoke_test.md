# Brief 00 — Cleanup Phase 1 smoke test

**Suggested agent**: do this yourself in the editor. No model needed.

## Goal
Remove the Phase 1 smoke scaffolding so Phase 2 work starts on a clean baseline.

## Files to delete
- `data/traits/test_photosynthesis.tres`
- `scripts/systems/_smoke_growth.gd`

## Reset the save file
The smoke test persisted accumulated biomass into `user://save.json` via ResourceLedger's write-through to `GameState.run_save.resources`. After removing the source, that biomass would otherwise stay frozen on every launch. Reset before continuing:

- Easiest: launch the app, on main menu tap **Reset Save** → confirm.
- Equivalent: delete `user://save.json` manually (`adb shell rm /sdcard/Android/data/<package>/files/save.json`).

## Files to modify

### `scenes/world/world.tscn`
Remove the `SmokeGrowth` node under `Systems`. The `Systems` node itself stays — it'll host the real Phase 2 systems.

Also delete the dangling `[ext_resource ... _smoke_growth.gd ...]` line at the top of `world.tscn`. Godot will flag it as a missing dependency when you open the scene; accept its cleanup offer or remove the line by hand.

### `scenes/ui/hud.tscn`
Remove the `SmokeLabel` node under `Bar/Margin/ResourcesRow`.

### `scripts/ui/hud.gd`
- Remove `_smoke_label` `@onready` reference.
- Remove `_smoke_tick_count`.
- Remove `_smoke_label.text = "SMOKE: 0"` from `_ready()`.
- Remove the SMOKE text-update lines from `_on_tick()` (keep the tick-indicator pulse — that's permanent).
- Replace the scale-based pulse with a modulate alpha fade. Reason: `TickIndicator` is a `ColorRect` inside an `HBoxContainer`, and Control scale with default pivot is invisible inside containers. Modulate is layout-agnostic:
  ```gdscript
  func _on_tick(_delta_seconds: float) -> void:
      var tween := create_tween()
      _tick_indicator.modulate.a = 1.0
      tween.tween_property(_tick_indicator, "modulate:a", 0.3, 0.1)
      tween.tween_property(_tick_indicator, "modulate:a", 1.0, 0.1)
  ```

## Acceptance criteria
- [ ] Game still launches; HUD shows all five resources at 0.
- [ ] Tick indicator still pulses once per second (proves the tick path survives).
- [ ] Biomass no longer climbs by 1/sec (no source online yet).
- [ ] No references to "smoke", `_smoke_growth`, or `test_photosynthesis` remain anywhere in the repo. Verify with `grep -ri smoke .` in the project root.

## Why this matters
Phase 2 builds on the contract surface, not on the smoke. Leaving it in creates phantom biomass that masks bugs in `GrowthSystem` (brief 05).
