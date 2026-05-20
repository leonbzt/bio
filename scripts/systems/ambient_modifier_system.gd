extends Node

# Maps active event id -> multipliers applied while the event is active.
var _active: Dictionary[StringName, Dictionary] = {}
var _post_extinction_ticks_remaining: int = 0
var _post_extinction_total_ticks: int = 120


func _ready() -> void:
	EventBus.event_started.connect(_on_event_started)
	EventBus.event_resolved.connect(_on_event_resolved)
	EventBus.ability_used.connect(_on_ability_used)
	EventBus.tick.connect(_on_tick)


func _on_event_started(event_id: StringName, payload: Dictionary) -> void:
	if event_id == &"drought" and MetaModifiers.is_unlocked(&"drought_resilience"):
		return
	var mods: Dictionary = {}
	var payload_mods: Dictionary = payload.get("modifiers", {}) as Dictionary
	if payload_mods.has("nutrient_multiplier"):
		mods["nutrient_multiplier"] = float(payload_mods["nutrient_multiplier"])
	if payload_mods.has("sunlight_multiplier"):
		mods["sunlight_multiplier"] = float(payload_mods["sunlight_multiplier"])
	if payload_mods.has("biomass_multiplier"):
		mods["biomass_multiplier"] = float(payload_mods["biomass_multiplier"])
	if payload.has("nutrient_multiplier"):
		mods["nutrient_multiplier"] = float(payload["nutrient_multiplier"])
	if payload.has("sunlight_multiplier"):
		mods["sunlight_multiplier"] = float(payload["sunlight_multiplier"])
	if payload.has("biomass_multiplier"):
		mods["biomass_multiplier"] = float(payload["biomass_multiplier"])
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
	var base: float = _compute_base_multiplier(key)
	if _post_extinction_ticks_remaining > 0:
		if key == &"sunlight_multiplier" or key == &"biomass_multiplier":
			var progress: float = 1.0 - (float(_post_extinction_ticks_remaining) / float(_post_extinction_total_ticks))
			var debuff_mult: float = 0.5 + (0.5 * progress)
			base *= debuff_mult
	return base


func is_event_active(event_id: StringName) -> bool:
	return _active.has(event_id)


func get_event_multiplier(event_id: StringName, key: StringName) -> float:
	var raw: float = _raw_event_multiplier(event_id, key)
	if (event_id == &"cold_snap" or event_id == &"cool_spell") and MetaModifiers.is_unlocked(&"cryotolerance"):
		return 1.0 + (raw - 1.0) * 0.85
	return raw


func apply_post_extinction_debuff(ticks: int) -> void:
	_post_extinction_ticks_remaining = ticks
	_post_extinction_total_ticks = maxi(ticks, 120)


func _on_tick(_delta: float) -> void:
	if _post_extinction_ticks_remaining <= 0:
		return
	_post_extinction_ticks_remaining -= 1
	var pe: Dictionary = GameState.meta_save.get("post_extinction", {}) as Dictionary
	pe["debuff_ticks_remaining"] = _post_extinction_ticks_remaining
	GameState.meta_save["post_extinction"] = pe
	if _post_extinction_ticks_remaining % 30 == 0:
		SaveSystem.save_now()


func _compute_base_multiplier(key: StringName) -> float:
	var product: float = 1.0
	for mods in _active.values():
		if mods.has(key):
			product *= float(mods[key])
	return product


func _raw_event_multiplier(event_id: StringName, key: StringName) -> float:
	if not _active.has(event_id):
		return 1.0
	var mods: Dictionary = _active[event_id]
	if mods.has(key):
		return float(mods[key])
	return 1.0
