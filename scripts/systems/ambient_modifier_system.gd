extends Node

# Maps active event id -> multipliers applied while the event is active.
var _active: Dictionary[StringName, Dictionary] = {}


func _ready() -> void:
	EventBus.event_started.connect(_on_event_started)
	EventBus.event_resolved.connect(_on_event_resolved)


func _on_event_started(event_id: StringName, payload: Dictionary) -> void:
	var mods: Dictionary = {}
	if payload.has("nutrient_multiplier"):
		mods["nutrient_multiplier"] = float(payload["nutrient_multiplier"])
	if payload.has("sunlight_multiplier"):
		mods["sunlight_multiplier"] = float(payload["sunlight_multiplier"])
	if mods.is_empty():
		return
	_active[event_id] = mods


func _on_event_resolved(event_id: StringName, _outcome: StringName) -> void:
	_active.erase(event_id)


func get_multiplier(key: StringName) -> float:
	var product: float = 1.0
	for mods in _active.values():
		if mods.has(key):
			product *= float(mods[key])
	return product
