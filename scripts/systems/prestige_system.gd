extends Node

const EVOLUTION_INDEX_PATH: String = "res://data/evolution_tree/_index.tres"

var _all_nodes: Array[EvolutionNodeData] = []
var _nodes_by_id: Dictionary[StringName, EvolutionNodeData] = {}


func _ready() -> void:
	add_to_group("prestige_system")
	var index: EvolutionTreeIndex = load(EVOLUTION_INDEX_PATH) as EvolutionTreeIndex
	if index == null:
		push_error("PrestigeSystem: missing evolution tree index")
		return
	_all_nodes = index.nodes
	_nodes_by_id.clear()
	for node in _all_nodes:
		_nodes_by_id[node.id] = node


static func calculate_prestige_reward(total_biomass_earned: float) -> int:
	return int(sqrt(maxf(0.0, total_biomass_earned) / 10.0))


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
		"total_biomass_earned": earned
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
	if GameState.run_save is Dictionary:
		GameState.run_save["kingdom_id"] = String(kingdom_id)
	GameState.run_seed = randi()
	GameState.is_run_active = true
	if kingdom_id == &"symbiosis":
		GameState.placement_target = &"plantae"
	else:
		GameState.placement_target = kingdom_id
	EventBus.placement_target_changed.emit(GameState.placement_target)
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
	return _all_nodes


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
			"waves_defeated": 0
		}
	}
	GameState.run_save = fresh_run
	GameState.is_run_active = false
	GameState.current_kingdom_id = &""
	GameState.placement_target = &""
	ResourceLedger.reset_run()
	EventBus.run_loaded.emit(SaveSystem.SAVE_VERSION)
