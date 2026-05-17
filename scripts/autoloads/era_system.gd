extends Node
##
## EraSystem — owns era + ecosystem state, tracks per-run completion criteria,
## unlocks the next era when the current era is fully complete.
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
	EventBus.run_loaded.connect(_on_run_loaded_initial_emit)


func _on_run_loaded_initial_emit(_save_version: int) -> void:
	# Fire era_changed once on save load so DiscoveryLog can unlock the
	# current era's entry the first time it's seen.
	var era := get_current_era()
	if era != null:
		EventBus.era_changed.emit(era.id)


func _load_indexes() -> void:
	_eras_by_id.clear()
	var era_index := load(ERA_INDEX_PATH)
	if era_index is EraIndex:
		for era in (era_index as EraIndex).eras:
			if era != null:
				_eras_by_id[era.id] = era
	else:
		push_error("EraSystem: missing era index at %s" % ERA_INDEX_PATH)

	_ecosystems_by_id.clear()
	var eco_index := load(ECOSYSTEM_INDEX_PATH)
	if eco_index is EcosystemIndex:
		for eco in (eco_index as EcosystemIndex).ecosystems:
			if eco != null:
				_ecosystems_by_id[eco.id] = eco
	else:
		push_error("EraSystem: missing ecosystem index at %s" % ECOSYSTEM_INDEX_PATH)


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


func get_all_eras() -> Array[EraData]:
	var result: Array[EraData] = []
	# Iterate the era index in declared order for stable UI.
	var era_index := load(ERA_INDEX_PATH)
	if era_index is EraIndex:
		for era in (era_index as EraIndex).eras:
			if era != null:
				result.append(era)
	return result


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
		if eco == null:
			continue
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


func get_criterion_progress() -> float:
	return _criterion_progress


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
			_emit_mass_extinction(completed_era_id, era.id)
			return


func _emit_mass_extinction(from_era: StringName, to_era: StringName) -> void:
	# Brief 08: narrative-only event fires alongside the era transition.
	var payload: Dictionary = {
		"scope": "world",
		"narrative_only": true,
		"from_era": String(from_era),
		"to_era": String(to_era)
	}
	EventBus.event_started.emit(&"mass_extinction", payload)
	EventBus.event_resolved.emit(&"mass_extinction", &"narrative")
