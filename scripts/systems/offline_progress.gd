extends Node

const MAX_OFFLINE_SECONDS: float = 8.0 * 60.0 * 60.0


func _ready() -> void:
	EventBus.run_loaded.connect(_on_run_loaded)
	# Catch-up: SaveSystem may have emitted run_loaded before world.tscn loaded.
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
	var ticks: int = int(elapsed * TickClock.tick_hz)
	if ticks <= 0:
		return
	EventBus.replay_started.emit(ticks)
	TickClock.force_tick(ticks)
	EventBus.replay_finished.emit()
