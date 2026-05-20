# Brief 08 — Phase 15b smoke test

**Suggested agent**: you, on device.

Run after briefs 01-07 land. Goal: discovery feels rewarding (fog reveals + rocks add spatial puzzle), structures land + give felt bonuses.

## Pre-flight
- [ ] Project boots without parse errors.
- [ ] Save migrates v15 → v16 cleanly.

## Test path A — Save migration

1. Load a v15 save with an in-flight run.
2. Save becomes v16. Confirm:
   - `run.fog_revealed` populated (covers existing tiles + 5×5 around each).
   - `run.obstacles` populated (deterministic from run_seed).
   - `run.active_structures` exists (empty).
   - `meta.structures_discovered` exists (empty).
3. No gameplay disruption.

## Test path B — Fog of war

1. Start a fresh run.
2. Most of the map is dark; only a 5×5 area in the center is visible (initial reveal).
3. Place a tile on a revealed edge tile.
4. The 5×5 area around the new tile becomes visible (new biomes/rocks appear).
5. Try to tap a clearly hidden tile → placement is rejected (or silently no-op).
6. Continue expanding; new biome types appear in the biome legend as you reveal them.
7. Save mid-run, reload: fog state preserved.
8. Prestige + start new run: fog resets to center-only reveal.

## Test path C — Rock obstacles

1. Fresh run. About 5% of revealed tiles are dark gray rocks.
2. Try to place a tile on a rock: rejected (no placement, error sound if any).
3. Confirm the 7×7 center starting zone has no rocks.
4. Same `run_seed` (note seed, restart with same seed): rocks land in identical positions.
5. Different `run_seed`: rocks land in different positions.
6. Rocks don't move on save/load.

## Test path D — Fog-aware biome legend

1. Fresh run on Cryogenian polar_ice.
2. Initial biome legend shows only the biome(s) of the starting reveal area (likely 1-2).
3. Expand toward a tundra-rich area. New "Tundra" chip appears in the legend.
4. Discovery entry `disc_biome_tundra` unlocks at the same moment.
5. Biome chip tooltips work (impact pips visible).

## Test path E — Structure: Mycorrhizal Hub

1. Place 9 mycelium_thread tiles in a 3×3 block.
2. Place 4+ pioneer_grass tiles adjacent to the block.
3. Within ~5s, the 9 fungi tiles get a faint halo (purple).
4. Plantae tiles in the bounding box show +50% biomass (HUD biomass ticks faster).
5. Discovery entry `disc_structure_mycorrhizal_hub` unlocks.
6. Remove one fungi tile from the 3×3 — halo + bonus revert within ~5s.
7. Add it back — halo returns.

## Test path F — Structure: Old-Growth Stand

1. Place 16 contiguous pioneer_grass tiles in a 4×4 block.
2. Within ~5s, the 16 tiles get a green halo.
3. Biomass yield from the block is visibly doubled.
4. Trigger a herbivore_wave (wait or use debug). Herbivores skip those tiles.
5. Remove one — halo + bonus revert.

## Test path G — Structure: Fairy Ring

1. Place fungi tiles in a ring around an empty center (radius 1 = 3×3 minus center, so 8 tiles).
2. Within ~5s, ring halo appears (blue-cyan).
3. `run_save.fairy_ring_active = true`.
4. (If Sporulate is wired) Sporulate ability available without owning `mass_fruiting` node.
5. Remove a ring tile → bonus reverts.

## Test path H — Structure: Decay Pit

1. Start a run with corpses available (or wait for a herbivore to die).
2. Place 4 mycelium_thread tiles in a 2×2 on rich_soil biome, adjacent to a corpse.
3. Halo appears (rose-pink).
4. Nutrients yields from tiles within 3 steps visibly increase.

## Test path I — Recipe book

1. Tap "Recipes" button in HUD.
2. Modal opens with 4 entries: discovered ones are full (name + description + pattern), undiscovered are silhouettes ("???").
3. As you complete a structure for the first time, the entry updates from "???" to full.
4. Close button + tap outside dismisses.

## Test path J — Combined

1. Run a fresh 10-min session, no debug intervention.
2. Observe:
   - At least one structure formed (most likely Mycorrhizal Hub since it's cheap)
   - Biome legend has 3+ chips as you've explored
   - At least 30% of the map is still fog
   - Multiple rock obstacles visible
   - Recipe book shows 1-2 discovered + 2-3 silhouettes
3. Session feels like exploration + ecosystem-architecture, not just tile-spam.

## Test path K — Regression

- [ ] Phase 15a tests pass (multipliers, maturation, cost scaling).
- [ ] Phase 14b tests pass.
- [ ] Phase 13 tests pass.
- [ ] Tick TPS unchanged on 200-tile run.

## Sign-off

- [ ] All paths A–K pass.
- [ ] Update `docs/ROADMAP.md` Phase 15b row to ✅.
- [ ] Tag commit `phase_15b_complete`.

## If something fails

- **Fog doesn't render**: confirm `_FogOverlay` is added to `_overlay_layer`, `set_fog_state` called.
- **Rocks not placed**: check `ObstacleSystem._on_run_loaded` ran + `run.obstacles` is populated.
- **Structure doesn't promote**: print from `_scan()` to confirm `_find_pattern_matches` returns non-empty. Verify `pattern_params` in `.tres` use the correct keys (StringName values).
- **Halo doesn't render**: confirm `TileGrid.add_structure_halo` is called and the halo overlay draws.
- **Bonus doesn't apply**: confirm `_bonus_X(entry, true)` runs; check that tile_data flag is read in `GrowthSystem._apply_yields`.
- **Performance drop**: cluster + structure scans every tick on a 1500-tile map can be expensive. Adjust `SCAN_INTERVAL_TICKS` if needed; consider scanning only after `tile_colonized`/`tile_lost` events.
