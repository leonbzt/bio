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


static func calculate_prestige_reward(biomass: float, cycle_closed: bool, tier_mult: float = 1.0) -> int:
	var reproductions: int = int(biomass / 100.0)
	var closure_bonus: int = 50 if cycle_closed else 0
	return int(round((reproductions + closure_bonus) * tier_mult))


func get_pending_reward() -> int:
	var biomass: float = float(GameState.run_save.get("hero_biomass_lifetime_produced", 0.0))
	var closed: bool = bool(GameState.run_save.get("cycle_closed", false))
	return calculate_prestige_reward(biomass, closed, 1.0)


func trigger_prestige() -> void:
	var bonus_ep: int = _award_extinction_survivor_bonus_if_eligible()
	var biomass: float = float(GameState.run_save.get("hero_biomass_lifetime_produced", 0.0))
	var closed: bool = bool(GameState.run_save.get("cycle_closed", false))
	var reward: int = calculate_prestige_reward(biomass, closed, 1.0) + bonus_ep
	var reproductions: int = int(biomass / 100.0)
	_record_kingdom_played()
	_record_species_played()
	_update_meta_stats(reward, biomass)
	_append_lineage_run(biomass, reproductions, closed, reward)
	var summary := {
		"evolution_points_earned": reward,
		"extinction_bonus": bonus_ep,
		"biomass": biomass,
		"reproductions": reproductions,
		"cycle_closed": closed
	}
	_reset_run_state()
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
	if not is_node_purchasable(node):
		return false
	var cost: int = int(node.meta_cost.get("evolution_points", 0))
	var balance: int = get_evolution_points_balance()
	if balance < cost:
		return false
	_set_balance(balance - cost)
	_set_node_unlocked(node_id, true)
	for kingdom_id in node.grants_kingdoms:
		_unlock_kingdom(kingdom_id)
	for species_id in node.grants_species:
		_unlock_species(species_id)
	EventBus.evolution_node_unlocked.emit(node_id)
	SaveSystem.save_now()
	return true


func start_run(species: SpeciesData) -> void:
	if species == null:
		return
	if not _is_kingdom_available_in_current_era(species.kingdom_id):
		push_warning("PrestigeSystem: kingdom %s is not available in the current era" % String(species.kingdom_id))
		return
	GameState.current_kingdom_id = species.kingdom_id
	_reset_run_state()
	var run: Dictionary = GameState.run_save
	run["kingdom_id"] = String(species.kingdom_id)
	run["starting_species_id"] = String(species.id)
	run["unlocked_species_in_run"] = [String(species.id)]
	run["starting_species_kingdom_id"] = String(species.kingdom_id)
	GameState.run_save = run
	GameState.run_seed = randi()
	GameState.is_run_active = true
	GameState.placement_target_species_id = species.id
	EventBus.placement_target_changed.emit(String(species.id))
	EventBus.run_started.emit(species.kingdom_id)
	EventBus.species_introduced.emit(species.id)
	SaveSystem.save_now()


func _is_kingdom_available_in_current_era(kingdom_id: StringName) -> bool:
	if not has_node("/root/EraSystem"):
		return true
	var era_system: Node = get_node("/root/EraSystem")
	if not era_system.has_method("get_current_era"):
		return true
	var era: EraData = era_system.get_current_era()
	if era == null:
		return true
	if era.available_kingdoms.is_empty():
		return true
	return era.available_kingdoms.has(kingdom_id)


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


func is_node_purchasable(node: EvolutionNodeData) -> bool:
	return _node_purchase_block_reason(node) == ""


func get_node_purchase_block_reason(node_id: StringName) -> String:
	var node: EvolutionNodeData = _find_node(node_id)
	if node == null:
		return ""
	return _node_purchase_block_reason(node)


func _find_node(id: StringName) -> EvolutionNodeData:
	return _nodes_by_id.get(id, null)


func _node_purchase_block_reason(node: EvolutionNodeData) -> String:
	if node.id == &"mass_fruiting":
		return "coming_phase_15"
	if node.id == &"extinction_survivor":
		var completed: Array = GameState.meta_save.get("first_run_in_era_completed", []) as Array
		if completed.is_empty():
			return "requires_first_transition"
	if node.requires_era == &"":
		return ""
	var current_era: StringName = StringName(GameState.meta_save.get("current_era_id", ""))
	if current_era != node.requires_era:
		return "requires_era"
	return ""


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


