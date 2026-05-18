# Brief 06 — Mass extinction gameplay teeth (post-extinction recovery)

**Suggested agent**: ChatGPT 5.2. Route diff to **Claude** — lifecycle + meta-state correctness.

Read first:
1. `scripts/autoloads/era_system.gd` — `_maybe_unlock_next_era`, `_emit_mass_extinction` (current narrative-only path).
2. `scripts/systems/ambient_modifier_system.gd` — modifier channel pattern.
3. `scripts/systems/prestige_system.gd` — where to apply the EP bonus on prestige.
4. `docs/briefs/phase_13/01_save_v12_migration.md` — meta fields this brief reads/writes.
5. `docs/briefs/phase_12/08_mass_extinction_event.md` — for context on Phase 12's narrative scaffolding.

## Goal

Phase 12 shipped mass extinction as a narrative beat with no mechanical weight. Phase 13 gives it teeth: the **first run in the new era** opens with reduced yields and recovers over time. When that run ends (any prestige outcome), the player is rewarded with a one-shot +25 EP "Extinction Survivor" bonus. The state then clears — extinction is felt once per transition, never re-applied.

## State machine

```
              era_transition_started (from EraSystem)
                          |
                          v
        meta.post_extinction = {to_era_id, debuff_ticks_remaining: 120}
                          |
                          v
              [player closes era passage, lands on world map]
                          |
                          v
              player selects an ecosystem in the new era → run starts
                          |
                          v
       AmbientModifierSystem applies recovery debuff (linear from 0.5 → 1.0
       over 120 ticks). meta.post_extinction.debuff_ticks_remaining decays.
                          |
                          v
              [player plays the run — eventually prestiges]
                          |
                          v
       PrestigeSystem (post-extinction guard):
         if meta.post_extinction.to_era_id == current_era_id
            AND that era not in meta.first_run_in_era_completed:
              - award +25 EP "Extinction Survivor" bonus
              - mark era in meta.first_run_in_era_completed
              - clear meta.post_extinction = {}
              - emit signal for discovery + toast
```

If the player abandons the run (returns to world map without prestige), the debuff state persists — the *next* run in the new era picks up where it left off. Cleanest user experience: don't punish someone for closing the app mid-recovery.

If the player switches eras back to the old completed one (replay grinding), the debuff doesn't trigger — `meta.post_extinction.to_era_id` doesn't match.

## Outputs

### `scripts/autoloads/era_system.gd`

Extend `_emit_mass_extinction`:

```gdscript
func _emit_mass_extinction(from_era: StringName, to_era: StringName) -> void:
    var payload: Dictionary = {
        "scope": "world",
        "narrative_only": false,  # Phase 13: now has teeth.
        "from_era": String(from_era),
        "to_era": String(to_era)
    }
    EventBus.event_started.emit(&"mass_extinction", payload)
    EventBus.event_resolved.emit(&"mass_extinction", &"narrative")

    # Phase 13: stamp the post-extinction state.
    var completed: Array = GameState.meta_save.get("first_run_in_era_completed", []) as Array
    if completed.has(String(to_era)):
        # Already did our survivor run in this era — no debuff re-applied.
        return
    GameState.meta_save["post_extinction"] = {
        "to_era_id": String(to_era),
        "debuff_ticks_remaining": 120
    }
    SaveSystem.save_now()
```

Add a hook on `EventBus.run_started` to apply the debuff to AmbientModifierSystem:

```gdscript
# In _ready() add the connection.
EventBus.run_started.connect(_on_run_started_for_extinction_debuff, CONNECT_DEFERRED)

func _on_run_started_for_extinction_debuff(_kingdom_id: StringName) -> void:
    var pe: Dictionary = GameState.meta_save.get("post_extinction", {}) as Dictionary
    if pe.is_empty():
        return
    var to_era := String(pe.get("to_era_id", ""))
    var current_era := String(GameState.meta_save.get("current_era_id", ""))
    if to_era != current_era:
        return
    var ticks: int = int(pe.get("debuff_ticks_remaining", 0))
    if ticks <= 0:
        return
    # Tell AmbientModifierSystem to apply the recovery curve.
    var ams := _get_ambient_system()
    if ams != null and ams.has_method("apply_post_extinction_debuff"):
        ams.apply_post_extinction_debuff(ticks)
```

### `scripts/systems/ambient_modifier_system.gd`

Add the recovery curve:

