extends Node

# Maps active event id -> multipliers applied while the event is active.
var _active: Dictionary[StringName, Dictionary] = {}


func _ready() -> void:
	EventBus.event_started.connect(_on_event_started)
	EventBus.event_resolved.connect(_on_event_resolved)
	EventBus.ability_used.connect(_on_ability_used)


func _on_event_started(event_id: StringName, payload: Dictionary) -> void:
	if event_id == &"drought" and MetaModifiers.is_unlocked(&"drought_resilience"):
		return
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


func _on_ability_used(id: StringName, payload: Dictionary) -> void:
	if id != &"irrigate":
		return
	var coord: Vector2i = payload.get("coord", Vector2i.ZERO)
	var radius: int = int(payload.get("radius_tiles", 0))
	var per_tile_nutrients: float = float(payload.get("magnitude", 0.0))
	if radius <= 0 or per_tile_nutrients <= 0.0:
		return
	var territory: Node = get_node_or_null("../TerritorySystem")
	if territory == null:
		return
	var owned: Array[Vector2i] = territory.get_surface_owned_coords()
	var total: float = 0.0
	for c in owned:
		if abs(c.x - coord.x) + abs(c.y - coord.y) <= radius:
			total += per_tile_nutrients
	if total > 0.0:
		ResourceLedger.add(ResourceLedger.NUTRIENTS, total)


func get_multiplier(key: StringName) -> float:
	var product: float = 1.0
	for mods in _active.values():
		if mods.has(key):
			product *= float(mods[key])
	return product


func is_event_active(event_id: StringName) -> bool:
	return _active.has(event_id)


func get_event_multiplier(event_id: StringName, key: StringName) -> float:
	if not _active.has(event_id):
		return 1.0
	var mods: Dictionary = _active[event_id]
	if mods.has(key):
		return float(mods[key])
	return 1.0
