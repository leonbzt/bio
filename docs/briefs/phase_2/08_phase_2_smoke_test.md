# Brief 08 — Phase 2 integration smoke test

**Suggested agent**: do this yourself, by hand on the device. ChatGPT for any unit-test scaffolding only.

Read first:
1. `docs/ROADMAP.md` — Phase 2 exit criterion.

## Goal
End-to-end verification that all Phase 2 systems wire together correctly. This is a manual play-test, not an automated test — the goal is to catch integration bugs that unit tests miss.

## Procedure

### Setup
1. Delete your local save: in main menu, tap **Reset Save** → confirm. Or: `adb shell rm /sdcard/Android/data/<package>/files/save.json` on Android.
2. Launch the app. Confirm:
   - [ ] All five resources start at 0 in the HUD.
   - [ ] Tile grid is uniform (no owned overlay anywhere).
   - [ ] Tick indicator pulses once per second.

### Colonization
3. Tap a tile near the center. Confirm:
   - [ ] Tile turns to brighter overlay color (owned).
   - [ ] Biomass does NOT decrease (bootstrap first-tile rule, no cost).
4. Wait ~30 seconds. Confirm:
   - [ ] Biomass climbs steadily.
   - [ ] Sunlight and/or nutrients climb (depends on biome — verify per `data/biomes/grassland.tres` rates).
5. Once biomass ≥ 5, tap a tile **adjacent** to the owned tile. Confirm:
   - [ ] Tile gets the overlay.
   - [ ] Biomass decreases by 5 (cost).
6. Tap a tile **not adjacent**. Confirm:
   - [ ] No change (rejected).
   - [ ] Biomass unchanged.

### Persistence
7. Background the app (home button). Wait ≥ 10 seconds.
8. Foreground the app. Confirm:
   - [ ] Tiles are still owned (visual).
   - [ ] Biomass continued accumulating during background (offline progress fired).
   - [ ] HUD did NOT show rapid pulsing during the catch-up (replay was bracketed).
9. Force-kill the app from recents. Relaunch.
10. Confirm:
    - [ ] Tiles still owned.
    - [ ] Resource amounts match where they left off (modulo offline credit).

### Long offline
11. Background app. Set device clock forward 10 hours (or wait, if you're patient). Foreground.
12. Confirm:
    - [ ] Biomass increased by approximately `8 * 3600 * (sum of per-tick yield)` — capped at 8h, not 10h.
    - [ ] No errors in `adb logcat | grep -i godot`.

### Save integrity
13. Inspect the save file: `adb pull /sdcard/Android/data/<package>/files/save.json`. Open it and confirm:
    - [ ] `save_version == 2` (after the bump in brief 03).
    - [ ] `run.tiles` array contains the coords you colonized.
    - [ ] `run.biome_map` is populated for all 32*48 = 1536 cells.
    - [ ] `run.resources` reflects current HUD values.
    - [ ] `saved_at_unix` is recent.

## Exit criterion for Phase 2
All checkboxes above pass. Then we're clear to start Phase 3 (Active Gameplay).

## If something fails
Don't try to fix from this brief. Report:
- Which step failed.
- Expected vs observed.
- Relevant logs.

I'll diagnose and write a targeted fix brief.

## Out of scope
- Performance profiling. Phase 7.
- Edge cases like clock-skew defenses. Not for MVP.
