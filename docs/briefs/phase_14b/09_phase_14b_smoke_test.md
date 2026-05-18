# Brief 09 — Phase 14b smoke test

**Suggested agent**: you, on device.

Run after briefs 01-08 land. **Goal: era teeth land — biomes, mass extinction, era nodes, visuals.**

## Pre-flight
- [ ] Phase 14a complete + smoke-tested.
- [ ] Save migrates v13 → v14 cleanly OR fresh v14 save loads.

## Test path A — Save migration

1. Load a v13 save.
2. Save file becomes v14. Confirm:
   - `meta.post_extinction = {}`
   - `meta.first_run_in_era_completed = []`
   - `meta.first_era_seen` matches `meta.current_era_id`.
3. Active events (if any in flight) gain `scope = "world"` payload key.

## Test path B — New biomes render

For each Cryogenian ecosystem, start a run + visually confirm:
- [ ] `cryo_polar_ice`: ~70% tiles are pale gray-blue tundra.
- [ ] `cryo_volcanic_vent`: ~70% tiles are dark gray with orange flecks (mineral_vent).
- [ ] `cryo_under_ice_sea`: ~70% tiles are tundra.

For Devonian:
- [ ] `dev_inland_swamp`: ~70% tiles are olive-green swamp.
- [ ] `dev_forest_edge`: unchanged from Phase 13 (legacy biomes only).

## Test path C — Per-era visual tint

- [ ] Cryogenian runs: TileGrid + background visibly cool blue.
- [ ] Devonian runs: TileGrid + background visibly warm amber.
- [ ] Switch eras via world map: tint updates immediately.
- [ ] Owned-tile colors readable on both era backgrounds.
- [ ] HUD text legible.

## Test path D — Chemosynthesis + affinity

1. Cryogenian volcanic_vent run with Vent Archaeon.
2. Place tiles on mineral_vent biome vs tundra biome.
3. Compare per-tile biomass per tick (with debug log if needed):
   - Mineral vent: 1.0 base × (1 + 0.6 chemo) × 1.8 affinity ≈ **2.88× yield**.
   - Tundra: 1.0 base × 1.0 (no chemo) × 0.4 affinity ≈ **0.4× yield**.
4. Mineral vent tiles outproduce tundra tiles by ~7×.

Repeat with Cyanobacterial Mat on tundra (1.2 affinity) vs swamp (0.6 affinity) → 2× yield difference.

## Test path E — Axis-scoped events

In a 5-min Cryogenian fungi run on volcanic_vent:
- [ ] Eligible: `cold_snap`, `sulfur_bloom`, `spore_infection`, `drought`, `cool_spell`.
- [ ] Never fires: `herbivore_wave`, `wildfire`, `swamp_fever`.

In a 5-min Devonian plantae run on inland_swamp:
- [ ] Eligible: `drought`, `cool_spell`, `herbivore_wave`, `wildfire`, `swamp_fever`.
- [ ] Never fires: `cold_snap`, `sulfur_bloom`, `spore_infection`.

## Test path F — Mass extinction teeth

1. Complete all 3 Cryogenian ecosystems.
2. Trigger Cryogenian → Devonian transition via the 3rd ecosystem completion.
3. Era transition passage + extinction toast (Phase 12 narrative beats preserved).
4. Confirm save: `meta.post_extinction = {to_era_id: "devonian", debuff_ticks_remaining: 120}`.
5. Start any Devonian run.
6. At run start: HUD biomass yield ~0.5×, sunlight ~0.5×.
7. Over ~120 ticks (~2 min): multipliers recover to 1.0.
8. Reload mid-recovery → debuff resumes at correct tick.
9. Prestige the run.
10. **+25 EP "Extinction Survivor" bonus** shown in prestige summary.
11. `disc_milestone_extinction_survivor` unlocks (HUD toast).
12. `meta.post_extinction = {}` after prestige.
13. `meta.first_run_in_era_completed = ["devonian"]`.
14. Subsequent Devonian runs: no debuff, no bonus.
15. Switch to Cryogenian: no debuff.

## Test path G — Era-gated evolution nodes

Open evolution tree while in Cryogenian:
- [ ] `cryotolerance` purchasable.
- [ ] `chemosynthetic_pathway` purchasable (after `unlock_fungi`).
- [ ] `vascular_network` greyed + "Requires Devonian".
- [ ] `mass_fruiting` greyed + "Requires Devonian".
- [ ] `extinction_survivor` greyed + "Requires first era transition" (until path F completes).

After F:
- [ ] `extinction_survivor` purchasable.

Switch to Devonian:
- [ ] `vascular_network` + `mass_fruiting` purchasable.
- [ ] `cryotolerance` + `chemosynthetic_pathway` greyed (if unpurchased).

Verify effects:
- [ ] Cryotolerance: cold_snap sunlight debuff lighter (~0.85× severity).
- [ ] Chemosynthetic Pathway: fungi biomass on mineral_vent +50% above baseline.
- [ ] Vascular Network: plantae tiles with ≥4 neighbors +25%.
- [ ] Mass Fruiting: Sporulate ability available OR node greyed with deferred tooltip.
- [ ] Extinction Survivor: all biomass +10% across runs.

## Test path H — Discovery entries

- [ ] All 10 (or 13) new entries unlock at their triggers (biomes on first run with biome, events on first fire, nodes on purchase, milestone on first survivor prestige).
- [ ] Voice consistency.
- [ ] Discovery count denominator increases by +10/+13.

## Test path I — Regression

- [ ] Phase 14a tests (biome affinity, lineage milestones) still pass.
- [ ] Phase 13 tests (lichen, parasite, recipe placement) still pass.
- [ ] Save/load round-trip preserves all fields.
- [ ] No new uncaught exceptions over a 15-min play session.

## Sign-off

- [ ] All paths A–I pass.
- [ ] Update `docs/ROADMAP.md` Phase 14b row to ✅.
- [ ] Tag commit `phase_14b_complete`.

## If something fails

- **Biome not rendering distinct**: check `BIOME_ATLAS_BY_ID` mapping in tile_grid + verify the new atlas slots populated correctly.
- **Yield curve wrong**: confirm chemosynthesis math + affinity multiplier both apply (briefs 02 + Phase 14a brief 05).
- **Event scope leaking**: print event_data.scope + scope_target in `_event_matches_scope`.
- **Mass extinction debuff not applying**: confirm `apply_post_extinction_debuff` is called from EraSystem's `run_started` handler.
- **Era node lock not surfacing**: confirm UI reads `is_node_purchasable` not just `prerequisites_met`.
- **Tint washed out**: drop tint intensity (e.g., Cryogenian `Color(0.92, 0.96, 1.0)`).
