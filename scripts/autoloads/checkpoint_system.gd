extends Node

const CHECKPOINT_PLACE_HERO: StringName = &"place_hero"
const CHECKPOINT_UNLOCK_MYCORRHIZAL: StringName = &"unlock_mycorrhizal"
const CHECKPOINT_UNLOCK_ARTHROPLEURA: StringName = &"unlock_arthropleura"
const CHECKPOINT_BOTTLENECK_NUTRIENTS: StringName = &"bottleneck_nutrients"
const CHECKPOINT_BOTTLENECK_DETRITUS: StringName = &"bottleneck_detritus"
const CHECKPOINT_RUN_COMPLETE: StringName = &"run_complete"
const CHECKPOINT_ORDER: Array[StringName] = [
	CHECKPOINT_PLACE_HERO,
	CHECKPOINT_UNLOCK_MYCORRHIZAL,
	CHECKPOINT_UNLOCK_ARTHROPLEURA,
	CHECKPOINT_BOTTLENECK_NUTRIENTS,
	CHECKPOINT_BOTTLENECK_DETRITUS,
	CHECKPOINT_RUN_COMPLETE
]

# Partial-order prereqs. Bottleneck checkpoints depend only on the matching
# unlock checkpoint, not on each other or on the prior bottleneck — so the
# happy path (no bottlenecks ever fire) doesn't block run_complete.
const CHECKPOINT_PREREQS: Dictionary[StringName, Array] = {
	CHECKPOINT_UNLOCK_MYCORRHIZAL: [CHECKPOINT_PLACE_HERO],
	CHECKPOINT_UNLOCK_ARTHROPLEURA: [CHECKPOINT_UNLOCK_MYCORRHIZAL],
	CHECKPOINT_BOTTLENECK_NUTRIENTS: [CHECKPOINT_UNLOCK_MYCORRHIZAL],
	CHECKPOINT_BOTTLENECK_DETRITUS: [CHECKPOINT_UNLOCK_ARTHROPLEURA],
	CHECKPOINT_RUN_COMPLETE: [CHECKPOINT_UNLOCK_ARTHROPLEURA]
}

var _fired: Dictionary[StringName, bool] = {}
var _bottleneck_age_ticks: Dictionary[StringName, int] = {}


func _ready() -> void:
	EventBus.run_started.connect(_on_run_started)
	EventBus.run_loaded.connect(_on_run_loaded)
	EventBus.tick.connect(_on_tick)
	_on_run_loaded(SaveSystem.SAVE_VERSION)


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
	_evaluate(CHECKPOINT_UNLOCK_MYCORRHIZAL, _unlock_mycorrhizal_ready())
	_evaluate(CHECKPOINT_UNLOCK_ARTHROPLEURA, _unlock_arthropleura_ready())
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


func _unlock_mycorrhizal_ready() -> bool:
	var hero_biomass: float = GameState.get_hero_biomass()
	var starvation: bool = _age_starvation(CHECKPOINT_UNLOCK_MYCORRHIZAL, ResourceLedger.NUTRIENTS, _short_grace_ticks())
	return hero_biomass >= 50.0 or starvation


func _unlock_arthropleura_ready() -> bool:
	var hero_biomass: float = GameState.get_hero_biomass()
	var starvation: bool = _age_starvation(CHECKPOINT_UNLOCK_ARTHROPLEURA, ResourceLedger.DECAY, _short_grace_ticks())
	return hero_biomass >= 500.0 or starvation


func _bottleneck_nutrients_ready() -> bool:
	if not bool(GameState.run_save.get("cycle_closed", false)):
		_bottleneck_age_ticks[CHECKPOINT_BOTTLENECK_NUTRIENTS] = 0
		return false
	return _age_starvation(CHECKPOINT_BOTTLENECK_NUTRIENTS, ResourceLedger.NUTRIENTS, _long_grace_ticks())


func _bottleneck_detritus_ready() -> bool:
	if not bool(GameState.run_save.get("cycle_closed", false)):
		_bottleneck_age_ticks[CHECKPOINT_BOTTLENECK_DETRITUS] = 0
		return false
	return _age_starvation(CHECKPOINT_BOTTLENECK_DETRITUS, ResourceLedger.DECAY, _long_grace_ticks())


func _run_complete_ready() -> bool:
	var hero_biomass: float = GameState.get_hero_biomass()
	var cycle_closed: bool = bool(GameState.run_save.get("cycle_closed", false))
	return hero_biomass >= 100000.0 and cycle_closed


func _age_starvation(id: StringName, resource_id: StringName, grace_ticks: int) -> bool:
	var amount: float = ResourceLedger.get_amount(resource_id)
	if amount <= 5.0:
		_bottleneck_age_ticks[id] = int(_bottleneck_age_ticks.get(id, 0)) + 1
	else:
		_bottleneck_age_ticks[id] = 0
	return int(_bottleneck_age_ticks.get(id, 0)) >= grace_ticks


func _short_grace_ticks() -> int:
	return int(round(60.0 * TickClock.tick_hz))


func _long_grace_ticks() -> int:
	return int(round(300.0 * TickClock.tick_hz))
