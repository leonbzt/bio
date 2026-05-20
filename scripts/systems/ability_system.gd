extends Node

const ABILITY_INDEX_PATH: String = "res://data/abilities/_index.tres"

var _abilities_by_id: Dictionary[StringName, AbilityData] = {}
var _pending_ability_id: StringName = &""

@onready var _pressure: Node = get_node("../EcologicalPressure")


func _ready() -> void:
	_load_abilities()
	EventBus.tile_tapped.connect(_on_tile_tapped)


func _load_abilities() -> void:
	_abilities_by_id.clear()
	var index := load(ABILITY_INDEX_PATH)
	if index == null or not (index is AbilityIndex):
		push_error("AbilitySystem: missing ability index at %s" % ABILITY_INDEX_PATH)
		return
	for ability in (index as AbilityIndex).abilities:
		if ability == null:
			continue
		_abilities_by_id[ability.id] = ability


# Public API ---------------------------------------------------------------

func get_all_abilities() -> Array[AbilityData]:
	return _abilities_by_id.values()


func get_usable_abilities() -> Array[AbilityData]:
	var result: Array[AbilityData] = []
	for ability in _abilities_by_id.values():
		if _is_ability_usable(ability):
			result.append(ability)
	return result


func is_ability_usable(id: StringName) -> bool:
	if not _abilities_by_id.has(id):
		return false
	return _is_ability_usable(_abilities_by_id[id])


func is_ability_available(id: StringName) -> bool:
	if not _abilities_by_id.has(id):
		return false
	var ability: AbilityData = _abilities_by_id[id]
	if ability.unlock_node_id != &"" and not MetaModifiers.is_unlocked(ability.unlock_node_id):
		if not _has_fairy_ring_override(ability):
			return false
	if ability.requires_event_active != &"":
		if not _pressure.is_event_active(ability.requires_event_active):
			return false
	return true


func can_afford_ability(id: StringName) -> bool:
	if not _abilities_by_id.has(id):
		return false
	return ResourceLedger.can_afford(_abilities_by_id[id].cost)


func get_ability_cost(id: StringName) -> Dictionary:
	if not _abilities_by_id.has(id):
		return {}
	return _abilities_by_id[id].cost


# Request an ability. Returns true if entered target mode; false if rejected.
# For target_mode == &"self", invokes immediately and returns true on success.
func request_ability(id: StringName) -> bool:
	if not _abilities_by_id.has(id):
		return false
	var ability: AbilityData = _abilities_by_id[id]
	if not _is_ability_usable(ability):
		return false
	if _pending_ability_id == id:
		cancel_pending()
		return false
	if ability.target_mode == &"self":
		return _invoke_self(ability)
	_set_mode(GameState.INPUT_MODE_TARGET, id)
	_pending_ability_id = id
	return true


func cancel_pending() -> void:
	_set_mode(GameState.INPUT_MODE_COLONIZE, &"")
	_pending_ability_id = &""


# Backwards-compatible shim for code that still calls request_toxin_bloom.
func request_toxin_bloom() -> bool:
	return request_ability(&"toxin_bloom")


func get_toxin_bloom_cost() -> Dictionary:
	return get_ability_cost(&"toxin_bloom")


# Internals ---------------------------------------------------------------

func _is_ability_usable(ability: AbilityData) -> bool:
	if ability.unlock_node_id != &"" and not MetaModifiers.is_unlocked(ability.unlock_node_id):
		if not _has_fairy_ring_override(ability):
			return false
	if ability.requires_event_active != &"":
		if not _pressure.is_event_active(ability.requires_event_active):
			return false
	if not ResourceLedger.can_afford(ability.cost):
		return false
	return true


func _has_fairy_ring_override(ability: AbilityData) -> bool:
	if ability.id != &"sporulate":
		return false
	var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
	return bool(run.get("fairy_ring_active", false))


func _on_tile_tapped(coord: Vector2i) -> void:
	if _pending_ability_id == &"":
		return
	if not _abilities_by_id.has(_pending_ability_id):
		cancel_pending()
		return
	var ability: AbilityData = _abilities_by_id[_pending_ability_id]
	if not _is_coord_in_bounds(coord):
		cancel_pending()
		return
	if not ResourceLedger.spend_bundle(ability.cost):
		cancel_pending()
		return
	var payload: Dictionary = {
		"coord": coord,
		"radius_tiles": ability.radius,
		"magnitude": ability.magnitude
	}
	if ability.id == &"toxin_bloom":
		payload["damage"] = _get_toxin_damage(ability)
	for k in ability.extra_payload.keys():
		payload[k] = ability.extra_payload[k]
	EventBus.ability_used.emit(ability.id, payload)
	cancel_pending()


func _invoke_self(ability: AbilityData) -> bool:
	if not ResourceLedger.spend_bundle(ability.cost):
		return false
	var payload: Dictionary = {
		"magnitude": ability.magnitude
	}
	for k in ability.extra_payload.keys():
		payload[k] = ability.extra_payload[k]
	EventBus.ability_used.emit(ability.id, payload)
	return true


func _set_mode(mode: StringName, ability_id: StringName) -> void:
	if GameState.input_mode == mode and _pending_ability_id == ability_id:
		return
	GameState.input_mode = mode
	EventBus.input_mode_changed.emit(mode)


func _is_coord_in_bounds(coord: Vector2i) -> bool:
	return coord.x >= 0 and coord.x < 32 and coord.y >= 0 and coord.y < 48


func _get_toxin_damage(ability: AbilityData) -> float:
	if MetaModifiers.is_unlocked(&"toxin_potency"):
		return 5.0
	return ability.magnitude
