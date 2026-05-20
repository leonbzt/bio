# Brief 03 — Per-run species evolution UI + yield wiring

**Suggested agent**: ChatGPT 5.2. Route diff to **Claude** — yield math.

Read first:
1. `scripts/autoloads/adaptation_system.gd` (brief 02) — currency API.
2. `scripts/systems/growth_system.gd._apply_yields` — yield application chain.
3. `scripts/ui/species_panel.gd._build_introduced_row` — per-species UI row.

## Goal

Each introduced species can be **leveled up** during the run by spending Adaptation. Up to 3 levels per species. Each level grants +10% to that species' yields. Levels reset on prestige.

UI: species panel introduced rows gain a "Lvl N/3" indicator + an "Evolve" button. Tap opens a small modal showing current level, next level cost, confirm/cancel.

## Yield wiring

In `GrowthSystem._apply_yields`, after maturation and biome multipliers, before the resource-multiplier registry:

```gdscript
# Phase 15c: per-run species evolution level multiplier.
per_tile *= _species_level_yield_multiplier(species.id)
```

Helper:

```gdscript
const LEVEL_YIELD_BONUS: float = 0.10    # +10% per level

func _species_level_yield_multiplier(species_id: StringName) -> float:
    var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
    var levels: Dictionary = run.get("species_levels", {}) as Dictionary
    var level: int = int(levels.get(String(species_id), 1))
    return 1.0 + (LEVEL_YIELD_BONUS * float(level - 1))
```

Level 1 (starting) = ×1.0 baseline. Level 2 = ×1.10. Level 3 = ×1.20. Level 4 (max, but capped at 3 via UI) = ×1.30.

Actually with 3 levels:
- Level 1: ×1.00 (starting, no Adaptation spent)
- Level 2: ×1.10 (after first evolve)
- Level 3: ×1.20 (after second evolve)
- Cap at level 3.

(Alternative naming: Levels 0/1/2 with `+0.10 × level`. Pick whichever feels more natural for players — start-at-1 reads better as "tier" in UI.)

## Cost curve

```gdscript
const MAX_LEVEL: int = 3

# Cost to go from current_level to current_level+1.
# Tunable; numbers matched to early-run Adaptation rate (~5-10 / min).
const LEVEL_UP_COSTS: Array[float] = [
    0.0,     # level 1 -> 1 (no-op, default)
    5.0,     # level 1 -> 2: ~30s of decent ecosystem
    15.0,    # level 2 -> 3: ~2-3 min more
]


func get_level(species_id: StringName) -> int:
    var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
    var levels: Dictionary = run.get("species_levels", {}) as Dictionary
    return int(levels.get(String(species_id), 1))


func get_next_level_cost(species_id: StringName) -> float:
    var current: int = get_level(species_id)
    if current >= MAX_LEVEL:
        return -1.0
    return LEVEL_UP_COSTS[current]


func can_level_up(species_id: StringName) -> bool:
    var cost: float = get_next_level_cost(species_id)
    if cost < 0.0:
        return false
    return AdaptationSystem.can_afford(cost)


func level_up(species_id: StringName) -> bool:
    var cost: float = get_next_level_cost(species_id)
    if cost < 0.0 or not AdaptationSystem.spend(cost):
        return false
    var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
    var levels: Dictionary = run.get("species_levels", {}) as Dictionary
    var sp_key: String = String(species_id)
    levels[sp_key] = int(levels.get(sp_key, 1)) + 1
    run["species_levels"] = levels
    GameState.run_save = run
    EventBus.species_leveled.emit(species_id, levels[sp_key])
    SaveSystem.save_now()
    return true
```

These functions live in `AdaptationSystem` or a new `SpeciesEvolutionSystem` autoload — pick wherever fits the codebase. Recommend `AdaptationSystem` for cohesion (it's the only system that spends Adaptation).

## EventBus signal

```gdscript
signal species_leveled(species_id: StringName, new_level: int)
```

## UI: species panel level indicator

Update `species_panel.gd._build_introduced_row` to add a level + evolve button on each row:

```gdscript
func _build_introduced_row(species: SpeciesData) -> Control:
    # ... existing button setup ...
    var current_level: int = AdaptationSystem.get_level(species.id)
    var can_evolve: bool = AdaptationSystem.can_level_up(species.id)
    var next_cost: float = AdaptationSystem.get_next_level_cost(species.id)
    
    btn.text = "%s  Lvl%d" % [species.display_name, current_level]
    btn.tooltip_text = "%s\n%s\nLvl %d/3 (+%d%% yield)" % [
        species.display_name, species.latin_name,
        current_level, int((current_level - 1) * 10)
    ]
    if next_cost >= 0.0:
        btn.tooltip_text += "\nEvolve: %.0f Adaptation" % next_cost
    
    # Evolve indicator
    if can_evolve:
        btn.text += " ▲"   # arrow signals "can level up"
    
    btn.pressed.connect(func() -> void:
        # Tap = set as placement target (existing behavior)
        GameState.placement_target_species_id = species.id
        EventBus.placement_target_changed.emit(String(species.id))
        _refresh()
    )
    
    # Long-press → evolve modal (mobile-friendly). Alt: separate small button.
    # For simplicity in v1, add a small "▲" button to the row when evolvable.
    if can_evolve and current_level < 3:
        var evolve_btn := Button.new()
        evolve_btn.text = "▲"
        evolve_btn.custom_minimum_size = Vector2(24, 0)
        evolve_btn.tooltip_text = "Evolve (%.0f Adaptation)" % next_cost
        evolve_btn.pressed.connect(func() -> void:
            if AdaptationSystem.level_up(species.id):
                _refresh()
        )
        # ... add as sibling to btn in the row's HBoxContainer ...
    
    # Refresh on adaptation change so button enables/disables live.
    return btn
```

When `species_leveled` fires, refresh the panel.

```gdscript
# In species_panel.gd._ready:
EventBus.species_leveled.connect(func(_id, _level): _refresh())
AdaptationSystem.adaptation_changed.connect(func(_a): _refresh())
```

(`_refresh` may already over-refresh — fine for v1.)

## Acceptance criteria

- [ ] `AdaptationSystem.get_level / get_next_level_cost / can_level_up / level_up` all behave per spec.
- [ ] Each introduced species starts at level 1.
- [ ] Spending Adaptation correctly increments the species' level.
- [ ] Level cap at 3 (next_cost returns -1 when at max).
- [ ] Yields visibly increase: level 2 species ticks ~10% faster than level 1; level 3 ~20% faster.
- [ ] Species panel shows "Lvl N" per introduced species.
- [ ] When Adaptation is sufficient, an evolve button (▲) appears on the row.
- [ ] Tap evolve button: pool decrements, level increments, panel refreshes.
- [ ] Save round-trip preserves species_levels.
- [ ] Prestige resets all species to level 1.
- [ ] `species_leveled` signal fires correctly.

## Out of scope

- Branching evolution choices per level (just flat +10% yield in v1).
- Evolution beyond level 3 (cap is hard for v1).
- Per-species-different level costs (uniform cost curve for v1).
- Visual species transformation per level (Phase 16+ — could change tile_marker_color slightly per level).
- Evolution discovery entries (could land in Phase 16+ polish).
- Long-press gesture for evolve (button is simpler; do that for v1).
