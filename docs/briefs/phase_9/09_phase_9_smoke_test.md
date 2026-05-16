# Brief 09 — Phase 9 manual smoke test

**Suggested agent**: do this yourself, on the device.

Read first:
1. `docs/ROADMAP.md` Phase 9 exit criterion: "the evolution tree is the cross-kingdom web. Players can see and chase cross-wing paths. Discovery log is browsable with ≥25 entries."
2. `docs/briefs/phase_9/00_phase_8_recap.md` — the locked decisions.

## Procedure

### Setup
1. Back up your existing save.
2. Reset save. Launch.
3. `save_version` should be 6.
4. Open `save.json`. Verify presence of `meta.discovery_log: {}`, `meta.kingdoms_played: []`, `meta.niches_played: []`, `run.event_first_fires_seen: []`.

### Migration regression
5. Restore your backed-up v5 save. Relaunch.
   - [ ] Migrates cleanly to v6 — no errors in logcat.
   - [ ] `meta.discovery_log == {}`, `meta.kingdoms_played == []` (NOT backfilled from `unlocked_kingdoms`).
   - [ ] All previously-bought evolution nodes still appear as owned in the new tree UI.

### Tree visualization
6. Open prestige screen (trigger a prestige or use the dev shortcut).
   - [ ] Tree shows 4 wing columns labeled or color-distinguished: green Plantae, violet Fungi, teal Hybrid, amber Animals.
   - [ ] All 22 nodes visible. Older nodes wrap into the right columns per the tag table in brief 03.
   - [ ] Prereq lines visible. Cross-wing lines (e.g. `soil_memory` → its plantae prereq, with the "played fungi" gate) are colored by the destination wing.
7. ScrollContainer pans both axes smoothly with finger drag.
8. Long-press a locked node. Tooltip shows:
   - [ ] Title + body.
   - [ ] Cost in EP.
   - [ ] "Requires: X" if missing prereqs.
   - [ ] "Played run as: Y" if `kingdoms_played` gate not met.
9. Buy a node you can afford. Colors update; lines from this node lighten (alpha 1.0).

### `requires_kingdom_played` gate
10. Fresh save → play a plantae run from start to prestige. After prestige, `meta.kingdoms_played == ["plantae"]`.
11. Buy `unlock_fungi`. Then try to buy `soil_memory` (requires `kingdoms_played` includes `fungi`).
    - [ ] Button disabled with "Played run as: Fungi" in tooltip.
12. Play a fungi run to prestige. `meta.kingdoms_played` now contains `["plantae", "fungi"]`.
13. Buy `soil_memory`. Succeeds. Confirm `MetaModifiers.is_unlocked(&"soil_memory") == true`.

### Discovery log — entries fire correctly
14. Continuing from step 13: open pause menu.
    - [ ] Button text "Discovery Log — N / 28" with N > 0 (kingdom + niche + node entries should have fired).
15. Open the log.
    - [ ] Entries grouped: Kingdoms, Niches, Nodes, Events, Milestones.
    - [ ] At minimum: "The First Deal" (kingdom plantae), "The Decomposers Were Already Here" (kingdom fungi), "Photons and Patience" (photosynthesizer niche), "The Slow Return" (decomposer niche), "Beneath the Green" (unlock_fungi node), "What the Ground Remembers" (soil_memory node), "Across the Border" (first_cross_kingdom_node milestone).
    - [ ] **No locked entries visible.** No silhouettes. No redacted bodies.
16. Tap close. Tap "Discovery Log" button again — overlay re-opens cleanly.

### Discovery log — toast
17. Buy `unlock_symbiosis`. Confirm:
    - [ ] HUD toast appears: "New discovery — The Word for Two" (the unlock_symbiosis node entry) and another for "Two Lives, One Body" (the symbiosis kingdom entry). Queue should display them one after another.
18. Tap a toast mid-display.
    - [ ] Game pauses; discovery log overlay opens.

### Discovery log — event entries
19. Start a plantae run. Wait for or force-trigger a drought event.
    - [ ] First fire: toast "The Water That Isn't There" appears; entry unlocks.
    - [ ] Second drought in same run: no toast, no new unlock.
20. Prestige. New run. Force drought again.
    - [ ] No toast (already unlocked persistently; per-run dedup is irrelevant for already-unlocked entries).

### Discovery log — milestone
21. Reach prestige_count = 5 (5 total prestiges across the save).
    - [ ] "Five Lives Lived" entry unlocks; toast fires.

### Save integrity
22. Inspect `save.json` after step 21:
    - [ ] `save_version: 6`.
    - [ ] `meta.discovery_log` contains entry ids set to `true`.
    - [ ] `meta.kingdoms_played` contains the kingdoms you've completed.
    - [ ] `meta.niches_played` contains the niche ids you've started.
    - [ ] `run.event_first_fires_seen` contains the event_ids fired this run.

### Edge cases
23. Buy a node with `requires_kingdom_played` directly via dev tooling without satisfying it.
    - [ ] `PrestigeSystem.purchase_node` returns false. No state change.
24. Force-emit `EventBus.discovery_unlocked.emit(&"disc_kingdom_plantae")` on an already-unlocked entry.
    - [ ] `DiscoveryLog.unlock` no-ops. No double toast.
25. Open discovery log with 0 unlocks (fresh save, didn't start any run).
    - [ ] Empty list, no headers, no errors. Header reads "0 / 28".

## Exit criterion
- Steps 6–18 pass. Tree feels visually like a web; the gate produces informative blocked-purchase tooltips.
- Discovery log shows ≥7 entries after a normal cross-kingdom playthrough (kingdoms + niches + key nodes + at least one milestone).
- No new error spam in logcat.

## If something fails
Report: step, expected vs observed, relevant logcat lines.

## After exit
Phase 10 — symbiosis reframe + Animal kingdom foundation. We'll convert symbiosis from a kingdom into the Lichen species (unlocked by `lichen_heritage`), wire `insectivory` / `cordyceps_mastery` / `unlock_animals` to actual gameplay, and add the first animal niches. Phase 11 follows with the era / ecosystem system.