func _unlock_species(species_id: StringName) -> void:
	var unlocked: Array = GameState.meta_save.get("species_unlocked", []) as Array
	var species_id_str: String = String(species_id)
	if not unlocked.has(species_id_str):
		unlocked.append(species_id_str)
	GameState.meta_save["species_unlocked"] = unlocked


func _update_meta_stats(reward: int, earned_this_run: float) -> void:
	var stats: Dictionary = GameState.meta_save.get("statistics", {}) as Dictionary
	stats["prestige_count"] = int(stats.get("prestige_count", 0)) + 1
	stats["evolution_points_balance"] = int(stats.get("evolution_points_balance", 0)) + reward
	stats["total_biomass_lifetime"] = float(stats.get("total_biomass_lifetime", 0.0)) + earned_this_run
	GameState.meta_save["statistics"] = stats


func _record_kingdom_played() -> void:
	var kid: String = String(GameState.run_save.get("starting_species_kingdom_id", ""))
	if kid == "":
		return
	var played: Array = GameState.meta_save.get("kingdoms_played", []) as Array
	if not played.has(kid):
		played.append(kid)
	GameState.meta_save["kingdoms_played"] = played


func _record_species_played() -> void:
	var starter: String = String(GameState.run_save.get("starting_species_id", ""))
	if starter == "":
		return
	var played: Array = GameState.meta_save.get("species_played", []) as Array
	if not played.has(starter):
		played.append(starter)
		GameState.meta_save["species_played"] = played


func _reset_run_state() -> void:
	var fresh_run := {
		"kingdom_id": "",
		"starting_species_id": "",
		"starting_species_kingdom_id": "",
		"unlocked_species_in_run": [],
		"run_seed": 0,
		"tick_count": 0,
		"adaptation": 0.0,
		"species_levels": {},
		"biome_map": {},
		"tiles": [],
		"organisms": [],
		"active_events": [],
		"event_first_fires_seen": [],
		"spore_distribution_charges": 0,
		"goal_id": "",
		"goal_progress": {},
		"goal_met": false,
		"hero_biomass_lifetime_produced": 0.0,
		"cycle_closed": false,
		"checkpoints_fired": {},
		"statistics": {
			"total_biomass_earned": 0.0,
			"tiles_colonized": 0,
			"waves_defeated": 0
		}
	}
	GameState.run_save = fresh_run
	GameState.is_run_active = false
	GameState.current_kingdom_id = &""
	GameState.placement_target_species_id = &""
	GameState.input_mode = GameState.INPUT_MODE_COLONIZE
	EventBus.run_loaded.emit(SaveSystem.SAVE_VERSION)


func _award_extinction_survivor_bonus_if_eligible() -> int:
	var pe: Dictionary = GameState.meta_save.get("post_extinction", {}) as Dictionary
	if pe.is_empty():
		return 0
	var to_era: String = String(pe.get("to_era_id", ""))
	var current_era: String = String(GameState.meta_save.get("current_era_id", ""))
	if to_era != current_era:
		return 0
	var completed: Array = GameState.meta_save.get("first_run_in_era_completed", []) as Array
	if completed.has(to_era):
		return 0
	completed.append(to_era)
	GameState.meta_save["first_run_in_era_completed"] = completed
	GameState.meta_save["post_extinction"] = {}
	# Direct unlock call: discovery_unlocked is an OUTPUT signal fired by
	# DiscoveryLog.unlock() — emitting it here would bypass the registry
	# and leave the entry locked.
	if has_node("/root/DiscoveryLog"):
		var dl: Node = get_node("/root/DiscoveryLog")
		if dl.has_method("unlock"):
			dl.unlock(&"disc_milestone_extinction_survivor")
	return 25


func _append_lineage_run(biomass: float, reproductions: int, cycle_closed: bool, evolution_earned: int) -> void:
	var runs: Array = GameState.meta_save.get("lineage_runs", []) as Array
	var run_index: int = runs.size() + 1
	runs.append({
		"run_index": run_index,
		"date_unix": int(Time.get_unix_time_from_system()),
		"biomass": biomass,
		"reproductions": reproductions,
		"cycle_closed": cycle_closed,
		"evolution_earned": evolution_earned
	})
	GameState.meta_save["lineage_runs"] = runs
