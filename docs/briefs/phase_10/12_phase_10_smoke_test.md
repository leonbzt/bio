# Brief 12 — Phase 10 manual smoke test

**Suggested agent**: do this yourself, on the device.

Read first:
1. `docs/ROADMAP.md` Phase 10 exit criterion: "player can play a Lichen run as a Fungi niche (no kingdom called 'symbiosis' in UI), and an Animal Herbivore and Animal Predator run. Parasite plantae feels parasitic (steals from neighbors). Mycorrhizal fungi feels mutualistic (must bond with plants). Stub resources visible in HUD."

## Procedure

### Setup
1. Back up your existing save.
2. Reset save. Launch.
3. `save_version` should be 10.
4. Inspect `save.json`: `meta.unlocked_kingdoms == ["plantae"]`, `meta.kingdoms_played == []`, `run.resources` contains all 6 stub resources at 0.0.

### Migration regression
5. Restore the v9 backup. Relaunch.
   - [ ] Migrates cleanly to v10.
   - [ ] If the backup had `"symbiosis"` in `meta.unlocked_kingdoms`, it's stripped.
   - [ ] If the backup had an in-flight symbiosis run, `run.kingdom_id == "fungi"`, `run.niche_id == "lichen"`.
   - [ ] All 6 stub resources present in `run.resources`.

### Symbiosis kingdom retired
6. Prestige screen → kingdom selector.
   - [ ] Buttons: Plantae, Fungi (and Animals once unlock_animals bought). NO Symbiosis.
7. Plantae photosynthesizer run (regression).
   - [ ] Plays identically to before.
8. Fungi decomposer run (regression).
   - [ ] Plays identically to before.

### Lichen niche
9. Buy `unlock_symbiosis` (now "Lichen Heritage"). Open Fungi → niche selector.
   - [ ] Decomposer, Mycorrhizal, and Lichen options visible.
10. Choose Lichen. Confirm:
    - [ ] `kingdom_id == &"fungi"`, `niche_id == &"lichen"`.
    - [ ] HUD layer toggle visible with two buttons: Fungi, Plantae.
    - [ ] Active layer defaults to first (Fungi).
11. Tap a tile → fungi subsurface placed.
12. Tap Plantae button → tap a tile → plantae surface placed.
13. Both layers should tick yields (Decay + Spores from fungi tiles, Biomass + Sunlight from plant tiles).
14. With `symbiotic_generosity` (purchased) → fresh Lichen run starts with +10 biomass + 5 nutrients.
15. Discovery entry "The Body That Is Two Bodies" should fire on first `unlock_symbiosis` purchase (regression — Phase 9 brief 07 authored this).

### Parasite plantae signature (biomass-steal)
16. Buy `unlock_parasitic_plantae`. Start parasite plantae run.
17. Place 3 parasite tiles in a row, isolated from any fungi.
    - [ ] Yield per tick: ~baseline plantae (no 2× multiplier anymore).
    - [ ] After 30 ticks, isolated tiles still wither per parasite_decay_system (regression).
18. Dev cheat: spawn a fungi tile adjacent to a parasite tile (edit save.json or via dev console).
    - [ ] Biomass ticks 0.15 faster per such adjacency, capped at 0.5 per parasite tile per tick.

### Mycorrhizal fungi signature (substrate-claim)
19. Buy `unlock_mycorrhizal_fungi`. Start mycorrhizal fungi run.
20. Tap an empty tile → does nothing (invalid).
21. Build a couple plant tiles via dev cheat or via a sequential plantae-then-fungi run flow.
22. Tap a plant tile (now in mycorrhizal run) → fungi tile placed on subsurface; `tile.data.mycorrhizal_bond == true` in save.
23. On a bonded tile:
    - [ ] Plant biomass yield × 1.20.
    - [ ] Fungi decay yield × 1.20.
24. HUD hint visible during mycorrhizal run: "Tap plant tiles to bond".

### Animal Herbivore
25. Buy `unlock_animals` (20 EP, requires plantae + fungi played + insectivory + cordyceps_mastery).
    - [ ] Animals appears in kingdom list.
26. Open Animals → niche selector.
    - [ ] Herbivore + Predator options visible.
27. Choose Herbivore.
    - [ ] `kingdom_id == &"animals"`, `niche_id == &"herbivore"`.
    - [ ] HUD shows Protein resource active (colored, not greyed). Cellulose shows but greyed (per brief 10 — animals consume it but don't own it).
28. Dev cheat: grant 50 cellulose. Tap an empty grassland tile → Common Grazer placed (cost 8 cellulose).
29. Yield: 0.4 protein + 0.2 biomass per anchored animal, plus +0.1 biomass per grassland tile in 2-tile wander radius.

### Animal Predator
30. Choose Predator from animal niche selector.
    - [ ] `niche_id == &"predator"`.
    - [ ] HUD: Protein + Lifeforce active (greyed-removed when in predator runs).
31. Dev cheat: grant 50 protein. Tap empty tile → Common Predator placed (cost 10 protein).
32. Yield: 0.6 protein + 0.05 lifeforce per tick.

### Stub resources
33. In each kingdom run, verify HUD resource greying:
    - [ ] Plantae run: Cellulose colored, others greyed.
    - [ ] Fungi run: all stub resources greyed.
    - [ ] Animals Herbivore run: Protein colored, others greyed.
    - [ ] Animals Predator run: Protein + Lifeforce colored.
34. Long-press any greyed resource → tooltip text appears.

### Graphics
35. Niche badge HUD shows distinct icons for Lichen, Herbivore, Predator.
36. Animal tile variants render visibly different from plant + fungi.
37. Lichen run shows both layers (green plant + violet fungi).

### Save integrity
38. Inspect `save.json` after a normal session:
    - [ ] `save_version: 10`.
    - [ ] `meta.unlocked_kingdoms` doesn't contain "symbiosis".
    - [ ] 6 stub resources present in `run.resources`.
    - [ ] No regressions in pre-Phase-10 fields.

## Exit criterion
- All steps pass. Each kingdom is playable; Lichen demonstrates the layered model; per-niche signatures lift the parasite + mycorrhizal experience above flat-stat-bump.

## If something fails
Report: step, expected vs observed, relevant logcat lines.

## After exit
Phase 11 implementation should also be smoke-tested if not already done (briefs landed but full smoke pass deferred). Then Tier 1 is complete and you can shift focus to Tier 2 (Phase 12 era system).
