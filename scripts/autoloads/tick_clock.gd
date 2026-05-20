extends Node
##
## TickClock — drives the simulation at a fixed rate (default 1 Hz).
## Subscribe to EventBus.tick to receive ticks. Implementation in brief 01.
##

var is_paused: bool = false
var tick_hz: float = 1.0
var _accumulator: float = 0.0


func _process(delta: float) -> void:
	if is_paused:
		return
	if tick_hz <= 0.0:
		return
	var tick_interval := 1.0 / tick_hz
	_accumulator += delta
	while _accumulator >= tick_interval:
		_increment_tick_count()
		EventBus.tick.emit(tick_interval)
		_accumulator -= tick_interval


# Phase 15a: increment per-run tick counter so tile age, cluster timing, and
# anything else that needs "ticks since run started" has a working clock.
func _increment_tick_count() -> void:
	if not (GameState.run_save is Dictionary):
		return
	var stats: Dictionary = GameState.run_save.get("statistics", {}) as Dictionary
	stats["tick_count"] = int(stats.get("tick_count", 0)) + 1
	GameState.run_save["statistics"] = stats


func pause() -> void:
	if is_paused:
		return
	is_paused = true
	EventBus.paused_changed.emit(true)


func resume() -> void:
	if not is_paused:
		return
	is_paused = false
	EventBus.paused_changed.emit(false)


func force_tick(n: int = 1) -> void:
	# Emits n ticks immediately, ignores pause. Used by OfflineProgress.
	if n <= 0:
		return
	if tick_hz <= 0.0:
		return
	var tick_interval := 1.0 / tick_hz
	for _i in range(n):
		_increment_tick_count()
		EventBus.tick.emit(tick_interval)
