# Brief 04 — EraSystem autoload + ecosystem completion tracking

**Suggested agent**: ChatGPT 5.2. Route diff to Claude — adds signals and system contract.

Read first:
1. `docs/briefs/phase_12/02_era_ecosystem_schemas.md`, `03_author_eras_and_ecosystems.md`.
2. `scripts/autoloads/run_goal_system.gd` — similar listen-for-progress pattern.
3. `scripts/systems/prestige_system.gd` — `trigger_prestige()` is the integration point for completion check.

## Goal
A new autoload that:
- Loads era + ecosystem indexes on `_ready`.
- Tracks per-run progress against the current ecosystem's `completion_criterion`.
- On `prestige_triggered`, checks whether the criterion was met; if so, marks the ecosystem complete and emits `ecosystem_completed`.
- Detects era completion (all ecosystems in era done) and emits `era_transition_started` so the UI can play the passage.

## Outputs

### Create `scripts/autoloads/era_system.gd`

```gdscript
extends Node
##
## EraSystem — owns era + ecosystem state, tracks completion criteria,
## unlocks the next era when current is fully complete.
##

const ERA_INDEX_PATH: String = "res://data/eras/_index.tres"
const ECOSYSTEM_INDEX_PATH: String = "res://data/ecosystems/_index.tres"

var _eras_by_id: Dictionary[StringName, EraData] = {}
var _ecosystems_by_id: Dictionary[StringName, EcosystemData] = {}
# Per-run progress accumulator. Resets on run_started.
var _criterion_progress: float = 0.0


func _ready() -> void:
    _load_indexes()
    EventBus.run_started.connect(_on_run_started)
    EventBus.tile_colonized.connect(_on_tile_colonized)
    EventBus.event_resolved.connect(_on_event_resolved)
    EventBus.organism_died.connect(_on_organism_died)
    EventBus.evolution_node_unlocked.connect(_on_evolution_node_unlocked)
    EventBus.prestige_triggered.connect(_on_prestige_triggered)
    EventBus.tick.connect(_on_tick)


func _load_indexes() -> void:
    _eras_by_id.clear()
    var era_index := load(ERA_INDEX_PATH)
    if era_index is EraIndex:
        for era in (era_index as EraIndex).eras:
            if era != null:
                _eras_by_id[era.id] = era
    _ecosystems_by_id.clear()
    var eco_index := load(ECOSYSTEM_INDEX_PATH)
    if eco_index is EcosystemIndex:
        for eco in (eco_index as EcosystemIndex).ecosystems:
            if eco != null:
                _ecosystems_by_id[eco.id] = eco


# Public API ---------------------------------------------------------------

func get_current_era() -> EraData:
    var id := StringName(GameState.meta_save.get("current_era_id", ""))
    return _eras_by_id.get(id, null)


func get_current_ecosystem() -> EcosystemData:
    var id := StringName(GameState.meta_save.get("current_ecosystem_id", ""))
    return _ecosystems_by_id.get(id, null)


func get_era(era_id: StringName) -> EraData:
    return _eras_by_id.get(era_id, null)


func get_ecosystem(ecosystem_id: StringName) -> EcosystemData:
    return _ecosystems_by_id.get(ecosystem_id, null)


func set_current_ecosystem(ecosystem_id: StringName) -> void:
    var eco := get_ecosystem(ecosystem_id)
    if eco == null:
        return
    GameState.meta_save["current_ecosystem_id"] = String(ecosystem_id)
    # Update current era to match if needed.
    if String(GameState.meta_save.get("current_era_id", "")) != String(eco.era_id):
        GameState.meta_save["current_era_id"] = String(eco.era_id)
        EventBus.era_changed.emit(eco.era_id)
    SaveSystem.save_now()


func is_ecosystem_complete(ecosystem_id: StringName) -> bool:
    var completions: Dictionary = GameState.meta_save.get("ecosystem_completions", {})
    return bool(completions.get(String(ecosystem_id), false))


func is_era_complete(era_id: StringName) -> bool:
    var era := get_era(era_id)
    if era == null:
        return false
    for eco in era.ecosystems:
        if not is_ecosystem_complete(eco.id):
            return false
    return true


func is_era_unlocked(era_id: StringName) -> bool:
    var unlocked: Array = GameState.meta_save.get("eras_unlocked", [])
    return unlocked.has(String(era_id))


func get_ecosystems_in_era(era_id: StringName) -> Array[EcosystemData]:
    var era := get_era(era_id)
    if era == null:
        return []
    var result: Array[EcosystemData] = []
    for eco in era.ecosystems:
        if eco != null:
            result.append(eco)
    return result


# Internals — completion tracking -----------------------------------------

func _on_run_started(_kingdom_id: StringName) -> void:
    _criterion_progress = 0.0


func _on_tile_colonized(_coord: Vector2i, _owner: StringName) -> void:
    var eco := get_current_ecosystem()
    if eco == null or eco.completion_criterion != &"tiles_colonized":
        return
    _criterion_progress += 1.0


func _on_event_resolved(_event_id: StringName, _outcome: StringName) -> void:
    var eco := get_current_ecosystem()
    if eco == null or eco.completion_criterion != &"events_survived":
        return
    _criterion_progress += 1.0


func _on_organism_died(_id: int, cause: StringName) -> void:
    var eco := get_current_ecosystem()
    if eco == null or eco.completion_criterion != &"herbivores_defeated":
        return
    if cause != &"toxin_bloom":
        return
    _criterion_progress += 1.0


func _on_evolution_node_unlocked(_node_id: StringName) -> void:
    var eco := get_current_ecosystem()
    if eco == null or eco.completion_criterion != &"node_purchased":
        return
    _criterion_progress += 1.0


func _on_tick(_delta: float) -> void:
    var eco := get_current_ecosystem()
    if eco == null or eco.completion_criterion != &"biomass_earned":
        return
    var stats: Dictionary = GameState.run_save.get("statistics", {})
    var earned: float = float(stats.get("total_biomass_earned", 0.0))
    if earned > _criterion_progress:
        _criterion_progress = earned


func _on_prestige_triggered(_summary: Dictionary) -> void:
    var eco := get_current_ecosystem()
    if eco == null:
        return
    if is_ecosystem_complete(eco.id):
        return
    if _criterion_progress < eco.completion_target:
        return
    # Niche / kingdom gates.
    if eco.completion_required_niche != &"" and StringName(GameState.run_save.get("niche_id", "")) != eco.completion_required_niche:
        return
    if eco.completion_required_kingdom != &"" and StringName(GameState.run_save.get("kingdom_id", "")) != eco.completion_required_kingdom:
        return
    # Mark complete.
    var completions: Dictionary = GameState.meta_save.get("ecosystem_completions", {}) as Dictionary
    completions[String(eco.id)] = true
    GameState.meta_save["ecosystem_completions"] = completions
    EventBus.ecosystem_completed.emit(eco.id)
    # Check era transition.
    if is_era_complete(eco.era_id):
        _maybe_unlock_next_era(eco.era_id)
    SaveSystem.save_now()


func _maybe_unlock_next_era(completed_era_id: StringName) -> void:
    for era in _eras_by_id.values():
        if era.unlock_requires_prev_era == completed_era_id:
            if is_era_unlocked(era.id):
                return
            var unlocked: Array = GameState.meta_save.get("eras_unlocked", []) as Array
            unlocked.append(String(era.id))
            GameState.meta_save["eras_unlocked"] = unlocked
            EventBus.era_transition_started.emit(completed_era_id, era.id)
            return
```

