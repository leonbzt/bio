# Brief 04 — PerRunGoalData + RunGoalSystem + goal pool

**Suggested agent**: Kilo for the data, ChatGPT 5.2 for the system + tracking logic. Route diff to Claude.

Read first:
1. `docs/briefs/phase_11/00_phase_11_entry.md` decisions 6 + 7 (one goal per run, niche-tied pool).
2. `docs/briefs/phase_11/01_save_v9_migration.md` — `run.goal_id`, `run.goal_progress`, `run.goal_met`.
3. `scripts/systems/prestige_system.gd` — `start_run` and `_reset_run_state` are the integration points.
4. `scripts/autoloads/event_bus.gd`.

## Goal
Author 12 soft prestige goals + the `RunGoalSystem` autoload that picks one at run start, tracks progress, and emits when met. No UI in this brief — banner is brief 05.

## Outputs

### Create `scripts/data/per_run_goal_data.gd`

```gdscript
class_name PerRunGoalData
extends Resource
##
## A soft prestige goal. Player isn't forced to meet it; meeting it lights up
## the prestige button and shows a banner congratulation. Instances live in
## data/goals/<id>.tres.
##

@export var id: StringName = &""
@export var display_text: String = ""        # "Reach 30 tiles"

# Determines which event(s) the system listens to for progress.
# Recognized values:
#   &"tiles_colonized"     — increments on EventBus.tile_colonized
#   &"biomass_earned"      — accumulates from run.statistics.total_biomass_earned
#   &"events_survived"     — increments on EventBus.event_resolved (any outcome)
#   &"herbivores_defeated" — increments on EventBus.organism_died with cause &"toxin_bloom"
#   &"node_purchased"      — increments on EventBus.evolution_node_unlocked
@export var tracker: StringName = &""

# Target value to reach. Compared against the running counter.
@export var target: float = 0.0

# Niche scope. Empty list = available to any niche. Non-empty = only rolled
# when current niche is in this list.
@export var niches: Array[StringName] = []

# Kingdom scope. Same semantics. Empty = any.
@export var kingdoms: Array[StringName] = []
```

### Create `scripts/data/goal_index.gd`

```gdscript
class_name GoalIndex
extends Resource

@export var goals: Array[PerRunGoalData] = []
```

### Create `data/goals/` and the 12 goals

Each `.tres` follows the schema. Listed below as condensed table; expand each into a full `.tres` file with the standard format.

| File | id | display_text | tracker | target | niches | kingdoms |
|---|---|---|---|---|---|---|
| `goal_tiles_30.tres` | `tiles_30` | "Reach 30 tiles colonized" | `tiles_colonized` | 30 | `[]` | `[]` |
| `goal_tiles_60.tres` | `tiles_60` | "Reach 60 tiles colonized" | `tiles_colonized` | 60 | `[]` | `[]` |
| `goal_biomass_500.tres` | `biomass_500` | "Earn 500 biomass this run" | `biomass_earned` | 500 | `[]` | `[&"plantae"]` |
| `goal_biomass_2000.tres` | `biomass_2000` | "Earn 2000 biomass this run" | `biomass_earned` | 2000 | `[]` | `[&"plantae"]` |
| `goal_events_2.tres` | `events_2` | "Survive 2 ecological events" | `events_survived` | 2 | `[]` | `[]` |
| `goal_events_5.tres` | `events_5` | "Survive 5 ecological events" | `events_survived` | 5 | `[]` | `[]` |
| `goal_herbivores_10.tres` | `herbivores_10` | "Defeat 10 herbivores via Toxin Bloom" | `herbivores_defeated` | 10 | `[&"photosynthesizer"]` | `[]` |
| `goal_buy_node.tres` | `buy_node` | "Purchase an evolution node" | `node_purchased` | 1 | `[]` | `[]` |
| `goal_buy_two_nodes.tres` | `buy_two_nodes` | "Purchase two evolution nodes" | `node_purchased` | 2 | `[]` | `[]` |
| `goal_decomposer_corpses.tres` | `decomposer_corpses` | "Decompose 5 corpses" | `tiles_colonized` | 5 | `[&"decomposer"]` | `[]` |
| `goal_parasite_spread.tres` | `parasite_spread` | "Spread 20 parasite tiles" | `tiles_colonized` | 20 | `[&"parasitic_plantae"]` | `[]` |
| `goal_mycorrhizal_bond.tres` | `mycorrhizal_bond` | "Establish 10 mycorrhizal tiles" | `tiles_colonized` | 10 | `[&"mycorrhizal_fungi"]` | `[]` |

