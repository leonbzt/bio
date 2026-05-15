# Brief 04 — PrestigeSystem

**Suggested agent**: ChatGPT 5.2 via Copilot. **Route diff to Claude** — touches save state and the run lifecycle.

Read first:
1. `docs/ARCHITECTURE.md` § 3 (signals: `prestige_triggered`, `run_started`, `evolution_node_unlocked`), § 5 (PrestigeSystem row), `meta.*` save shape.
2. `scripts/systems/run_stats_tracker.gd` (brief 02) — provides `total_biomass_earned`.
3. `scripts/autoloads/resource_ledger.gd` — has `reset_run()`.
4. `scripts/systems/territory_system.gd` — has `reset_run()`.

## Goal
A system that:
1. Calculates prestige reward (evolution points) from the current run's stats.
2. Resets per-run state (resources, tiles, biome_map, organisms, active_events, run.statistics).
3. Updates lifetime meta stats (prestige_count, total_biomass_lifetime, evolution_points_balance).
4. Exposes `purchase_node(id)` for the evolution tree UI (brief 06) to call.
5. Exposes `start_run(kingdom_id)` to begin a new run with the chosen kingdom.

PrestigeSystem itself doesn't render UI; brief 06 does.

## Outputs (create)
- `scripts/systems/prestige_system.gd`
- Modification to `scenes/world/world.tscn` — add `PrestigeSystem` node under `Systems`, late in the list (after `RunStatsTracker`).

## Implementation

### EP formula
```gdscript
static func calculate_prestige_reward(total_biomass_earned: float) -> int:
    return int(sqrt(maxf(0.0, total_biomass_earned) / 10.0))
```
At 100 earned → 3 EP, 1000 → 10 EP, 10000 → 31 EP. Diminishing returns. Tune in Phase 7 if needed.

### Public API
```gdscript
func get_pending_reward() -> int:
    var earned: float = float(GameState.run_save.get("statistics", {}).get("total_biomass_earned", 0.0))
    return calculate_prestige_reward(earned)


func trigger_prestige() -> void:
    var reward: int = get_pending_reward()
    var earned: float = float(GameState.run_save.get("statistics", {}).get("total_biomass_earned", 0.0))
    _update_meta_stats(reward, earned)
    _reset_run_state()
    var summary := {
        "evolution_points_earned": reward,
        "total_biomass_earned": earned,
    }
    EventBus.prestige_triggered.emit(summary)
    SaveSystem.save_now()


func purchase_node(node_id: StringName) -> bool:
    var node := _find_node(node_id)
    if node == null:
        return false
    if is_node_unlocked(node_id):
        return false
    if not _prerequisites_met(node):
        return false
    var cost: int = int(node.meta_cost.get("evolution_points", 0))
    var balance: int = get_evolution_points_balance()
    if balance < cost:
        return false
    _set_balance(balance - cost)
    _set_node_unlocked(node_id, true)
    for kingdom_id in node.grants_kingdoms:
        _unlock_kingdom(kingdom_id)
    EventBus.evolution_node_unlocked.emit(node_id)
    SaveSystem.save_now()
    return true


func start_run(kingdom_id: StringName) -> void:
    if not is_kingdom_unlocked(kingdom_id):
        return
    GameState.current_kingdom_id = kingdom_id
    GameState.run_seed = randi()
    GameState.is_run_active = true
    EventBus.run_started.emit(kingdom_id)
    SaveSystem.save_now()


func is_node_unlocked(node_id: StringName) -> bool:
    var tree: Dictionary = GameState.meta_save.get("evolution_tree", {})
    return bool(tree.get(String(node_id), false))


func is_kingdom_unlocked(kingdom_id: StringName) -> bool:
    var kingdoms: Array = GameState.meta_save.get("unlocked_kingdoms", [])
    return kingdoms.has(String(kingdom_id))


func get_evolution_points_balance() -> int:
    return int(GameState.meta_save.get("statistics", {}).get("evolution_points_balance", 0))


func get_all_nodes() -> Array[EvolutionNodeData]:
    # For the UI — returns nodes loaded from the index.
    return _all_nodes
```

