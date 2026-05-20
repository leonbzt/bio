# Brief 05 — Phase 15c smoke test

**Suggested agent**: you, on device.

Run after briefs 01-04 land. Goal: mid-run progression (Adaptation + species evolution) feels rewarding, and new placement rules add variety.

## Pre-flight
- [ ] Project boots without parse errors.
- [ ] Save migrates v16 → v17 cleanly.

## Test path A — Save migration

1. Load a v16 save with an in-flight run.
2. Save becomes v17. Confirm:
   - `run.adaptation = 0.0`
   - `run.species_levels = {}`
3. No gameplay disruption.

## Test path B — Adaptation accumulation

1. Start a fresh run, place a few tiles to form a cluster of ≥5 of one species.
2. HUD shows Adaptation chip with rate "+N.N/min" (non-zero now that cluster qualifies).
3. Wait ~30 seconds; Adaptation pool increments visibly.
4. Reveal more biomes (Phase 15b fog): rate increases.
5. Introduce another species: rate increases further.
6. Smaller clusters (< 5 tiles) don't contribute to the cluster portion of the rate.

## Test path C — Species evolution

1. With ≥5 Adaptation in the pool, find an introduced species in the species panel.
2. Row shows "Lvl 1" + ▲ icon indicating it can evolve.
3. Tap the ▲ button (or designated evolve trigger).
4. Adaptation decrements by 5; species level becomes "Lvl 2"; tile yields visibly increase ~10%.
5. Continue accumulating; once pool has 15 more, evolve to Lvl 3. Costs visible in tooltip.
6. At Lvl 3, ▲ disappears (no further evolution possible).
7. Save round-trip: levels preserved.
8. Prestige + start new run: species back at Lvl 1, pool back to 0.

## Test path D — Creeping Vine (diagonal_only)

1. Introduce Creeping Vine (auto-unlocked).
2. Place the first tile anywhere — succeeds (first-tile-free).
3. Try to place a second tile cardinally adjacent (N/S/E/W of first) — rejected.
4. Try to place a tile diagonally adjacent (NE/NW/SE/SW of first) — succeeds.
5. Vine grows in a "checkerboard" pattern, never straight.

## Test path E — Spore Drift (gap_jumper)

1. Introduce Spore Drift.
2. Place first tile.
3. Place a tile up to 4 tiles away in a cardinal direction — succeeds.
4. Place a tile 5+ tiles away — rejected.
5. Place a rock-blocked line: rock between source and target → placement rejected at far tile.
6. Diagonal placements rejected unless line-of-sight cardinal exists.

## Test path F — Scavenger Swarm (corpse_only)

1. Wait for a herbivore to die (or trigger via debug) → corpse appears.
2. Introduce Scavenger Swarm (need biomass + protein).
3. Try to place on a normal tile — rejected.
4. Place on the corpse tile — succeeds.
5. Continue: only corpse tiles accept Scavenger Swarm placement.

## Test path G — Combined session

1. Run a fresh 10-min session.
2. Observe:
   - Adaptation accumulates from cluster + biome + species sources
   - You level up at least one species via Adaptation
   - Evolved species visibly produces more
   - At least one new placement rule is used (diagonal, gap, or corpse)
3. Session feels like a genuine *mid-run progression* with strategic choices.

## Test path H — Regression

- [ ] Phase 15b tests pass (fog, rocks, structures).
- [ ] Phase 15a tests pass (multipliers, maturation, costs).
- [ ] Phase 14 tests pass.
- [ ] No new uncaught exceptions over a 15-min play session.
- [ ] Tick TPS unchanged.

## Sign-off

- [ ] All paths A–H pass.
- [ ] Update `docs/ROADMAP.md` Phase 15c row to ✅.
- [ ] Tag commit `phase_15c_complete`.

## If something fails

- **Adaptation rate is 0**: cluster < 5 tiles, no biomes revealed, or single species. Confirm at least one cluster is 5+.
- **Evolve button doesn't appear**: confirm `can_level_up` returns true; check Adaptation pool against `next_cost`.
- **Yields don't increase after evolve**: confirm `_species_level_yield_multiplier` is called in `_apply_yields`; verify `species_levels` dict reads correctly.
- **diagonal_only allows cardinal**: confirm `_rule_diagonal_only` checks only the 4 diagonal coords, not cardinal.
- **gap_jumper places beyond range**: check `GAP_JUMPER_MAX_RANGE` is respected; verify LOS check skips correctly when rocks present.
- **scavenger_swarm anywhere**: confirm `is_corpse_at` returns false for non-corpse tiles; verify CorpseSystem state is queried.