Note `decomposer_corpses` uses `tiles_colonized` as a proxy — the precise "corpse decomposed" tracker would need an event from `CorpseSystem`. For v1, "tiles colonized while playing decomposer fungi" is close enough. If precision matters, add a `EventBus.corpse_decomposed(coord)` signal and a `corpses_decomposed` tracker in the system; defer that to Phase 12 if it doesn't fit Phase 11 scope.

### Create `data/goals/_index.tres`

Reference all 12 in `goals: Array[Resource]`.

### Create `scripts/autoloads/run_goal_system.gd`

```gdscript
extends Node
##
## RunGoalSystem — picks a per-run goal at start_run, tracks progress, emits when met.
##

const GOAL_INDEX_PATH: String = "res://data/goals/_index.tres"

var _all_goals: Array[PerRunGoalData] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
    _load_goals()
    EventBus.run_started.connect(_on_run_started)
    EventBus.tile_colonized.connect(_on_tile_colonized)
    EventBus.event_resolved.connect(_on_event_resolved)
    EventBus.organism_died.connect(_on_organism_died)
    EventBus.evolution_node_unlocked.connect(_on_node_unlocked)
    EventBus.tick.connect(_on_tick)


func _load_goals() -> void:
    _all_goals.clear()
    var index := load(GOAL_INDEX_PATH)
    if index == null or not (index is GoalIndex):
        push_error("RunGoalSystem: missing goal index at %s" % GOAL_INDEX_PATH)
        return
    for goal in (index as GoalIndex).goals:
        if goal != null:
            _all_goals.append(goal)


# Public API ---------------------------------------------------------------

func get_active_goal() -> PerRunGoalData:
    var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
    var id := StringName(run.get("goal_id", ""))
    if id == &"":
        return null
    for goal in _all_goals:
        if goal.id == id:
            return goal
    return null


func get_progress() -> float:
    var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
    var progress: Dictionary = run.get("goal_progress", {})
    return float(progress.get("value", 0.0))


func is_met() -> bool:
    var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
    return bool(run.get("goal_met", false))


# Internals ---------------------------------------------------------------

func _on_run_started(kingdom_id: StringName) -> void:
    _rng.seed = int(GameState.run_seed) ^ int(Time.get_unix_time_from_system())
    var niche_id: StringName = GameState.current_niche_id
    var candidates: Array[PerRunGoalData] = []
    for goal in _all_goals:
        if not goal.kingdoms.is_empty() and not goal.kingdoms.has(kingdom_id):
            continue
        if not goal.niches.is_empty() and not goal.niches.has(niche_id):
            continue
        candidates.append(goal)
    if candidates.is_empty():
        candidates = _all_goals    # safety: fall back to global pool
    var picked: PerRunGoalData = candidates[_rng.randi_range(0, candidates.size() - 1)]
    _set_goal(picked.id)


func _set_goal(id: StringName) -> void:
    var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
    run["goal_id"] = String(id)
    run["goal_progress"] = {"value": 0.0}
    run["goal_met"] = false
    GameState.run_save = run
    SaveSystem.save_now()
    EventBus.goal_progress_changed.emit({"value": 0.0, "target": _get_target_for(id)})


func _on_tile_colonized(coord: Vector2i, _owner: StringName) -> void:
    var goal := get_active_goal()
    if goal == null or goal.tracker != &"tiles_colonized":
        return
    _increment_progress(1.0)


func _on_event_resolved(_id: StringName, _outcome: StringName) -> void:
    var goal := get_active_goal()
    if goal == null or goal.tracker != &"events_survived":
        return
    _increment_progress(1.0)


func _on_organism_died(_id: int, cause: StringName) -> void:
    var goal := get_active_goal()
    if goal == null or goal.tracker != &"herbivores_defeated":
        return
    if cause != &"toxin_bloom":
        return
    _increment_progress(1.0)


func _on_node_unlocked(_node_id: StringName) -> void:
    var goal := get_active_goal()
    if goal == null or goal.tracker != &"node_purchased":
        return
    _increment_progress(1.0)


# Biomass goal can't increment cleanly from a single event — sample on tick
# from run.statistics.total_biomass_earned and emit progress when it grows.
var _last_biomass_sample: float = 0.0


func _on_tick(_delta: float) -> void:
    var goal := get_active_goal()
    if goal == null or goal.tracker != &"biomass_earned":
        return
    var stats: Dictionary = GameState.run_save.get("statistics", {})
    var earned: float = float(stats.get("total_biomass_earned", 0.0))
    if earned > _last_biomass_sample:
        var delta: float = earned - _last_biomass_sample
        _last_biomass_sample = earned
        _increment_progress(delta)


func _increment_progress(amount: float) -> void:
    var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
    var progress: Dictionary = run.get("goal_progress", {})
    var new_value: float = float(progress.get("value", 0.0)) + amount
    progress["value"] = new_value
    run["goal_progress"] = progress
    var goal := get_active_goal()
    if goal == null:
        return
    EventBus.goal_progress_changed.emit({"value": new_value, "target": goal.target})
    if not bool(run.get("goal_met", false)) and new_value >= goal.target:
        run["goal_met"] = true
        EventBus.goal_met.emit()
    GameState.run_save = run


func _get_target_for(id: StringName) -> float:
    for goal in _all_goals:
        if goal.id == id:
            return goal.target
    return 0.0
```