### Helpers
```gdscript
const EVOLUTION_INDEX_PATH := "res://data/evolution_tree/_index.tres"
var _all_nodes: Array[EvolutionNodeData] = []
var _nodes_by_id: Dictionary[StringName, EvolutionNodeData] = {}


func _ready() -> void:
    var index: EvolutionTreeIndex = load(EVOLUTION_INDEX_PATH) as EvolutionTreeIndex
    if index == null:
        push_error("PrestigeSystem: missing evolution tree index")
        return
    _all_nodes = index.nodes
    for node in _all_nodes:
        _nodes_by_id[node.id] = node


func _find_node(id: StringName) -> EvolutionNodeData:
    return _nodes_by_id.get(id, null)


func _prerequisites_met(node: EvolutionNodeData) -> bool:
    for prereq in node.prerequisites:
        if not is_node_unlocked(prereq):
            return false
    return true


func _set_node_unlocked(id: StringName, unlocked: bool) -> void:
    var meta: Dictionary = GameState.meta_save
    var tree: Dictionary = meta.get("evolution_tree", {}) as Dictionary
    tree[String(id)] = unlocked
    meta["evolution_tree"] = tree


func _set_balance(new_balance: int) -> void:
    var stats: Dictionary = GameState.meta_save.get("statistics", {}) as Dictionary
    stats["evolution_points_balance"] = new_balance
    GameState.meta_save["statistics"] = stats


func _unlock_kingdom(kingdom_id: StringName) -> void:
    var kingdoms: Array = GameState.meta_save.get("unlocked_kingdoms", []) as Array
    if not kingdoms.has(String(kingdom_id)):
        kingdoms.append(String(kingdom_id))
    GameState.meta_save["unlocked_kingdoms"] = kingdoms


func _update_meta_stats(reward: int, earned_this_run: float) -> void:
    var stats: Dictionary = GameState.meta_save.get("statistics", {}) as Dictionary
    stats["prestige_count"] = int(stats.get("prestige_count", 0)) + 1
    stats["evolution_points_balance"] = int(stats.get("evolution_points_balance", 0)) + reward
    stats["total_biomass_lifetime"] = float(stats.get("total_biomass_lifetime", 0.0)) + earned_this_run
    GameState.meta_save["statistics"] = stats
```

### `_reset_run_state()`
This is the dangerous part. Must clear:
- `ResourceLedger.reset_run()` (already exists)
- `TerritorySystem.reset_run()` (already exists; pass null kingdom or signal it via run_started)
- The `run` dict itself — rebuild from scratch with all the v3 default fields.

Cleanest path: replace `GameState.run_save` with a fresh default dict (matching SaveSystem._build_default_save's `run` block), then call each system's reset. Then emit `run_loaded` so systems re-hydrate from the cleared state. Be careful: `run_loaded` triggers full hydration paths — that's fine because run_save is now defaulted.

```gdscript
func _reset_run_state() -> void:
    var fresh_run := {
        "kingdom_id": "",
        "run_seed": 0,
        "tick_count": 0,
        "resources": {},
        "biome_map": {},
        "tiles": [],
        "organisms": [],
        "active_events": [],
        "statistics": {
            "total_biomass_earned": 0.0,
            "tiles_colonized": 0,
            "waves_defeated": 0,
        }
    }
    GameState.run_save = fresh_run
    GameState.is_run_active = false
    ResourceLedger.reset_run()
    # Re-emit run_loaded so all world systems rehydrate from the empty state.
    # NutrientSystem will regenerate biome_map on the next run_started.
    EventBus.run_loaded.emit(SaveSystem.SAVE_VERSION)
```

Some systems (TerritorySystem, NutrientSystem, HerbivoreManager) listen to `run_loaded` and will clear their state appropriately. RunStatsTracker also resets. ResourceLedger's reset already zeroes.

## Acceptance criteria
- [ ] `get_pending_reward()` returns a non-negative integer matching the formula.
- [ ] `trigger_prestige()` increments `prestige_count`, increases `evolution_points_balance` by the reward, adds the run's `total_biomass_earned` to `total_biomass_lifetime`, clears run state, emits `prestige_triggered`.
- [ ] `purchase_node(id)` correctly validates prereqs, balance, and prevents double-purchase.
- [ ] Buying `unlock_fungi` adds `&"fungi"` to `meta.unlocked_kingdoms`.
- [ ] `start_run("plantae")` sets the kingdom and emits `run_started`.
- [ ] After prestige, owned tiles are gone, biomass = 0, biome_map regenerates on the next colonize/tick path.
- [ ] No data leaks between runs (tiles, organisms, active_events all empty after prestige).

## Out of scope
- The UI (brief 06).
- Kingdom-specific gameplay differences (Phase 5).
- Refunding spent EP. Unlocks are permanent.
