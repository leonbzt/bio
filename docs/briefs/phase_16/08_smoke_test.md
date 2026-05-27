# Brief 08 — Phase 16 smoke test

**Suggested agent**: Leon executes on device. No code changes.

## Pre-flight

- [ ] Briefs 02–07 complete and merged into main.
- [ ] Game runnable from `scenes/world/world.tscn`.
- [ ] Save format bumped per Step 2; existing saves cleared if needed.
- [ ] Run on a real device + browser export, not just editor.

## Test 1 — Fresh boot

1. Launch the game from main menu.
2. Click "Start Run".

**Expect**: world.tscn loads. Calamites is the locked placement target. HUD shows starting biomass = 50 (seeded pool). EcosystemNameLabel shows "Coal Swamp".

## Test 2 — First placement + biomass tick

1. Place a single Calamites cluster on a wetland tile.
2. Watch the HUD biomass counter for 30 seconds.

**Expect**: Counter climbs by ~60 (~2/s × 30s). Rate label shows ~`+2.0/s`. Cluster status dot is green.

## Test 3 — Nutrient bottleneck

1. After test 2, keep playing without placing Mycorrhizal Network.
2. Watch the nutrients pool deplete (initial 50 − 1/s × ~50s = empty).

**Expect**: At ~50s mark, Calamites' status dot turns yellow then red. Counter rate drops toward 0. `unlock_mycorrhizal` checkpoint fires; onboarding bubble appears.

## Test 4 — First support + cycle bootstrap

1. Place Mycorrhizal Network adjacent to Calamites.

**Expect**: Hero biomass counter dips by 30 (placement cost). Rate recovers as nutrients flow.

2. Continue playing until hero biomass ≥ 500.

**Expect**: `unlock_arthropleura` checkpoint fires.

## Test 5 — Cycle closure

1. Place Arthropleura.

**Expect**: Hero biomass dips by 50. All 3 species placed + feeding pools. After ~5 ticks of stable flow, `cycle_closed` fires — HUD pulses gold for 2s. Rate climbs ~50% (×1.5 multiplier).

## Test 6 — Run end

1. Continue idle play (or active placement of more clusters).
2. Wait until hero biomass reaches 100,000.

**Expect**: `run_complete` checkpoint fires. Prestige screen appears showing biomass, reproductions, cycle closed (yes), evolution earned (1050).

3. Click "Begin next run".

**Expect**: Returns to main menu, auto-launches fresh Calamites run. `meta_save.lineage_runs` has +1 entry.

## Test 7 — Save/load round-trip

1. Mid-run (all 3 species placed), force-quit the app.
2. Relaunch.

**Expect**: Run resumes with same hero biomass, same placed clusters, same cycle_closed state. Checkpoint-fired states persisted.

## Test 8 — Idle test (offline progress)

1. Mid-run, leave the app running unfocused for 30 minutes.
2. Return.

**Expect**: HUD shows significantly higher biomass than before. Rate label is current. No console errors. Offline catch-up replayed the ticks.

## Pass criteria

All 8 tests pass without console errors. Any failed test → file an issue and block phase exit.

## Known regressions to verify

- [ ] No 5-resource row visible in HUD
- [ ] No abilities bar visible
- [ ] No event toast appears (events system unwired)
- [ ] No Coal Gauge / goal banner visible (cut in step 7)
- [ ] No Recipe Book button in HUD (cut in step 2)
- [ ] Evolution tree shows as flat list, not graph
- [ ] No starting-species picker on main menu
- [ ] No world map / ecosystem picker accessible from main menu

## Stretch tests (defer if running long)

- [ ] Place 5+ Calamites clusters — biomass rate scales linearly with cluster count
- [ ] Force a long bottleneck (deplete detritus 5+ min post-closure) → `bottleneck_detritus` checkpoint fires
- [ ] Trigger prestige before cycle closes → goal_met does NOT fire even at 100k biomass

## After smoke test

If all pass:
- Commit a tag/milestone marking Phase 16 prototype playable (e.g., `v1-prototype-1`)
- Update `docs/V1_PROTOTYPE.md` with playtest notes (numbers that needed tuning)
- Write Phase 17 entry brief (v2 features per design lock § 7 deferred list)

If issues found:
- File in a Phase 16 retro doc
- Decide per-issue: hotfix in Phase 16, or defer to Phase 17
- Don't let "minor polish" issues block the milestone — capture in a backlog instead