### Register autoload

In `project.godot`, add after `DiscoveryLog`:
```
RunGoalSystem="*res://scripts/autoloads/run_goal_system.gd"
```

### `scripts/autoloads/event_bus.gd` additions

```gdscript
signal goal_progress_changed(progress: Dictionary)   # {value: float, target: float}
signal goal_met()
```

Document in `ARCHITECTURE.md` § 7.

### Reset on prestige

`prestige_system._reset_run_state` already clears `goal_id`/`goal_progress`/`goal_met` per brief 01. Also reset `_last_biomass_sample` in `RunGoalSystem` on `run_started`:

```gdscript
func _on_run_started(kingdom_id: StringName) -> void:
    _last_biomass_sample = 0.0
    # ... existing code ...
```

## ARCHITECTURE.md updates

- §4 schema — add `PerRunGoalData`.
- §5 system map — add `RunGoalSystem`.
- §7 signals — add `goal_progress_changed` + `goal_met`.

## Acceptance criteria
- [ ] 12 `.tres` files exist with correct schema; `_index.tres` references all 12.
- [ ] `RunGoalSystem` autoload registered; cold load succeeds with no errors.
- [ ] Starting a plantae photosynthesizer run picks a goal from the niche-matching pool (sample many runs in dev; verify niche filter works).
- [ ] `get_active_goal()` returns the active goal; `get_progress()` returns 0.0 initially.
- [ ] Colonize 1 tile → `goal_progress_changed` emitted with value 1.
- [ ] Reach the target → `goal_met` emitted exactly once.
- [ ] Prestige resets goal state; new run picks a fresh goal.
- [ ] `save.json` after running: `run.goal_id` populated, `run.goal_progress.value` reflects ticker, `run.goal_met` flips when target hit.

## Out of scope
- Banner UI (brief 05).
- Goal-met → prestige button lights up (brief 05).
- Per-tile goals (e.g., "place a tile adjacent to X") — schema doesn't support locality yet.
- Goal rewards beyond the goal-met emit (no extra EP, no extra discovery entry — that's a polish add).
- `corpses_decomposed` tracker (would need a new CorpseSystem signal; defer to Phase 12 if `decomposer_corpses` proxy is too loose).
