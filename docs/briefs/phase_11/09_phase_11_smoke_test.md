# Brief 09 — Phase 11 manual smoke test

**Suggested agent**: do this yourself, on the device.

Read first:
1. `docs/ROADMAP.md` Phase 11 exit criterion: "a 10-minute session contains at least one active-intervention moment beyond herbivore wave; the player can visually see which tiles they grew on a previous run; prestige feels like *closing a chapter*."

## Procedure

### Setup
1. Back up your existing save.
2. Reset save. Launch.
3. `save_version` should be 9.
4. Inspect `save.json`: `meta.tile_history == {}`, `run.goal_id == ""`, `run.goal_progress == {}`, `run.goal_met == false`.

### Migration regression
5. Restore the v8 backup. Relaunch.
   - [ ] Migrates cleanly to v9. No errors in logcat.
   - [ ] `meta.tile_history == {}`, `run.goal_id == ""`.
   - [ ] All previously-bought evolution nodes still appear as owned.
   - [ ] All discovery entries still listed correctly.

### Tile history persistence + rendering
6. Start a plantae photosynthesizer run. Colonize tiles at (5,5), (5,6), (5,7). Confirm:
   - [ ] After each colonization, inspect `save.json`: `meta.tile_history["5,5"]` etc. contain `["plantae"]`.
   - [ ] No faint tint visible yet (current tile is bright green; history is overshadowed).
7. Prestige. Start a fungi decomposer run.
   - [ ] On run-load, tiles (5,5)/(5,6)/(5,7) show a faint green pre-existing tint underneath the empty base.
8. Colonize tile (5,5) as fungi (subsurface).
   - [ ] `save.json`: `meta.tile_history["5,5"] == ["plantae", "fungi"]`.
   - [ ] Tile now shows fungi violet on top.
9. Prestige. Start a plantae run.
   - [ ] On run-load, tile (5,5) shows a faint violet tint (most-recent kingdom was fungi).
   - [ ] Tiles (5,6)/(5,7) still show faint green.

### Tile-local soil_memory
10. Buy `soil_memory` (8 EP, requires plantae played and prereqs).
11. Start a plantae run on the existing save (so tile_history is populated).
12. Colonize tile (5,5) (had fungi in history) vs (10,10) (no history). Leave both alone for 10 ticks.
    - [ ] Biomass yield per tick on (5,5) is ~1.15× yield on (10,10). Verify by reading ResourceLedger before/after.
13. Toggle `soil_memory` off (manually remove from `meta.evolution_tree` in save.json + reload). Same test:
    - [ ] No bonus difference; tiles produce same biomass.

### AbilityData generalization (Toxin Bloom regression)
14. Start plantae run. Earn 50+ biomass. Tap Toxin Bloom button.
    - [ ] Enters target mode. Tap a tile near a herbivore.
    - [ ] Herbivore takes 3 damage (or 5 if `toxin_potency` bought).
    - [ ] 50 biomass spent.
15. Re-tap Toxin Bloom while already in target mode:
    - [ ] Cancels target mode.

### Event-tied abilities

#### Drought + Irrigate
16. Buy `deep_roots` (8 EP, prereq `pioneer_resilience`).
17. Start plantae run. Wait for or force-trigger drought.
    - [ ] Irrigate button appears in HUD ability bar alongside Toxin Bloom.
18. Tap Irrigate (cost 30 biomass). Tap a tile near owned area.
    - [ ] 30 biomass spent.
    - [ ] Nutrients jump by `5 × (owned tiles within 3-tile radius)`.
19. Drought resolves.
    - [ ] Irrigate button disappears from bar.

#### Cool spell + Bundle
20. Buy `cold_tolerance` (8 EP). Start fungi run. Force cool spell.
    - [ ] Bundle button appears.
21. Tap Bundle (cost 20 decay). Tap a tile.
    - [ ] 20 decay spent.
    - [ ] That tile + 4 neighbors get `warmed_until_unix` data in save (inspect).
    - [ ] For the next 10 sec, those tiles' yields are not reduced by cool_spell.
22. After 10 sec, warm effect expires.
    - [ ] Yields drop again to cool_spell-reduced values.

#### Spore infection + Cull
23. Buy `quarantine` (10 EP, prereq `saprophytic_efficiency_ii`). Fungi run. Force spore_infection.
    - [ ] Cull button appears.
24. Tap Cull (cost 15 spores). Tap a tile.
    - [ ] 15 spores spent.
    - [ ] Spore_infection does not spread to that tile or its 4 neighbors for the rest of the event.

### Soft prestige goal
25. Start a plantae photosynthesizer run.
    - [ ] Banner appears at top of HUD: "<goal text>: 0 / <target>" with empty progress bar.
26. Colonize tiles / earn biomass / etc. depending on the rolled goal.
    - [ ] Progress bar fills incrementally; label updates.
27. Hit the target:
    - [ ] Banner tint flips to yellow-ish.
    - [ ] Brief flash animation.
    - [ ] HUD prestige button starts pulsing.
28. Prestige.
    - [ ] New run starts with a fresh goal (different id likely).
    - [ ] Banner shows fresh goal, prestige glow clears.

### Niche-tied goal filtering
29. Sample 10 plantae photosynthesizer runs.
    - [ ] Goals rolled are from `[]` (any) + `[&"photosynthesizer"]` pools.
    - [ ] Parasite-specific goals (`parasite_spread`) never roll for photosynthesizer.

### Generations counter
30. Fresh save → title screen shows no generations descriptor.
31. After 1st prestige → title shows "Pioneers · 1 generations".
32. (Optional, slow) Dev shortcut to set `meta.statistics.prestige_count = 6` → "Settled Colonies".
33. Set to 21 → "Networked Life". 101 → "The Anthropocene Watches".

### Save integrity
34. Inspect `save.json` after a normal session:
    - [ ] `save_version: 9`.
    - [ ] `meta.tile_history` populated.
    - [ ] `run.goal_id`, `run.goal_progress.value`, `run.goal_met` populated correctly.
    - [ ] No regressions in pre-Phase-11 fields.

## Exit criterion
- Steps 14–28 pass. A 10-minute session containing drought (or cool_spell or spore_infection) lets you intervene actively.
- Tile history is visually obvious after one prestige cycle.
- Soft-goal banner gives runs shape; prestige glow makes the prestige decision feel earned.
- Generations descriptor shifts after the first prestige.

## If something fails
Report: step, expected vs observed, relevant logcat lines.

## After exit
Phase 12 — Era system + ecosystem selector. World map UI replaces "begin run" button; per-ecosystem completion gating uses the layered-lifeform model from Phase 10.
