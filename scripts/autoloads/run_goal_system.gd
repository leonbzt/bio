extends Node
##
## RunGoalSystem — picks a per-run goal at start_run, tracks progress, emits when met.
##

const GOAL_INDEX_PATH: String = "res://data/goals/_index.tres"
const _NICHE_TO_SPECIES: Dictionary[StringName, StringName] = {
	&"photosynthesizer": &"pioneer_grass",
	&"decomposer": &"mycelium_thread",
	&"parasitic_plantae": &"bramble",
	&"mycorrhizal_fungi": &"mycelium_thread_mycorrhizal",
	&"lichen": &"lichen_common",
	&"herbivore": &"common_grazer",
	&"predator": &"common_predator"
}

var _all_goals: Array[PerRunGoalData] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _last_biomass_sample: float = 0.0


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
	_last_biomass_sample = 0.0
	_rng.seed = int(GameState.run_seed) ^ int(Time.get_unix_time_from_system())
	# Ecosystem override: each ecosystem can pin a specific goal so its banner
	# matches its completion criterion (Coal Swamp → "Fill the Coal Gauge"),
	# instead of rolling from the random pool.
	if has_node("/root/EraSystem"):
		var era_system: Node = get_node("/root/EraSystem")
		if era_system.has_method("get_current_ecosystem"):
			var eco: EcosystemData = era_system.get_current_ecosystem()
			if eco != null and eco.goal_id != &"":
				for goal in _all_goals:
					if goal.id == eco.goal_id:
						_set_goal(goal.id)
						return
	var starter_species: StringName = StringName(GameState.run_save.get("starting_species_id", ""))
	var candidates: Array[PerRunGoalData] = []
	for goal in _all_goals:
		if not goal.kingdoms.is_empty() and not goal.kingdoms.has(kingdom_id):
			continue
		if not goal.niches.is_empty():
			var niche_match: bool = false
			for niche_id in goal.niches:
				if _NICHE_TO_SPECIES.get(niche_id, &"") == starter_species:
					niche_match = true
					break
			if not niche_match:
				continue
		candidates.append(goal)
	if candidates.is_empty():
		candidates = _all_goals
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


func _on_tile_colonized(_coord: Vector2i, _owner: StringName) -> void:
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
