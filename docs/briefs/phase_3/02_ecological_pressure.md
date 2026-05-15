# Brief 02 — EcologicalPressure scheduler

**Suggested agent**: ChatGPT 5.2 via Copilot.

Read first:
1. `docs/ARCHITECTURE.md` § 3 (signals: `event_started`, `event_resolved`), § 5 (system map), § 7a (world-scope hydration pattern).
2. `data/events/_index.tres` (created in brief 01).
3. `scripts/systems/territory_system.gd` for `get_owned_coords()`.

## Goal
A system that:
1. Watches the world over time.
2. Decides when to spawn an ecological event from the index.
3. Emits `event_started` and tracks `ticks_remaining` per active event.
4. On expiry, emits `event_resolved` with outcome `&"expired"`.
5. Persists active events in `GameState.run_save.active_events` so killing/relaunching mid-event resumes the timer.

The actual *handling* (spawning herbivores, applying multipliers) is done by other systems subscribing to `event_started`. This system is the scheduler only.

## Outputs (create)
- `scripts/systems/ecological_pressure.gd`
- Modification to `scenes/world/world.tscn` — add `EcologicalPressure` node under `Systems`, between `GrowthSystem` and `OfflineProgress`.

## Implementation notes
- `Node`. Loads the EventIndex in `_ready` (via the `_index.tres` pattern).
- Constants:
  - `const MIN_TILES_BEFORE_EVENTS: int = 3` — no events fire while player has ≤ 3 tiles.
  - `const TRIGGER_CHECK_INTERVAL_TICKS: int = 30` — check every 30 ticks (~30s) whether to fire an event.
  - `const TRIGGER_PROBABILITY: float = 0.4` — at each check, roll for whether anything fires.
  - `const HERBIVORE_PRESSURE_THRESHOLD: float = 0.6` — when herbivore_wave is rolled, only actually fire if owned-tile count is comfortably above MIN_TILES_BEFORE_EVENTS (e.g. ≥ 6) so the wave isn't trivially won.
- State:
  - `var _events_by_id: Dictionary[StringName, EventData] = {}` (built from index in `_ready`).
  - `var _active: Array[Dictionary] = []` (mirrors `run_save.active_events`).
  - `var _ticks_until_check: int = TRIGGER_CHECK_INTERVAL_TICKS`.
  - `var _rng: RandomNumberGenerator` — seeded from `GameState.run_seed XOR Time.get_unix_time_from_system()` once in `_ready` so events vary across sessions but are reproducible within one play.

- `_ready()`:
  - Load EventIndex; populate `_events_by_id`.
  - Connect `EventBus.tick.connect(_on_tick)`, `EventBus.run_loaded.connect(_on_run_loaded)`.
  - Catch-up: `if not GameState.run_save.is_empty(): _on_run_loaded(SaveSystem.SAVE_VERSION)`.

- `_on_run_loaded(_v)`:
  - Reset `_active`. Read `run.active_events`. For each entry that maps to a known event id, push into `_active`. Re-emit `event_started` for each so subscribers (HerbivoreManager, HUD) can rebuild their state.
  - Reset `_ticks_until_check` to its full value.

- `_on_tick(_delta)`:
  - **Suppress during replay.** If you've subscribed to `replay_started` / `replay_finished` like HUD does, skip event logic during replay (events shouldn't fire 28800 times in a catch-up burst). Track `var _is_replaying: bool` similarly.
  - Decrement `ticks_remaining` on each entry in `_active`. Any that hit 0 → emit `event_resolved(id, &"expired")` and remove.
  - `_sync_run_save()` to mirror back into save dict.
  - `_ticks_until_check -= 1`. When it reaches 0, reset and call `_maybe_trigger()`.

- `_maybe_trigger()`:
  - Skip if `TerritorySystem.get_owned_coords().size() < MIN_TILES_BEFORE_EVENTS`.
  - Roll `_rng.randf() < TRIGGER_PROBABILITY`. If false, return.
  - Pick an event by `trigger_weight`. For Phase 3, only act on `&"herbivore_wave"` — if the roll picks drought/cool_spell, log "would have fired X" and skip (subsequent phases will handle them). This keeps drought/cool_spell in scheduling rotation without breaking.
  - For herbivore_wave: also check `owned_count >= 6`; otherwise skip.
  - On fire: append `{"id": id, "ticks_remaining": event.duration_ticks, "payload": event.payload}` to `_active`, persist, and emit `event_started(id, event.payload)`.

- `_sync_run_save()`: rebuild `run.active_events` from `_active`. Mirror what TerritorySystem does for tiles.

- Public method `func resolve_event(id: StringName, outcome: StringName) -> void` — for AbilitySystem / HerbivoreManager to call when an event ends early (e.g. all herbivores killed). Removes the entry, persists, emits `event_resolved(id, outcome)`.

- Public method `func is_event_active(id: StringName) -> bool` — for read-only checks.

## Acceptance criteria
- [ ] No event fires before player owns ≥ MIN_TILES_BEFORE_EVENTS tiles.
- [ ] After enough tiles owned, herbivore_wave fires at most once per ~75 ticks on average (TRIGGER_CHECK_INTERVAL × 1/TRIGGER_PROBABILITY).
- [ ] `event_started(&"herbivore_wave", payload)` fires exactly once per wave.
- [ ] After `duration_ticks` ticks pass, `event_resolved` fires (assuming no early resolve).
- [ ] Killing the app mid-event and relaunching: timer continues from saved `ticks_remaining` (no reset).
- [ ] No events fire during offline replay.
- [ ] Drought/cool_spell are picked sometimes but logged-and-skipped without firing.

## Out of scope
- The actual herbivore spawn — that's brief 04.
- Difficulty curve over time. Tune in Phase 7.
- Multiple events stacking. For Phase 3, only allow one active event at a time. Add a guard in `_maybe_trigger()`.
