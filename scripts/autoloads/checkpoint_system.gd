extends Node

const CHECKPOINT_PLACE_HERO: StringName = &"place_hero"
const CHECKPOINT_PLACE_RECYCLER: StringName = &"place_recycler"
const CHECKPOINT_PLACE_HARVESTER: StringName = &"place_harvester"
const CHECKPOINT_BOTTLENECK_NUTRIENTS: StringName = &"bottleneck_nutrients"
const CHECKPOINT_BOTTLENECK_DETRITUS: StringName = &"bottleneck_detritus"
const CHECKPOINT_RUN_COMPLETE: StringName = &"run_complete"
const CHECKPOINT_ORDER: Array[StringName] = [
	CHECKPOINT_PLACE_HERO,
	CHECKPOINT_PLACE_RECYCLER,
	CHECKPOINT_PLACE_HARVESTER,
	CHECKPOINT_BOTTLENECK_NUTRIENTS,
	CHECKPOINT_BOTTLENECK_DETRITUS,
	CHECKPOINT_RUN_COMPLETE
]

const CHECKPOINT_PREREQS: Dictionary[StringName, Array] = {
	CHECKPOINT_PLACE_RECYCLER: [CHECKPOINT_PLACE_HERO],
	CHECKPOINT_PLACE_HARVESTER: [CHECKPOINT_PLACE_RECYCLER],
	CHECKPOINT_BOTTLENECK_NUTRIENTS: [CHECKPOINT_PLACE_RECYCLER],
	CHECKPOINT_BOTTLENECK_DETRITUS: [CHECKPOINT_PLACE_HARVESTER],
	CHECKPOINT_RUN_COMPLETE: [CHECKPOINT_PLACE_HARVESTER]
}

var _fired: Dictionary[StringName, bool] = {}
var _bottleneck_age_ticks: Dictionary[StringName, int] = {}
var _species_cache: Dictionary[StringName, SpeciesData] = {}


func _ready() -> void:
	_build_species_cache()
	EventBus.run_started.connect(_on_run_started)
	EventBus.run_loaded.connect(_on_run_loaded)
	EventBus.tick.connect(_on_tick)
	_on_run_loaded(SaveSystem.SAVE_VERSION)


func _build_species_cache() -> void:
	_species_cache.clear()
	var index: SpeciesIndex = load("res://data/species/_index.tres") as SpeciesIndex
	if index == null:
		return
	for species in index.species:
		if species != null:
			_species_cache[species.id] = species


func _on_run_started(_kingdom_id: StringName) -> void:
	_fired.clear()
	_bottleneck_age_ticks.clear()
	GameState.run_save["checkpoints_fired"] = {}
	_fire(CHECKPOINT_PLACE_HERO)


func _on_run_loaded(_save_version: int) -> void:
	_fired.clear()
	_bottleneck_age_ticks.clear()
	var raw: Dictionary = GameState.run_save.get("checkpoints_fired", {}) as Dictionary
	for id in raw.keys():
		if bool(raw[id]):
			_fired[StringName(id)] = true


func _on_tick(_delta: float) -> void:
	_evaluate(CHECKPOINT_PLACE_RECYCLER, _has_role_placed(&"recycler"))
	_evaluate(CHECKPOINT_PLACE_HARVESTER, _has_role_placed(&"harvester"))
	_evaluate(CHECKPOINT_BOTTLENECK_NUTRIENTS, _bottleneck_nutrients_ready())
	_evaluate(CHECKPOINT_BOTTLENECK_DETRITUS, _bottleneck_detritus_ready())
	_evaluate(CHECKPOINT_RUN_COMPLETE, _run_complete_ready())


func _evaluate(id: StringName, ready: bool) -> void:
	if not _can_consider(id):
		return
	if ready:
		_fire(id)


func _can_consider(id: StringName) -> bool:
	var prereqs: Array = CHECKPOINT_PREREQS.get(id, [])
	for prereq in prereqs:
		if not _fired.get(prereq, false):
			return false
	return true


func _fire(id: StringName) -> void:
	if _fired.get(id, false):
		return
	_fired[id] = true
	var persisted: Dictionary = GameState.run_save.get("checkpoints_fired", {}) as Dictionary
	persisted[String(id)] = true
	GameState.run_save["checkpoints_fired"] = persisted
	EventBus.checkpoint_triggered.emit(id, {})
	SaveSystem.save_now()


func _has_role_placed(role: StringName) -> bool:
	var territory: Node = _get_territory_system()
	if territory == null:
		return false
	var unlocked: Array = GameState.run_save.get("unlocked_species_in_run", []) as Array
	for species_id_str in unlocked:
		var species_id: StringName = StringName(species_id_str)
		var species: SpeciesData = _species_cache.get(species_id, null)
		if species != null and species.role == role:
			var coords: Array = territory.get_species_occupied_coords(species_id)
			if not coords.is_empty():
				return true
	return false




func _bottleneck_nutrients_ready() -> bool:
	if not bool(GameState.run_save.get("cycle_closed", false)):
		_bottleneck_age_ticks[CHECKPOINT_BOTTLENECK_NUTRIENTS] = 0
		return false
	return _age_starvation(CHECKPOINT_BOTTLENECK_NUTRIENTS, _long_grace_ticks())


func _bottleneck_detritus_ready() -> bool:
	if not bool(GameState.run_save.get("cycle_closed", false)):
		_bottleneck_age_ticks[CHECKPOINT_BOTTLENECK_DETRITUS] = 0
		return false
	return _age_starvation(CHECKPOINT_BOTTLENECK_DETRITUS, _long_grace_ticks())


func _run_complete_ready() -> bool:
	return RunGoalSystem.is_met()


func _age_starvation(id: StringName, grace_ticks: int) -> bool:
	var starving: bool = _any_tile_starving()
	if starving:
		_bottleneck_age_ticks[id] = int(_bottleneck_age_ticks.get(id, 0)) + 1
	else:
		_bottleneck_age_ticks[id] = 0
	return int(_bottleneck_age_ticks.get(id, 0)) >= grace_ticks


func _any_tile_starving() -> bool:
	var growth: Node = _get_growth_system()
	if growth == null or not growth.has_method("get_tile_input_satisfaction"):
		return false
	var territory: Node = _get_territory_system()
	if territory == null:
		return false
	var all_coords: Array = territory.get_all_owned_coords()
	var starving_count: int = 0
	for coord in all_coords:
		if float(growth.get_tile_input_satisfaction(coord)) < 0.3:
			starving_count += 1
	return starving_count >= 3


func _get_growth_system() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null("World/Systems/GrowthSystem")


func _get_territory_system() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null("World/Systems/TerritorySystem")


func _long_grace_ticks() -> int:
	return int(round(300.0 * TickClock.tick_hz))
