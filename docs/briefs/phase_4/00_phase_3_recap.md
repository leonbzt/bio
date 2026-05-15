# Brief 00 — Phase 4 entry checklist

**Suggested agent**: do this yourself.

## Acknowledged debt
Phase 3's full smoke test (brief 08) wasn't completed. Waves, HUD toast, and persistence are confirmed working. Outstanding:
- Loss state (lose all tiles to a wave) untested.
- Drought / cool_spell scheduling-without-handler untested.
- Long-running stability untested.

This is acceptable to defer **as long as** Phase 4 doesn't depend on those code paths. It doesn't — prestige resets the run state regardless of how the run ended. But if Phase 4 work surfaces something flaky in Phase 3, fix it before continuing.

## Pre-flight checks
- [ ] Save file is at `save_version: 2` (about to bump to 3 in brief 01).
- [ ] Herbivore wave fires, can be defeated with Toxin Bloom, persists across kill-and-relaunch.
- [ ] No autoloads or signals that aren't in `docs/ARCHITECTURE.md`.

## What lands during Phase 4 setup
- Save schema bump to v3 (brief 01).
- Default `meta.unlocked_kingdoms = ["plantae"]` so plantae is always available.
- New `meta.statistics.{prestige_count, evolution_points_balance, total_biomass_lifetime}`.
- New `run.statistics.{total_biomass_earned, tiles_colonized, waves_defeated}`.
- `PrestigeSystem` and `RunStatsTracker` added to system map (already in `ARCHITECTURE.md`).

## Out of scope this phase
- Fungi mechanics. Phase 5. Selecting Fungi after the unlock will start a run that mechanically still plays as plantae (`GrowthSystem` still loads `pioneer_grass`). That's a deliberate seam — Phase 5 plugs the fungi side in.
