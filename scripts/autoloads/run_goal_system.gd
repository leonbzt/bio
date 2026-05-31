extends Node

const TARGET_BIOMASS: float = 15000.0


func _ready() -> void:
	EventBus.run_started.connect(_on_run_started)
	EventBus.tick.connect(_on_tick)


func get_progress() -> float:
	return minf(1.0, GameState.get_hero_biomass() / TARGET_BIOMASS)


func is_met() -> bool:
	var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
	return bool(run.get("goal_met", false))


func _on_run_started(_kingdom_id: StringName) -> void:
	var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
	run["goal_id"] = "prototype_v1"
	run["goal_progress"] = {"value": 0.0, "target": TARGET_BIOMASS}
	run["goal_met"] = false
	GameState.run_save = run
	EventBus.goal_progress_changed.emit({"value": 0.0, "target": TARGET_BIOMASS})


func _on_tick(_delta: float) -> void:
	var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
	var biomass: float = GameState.get_hero_biomass()
	run["goal_progress"] = {"value": biomass, "target": TARGET_BIOMASS}
	EventBus.goal_progress_changed.emit({"value": biomass, "target": TARGET_BIOMASS})
	if bool(run.get("goal_met", false)):
		GameState.run_save = run
		return
	var cycle_done: bool = bool(run.get("cycle_closed", false))
	if biomass >= TARGET_BIOMASS and cycle_done:
		run["goal_met"] = true
		EventBus.goal_met.emit()
	GameState.run_save = run
