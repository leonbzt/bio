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

const _KNOWN_IDS: Array[StringName] = [BIOMASS, NUTRIENTS, SUNLIGHT, DECAY, SPORES, PRESSURE]

var _amounts: Dictionary[StringName, float] = {}


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
