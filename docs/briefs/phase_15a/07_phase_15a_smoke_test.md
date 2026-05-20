# Brief 07 — Phase 15a smoke test

**Suggested agent**: you, on device.

Run after briefs 01–06 land. Goal: the loop *feels* alive — visible income, visible aging, visible cost-rising — without regressions.

## Pre-flight
- [ ] Project boots without parse errors.
- [ ] Save migrates v14 → v15 cleanly (or fresh save loads).

## Test path A — Save migration

1. Load a v14 save with an in-flight run + several owned tiles.
2. Save file becomes v15. Confirm:
   - `run.tile_ages` exists (empty dict for legacy tiles — they get age 0 implicitly).
   - `run.species_tile_counts` populated from existing tiles (e.g., `pioneer_grass: 18`).
   - `meta.lifetime_counters` exists with `tiles_placed_lifetime`, `clusters_formed_lifetime`.
3. No gameplay disruption — run resumes; tiles intact.

## Test path B — Per-resource multipliers visible

1. Start any fresh run.
2. HUD shows multiplier chips: `Biomass ×1.0`, `Spores ×1.0`, `Decay ×1.0`, `Nutrients ×1.0`.
3. From a debug menu or console, call `ResourceLedger.set_multiplier_source(&"biomass", &"run:test", 2.0)`.
4. Biomass chip immediately updates to `×2.0`.
5. Hover/tap chip → tooltip shows `Biomass multipliers: run:test: ×2.00`.
6. `ResourceLedger.clear_multiplier_source(&"biomass", &"run:test")` reverts chip to `×1.0`.

## Test path C — Cluster floats

1. Start a run, place 5+ contiguous tiles of one species.
2. Within ~8 seconds, a `+X biomass` label drifts up from the cluster center + fades out.
3. With 2 separate clusters, each emits its own float; staggered (not same tick).
4. Empty/single-tile clusters do NOT emit floats (or emit very small amounts).
5. Float text uses biomass green color.

## Test path D — Tile pulse

1. Start a run, place 10+ tiles.
2. Observe the tile fills: roughly 1 in 10 tiles briefly brightens on each tick.
3. Empty tiles do NOT pulse.
4. No flickering / no perf drop.

## Test path E — Tile maturation

1. Place a fresh tile. It should look dimmer + slightly transparent.
2. Resource accumulation rate is ~half of what it would normally produce.
3. After ~15 ticks (~15 sec), the tile transitions to "Mature" — full saturation, full yield.
4. After ~60 ticks (~1 min), the tile becomes "Ancient" — full saturation + (optionally) subtle inner glow. Yield is ~30% higher.
5. Place an adjacent tile of the same species/kingdom next to an Ancient tile: it gains a small biomass bonus (visible in HUD totals if observed carefully, or via cluster float amount).
6. Reload mid-life: tile ages persist correctly.

## Test path F — Tile cost scaling

1. Start a fresh plantae run.
2. First Pioneer Stem tile: free.
3. Open species panel → tap Pioneer Stem → tooltip shows current cost ≈ base × 1.05.
4. Place tiles, watching cost rise: after ~10 owned tiles, cost is ~1.6× base; after ~25, ~3.4× base.
5. Continue: cost becomes prohibitive around 50 tiles unless multipliers have scaled income to match.
6. Remove a tile (e.g., via event or manual clear if available): cost drops accordingly.
7. Compare with another species (say, introduce a 2nd species): its cost starts fresh (×1.0 for the first) regardless of how many of the first you have.

## Test path G — Combined feel

1. Run for 5 minutes uninterrupted, no debug intervention.
2. By the end, you should observe:
   - At least one species cultivated to maturity / ancient
   - Cluster floats popping every several seconds across the map
   - Cost-rise pushing you to introduce a second species
   - Multiplier chips reading > ×1.0 (from any sources Phase 15b/c add — for now likely still ×1.0 unless any other source was wired)
3. The session should feel measurably more alive than pre-15a.

## Test path H — Regression

- [ ] Phase 14 tests pass (biomes, events, mass extinction, era nodes).
- [ ] Phase 13 tests pass (placement, recipes, species introduction).
- [ ] Save/load round-trip preserves all new fields.
- [ ] No new uncaught exceptions over a 15-min play session.
- [ ] Tick TPS unchanged (~1Hz, no drops on 200-tile maps).

## Sign-off

- [ ] All paths A–H pass.
- [ ] Update `docs/ROADMAP.md` Phase 15a row to ✅.
- [ ] Tag commit `phase_15a_complete`.

## If something fails

- **Multiplier chip stuck at ×1.0**: confirm `set_multiplier_source` is being called somewhere or test via console as in path B.
- **Cluster floats don't appear**: check `ClusterIncomeTracker` is mounted under World/Systems; verify `get_clusters()` returns non-empty.
- **Tiles don't visually age**: confirm `_on_tick_age_refresh` is wired + repaint runs every ~5 ticks.
- **Costs don't scale**: confirm `_scaled_cost(species)` is the only cost path used in rules; verify `species_tile_counts` updates on add/remove.
- **Perf drop**: profile with the debug FPS overlay; most likely culprits are cluster detection (O(N) per tick) or tile pulse tween creation. Throttle accordingly.