```gdscript
var _post_extinction_ticks_remaining: int = 0
var _post_extinction_total_ticks: int = 120

func apply_post_extinction_debuff(ticks: int) -> void:
    _post_extinction_ticks_remaining = ticks
    _post_extinction_total_ticks = max(ticks, 120)

func _on_tick(_delta: float) -> void:
    # ... existing per-tick logic ...
    if _post_extinction_ticks_remaining > 0:
        _post_extinction_ticks_remaining -= 1
        # Persist to meta so reloads pick up the right tick count.
        var pe: Dictionary = GameState.meta_save.get("post_extinction", {}) as Dictionary
        pe["debuff_ticks_remaining"] = _post_extinction_ticks_remaining
        GameState.meta_save["post_extinction"] = pe
        # Save periodically — every 30 ticks is fine for this field.
        if _post_extinction_ticks_remaining % 30 == 0:
            SaveSystem.save_now()

func get_multiplier(key: StringName) -> float:
    var base := _compute_base_multiplier(key)  # existing event-stacking logic
    if _post_extinction_ticks_remaining > 0:
        if key == &"sunlight_multiplier" or key == &"biomass_multiplier":
            # Linear recovery from 0.5 at full debuff to 1.0 at end.
            var progress := 1.0 - (float(_post_extinction_ticks_remaining) / float(_post_extinction_total_ticks))
            var debuff_mult := 0.5 + (0.5 * progress)
            base *= debuff_mult
    return base
```

(If `_compute_base_multiplier` doesn't exist by that name, fold the existing event-modifier stacking into a helper and apply the recovery on top.)

### `scripts/systems/prestige_system.gd`

In the prestige-triggered path (where EP is awarded), add the survivor bonus:

```gdscript
func _award_extinction_survivor_bonus_if_eligible() -> int:
    var pe: Dictionary = GameState.meta_save.get("post_extinction", {}) as Dictionary
    if pe.is_empty():
        return 0
    var to_era := String(pe.get("to_era_id", ""))
    var current_era := String(GameState.meta_save.get("current_era_id", ""))
    if to_era != current_era:
        return 0
    var completed: Array = GameState.meta_save.get("first_run_in_era_completed", []) as Array
    if completed.has(to_era):
        return 0
    # Award + clear.
    completed.append(to_era)
    GameState.meta_save["first_run_in_era_completed"] = completed
    GameState.meta_save["post_extinction"] = {}
    var bonus: int = 25
    EventBus.discovery_unlocked.emit(&"milestone_extinction_survivor")  # toast hook
    SaveSystem.save_now()
    return bonus
```

Call this from the prestige flow before computing total EP, adding the bonus to whatever the run's prestige reward would have been. Brief 09 authors the discovery entry; the unlock signal carries through.

### Discovery entry (preview — brief 09 authors)

`disc_milestone_extinction_survivor` — fired when the player first claims the EP bonus. Voice text in brief 09.

## Acceptance criteria

- [ ] On Cryogenian → Devonian transition (assuming all Cryogenian ecosystems completed):
  - [ ] `meta.post_extinction = {to_era_id: "devonian", debuff_ticks_remaining: 120}` is written.
  - [ ] Save file persists this state.
- [ ] Starting any Devonian run while `post_extinction` is active:
  - [ ] HUD shows reduced biomass yield (0.5× initially, recovering).
  - [ ] HUD shows reduced sunlight yield (0.5× initially, recovering).
  - [ ] After ~120 ticks, multipliers reach 1.0.
- [ ] `meta.post_extinction.debuff_ticks_remaining` updates and saves at least every 30 ticks.
- [ ] On prestige during a post-extinction run:
  - [ ] +25 EP bonus added to the prestige reward.
  - [ ] `meta.first_run_in_era_completed` adds the era id.
  - [ ] `meta.post_extinction = {}`.
  - [ ] Discovery entry `milestone_extinction_survivor` unlocks (brief 09 authors).
- [ ] Subsequent runs in the same era: no debuff applied, no extra EP.
- [ ] Player abandons mid-recovery run (back to world map without prestige): next run resumes the debuff at the saved tick count.
- [ ] Switching back to Cryogenian (no debuff there) plays clean.

## Out of scope

- Mass extinction "save one species" rescue mechanic (parked).
- Visible tile-destruction VFX (Phase 14 — Phase 13 ships the yield debuff without a tile-clearing animation).
- Multiple stacked extinctions (one debuff window per transition; one bonus per era; never compounded).
- Difficulty modes (debuff strength is fixed at 0.5×; tuning is post-test).
- Per-kingdom extinction asymmetry (all kingdoms see the same debuff).
