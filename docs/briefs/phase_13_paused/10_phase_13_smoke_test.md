# Brief 10 — Phase 13 manual smoke test

**Suggested agent**: you, on device.

Run after all preceding briefs (01–09) have landed and the build is green.

## Pre-flight

- [ ] Build runs on Android device (the canonical test surface).
- [ ] Save file is v11 (Phase 12 ship state). If you don't have one, play a fresh run to v11 + complete one ecosystem before starting.
- [ ] You have at least one completed Cryogenian ecosystem (so era transition is reachable).

## Test path A — Save migration

1. Launch app with a v11 save.
2. Confirm app loads without errors.
3. Open the save file (`user://save_v0.json` or wherever) and confirm:
   - `version: 12`
   - `meta.post_extinction = {}`
   - `meta.first_run_in_era_completed = []`
   - `meta.first_era_seen` matches `meta.current_era_id`.

## Test path B — Per-ecosystem biome generation

For each Cryogenian ecosystem, start a run and visually confirm the dominant biome:

| Ecosystem | Expected dominant biome | Visual cue |
|---|---|---|
| `cryo_polar_ice` | tundra (pale gray-blue) | Most tiles light, cold-looking |
| `cryo_volcanic_vent` | mineral_vent (dark + orange flecks) | Most tiles dark, orange specks |
| `cryo_under_ice_sea` | tundra (pale gray-blue) | Similar to polar_ice |

For Devonian:

| Ecosystem | Expected dominant biome | Visual cue |
|---|---|---|
| `dev_tidal_pool` | rich_soil (existing color) | Same as Phase 12 |
| `dev_forest_edge` | forest_edge (existing color) | Same as Phase 12 |
| `dev_inland_swamp` | swamp (olive-green) | Most tiles olive-toned |

- [ ] All 6 ecosystems show correct dominant biome.
- [ ] ~30% of tiles are still mixed in (natural era variety).
- [ ] Same `run_seed` reproduces the same map across reloads.

## Test path C — Per-era visual identity

- [ ] Cryogenian runs visibly cool-tinted (blue cast over TileGrid + background).
- [ ] Devonian runs visibly warm-tinted (amber cast).
- [ ] Switching between eras (back to world map → other era) updates the tint immediately.
- [ ] Owned-tile colors (plant green, fungi purple, animal amber) remain readable on both tints.
- [ ] HUD text remains readable on both backgrounds.

## Test path D — Axis-scoped events

Play a 5-minute fungi run on `cryo_volcanic_vent`:

- [ ] `cold_snap` may fire (Cryogenian-scoped, eligible).
- [ ] `sulfur_bloom` may fire (volcanic_vent-scoped, eligible).
- [ ] `spore_infection` may fire (fungi-scoped, eligible).
- [ ] `cool_spell` / `drought` may fire (world-scoped, eligible).
- [ ] `herbivore_wave` **NEVER** fires (kingdom:plantae, ineligible).
- [ ] `wildfire` **NEVER** fires (era:devonian, ineligible).
- [ ] `swamp_fever` **NEVER** fires (ecosystem:dev_inland_swamp, ineligible).

Play a 5-minute plantae run on `dev_inland_swamp`:

- [ ] `wildfire`, `swamp_fever`, `herbivore_wave`, `drought`, `cool_spell` are all eligible.
- [ ] `cold_snap`, `sulfur_bloom`, `spore_infection` **NEVER** fire.

## Test path E — Mass extinction gameplay teeth

Pre-condition: complete all 3 Cryogenian ecosystems.

1. Trigger Cryogenian → Devonian transition via the 3rd ecosystem completion.
2. Era transition passage shows (Phase 12 behavior).
3. Mass extinction toast fires (Phase 12 behavior).
4. Confirm in save file: `meta.post_extinction = {to_era_id: "devonian", debuff_ticks_remaining: 120}`.
5. Pick any Devonian ecosystem; start a run.
6. **At run start**: confirm HUD biomass yield is ~0.5× normal AND sunlight is ~0.5× normal.
7. **Over ~120 ticks (~2 minutes)**: confirm the multipliers linearly recover to 1.0.
8. Reload the app mid-recovery: confirm the debuff resumes at the correct tick count.
9. Prestige the run.
10. **At prestige**: confirm:
    - +25 EP "Extinction Survivor" bonus added to the prestige reward.
    - Discovery entry `disc_milestone_extinction_survivor` unlocks (HUD toast).
    - `meta.post_extinction = {}` after prestige.
    - `meta.first_run_in_era_completed = ["devonian"]`.