### Register autoload

`project.godot`, after `RunGoalSystem`:
```
EraSystem="*uid://<new_uid>"
```

Use `*res://scripts/autoloads/era_system.gd` initially; the user's project will generate the .uid on first Godot open and the autoload entry can be switched to `*uid://` form to match the existing autoload pattern.

### Extend `EventBus`

In `scripts/autoloads/event_bus.gd`:
```gdscript
signal era_transition_started(from_era: StringName, to_era: StringName)
signal ecosystem_completed(ecosystem_id: StringName)
signal era_changed(era_id: StringName)
```

Document in `ARCHITECTURE.md` § 3 + § 7.

## Acceptance criteria
- [ ] EraSystem autoload registers; cold load succeeds.
- [ ] `EraSystem.get_current_era()` returns Cryogenian on fresh v11 save.
- [ ] `EraSystem.get_current_ecosystem()` returns cryo_polar_ice.
- [ ] Mid-run, after surviving 3 events with fungi: prestige triggers → `ecosystem_completed("cryo_polar_ice")` signal fires; save reflects completion.
- [ ] After completing all 3 Cryogenian ecosystems: `era_transition_started(&"cryogenian", &"devonian")` emits; `eras_unlocked` contains "devonian".
- [ ] Failing the niche gate: `dev_inland_swamp` run with photosynthesizer niche does NOT mark complete even if biomass criterion met.

## Out of scope
- World map UI (brief 05).
- Narrative passage UI (brief 06).
- Era-locked kingdom filtering in start_run (brief 07).
- Mass extinction event content (brief 08).
