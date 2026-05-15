# Brief 08 — Phase 3 integration smoke test

**Suggested agent**: do this yourself, on the device.

Read first:
1. `docs/ROADMAP.md` Phase 3 — exit criterion: "the player must intervene during a herbivore wave or lose territory".

## Procedure

### Setup
1. Reset save (main menu → Reset Save → confirm).
2. Launch the app.

### Quiet period
3. Colonize ≤ 3 tiles. Wait 60 seconds.
   - [ ] No event fires (below MIN_TILES_BEFORE_EVENTS threshold).
   - [ ] No toast appears.

### Triggering a wave
4. Continue colonizing until you own ≥ 6 tiles. Keep playing.
   - [ ] Within ~75 seconds (TRIGGER_CHECK_INTERVAL × 1/TRIGGER_PROBABILITY ≈ 75), Herbivore Wave fires.
   - [ ] Toast appears at top with "Herbivore Wave" title.
   - [ ] N=3 herbivores spawn at the edges of the grid.

### Passive observation
5. Don't intervene. Watch.
   - [ ] Herbivores walk toward your territory at the speed_ticks cadence.
   - [ ] On reaching an owned tile, herbivore pauses and "chews" for chew_ticks ticks.
   - [ ] After chewing, the tile reverts to unowned (overlay clears).
   - [ ] Biomass production drops as you lose tiles.

### Active defense
6. Tap **Toxin Bloom** button (bottom-right).
   - [ ] Button modulates brighter (targeting mode).
   - [ ] Tile taps no longer colonize new tiles.
7. Tap a tile near a herbivore (within 3 Manhattan tiles).
   - [ ] 50 biomass spent.
   - [ ] Herbivores within radius take 3 damage. Any reaching 0 hp despawn.
   - [ ] Mode returns to colonize (button stops glowing).

### Wave resolution
8. Continue using Toxin Bloom until all herbivores die.
   - [ ] `event_resolved(&"herbivore_wave", &"defeated")` fires (visible in logcat).
   - [ ] Toast dismisses (or shows resolved confirmation if you implemented one).
   - [ ] Tile colonization works normally again.

### Persistence
9. Trigger a new wave. Mid-wave, kill the app from recents.
10. Relaunch.
    - [ ] Wave timer continues from where it left off (NOT a fresh wave).
    - [ ] Herbivores reappear at their saved positions and hp.
    - [ ] No duplicate toast (event id was already shown).
    - [ ] Toxin Bloom still functional.

### Loss state
11. Trigger a wave. Don't intervene.
12. Let herbivores chew you down to zero owned tiles.
    - [ ] No crash.
    - [ ] Logcat shows the warning from HerbivoreManager about "all owned tiles lost".
    - [ ] Event eventually expires; herbivores despawn.
    - [ ] You can colonize a new tile (bootstrap rule applies again with zero owned).

### Drought / cool spell
13. Play for several minutes through multiple event-check intervals.
    - [ ] Logcat occasionally shows "would have fired drought" or "would have fired cool_spell" but no game-effect actually applies.
    - [ ] These don't break Herbivore Wave scheduling.

## Exit criterion
All steps pass. Then we're clear for Phase 4.

## If something fails
Report: which step, expected vs observed, relevant logcat lines (filter `adb logcat | grep -i "herbivore\|ecological\|ability\|toxin"`).
