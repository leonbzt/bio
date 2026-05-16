# Brief 08 — Phase 8 manual smoke test

**Suggested agent**: do this yourself, on the device.

Read first:
1. `docs/ROADMAP.md` Phase 8 exit criterion: "each kingdom has at least 2 niches playable. Carnivore plantae plays measurably differently from Photosynthesizer plantae."
   - Phase 8 substitutes **Parasite plantae** for Carnivore (per the open-question answers locked in brief 00).

## Procedure

### Setup
1. Reset save. Launch.
2. `save_version` should be 5.
3. Buy enough EP across plantae runs to afford `unlock_parasitic_plantae` (8 EP) and `unlock_mycorrhizal_fungi` (8 EP). Total: 16 + the prereqs (`thrifty_growth` 3, `unlock_fungi` 10) = ~30 EP across multiple runs.

### Default niche regression
4. Start a Plantae run. Confirm:
   - [ ] No niche-select screen appears (only 1 niche unlocked: photosynthesizer). Run starts directly.
   - [ ] HUD shows "Photosynthesizer" badge top-center.
   - [ ] Tile colors: bright green surface overlay on colonized tiles.
   - [ ] Plays identically to pre-Phase-8 plantae.
5. Same regression for Fungi (decomposer). Tile colors violet, badge "Decomposer".

### Parasite plantae niche
6. Buy `unlock_parasitic_plantae`. Start a Plantae run.
   - [ ] Niche-select screen appears with two options: Photosynthesizer, Parasitic.
7. Pick Parasitic. Confirm:
   - [ ] Niche badge: "Parasitic".
   - [ ] First tile free, anywhere. Crimson overlay.
   - [ ] Second tile must be adjacent to first. Cost: 3 biomass.
   - [ ] Per-tile biomass yield is ~1.0/tick (vs 0.5 for photosynthesizer) — verify by leaving 5 isolated tiles for 10 seconds, compare HUD biomass climb.
8. Build a small "isolated" parasite tile (only one neighbor). Wait ~30 ticks.
   - [ ] After 30 seconds, the isolated tile is removed (tile_lost fires, overlay disappears).
9. Build a dense parasite cluster (4 tiles with each having ≥2 neighbors). Leave for 60 seconds.
   - [ ] No tiles die. The cluster is stable.
10. Kill app mid-run. Relaunch. Verify the `parasite_decay_ticks` counter resumed correctly (visible in `save.json` `run.tiles[i].data.parasite_decay_ticks`).

### Mycorrhizal fungi niche
11. Prestige, buy `unlock_mycorrhizal_fungi`. Start a Fungi run.
    - [ ] Niche-select: Decomposer + Mycorrhizal.
12. Pick Mycorrhizal. Confirm:
    - [ ] Niche badge: "Mycorrhizal".
    - [ ] Cannot bootstrap on empty grid (since no plant tiles exist). Taps do nothing.
    - This is the intended design — mycorrhizal needs a plant substrate.
13. Prestige out, start a Plantae run, build some plant tiles, prestige back into Fungi → Mycorrhizal.
    - **Note**: this won't work yet because prestige resets the run. The full mycorrhizal experience needs Phase 10's symbiotic species (Lichen). For Phase 8, mycorrhizal is dev-testable but not really playable.
    - Alternative test: manually edit `save.json` mid-load to spawn 5 plantae tiles, then enter mycorrhizal fungi run. Verify the niche can colonize on/adjacent to those tiles.
    - If you have time and a cross-kingdom feature you'd like to defer-test, note in the smoke-test log that "mycorrhizal full validation deferred to Phase 10".

### Visual sanity
14. Open the pause menu and confirm tile colors are visually distinct: green / crimson / violet / teal.

### Save integrity
15. Inspect `save.json` mid-run:
    - [ ] `save_version: 5`.
    - [ ] `run.niche_id`: matches your active niche.
    - [ ] Parasite tile entries have `data.parasite_decay_ticks: <int>`.

### Save migration
16. Edit a copy of an old v4 save (back it up first). Change `save_version` to 4 manually. Relaunch.
    - [ ] Migrates cleanly to v5, with `niche_id` populated based on `kingdom_id`.
    - [ ] No errors in logcat.

## Exit criterion
- Steps 1–10 pass. Parasite plantae feels genuinely different from photosynthesizer.
- Mycorrhizal foundation is in place (full validation acceptable to defer to Phase 10).
- Migration works.

## If something fails
Report: step, expected vs observed, relevant logcat lines.

## After exit
Phase 9 — the interconnected progression web. We'll restructure the evolution tree into the cross-kingdom DAG, add 10–15 cross-wing nodes, and build the new tree-visualization UI. Phase 10 then completes Tier 1 with symbiosis reframe + Animal kingdom foundation.
