extends Node

const THROUGHPUT_THRESHOLD: float = 8.0
const SUSTAINED_TICKS_TARGET: int = 45
const RATE_WINDOW: int = 10

var _rate_history: Array[float] = []
var _last_biomass: float = 0.0
var _sustained_ticks: int = 0


func _ready() -> void:
	EventBus.run_started.connect(_on_run_started)
	EventBus.run_loaded.connect(_on_run_loaded)
	EventBus.tick.connect(_on_tick)


func get_progress() -> float:
	return minf(1.0, float(_sustained_ticks) / float(SUSTAINED_TICKS_TARGET))


func get_sustained_ticks() -> int:
	return _sustained_ticks


func get_current_rate() -> float:
	if _rate_history.is_empty():
		return 0.0
	var total: float = 0.0
	for d in _rate_history:
		total += d
	return (total / float(_rate_history.size())) * TickClock.tick_hz


func is_met() -> bool:
	var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
	return bool(run.get("goal_met", false))


func _on_run_started(_kingdom_id: StringName) -> void:
	_rate_history.clear()
	_sustained_ticks = 0
	_last_biomass = GameState.get_hero_biomass()
	var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
	run["goal_id"] = "throughput_v1"
	run["goal_met"] = false
	GameState.run_save = run


func _on_run_loaded(_save_version: int) -> void:
	_rate_history.clear()
	_sustained_ticks = 0
	_last_biomass = GameState.get_hero_biomass()


func _on_tick(_delta: float) -> void:
	var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
	if bool(run.get("goal_met", false)):
		return

	var current: float = GameState.get_hero_biomass()
	var delta_biomass: float = current - _last_biomass
	_last_biomass = current

	_rate_history.push_back(delta_biomass)
	if _rate_history.size() > RATE_WINDOW:
		_rate_history.pop_front()

	var rate: float = get_current_rate()
	var cycle_closed: bool = bool(run.get("cycle_closed", false))

	if cycle_closed and rate >= THROUGHPUT_THRESHOLD:
		_sustained_ticks += 1
	else:
		_sustained_ticks = 0

	var progress: Dictionary = {
		"sustained": _sustained_ticks,
		"target": SUSTAINED_TICKS_TARGET,
		"rate": rate,
		"threshold": THROUGHPUT_THRESHOLD
	}
	EventBus.goal_progress_changed.emit(progress)

	if _sustained_ticks >= SUSTAINED_TICKS_TARGET:
		run["goal_met"] = true
		GameState.run_save = run
		EventBus.goal_met.emit()
