# Brief 08 — Phase 14a smoke test

**Suggested agent**: you, on device.

Run after briefs 01–07 land. **Goal: new species playable + biome affinity visibly affecting yields + lineage discovery firing.**

## Pre-flight
- [ ] Project boots without parse errors.
- [ ] A v12 save migrates to v13 cleanly (or a fresh save loads).

## Test path A — Schema + migration

1. Load a v12 save (Phase 13 ship state).
2. Save file becomes v13. Confirm:
   - `meta.lineages_played` exists.
   - If a Phase 12 / 13 run had played plantae → `lineages_played` includes `"pioneer_stem"`.
3. Inspect any species `.tres` in editor:
   - `latin_name`, `lineage_id`, `biome_affinity` fields visible + populated.

## Test path B — Existing species display update

1. Open world map → starting species picker.
2. Pioneer Stem (was "Pioneer Grass") shows new display name + Latin tooltip.
3. Mycorrhizal Mycelium shows "Glomus intraradices" Latin name.
4. Climbing Bramble shows "Trimerophyton robustius" Latin name.
5. Lobe-Finned Browser + Apex Stalker show their Latin names.
6. Cryo-Lichen recipe icon appears in Cryogenian ecosystems' picker.

## Test path C — New species in the picker

For Cryogenian ecosystems:
- [ ] `cryo_polar_ice`: shows Mycelium Thread, **Cyanobacterial Mat**, **Cryo-Lichen** as eligible.
- [ ] `cryo_volcanic_vent`: shows Mycelium Thread, **Vent Archaeon**.
- [ ] `cryo_under_ice_sea`: shows Mycelium Thread, **Cyanobacterial Mat**.

For Devonian ecosystems:
- [ ] `dev_tidal_pool`: unchanged baseline.
- [ ] `dev_forest_edge`: empty filter → shows all unlocked species (Pioneer Stem, Mycelium Thread, Lobe-Finned Browser, etc.) — plus Tree-Fern Stem and Wood-Rot Bracket if unlocked.
- [ ] `dev_inland_swamp`: shows Pioneer Stem, Mycelium Thread, Climbing Bramble, **Tree-Fern Stem**, **Wood-Rot Bracket**.

## Test path D — Pioneer placement rule

1. Start a Cryogenian polar_ice run with Cyanobacterial Mat.
2. Tap any bare tile on the map (no adjacency to existing tiles): **succeeds**.
3. Tap a second tile in a different corner of the map: **also succeeds** (pioneer rule means no adjacency required).
4. Tiles render with the Cyanobacterial Mat color (greenish).
5. Repeat the same test with Vent Archaeon in cryo_volcanic_vent — should also place anywhere.

## Test path E — Biome affinity visible in yield

For a measurable test, enable `DEBUG_BIOME_AFFINITY = true` in growth_system.gd temporarily.

1. Start a Devonian forest_edge run with Pioneer Stem.
2. Place tiles on at least one `forest_edge` biome (affinity 1.2) and one `grassland` biome (affinity 1.0).
3. Watch the debug log for ~30 ticks. Confirm:
   - `forest_edge` tiles report `affinity=1.20` and a higher per_tile biomass.
   - `grassland` tiles report `affinity=1.00` and a lower per_tile biomass.
4. Disable debug, run for 2 minutes; the forest_edge cluster should outproduce the grassland cluster by ~15-20% in total biomass (the 1.2× affinity compounds via tick count).

Repeat for Cyanobacterial Mat — placement on tiles with the most favorable biome (per its affinity dict) should outproduce other tiles measurably.

## Test path F — Recipe (Cryo-Lichen)

1. Cryogenian run.
2. Unlock Cyanobacterial Mat + Mycelium Thread (default starter).
3. Unlock Cryo-Lichen via EP (5 EP cost).
4. Introduce Cryo-Lichen during the run (pays 100 biomass + 40 spores).
5. Tap an empty tile → both cyanobacterial_mat + mycelium_thread placed atomically.
6. Tile renders with the blended fill color.
7. Cost confirmed: combined component costs + recipe's own cost.

## Test path G — Lineage milestone discovery

Cultivate species spanning 2 eras for at least one lineage:

1. Cryogenian: cultivate Cyanobacterial Mat (lineage `pioneer_stem`).
2. Prestige; transition to Devonian.
3. Devonian: cultivate Pioneer Stem (also lineage `pioneer_stem`).
4. Confirm: `disc_lineage_pioneer_stem` discovery entry unlocks (HUD toast).

Repeat for `mycorrhizal` (Mycelium Thread in Cryogenian → Mycelium Thread in Devonian).

Repeat for `lichen` (Cryo-Lichen → Devonian Lichen).

## Test path H — Discovery count

- [ ] Discovery log total denominator increases by +8 (5 species + 3 lineage).
- [ ] Per-species entries fire on first introduction.
- [ ] Voice text consistent with existing entries.

## Test path I — Regression sweep

- [ ] Phase 13 lichen run still works (now branded "Devonian Lichen").
- [ ] Phase 13 parasite plantae run still works (now branded "Climbing Bramble").
- [ ] All 6 ecosystems still complete with their species-first criteria.
- [ ] Save round-trip preserves all new fields.
- [ ] Audio/HUD/world map still functional.

## Sign-off

- [ ] All paths A–I pass.
- [ ] Update `docs/ROADMAP.md` Phase 14a row to ✅.
- [ ] Tag commit `phase_14a_complete`.

## If something fails

- **Picker empty for a new ecosystem**: confirm `starting_species_filter` in the ecosystem .tres contains the new species id, and the species id is in `meta.species_unlocked` (defensive load repair from Phase 13 should seed it).
- **Pioneer placement rejected**: confirm species `.tres` has `tags = Array[StringName]([&"pioneer", ...])` (not just a comma-separated string).
- **Lineage milestone never fires**: confirm `meta.lineage_ecosystems_seen` is accumulating (debug print in discovery_log).
- **Biome affinity not applying**: confirm species `biome_affinity` dict uses StringName keys (`&"forest_edge"`, not `"forest_edge"`).
