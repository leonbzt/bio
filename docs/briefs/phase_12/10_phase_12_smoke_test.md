# Brief 10 — Phase 12 manual smoke test

**Suggested agent**: do this yourself, on the device.

Read first:
1. `docs/ROADMAP.md` Phase 12 exit criterion: 3 ecosystems in each of 2 eras playable, Cryogenian forces a fungi-first opening, era transition plays a narrative passage, world-map UI replaces the old "begin run as X" flow.

## Procedure

### Setup
1. Back up your existing save.
2. Reset save. Launch.
3. `save_version` should be 11.
4. Inspect `save.json`:
   - `meta.current_era_id == "cryogenian"`
   - `meta.current_ecosystem_id == "cryo_polar_ice"`
   - `meta.ecosystem_completions == {}`
   - `meta.eras_unlocked == ["cryogenian"]`

### Migration regression
5. Restore v10 backup. Relaunch.
   - [ ] Migrates to v11 cleanly.
   - [ ] Era fields populated to Cryogenian defaults.
   - [ ] Existing unlocked_kingdoms preserved (plantae + fungi if you had both).
   - [ ] First-launch era discovery entry "The First Cold" fires once.

### World map flow
6. Title screen → Play (or trigger from main menu).
   - [ ] World map opens.
   - [ ] Cryogenian tab active (yellow tint).
   - [ ] Devonian tab visible but locked (lock icon, greyed).
   - [ ] 3 Cryogenian ecosystem cards visible: Polar Ice Cap, Volcanic Vent, Under-ice Sea.
   - [ ] Continue button disabled.
7. Tap Polar Ice Cap card.
   - [ ] Card border highlights yellow.
   - [ ] Continue button enables.
8. Tap Continue.
   - [ ] World map closes, prestige screen opens to kingdom-select directly.
   - [ ] Only Fungi kingdom button visible (no Plantae, even if previously unlocked).
9. Pick Fungi → Decomposer → run starts.

### Cryogenian gameplay
10. During the run, `current_kingdom_id == &"fungi"`, `current_niche_id == &"decomposer"`.
11. Force/wait for 3 events to resolve (cool_spell counts, drought counts, herbivore_wave is plantae-only so skipped).
    - [ ] After the 3rd event resolves, niche prestige to confirm ecosystem completion.
12. Open pause menu → Prestige.
    - [ ] `ecosystem_completed("cryo_polar_ice")` signal fires.
    - [ ] Discovery entry "Patience as a Strategy" unlocks (HUD toast or discovery log).
    - [ ] save.json: `meta.ecosystem_completions["cryo_polar_ice"] == true`.
13. World map opens again.
    - [ ] Polar Ice Cap card shows ✓ + greyed background.
    - [ ] Continue still requires picking a new ecosystem.

### Hard-gate test (era_locked_kingdoms)
14. Dev console (or break into start_run via test):
    - [ ] `PrestigeSystem.start_run(&"plantae")` returns no-op + console warning ("kingdom not available in current era").
    - [ ] `GameState.is_run_active == false`.

### Era completion
15. Complete remaining 2 Cryogenian ecosystems: Volcanic Vent (build 20 fungi tiles), Under-ice Sea (earn 300 decay).
16. On the prestige that completes the 3rd ecosystem:
    - [ ] `era_transition_started(&"cryogenian", &"devonian")` fires.
    - [ ] Mass extinction event toast appears.
    - [ ] Era transition full-screen narrative passage shows the Devonian text fading in.
    - [ ] First 2 seconds: tapping does nothing.
    - [ ] After 2 seconds: tap dismisses, game resumes.
    - [ ] Discovery entries "Time Has a Direction" + "The Wave That Erased the Drafts" + "The Warm Returns" all unlock.
17. World map after dismissal:
    - [ ] Devonian tab is no longer locked.
    - [ ] Tapping it shows 3 ecosystem cards (Tidal Pool, Forest Edge, Inland Swamp).

### Devonian gameplay
18. Pick Tidal Pool. Continue. Kingdom selector now shows Plantae + Fungi (+ Animals if unlocked).
19. Play a Plantae run, reach 30 tiles, prestige.
    - [ ] Tidal Pool ✓ + ecosystem entry unlocks.

### Niche-gated ecosystem
20. Pick Inland Swamp. Continue. Kingdom selector shows Fungi (since Lichen lives under Fungi).
21. Buy `unlock_symbiosis` if not bought, pick Fungi → Lichen niche.
22. Earn 500 biomass in the Lichen run, prestige.
    - [ ] Inland Swamp completion check passes (niche == lichen ✓, biomass >= 500 ✓).
    - [ ] Inland Swamp ✓.
23. Attempt a different niche (Decomposer) and try to complete the same Inland Swamp ecosystem (criterion is biomass — easy enough).
    - [ ] After 500 biomass + prestige: `ecosystem_completed` does NOT fire because niche != lichen.
    - [ ] Save still shows Inland Swamp ✓ from step 22 (idempotent).

### Discovery log UI
24. Open pause menu → Discovery Log.
    - [ ] New categories at top: Eras, Ecosystems.
    - [ ] Header shows updated denominator: "N / 38" (where N = unlocked).
    - [ ] Era entries grouped under Eras header.
    - [ ] Ecosystem entries grouped under Ecosystems header.

### Save integrity
25. Inspect `save.json` after a full Cryogenian → Devonian transition:
    - [ ] `save_version: 11`.
    - [ ] `meta.eras_unlocked == ["cryogenian", "devonian"]`.
    - [ ] `meta.ecosystem_completions` has all 3 cryo + at least 1 devonian.
    - [ ] No regressions in pre-Phase-12 fields.

## Exit criterion
- Steps 6–23 pass. The era system makes a Cryogenian run feel different from a Devonian run (kingdom restriction). The world map is the new primary flow. The transition passage delivers narrative weight.

## If something fails
Report: step, expected vs observed, relevant logcat lines.

## After exit
Phase 13 — ecosystem-specific biomes + graphics + axis-scoped events. Mass extinction gets gameplay teeth. Per-era visuals land. Phase 14 follows with Predator/Cordyceps content + 3-layer species packs (Coral).
