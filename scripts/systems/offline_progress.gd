extends Node

const MAX_OFFLINE_SECONDS: float = 8.0 * 60.0 * 60.0
const MAX_SIM_TICKS: int = 300
const RATE_SAMPLE_TICKS: int = 10


func _ready() -> void:
	EventBus.run_loaded.connect(_on_run_loaded)
	if GameState.last_save_unix > 0:
		_on_run_loaded(SaveSystem.SAVE_VERSION)


func _on_run_loaded(_save_version: int) -> void:
	var last_save: int = GameState.last_save_unix
	if last_save <= 0:
		return
	var now: int = int(Time.get_unix_time_from_system())
	var elapsed: float = float(max(0, now - last_save))
	if elapsed <= 0.0:
		return
	elapsed = min(elapsed, MAX_OFFLINE_SECONDS)
	var total_ticks: int = int(elapsed * TickClock.tick_hz)
	if total_ticks <= 0:
		return

	var before: float = GameState.get_hero_biomass()
	EventBus.replay_started.emit(total_ticks)

	var sim_ticks: int = mini(total_ticks, MAX_SIM_TICKS)
	TickClock.force_tick(sim_ticks)

	var remaining: int = total_ticks - sim_ticks
	if remaining > 0:
		_extrapolate(remaining)

	EventBus.replay_finished.emit()
	var gained: float = GameState.get_hero_biomass() - before
	if gained > 0.0:
		EventBus.offline_summary.emit(gained)


func _extrapolate(remaining_ticks: int) -> void:
	var before: float = GameState.get_hero_biomass()
	var sample_count: int = mini(RATE_SAMPLE_TICKS, remaining_ticks)
	TickClock.force_tick(sample_count)
	remaining_ticks -= sample_count
	if remaining_ticks <= 0:
		return

	var after: float = GameState.get_hero_biomass()
	var rate_per_tick: float = (after - before) / float(sample_count)

	_advance_tick_count(remaining_ticks)

	if rate_per_tick > 0.0:
		var current: float = float(GameState.run_save.get("hero_biomass_lifetime_produced", 0.0))
		GameState.run_save["hero_biomass_lifetime_produced"] = current + rate_per_tick * float(remaining_ticks)

	TickClock.force_tick(1)


func _advance_tick_count(ticks: int) -> void:
	var stats: Dictionary = GameState.run_save.get("statistics", {}) as Dictionary
	stats["tick_count"] = int(stats.get("tick_count", 0)) + ticks
	GameState.run_save["statistics"] = stats
