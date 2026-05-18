# Brief 05 — Mass extinction gameplay teeth

**Suggested agent**: ChatGPT 5.2. Route diff to **Claude** — lifecycle correctness.

Read first:
1. `scripts/autoloads/era_system.gd` — `_emit_mass_extinction`.
2. `scripts/systems/ambient_modifier_system.gd` — modifier channels.
3. `scripts/systems/prestige_system.gd` — prestige reward path.
4. `docs/briefs/phase_13_paused/06_mass_extinction_teeth.md` — direct source material.

## Goal

Mass extinction becomes a real mechanical beat. On era transition: post-extinction state stamped. First run in the new era opens at 0.5× sun + biomass, recovers over 120 ticks. On prestige: +25 EP Extinction Survivor bonus, one-shot per era, clears state.

## State machine

```
era_transition_started (EraSystem)
  ↓
meta.post_extinction = {to_era_id, debuff_ticks_remaining: 120}
  ↓
[player closes era passage, lands on world map]
  ↓
player picks an ecosystem in to_era → run starts
  ↓
AmbientModifierSystem applies recovery debuff
(linear 0.5 → 1.0 over 120 ticks)
meta.post_extinction.debuff_ticks_remaining decays per tick
  ↓
[player plays, eventually prestiges]
  ↓
PrestigeSystem:
  if meta.post_extinction.to_era_id == current_era
     AND to_era NOT in meta.first_run_in_era_completed:
       +25 EP, mark completed, clear post_extinction
       unlock disc_milestone_extinction_survivor
```

## EraSystem

`scripts/autoloads/era_system.gd._emit_mass_extinction`:

```gdscript
func _emit_mass_extinction(from_era: StringName, to_era: StringName) -> void:
    var payload: Dictionary = {
        "scope": "world",
        "narrative_only": false,
        "from_era": String(from_era),
        "to_era": String(to_era)
    }
    EventBus.event_started.emit(&"mass_extinction", payload)
    EventBus.event_resolved.emit(&"mass_extinction", &"narrative")

    var completed: Array = GameState.meta_save.get("first_run_in_era_completed", []) as Array
    if completed.has(String(to_era)):
        return  # already paid the survivor toll
    GameState.meta_save["post_extinction"] = {
        "to_era_id": String(to_era),
        "debuff_ticks_remaining": 120
    }
    SaveSystem.save_now()
```

Connect to `run_started` for debuff activation:

```gdscript
# In _ready():
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
    var ams := _get_ambient_system()
    if ams != null and ams.has_method("apply_post_extinction_debuff"):
        ams.apply_post_extinction_debuff(ticks)


func _get_ambient_system() -> Node:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null:
        return null
    return tree.root.get_node_or_null("World/Systems/AmbientModifierSystem")
```

## AmbientModifierSystem

`scripts/systems/ambient_modifier_system.gd`:

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
        var pe: Dictionary = GameState.meta_save.get("post_extinction", {}) as Dictionary
        pe["debuff_ticks_remaining"] = _post_extinction_ticks_remaining
        GameState.meta_save["post_extinction"] = pe
        if _post_extinction_ticks_remaining % 30 == 0:
            SaveSystem.save_now()

func get_multiplier(key: StringName) -> float:
    var base := _compute_base_multiplier(key)   # existing event stacking
    if _post_extinction_ticks_remaining > 0:
        if key == &"sunlight_multiplier" or key == &"biomass_multiplier":
            var progress := 1.0 - (float(_post_extinction_ticks_remaining) / float(_post_extinction_total_ticks))
            var debuff_mult := 0.5 + (0.5 * progress)   # linear recovery
            base *= debuff_mult
    return base
```

(If `_compute_base_multiplier` doesn't exist, fold existing event-stacking logic into that helper.)

## PrestigeSystem

`scripts/systems/prestige_system.gd.trigger_prestige` — call new helper at start:

```gdscript
func trigger_prestige() -> void:
    var bonus_ep: int = _award_extinction_survivor_bonus_if_eligible()
    var earned: float = float(GameState.run_save.get("statistics", {}).get("total_biomass_earned", 0.0))
    var diversity: int = (GameState.run_save.get("unlocked_species_in_run", []) as Array).size()
    var reward: int = calculate_prestige_reward(earned, diversity) + bonus_ep
    _record_kingdom_played()
    _record_species_played()
    _update_meta_stats(reward, earned)
    var summary := {
        "evolution_points_earned": reward,
        "extinction_bonus": bonus_ep,
        "total_biomass_earned": earned,
        "species_cultivated": diversity,
        "starting_species_id": GameState.run_save.get("starting_species_id", "")
    }
    _reset_run_state()
    EventBus.prestige_triggered.emit(summary)
    SaveSystem.save_now()


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
    completed.append(to_era)
    GameState.meta_save["first_run_in_era_completed"] = completed
    GameState.meta_save["post_extinction"] = {}
    EventBus.discovery_unlocked.emit(&"disc_milestone_extinction_survivor")
    return 25
```

## Prestige summary UI

In whichever scene shows prestige results (probably `prestige_screen.gd`), if `summary.extinction_bonus > 0`:

> "+25 EP **Extinction Survivor** bonus (you cultivated the first generation after the great dying)"

Light text addition; no new scene.

## Discovery entry

`disc_milestone_extinction_survivor` authored in brief 08 — fires via the direct unlock call above.

## Acceptance criteria

- [ ] Cryogenian → Devonian transition stamps `meta.post_extinction = {to_era_id: "devonian", debuff_ticks_remaining: 120}`.
- [ ] First Devonian run opens at ~0.5× sunlight + biomass.
- [ ] Multipliers linearly recover to 1.0 over 120 ticks.
- [ ] Reload mid-debuff: ticks_remaining resumes correctly.
- [ ] Prestige during that run adds +25 EP; discovery unlocks; `post_extinction` clears; era added to `first_run_in_era_completed`.
- [ ] Subsequent Devonian runs: no debuff, no extra EP.
- [ ] Cryogenian run after the bonus: no debuff (different era).

## Out of scope

- Visible tile-destruction VFX (Phase 15).
- Multiple stacked extinctions.
- Per-kingdom asymmetric debuff.
- Difficulty modes.
- Rescue mechanic ("save one species") — parked.
