# Brief 02 — placement_target state + PrestigeSystem.start_run wiring

**Suggested agent**: ChatGPT 5.2 via Copilot.

Read first:
1. `scripts/autoloads/game_state.gd` — already has `placement_target: StringName` field (set by Phase 6 contract setup).
2. `scripts/autoloads/event_bus.gd` — already has `placement_target_changed` signal.
3. `scripts/systems/prestige_system.gd` — `start_run(kingdom_id)`.

## Goal
Initialize `GameState.placement_target` correctly when a run starts. In single-kingdom runs, lock it to that kingdom (so the colonization systems still receive it consistently). In symbiosis runs, default to `&"plantae"` and let the player toggle.

## Outputs (modify)
- `scripts/systems/prestige_system.gd` — `start_run` sets `placement_target`.

## Patch

In `prestige_system.gd::start_run(kingdom_id)`, after setting `current_kingdom_id` and before the `EventBus.run_started.emit(kingdom_id)`:

```gdscript
if kingdom_id == &"symbiosis":
    GameState.placement_target = &"plantae"   # default; player can toggle
else:
    GameState.placement_target = kingdom_id   # locked in single-kingdom runs
EventBus.placement_target_changed.emit(GameState.placement_target)
```

Also update `_reset_run_state()` to clear `placement_target = &""` (since the run is no longer active until a new `start_run`).

## Acceptance criteria
- [ ] After `start_run(&"plantae")`: `GameState.placement_target == &"plantae"`.
- [ ] After `start_run(&"fungi")`: `GameState.placement_target == &"fungi"`.
- [ ] After `start_run(&"symbiosis")`: `GameState.placement_target == &"plantae"` (default).
- [ ] `placement_target_changed` fires once per `start_run`.
- [ ] After `trigger_prestige`: `placement_target == &""`.

## Out of scope
- The actual toggle UI (brief 03).
- Colonization-system filter logic (brief 04).
