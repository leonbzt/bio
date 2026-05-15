# Brief 08 — Phase 5 manual smoke test

**Suggested agent**: do this yourself, on the device.

Read first:
1. `docs/ROADMAP.md` Phase 5 — exit criterion: "a fungi run feels fundamentally different from a plant run (Pillar #3)".

## Procedure

### Setup
1. Reset save → fresh v4 save built.
2. Confirm `save.json` has `save_version: 4`.

### Plantae regression
3. Begin a plantae run.
4. Colonize 4 tiles. Verify:
   - [ ] Cost is 5 biomass per tile (4 if you bought `thrifty_growth` previously).
   - [ ] Tiles render with the green surface overlay.
   - [ ] `save.json`'s `run.tiles[i]` uses `surface_owner: "plantae"`, `subsurface_owner: ""`.
5. Survive a herbivore wave with Toxin Bloom. Verify:
   - [ ] Killed herbivores leave corpses in `run.organisms` (species_id = "corpse").
   - [ ] Decay resource ticks up in the HUD over the next ~30s.
   - [ ] Corpses despawn after `decay_remaining_ticks` reaches 0.
6. Plantae run plays identically to Phase 4. No regressions.

### Prestige to fungi
7. Buy enough EP across runs to unlock `unlock_fungi`. Prestige.
8. From the prestige screen, choose **Begin run as Fungi**.

### Fungi run
9. New run starts. Confirm:
   - [ ] HUD biomass starts at 0 and stays at 0 (no plant growth).
   - [ ] No surface overlay tiles visible.
   - [ ] Pressing Toxin Bloom button works mechanically (it's still a plantae-flavored ability for now; tuning later).
10. First tap on any tile: places a violet subsurface overlay (bootstrap rule, no cost).
11. Subsequent taps:
    - [ ] On an adjacent tile (any layer): valid, costs spores.
    - [ ] On a non-adjacent empty tile: no-op.
    - [ ] Spores ledger decreases on each colonize.

### Decay / spore yields
12. With one fungi tile owned, wait ~30 seconds. Verify in HUD:
    - [ ] `decay` is increasing by `0.4 * tiles_owned` per second (mycelium_thread yield).
    - [ ] `spores` is increasing by `0.15 * tiles_owned` per second.
    - [ ] `biomass` is NOT increasing.

### Spore infection event
13. Build up to ≥ 6 fungi tiles. Continue playing for 1–2 minutes.
    - [ ] Eventually `Spore Bloom` toast fires.
    - [ ] During the event, a new fungi tile appears every ~5 seconds on the edge of your network (autonomously, without input).
    - [ ] After the event expires, passive spread stops.

### Fungi cross-kingdom validation
14. From the fungi run, kill the app and edit `save.json`: set `current_kingdom_id` back to `"plantae"` (or just prestige again and choose plantae). Confirm:
    - [ ] Switching to plantae: biomass starts growing again on plant tiles. No leftover fungi yields.
    - [ ] No crash, no signal misfire.

### Save integrity
15. Inspect `save.json` mid fungi run:
    - [ ] Tile entries use the new shape.
    - [ ] `run.organisms` contains corpse entries (if any deaths) with the proper `data` fields.
    - [ ] `active_events` references `spore_infection` while it's active.
    - [ ] Migration from a fresh v4 install: no errors, no warnings in logcat.

### Persistence test
16. Mid-fungi-run with infection active: kill app, relaunch.
    - [ ] Fungi tiles preserved (subsurface overlay visible).
    - [ ] Infection event resumes its `spread_every_ticks` cadence.
    - [ ] Corpses persisted.

## Exit criterion
All steps pass AND the fungi run feels mechanically different (per Pillar #3): different resources, different colonization rules, different event tempo.

## If something fails
Report: step, expected vs observed, relevant logcat (`adb logcat | grep -i "fungi\|corpse\|spore"`).

## Notes for Phase 6
This phase produced *co-occupiable* tiles (surface + subsurface). Phase 6 will reward co-occupation with bonuses. Don't add those bonuses now — symbiosis is the centerpiece of Phase 6.
