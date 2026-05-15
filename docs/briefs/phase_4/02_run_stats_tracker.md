# Brief 02 — RunStatsTracker

**Suggested agent**: ChatGPT 5.2 via Copilot.

Read first:
1. `docs/ARCHITECTURE.md` § 5 (RunStatsTracker row), `run.statistics` shape.
2. `scripts/autoloads/resource_ledger.gd` — emits `resource_changed` after every mutation.
3. `scripts/systems/territory_system.gd` — emits `tile_colonized`.
4. `scripts/systems/ecological_pressure.gd` — emits `event_resolved`.

## Goal
A passive observer that maintains `GameState.run_save.statistics` so PrestigeSystem (brief 04) has data to calculate evolution points from.

Tracks only cumulative-this-run values. Lifetime stats are updated by PrestigeSystem when a run ends.

## Outputs (create)
- `scripts/systems/run_stats_tracker.gd`
- Modification to `scenes/world/world.tscn` — add `RunStatsTracker` node under `Systems`, near the end of the children list (after `OfflineProgress` is fine; order doesn't matter for an observer).

## Implementation

### Tracking rules
- **`total_biomass_earned`** (float): incremented by the *positive delta* of biomass `resource_changed` events. Read previous biomass amount before each event and compute delta. If delta > 0 add it; if ≤ 0 ignore (don't subtract on spend). Spending doesn't reduce lifetime "earned".
- **`tiles_colonized`** (int): incremented by 1 on each `tile_colonized` signal.
- **`waves_defeated`** (int): incremented by 1 on each `event_resolved` where `outcome == &"defeated"`.

### Implementation notes
- Subscribe to `EventBus.tick.connect` for nothing — we don't need ticks; we listen to source signals directly.
- For biomass delta tracking, cache `_last_biomass: float`. On `resource_changed(id, new_amount)`:
  - If `id != ResourceLedger.BIOMASS`: ignore.
  - `delta = new_amount - _last_biomass`. `_last_biomass = new_amount`.
  - If `delta > 0`: stats.total_biomass_earned += delta; sync.
- On `_on_run_loaded`: read existing stats from save (don't reset). Set `_last_biomass = ResourceLedger.get_amount(BIOMASS)` so future deltas are correct.
- Connect handlers in `_ready` and apply the catch-up pattern from § 7a.

### Helper: `_sync_run_save()`
Write the in-memory stats dict back to `GameState.run_save["statistics"]`. Same pattern as TerritorySystem.

### `reset_run()`
Public method. Zeroes all in-memory counters and writes back. Called by PrestigeSystem (brief 04).

## Acceptance criteria
- [ ] After colonizing 5 tiles, `run.statistics.tiles_colonized == 5` in the save JSON.
- [ ] After ~30s of growth on 5 tiles, `total_biomass_earned` reflects ~30 × per-tick yield, not the live biomass balance (which decreases on colonize spends).
- [ ] After defeating one herbivore wave, `waves_defeated == 1`.
- [ ] After spending biomass on colonization or Toxin Bloom, `total_biomass_earned` does NOT decrease.
- [ ] Killing and relaunching: stats are preserved.

## Out of scope
- Lifetime stat updates (PrestigeSystem handles).
- Other resources' lifetime totals (only biomass for prestige formula).