11. Start another Devonian run:
    - [ ] No debuff applied.
    - [ ] No EP bonus on prestige.
12. Start a Cryogenian run:
    - [ ] No debuff applied (different era).
    - [ ] No EP bonus.

## Test path F — Era-gated evolution nodes

1. Open evolution tree while in Cryogenian.
   - [ ] `cryotolerance` purchasable (if prereqs met).
   - [ ] `chemosynthetic_pathway` purchasable (if prereqs met).
   - [ ] `vascular_network` greyed-out with "Requires Devonian" tooltip.
   - [ ] `mass_fruiting` greyed-out with "Requires Devonian" tooltip.
   - [ ] `extinction_survivor` greyed-out with "Requires first era transition" tooltip (until path E completes).
2. After path E completes, re-check the tree:
   - [ ] `extinction_survivor` purchasable.
3. Switch to Devonian:
   - [ ] `vascular_network` and `mass_fruiting` now purchasable.
   - [ ] `cryotolerance` and `chemosynthetic_pathway` greyed-out (if not already purchased).
4. Purchase `cryotolerance` while in Cryogenian:
   - [ ] During a `cold_snap` event, the sunlight debuff is noticeably milder (~0.85× instead of 0.5×).
5. Purchase `chemosynthetic_pathway` while in Cryogenian playing fungi:
   - [ ] Fungi on `mineral_vent` tiles earn ~50% more biomass than without the node.
6. Purchase `vascular_network` while in Devonian playing plantae:
   - [ ] Plantae tiles with 4+ neighbors earn ~25% more biomass.
7. Purchase `extinction_survivor`:
   - [ ] All subsequent runs gain ~10% biomass across the board.

## Test path G — Discovery entries

Confirm all 10 new entries unlock:

- [ ] `disc_biome_tundra` — on first run with a tundra map.
- [ ] `disc_biome_mineral_vent` — on first run with a mineral_vent map.
- [ ] `disc_biome_swamp` — on first run with a swamp map.
- [ ] `disc_event_cold_snap` — first cold_snap firing.
- [ ] `disc_event_sulfur_bloom` — first sulfur_bloom firing.
- [ ] `disc_event_wildfire` — first wildfire firing.
- [ ] `disc_event_swamp_fever` — first swamp_fever firing.
- [ ] `disc_node_cryotolerance` — on purchase.
- [ ] `disc_node_chemosynthetic_pathway` — on purchase.
- [ ] `disc_milestone_extinction_survivor` — on first survivor prestige.
- [ ] (Bonus if shipped) `disc_node_vascular_network`, `disc_node_mass_fruiting`, `disc_node_extinction_survivor` — on purchase.

Discovery log denominator updated by +10 (or +13).

## Test path H — Regression sweep

- [ ] Phase 12 world map flow still works (era tabs, ecosystem cards, Continue button).
- [ ] Phase 12 era transition passage UI still works.
- [ ] Phase 11 active interventions (Irrigate, Bundle, Cull) still work.
- [ ] Phase 11 soft prestige goals still work (banner shows + completes).
- [ ] Phase 10 Lichen run still works (Fungi → Lichen niche → 2-layer growth).
- [ ] Phase 10 animal runs still work (Herbivore, Predator).
- [ ] Save/load round-trip works without data loss.
- [ ] No new uncaught exceptions in the log over a 15-minute play session.

## Sign-off

- [ ] All paths A–H pass.
- [ ] No crashes.
- [ ] No regressions to MVP play loop.
- [ ] Update `docs/ROADMAP.md` Phase 13 row to ✅.
- [ ] Update `MEMORY.md` if any locked decisions changed during implementation.
- [ ] Tag commit `phase_13_complete` for easy rollback reference.

## If something fails

- Yield-curve issues (debuff too harsh / too gentle): tune in `ambient_modifier_system.gd._post_extinction_total_ticks` or the `0.5 → 1.0` lerp endpoints. Re-run path E.
- Biome generation wrong: check `ecosystem.biome_preference` is set correctly and `NutrientSystem._generate_biome_map` reads it. Verify `ERA_NATURAL_BIOMES` mapping covers the current era id.
- Event scope leaks (wrong event firing in wrong context): grep `EcologicalPressure._event_matches_scope` logic; add temporary `print(event_data.id, event_data.scope, event_data.scope_target)` to confirm filter is invoked.
- Tint not applying: confirm `EraSystem.get_current_era()` returns non-null; check `EventBus.era_changed` is connected in tile_grid + background.
- Discovery entry not firing: confirm category + trigger_id match exactly; for biome category, confirm `NutrientSystem` emits / calls the unlock path.
