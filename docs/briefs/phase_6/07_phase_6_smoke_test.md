# Brief 07 — Phase 6 manual smoke test

**Suggested agent**: do this yourself, on the device.

Read first:
1. `docs/ROADMAP.md` Phase 6 exit criterion: "player can build a measurably stronger ecosystem with symbiosis than without."

## Procedure

### Setup
1. Have an active save with sufficient EP to buy `unlock_fungi` (10) + `unlock_symbiosis` (15) + `mutualism` (12) + `wood_wide_web` (18). Total: ~55 EP. Either grind multiple plantae runs or edit save.json's `evolution_points_balance` for testing.
2. Buy `unlock_fungi`, then `unlock_symbiosis`. Confirm the prestige screen shows three kingdom buttons: Plantae, Fungi, Symbiosis.

### Plantae regression
3. Start a Plantae run. Verify everything works as before (no regressions from briefs 02–06).
   - [ ] LayerToggle button is hidden.
   - [ ] Colonize, see herbivores, defeat with Toxin Bloom. Same Phase 4/5 behavior.

### Fungi regression
4. Prestige, start a Fungi run.
   - [ ] LayerToggle button is hidden.
   - [ ] Fungi behavior identical to Phase 5.

### Symbiosis first run
5. Prestige, start a Symbiosis run.
   - [ ] LayerToggle button visible bottom-left, shows "Layer: Plant" (default).
   - [ ] First tap places a green surface plant tile.
   - [ ] Tap LayerToggle. Label changes to "Layer: Fungi".
   - [ ] Next tap places a violet subsurface fungi tile on the plant tile (parasitic substrate rule).
6. Inspect the tile: green AND violet overlay both visible.
   - [ ] Save file's `run.tiles[i]` has `surface_owner: "plantae"` AND `subsurface_owner: "fungi"`.

### Yield verification (the exit criterion)
7. Build out 4 symbiotic tiles (i.e., 4 tiles where both layers are owned).
8. Note the per-second yield in the HUD:
   - Biomass should increase by approximately `4 × 0.5 × biome_sun × (1 + traits) × 1.30` per tick.
   - Decay should increase by approximately `4 × 0.4 × (1 + traits) × 1.30` per tick.
   - Spores should increase by approximately `4 × 0.15 × (1 + traits) × 1.30` per tick.

   Verify the **× 1.30** is observable — compare against:
   - 4 surface-only plant tiles: same biomass without the multiplier.
   - 4 subsurface-only fungi tiles: same decay/spores without the multiplier.

   If you can build 4 of each layout in three separate symbiosis runs, you should see ~30% more output in the co-occupied configuration. That's the exit criterion.

### Mutualism upgrade
9. Prestige (cash in some EP). Buy `mutualism`.
10. Start a new symbiosis run. Build 4 co-occupied tiles.
    - [ ] Yields are now × 1.50 (compared to × 1.30 in step 8).

### Wood Wide Web upgrade
11. Buy `wood_wide_web`.
12. Build a "core" of 1 symbiotic tile, then 4 single-layer neighbors around it.
    - [ ] The 4 neighbor tiles yield × 1.15.
    - [ ] The core yields × 1.50 (mutualism).
    - [ ] No multiplier overlap on the core itself.

### Persistence
13. Mid symbiosis run, kill the app. Relaunch.
    - [ ] Tiles preserved with both layers visible.
    - [ ] LayerToggle visible; label matches saved or reset state per your persistence choice in brief 03.
    - [ ] Yields resume correctly.

### Edge cases
14. In a symbiosis run, try to place a plant on a tile that already has a plant: no-op. ✓
15. Try to place a fungus on a tile that already has fungus: no-op. ✓
16. Toggle layer while in Toxin Bloom targeting mode: layer toggles fine, but tile taps still target the bloom (input_mode wins).

## Exit criterion
All steps pass. Co-occupied tiles produce measurably more (× 1.30 / × 1.50) than single-layer equivalents. Phase 6 done.

## If something fails
Report: step, expected vs observed, relevant logcat (`adb logcat | grep -i "symbio\|placement\|growth"`).

## After exit
Phase 7 (polish) is the final phase. Ping me with the smoke result and we'll plan polish work — balancing, sound/music, perf profiling, iOS export decision.
