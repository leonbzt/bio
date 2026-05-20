extends Node
##
## ResourceLedger — current-run resource balances.
## All mutations emit EventBus.resource_changed. Implementation in brief 02.
##

const BIOMASS    := &"biomass"
const NUTRIENTS  := &"nutrients"
const SUNLIGHT   := &"sunlight"
const DECAY      := &"decay"
const SPORES     := &"spores"
const PRESSURE   := &"population_pressure"
const PROTEIN    := &"protein"
const LIFEFORCE  := &"lifeforce"
const BLOOD      := &"blood_cohesion"
const GRAY_MATTER := &"gray_matter"
const MYCELIAL_STABILITY := &"mycelial_stability"

const _KNOWN_IDS: Array[StringName] = [
	BIOMASS,
	NUTRIENTS,
	SUNLIGHT,
	DECAY,
	SPORES,
	PRESSURE,
	PROTEIN,
	LIFEFORCE,
	BLOOD,
	GRAY_MATTER,
	MYCELIAL_STABILITY
]

var _amounts: Dictionary[StringName, float] = {}

# Phase 15a: Per-resource multiplier registry.
# Each resource has a Dictionary of {source_key: float_value}.
# Effective multiplier = product of all source values; missing keys default to 1.0.
var _multiplier_sources: Dictionary[StringName, Dictionary] = {}


func _ready() -> void:
	_sync_from_run_save()
	EventBus.run_loaded.connect(_on_run_loaded)


func get_amount(resource_id: StringName) -> float:
	return _amounts.get(resource_id, 0.0)


func add(resource_id: StringName, amount: float) -> void:
	if amount == 0.0:
		return
	var current: float = get_amount(resource_id)
	var new_amount: float = maxf(0.0, current + amount)
	if new_amount == current:
		return
	_amounts[resource_id] = new_amount
	_set_run_resource(resource_id, new_amount)
	EventBus.resource_changed.emit(resource_id, new_amount)


func spend(resource_id: StringName, amount: float) -> bool:
	# Returns false and does NOT mutate if insufficient.
	if amount <= 0.0:
		return true
	var current: float = get_amount(resource_id)
	if current < amount:
		return false
	var new_amount := current - amount
	_amounts[resource_id] = new_amount
	_set_run_resource(resource_id, new_amount)
	EventBus.resource_changed.emit(resource_id, new_amount)
	return true


func can_afford(costs: Dictionary) -> bool:
	# Checks every entry in {resource_id: amount}.
	for resource_id: StringName in costs.keys():
		var amount: float = float(costs[resource_id])
		if amount <= 0.0:
			continue
		if get_amount(resource_id) < amount:
			return false
	return true


func spend_bundle(costs: Dictionary) -> bool:
	# ATOMIC: check all, then mutate all. If any fails, mutate nothing.
	if not can_afford(costs):
		return false
	for resource_id: StringName in costs.keys():
		var amount: float = float(costs[resource_id])
		if amount <= 0.0:
			continue
		var new_amount: float = get_amount(resource_id) - amount
		_amounts[resource_id] = new_amount
		_set_run_resource(resource_id, new_amount)
		EventBus.resource_changed.emit(resource_id, new_amount)
	return true


func reset_run() -> void:
	# Zeroes all known resources on prestige.
	_amounts.clear()
	for resource_id in _KNOWN_IDS:
		_amounts[resource_id] = 0.0
		_set_run_resource(resource_id, 0.0)
		EventBus.resource_changed.emit(resource_id, 0.0)
	
	# Phase 15a: clear per-run multiplier sources.
	# Sources keyed with prefix "run:" are wiped; "meta:" sources persist.
	for resource_id in _multiplier_sources.keys():
		var d: Dictionary = _multiplier_sources[resource_id]
		for k in d.keys():
			if String(k).begins_with("run:"):
				d.erase(k)


func set_multiplier_source(resource_id: StringName, source_key: StringName, value: float) -> void:
	if not _multiplier_sources.has(resource_id):
		_multiplier_sources[resource_id] = {}
	_multiplier_sources[resource_id][source_key] = value
	EventBus.resource_multiplier_changed.emit(resource_id, get_multiplier(resource_id))


func clear_multiplier_source(resource_id: StringName, source_key: StringName) -> void:
	if not _multiplier_sources.has(resource_id):
		return
	var d: Dictionary = _multiplier_sources[resource_id]
	d.erase(source_key)
	EventBus.resource_multiplier_changed.emit(resource_id, get_multiplier(resource_id))


func get_multiplier(resource_id: StringName) -> float:
	if not _multiplier_sources.has(resource_id):
		return 1.0
	var product: float = 1.0
	for v in _multiplier_sources[resource_id].values():
		product *= float(v)
	return product


func get_multiplier_breakdown(resource_id: StringName) -> Array:
	var out: Array = []
	if _multiplier_sources.has(resource_id):
		for k in _multiplier_sources[resource_id].keys():
			out.append({"source": String(k), "value": float(_multiplier_sources[resource_id][k])})
	return out


func _sync_from_run_save() -> void:
	var resources := _get_run_resources()
	_amounts.clear()
	for resource_id in resources.keys():
		var amount: float = float(resources[resource_id])
		_amounts[resource_id] = amount
		EventBus.resource_changed.emit(resource_id, amount)


func _on_run_loaded(_save_version: int) -> void:
	_sync_from_run_save()


func _get_run_resources() -> Dictionary:
	var run: Dictionary
	if GameState.run_save is Dictionary:
		run = GameState.run_save
	else:
		run = {}
		GameState.run_save = run

	var resources_raw: Variant = run.get("resources", {})
	if resources_raw is Dictionary:
		return resources_raw as Dictionary
	var resources: Dictionary = {}
	run["resources"] = resources
	return resources


func _set_run_resource(resource_id: StringName, amount: float) -> void:
	var resources := _get_run_resources()
	resources[resource_id] = amount
