# Brief 07 — OfflineProgress

**Suggested agent**: ChatGPT 5.2 via Copilot. Route diff through Claude before merge — this touches save state and the tick path.

Read first:
1. `docs/ARCHITECTURE.md` — sections 1 (offline cap = 8h), 3 (`replay_started`, `replay_finished` signals, `TickClock.force_tick`), 5 (system map).
2. `scripts/autoloads/tick_clock.gd` — `force_tick(n)` ignores pause.
3. `scripts/autoloads/save_system.gd` — `_build_default_save` writes `saved_at_unix`.

## Goal
On `run_loaded`, compute elapsed wall-clock time since the last save, convert to ticks, cap at 8 hours, and burst-replay through `TickClock.force_tick(n)`. Bracket the burst with `replay_started` / `replay_finished` so HUD can suppress animation.

## Outputs (create)
- `scripts/systems/offline_progress.gd`
- Modification to `scenes/world/world.tscn` — add `OfflineProgress` node under `Systems`, **last** in the children order. Reason: must execute after TerritorySystem and NutrientSystem have hydrated, since the replayed ticks call into them.

## Implementation notes
- `Node`. No state beyond constants.
- `const MAX_OFFLINE_SECONDS: float = 8.0 * 60.0 * 60.0` (28800).
- `_ready()`: connect `EventBus.run_loaded.connect(_on_run_loaded)`.
- `_on_run_loaded(_v)`:
  - Read `saved_at_unix` from save. The simplest path: store the value when SaveSystem loads (add a field to `GameState`, e.g. `last_save_unix: int`). **Don't read directly from the JSON file again.** Coordinate with the SaveSystem change below.
  - `now = Time.get_unix_time_from_system()`
  - `elapsed = max(0, now - last_save_unix)`
  - `elapsed = min(elapsed, MAX_OFFLINE_SECONDS)`
  - `ticks = int(elapsed * TickClock.tick_hz)`
  - `if ticks <= 0: return`
  - `EventBus.replay_started.emit(ticks)`
  - `TickClock.force_tick(ticks)`
  - `EventBus.replay_finished.emit()`

## SaveSystem coordination
Add to `GameState`:
```gdscript
var last_save_unix: int = 0
```

In `SaveSystem.load_or_create`, after parsing the dict, set:
```gdscript
GameState.last_save_unix = int(data.get("saved_at_unix", 0))
```

For the default-save path (file not found), use:
```gdscript
GameState.last_save_unix = int(Time.get_unix_time_from_system())
```

This avoids a "first launch = 8h of free progress" bug.

## HUD coordination
In `scripts/ui/hud.gd`:
- Subscribe to `EventBus.replay_started.connect(_on_replay_started)` and `replay_finished.connect(_on_replay_finished)`.
- Add `var _is_replaying: bool = false`. Set true/false in the handlers.
- In `_on_tick`, skip the tween pulse if `_is_replaying`. Resource label updates still happen via `_on_resource_changed` (those signals fire during the burst), so the numbers will climb visibly when replay ends.

## Acceptance criteria
- [ ] First launch (no save): no replay (default `last_save_unix` set to current time).
- [ ] Background app for 30s, foreground: biomass increased by roughly `30 * 0.575 ≈ 17` (for 1 owned tile with pioneer_grass on grassland).
- [ ] Background app for 9h: biomass increased by `8 * 3600 * 0.575 = 16,560` (capped at 8h, not 9h).
- [ ] HUD does NOT pulse 28,800 times during a full-cap replay. Verified by visual check (no rapid scaling).
- [ ] `replay_started(ticks)` fires once, `replay_finished()` fires once, in order.
- [ ] No direct system imports.

## Out of scope
- "While you were away" summary modal — Phase 4 polish.
- Event scheduling during replay (events should NOT fire during catch-up). The current `EcologicalPressure` design ignores ticks during `_is_replaying`; we'll wire that in Phase 3.

## Why route this through Claude
Two reasons:
1. The tick burst can re-enter every system. Off-by-one or out-of-order errors will manifest as either lost progress or doubled progress, and both look "kinda right" to a casual visual check.
2. `last_save_unix` is now part of the cross-system contract. If it gets stomped accidentally, players lose progress.
