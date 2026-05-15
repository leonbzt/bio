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
		EventBus.tick.emit(tick_interval)
		_accumulator -= tick_interval


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
		EventBus.tick.emit(tick_interval)
