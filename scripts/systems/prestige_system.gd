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
	_record_kingdom_played()
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
	if not _kingdoms_played_satisfied(node):
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


func start_run(kingdom_id: StringName, niche_id: StringName = &"") -> void:
	if not is_kingdom_unlocked(kingdom_id):
		return
	var resolved_niche: StringName = _resolve_niche(kingdom_id, niche_id)
	if resolved_niche == &"":
		push_error("PrestigeSystem: no valid niche for kingdom %s" % String(kingdom_id))
		return
	GameState.current_kingdom_id = kingdom_id
	GameState.current_niche_id = resolved_niche
	if GameState.run_save is Dictionary:
		GameState.run_save["kingdom_id"] = String(kingdom_id)
		GameState.run_save["niche_id"] = String(resolved_niche)
		if MetaModifiers.is_unlocked(&"spore_distribution"):
			GameState.run_save["spore_distribution_charges"] = 3
		else:
			GameState.run_save["spore_distribution_charges"] = 0
	GameState.run_seed = randi()
	GameState.is_run_active = true
	GameState.placement_target = kingdom_id
	EventBus.placement_target_changed.emit(GameState.placement_target)
	EventBus.niche_changed.emit(resolved_niche)
	EventBus.run_started.emit(kingdom_id)
	_apply_conditional_start_bonus(resolved_niche)
	SaveSystem.save_now()


func _resolve_niche(kingdom_id: StringName, requested: StringName) -> StringName:
	var niches: Array[NicheData] = get_niches_for_kingdom(kingdom_id, true)
	if niches.is_empty():
		return &""
	if requested != &"":
		for niche in niches:
			if niche.id == requested:
				return requested
	return niches[0].id


func get_niches_for_kingdom(kingdom_id: StringName, only_unlocked: bool = true) -> Array[NicheData]:
	var index := load("res://data/niches/_index.tres")
	if index == null or not (index is NicheIndex):
		return []
	var result: Array[NicheData] = []
	for niche in (index as NicheIndex).niches:
		if niche == null:
			continue
		if niche.kingdom_id != kingdom_id:
			continue
		if only_unlocked and niche.unlock_node_id != &"":
			if not MetaModifiers.is_unlocked(niche.unlock_node_id):
				continue
		result.append(niche)
	return result


func _get_niche_by_id(niche_id: StringName) -> NicheData:
	var index := load("res://data/niches/_index.tres")
	if index == null or not (index is NicheIndex):
		return null
	for niche in (index as NicheIndex).niches:
		if niche != null and niche.id == niche_id:
			return niche
	return null


func _apply_conditional_start_bonus(niche_id: StringName) -> void:
	var niche := _get_niche_by_id(niche_id)
	if niche == null:
		return
	if niche.conditional_start_bonus.is_empty():
		return
	if niche.conditional_start_bonus_requires != &"" and not MetaModifiers.is_unlocked(niche.conditional_start_bonus_requires):
		return
	for key in niche.conditional_start_bonus.keys():
		var amount: float = float(niche.conditional_start_bonus[key])
		if amount == 0.0:
			continue
		ResourceLedger.add(StringName(key), amount)


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


func get_unsatisfied_kingdoms(node_id: StringName) -> Array[StringName]:
	var node := _find_node(node_id)
	if node == null:
		return []
	var played: Array = GameState.meta_save.get("kingdoms_played", [])
	var missing: Array[StringName] = []
	for required in node.requires_kingdom_played:
		if not played.has(String(required)):
			missing.append(required)
	return missing


func _find_node(id: StringName) -> EvolutionNodeData:
	return _nodes_by_id.get(id, null)


func _prerequisites_met(node: EvolutionNodeData) -> bool:
	for prereq in node.prerequisites:
		if not is_node_unlocked(prereq):
			return false
	return true


func _kingdoms_played_satisfied(node: EvolutionNodeData) -> bool:
	if node.requires_kingdom_played.is_empty():
		return true
	var played: Array = GameState.meta_save.get("kingdoms_played", [])
	for required in node.requires_kingdom_played:
		if not played.has(String(required)):
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


func _record_kingdom_played() -> void:
	var kid: String = String(GameState.run_save.get("kingdom_id", ""))
	if kid == "":
		return
	var played: Array = GameState.meta_save.get("kingdoms_played", []) as Array
	if not played.has(kid):
		played.append(kid)
	GameState.meta_save["kingdoms_played"] = played


func _reset_run_state() -> void:
	var fresh_run := {
		"kingdom_id": "",
		"niche_id": "",
		"run_seed": 0,
		"tick_count": 0,
		"resources": {
			"biomass": 0.0,
			"nutrients": 0.0,
			"sunlight": 0.0,
			"decay": 0.0,
			"spores": 0.0,
			"population_pressure": 0.0,
			"protein": 0.0,
			"lifeforce": 0.0,
			"blood_cohesion": 0.0,
			"gray_matter": 0.0,
			"mycelial_stability": 0.0
		},
		"biome_map": {},
		"tiles": [],
		"organisms": [],
		"active_events": [],
		"event_first_fires_seen": [],
		"spore_distribution_charges": 0,
		"goal_id": "",
		"goal_progress": {},
		"goal_met": false,
		"statistics": {
			"total_biomass_earned": 0.0,
			"tiles_colonized": 0,
			"waves_defeated": 0
		}
	}
	GameState.run_save = fresh_run
	GameState.is_run_active = false
	GameState.current_kingdom_id = &""
	GameState.current_niche_id = &""
	GameState.placement_target = &""
	ResourceLedger.reset_run()
	EventBus.niche_changed.emit(&"")
	EventBus.run_loaded.emit(SaveSystem.SAVE_VERSION)
