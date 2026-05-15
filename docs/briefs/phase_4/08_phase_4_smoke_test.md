# Brief 08 — Phase 4 integration smoke test

**Suggested agent**: do this yourself, on the device.

Read first:
1. `docs/ROADMAP.md` Phase 4 — exit criterion: "completing a plant run unlocks fungi as a playable kingdom".

## Procedure

### Setup
1. Reset save. Launch app.
2. Confirm main menu → Play → kingdom-select appears with only "Plantae" enabled.
3. Pick Plantae. World loads with empty grid.

### Build up the first run
4. Colonize tiles. Survive a herbivore wave (or two).
5. Open Menu (top-left) → confirm Prestige button shows "Prestige (earn N EP)" with N matching `floor(sqrt(total_biomass_earned/10))`.

### First prestige
6. Tap Prestige. Confirm prestige screen opens with the summary.
7. Tap Confirm. Confirm:
   - [ ] Tree section appears with all 5 nodes visible.
   - [ ] Balance shows the earned EP.
   - [ ] `thrifty_growth` and `pioneer_resilience` are affordable; others are locked (greyed).
   - [ ] Kingdom section shows only "Begin run as Plantae".

### Buy and start
8. Buy `thrifty_growth`. Confirm balance decreases by 3, button becomes "Owned".
9. Tap "Begin run as Plantae". World loads with empty grid.
10. Colonize a tile — confirm cost is 4 biomass (not 5). Modifier active.

### Cumulative progression
11. Play, prestige again. Confirm:
    - [ ] Tree shows your previous unlocks still owned.
    - [ ] New EP added to balance.
    - [ ] `toxin_potency` is now unlockable (prereq `thrifty_growth` met).
12. Keep prestiging until you can afford `unlock_fungi`. Expected total: 26 EP across multiple runs.
13. Buy `unlock_fungi`. Confirm:
    - [ ] `meta.unlocked_kingdoms` in save.json contains "fungi".
    - [ ] Kingdom section now shows "Begin run as Fungi" alongside Plantae.

### Fungi-as-plantae run
14. Tap "Begin run as Fungi". Confirm:
    - [ ] Run starts; `GameState.current_kingdom_id == "fungi"`.
    - [ ] Game plays mechanically identical to plantae (per Phase 4 deliberate seam).
    - [ ] No crashes when traversing all systems (colonize, wave, ability).

### Persistence
15. Mid-run, kill app. Relaunch.
    - [ ] Continue → returns to the run, kingdom_id preserved.
    - [ ] Meta-progress (unlocks, balance, prestige_count) preserved.

### Cascade migration sanity
16. (Optional) Open save.json, edit `save_version` to 0 (test the cascade). Relaunch.
    - [ ] Save migrates cleanly to v3 without errors.
    - [ ] No data loss.

## Exit criterion
Steps 1–14 pass. Phase 5 is clear.

## If something fails
Report the step, expected vs observed, and any logcat lines from `adb logcat | grep -i "prestige\|evolution"`.
