# Brief 00 — Phase 3 entry checklist

**Suggested agent**: do this yourself. No code generation needed.

## Goal
Confirm Phase 2 baseline is stable before adding Phase 3 systems on top.

## Pre-flight checks
- [ ] Brief 08 from Phase 2 (manual smoke test) passed end-to-end on Android.
- [ ] Save file is at `save_version: 2` (`adb pull` and inspect the JSON).
- [ ] Resources climb steadily with owned tiles; HUD pulses; offline catch-up works after 30s+ background.
- [ ] No unhandled errors in `adb logcat | grep -i godot` during normal play.

## Contracts that landed during the Phase 3 doc update
These are already in `scripts/autoloads/event_bus.gd` and `scripts/autoloads/game_state.gd`. No code changes needed from you — the briefs below depend on them existing.

- `EventBus.input_mode_changed(mode: StringName)`
- `EventBus.ability_used(ability_id: StringName, payload: Dictionary)`
- `GameState.input_mode: StringName` (default `&"colonize"`)
- `GameState.INPUT_MODE_COLONIZE` constant.

Also new in `docs/ARCHITECTURE.md`:
- `AbilitySystem` and `HerbivoreManager` system definitions.
- `run.organisms` and `run.active_events` per-entry shapes.

## Out of scope
- Refactoring Phase 2 code unless something is actually broken.
- Performance optimization. Phase 7.
