# Brief 07 — Phase 11 manual smoke test

**Suggested agent**: do this yourself, on the device.

Read first:
1. `docs/ROADMAP.md` Phase 11 exit criterion: "a 10-minute session contains at least one active-intervention moment beyond herbivore wave; prestige feels like *closing a chapter*, not 'I guess I should restart now.'"

## Procedure

### Setup
1. Back up your existing save.
2. Reset save. Launch.
3. `save_version` should be 9.
4. Inspect `save.json`: `run.goal_id == ""`, `run.goal_progress == {}`, `run.goal_met == false`.

### Migration regression
5. Restore the v8 backup. Relaunch.
   - [ ] Migrates cleanly to v9. No errors in logcat.
   - [ ] `run.goal_id == ""`.
   - [ ] All previously-bought evolution nodes still appear as owned.
   - [ ] All discovery entries still listed correctly.

### AbilityData generalization (Toxin Bloom regression)
6. Start plantae run. Earn 50+ biomass. Tap Toxin Bloom button.
   - [ ] Enters target mode. Tap a tile near a herbivore.
   - [ ] Herbivore takes 3 damage (or 5 if `toxin_potency` bought).
   - [ ] 50 biomass spent.
7. Re-tap Toxin Bloom while already in target mode:
   - [ ] Cancels target mode.

### Event-tied abilities

#### Drought + Irrigate
8. Buy `deep_roots` (8 EP, prereq `pioneer_resilience`).
9. Start plantae run. Wait for or force-trigger drought.
   - [ ] Irrigate button appears in HUD ability bar alongside Toxin Bloom.
10. Tap Irrigate (cost 30 biomass). Tap a tile near owned area.
    - [ ] 30 biomass spent.
    - [ ] Nutrients jump by `5 × (owned tiles within 3-tile radius)`.
11. Drought resolves.
    - [ ] Irrigate button disappears from bar.

#### Cool spell + Bundle
12. Buy `cold_tolerance` (8 EP). Start fungi run. Force cool spell.
    - [ ] Bundle button appears.
13. Tap Bundle (cost 20 decay). Tap a tile.
    - [ ] 20 decay spent.
    - [ ] That tile + 4 neighbors get `warmed_until_unix` data in save (inspect).
    - [ ] For the next 10 sec, those tiles' yields are not reduced by cool_spell.
14. After 10 sec, warm effect expires.
    - [ ] Yields drop again to cool_spell-reduced values.

#### Spore infection + Cull
15. Buy `quarantine` (10 EP, prereq `saprophytic_efficiency_ii`). Fungi run. Force spore_infection.
    - [ ] Cull button appears.
16. Tap Cull (cost 15 spores). Tap a tile.
    - [ ] 15 spores spent.
    - [ ] Spore_infection does not spread to that tile or its 4 neighbors for the rest of the event.

### Soft prestige goal
17. Start a plantae photosynthesizer run.
    - [ ] Banner appears at top of HUD: "<goal text>: 0 / <target>" with empty progress bar.
18. Colonize tiles / earn biomass / etc. depending on the rolled goal.
    - [ ] Progress bar fills incrementally; label updates.
19. Hit the target:
    - [ ] Banner tint flips to yellow-ish.
    - [ ] Brief flash animation.
    - [ ] HUD prestige button starts pulsing.
20. Prestige.
    - [ ] New run starts with a fresh goal (different id likely).
    - [ ] Banner shows fresh goal, prestige glow clears.

### Niche-tied goal filtering
21. Sample 10 plantae photosynthesizer runs.
    - [ ] Goals rolled are from `[]` (any) + `[&"photosynthesizer"]` pools.
    - [ ] Parasite-specific goals (`parasite_spread`) never roll for photosynthesizer.

### Generations counter
22. Fresh save → title screen shows no generations descriptor.
23. After 1st prestige → title shows "Pioneers · 1 generations".
24. (Optional, slow) Dev shortcut to set `meta.statistics.prestige_count = 6` → "Settled Colonies".
25. Set to 21 → "Networked Life". 101 → "The Anthropocene Watches".

### Save integrity
26. Inspect `save.json` after a normal session:
    - [ ] `save_version: 9`.
    - [ ] `run.goal_id`, `run.goal_progress.value`, `run.goal_met` populated correctly.
    - [ ] No regressions in pre-Phase-11 fields.

## Exit criterion
- Steps 6–20 pass. A 10-minute session containing drought (or cool_spell or spore_infection) lets you intervene actively.
- Soft-goal banner gives runs shape; prestige glow makes the prestige decision feel earned.
- Generations descriptor shifts after the first prestige.

## If something fails
Report: step, expected vs observed, relevant logcat lines.

## After exit
Phase 12 — Era system + ecosystem selector. World map UI replaces "begin run" button; per-ecosystem completion gating uses the layered-lifeform model from Phase 10. The "world remembers" mechanic dropped from Phase 11 gets revisited here with ecosystem-level history (not per-tile).
