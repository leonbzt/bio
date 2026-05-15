extends Node

const TOXIN_BLOOM_ID: StringName = &"toxin_bloom"
const TOXIN_BLOOM_TARGET_MODE: StringName = &"target_toxin_bloom"
const TOXIN_BLOOM_COST: Dictionary = {ResourceLedger.BIOMASS: 50.0}
const TOXIN_BLOOM_RADIUS: int = 3
const TOXIN_BLOOM_DAMAGE: float = 3.0
# TODO Phase 4+: move into AbilityData resource files

var _pending_ability: StringName = &""


func _ready() -> void:
	EventBus.tile_tapped.connect(_on_tile_tapped)


func request_toxin_bloom() -> bool:
	if _pending_ability == TOXIN_BLOOM_ID:
		cancel_pending()
		return false
	if not ResourceLedger.can_afford(TOXIN_BLOOM_COST):
		return false
	_set_mode(TOXIN_BLOOM_TARGET_MODE, TOXIN_BLOOM_ID)
	return true


func cancel_pending() -> void:
	_set_mode(GameState.INPUT_MODE_COLONIZE, &"")


func get_toxin_bloom_cost() -> Dictionary:
	return TOXIN_BLOOM_COST


func _on_tile_tapped(coord: Vector2i) -> void:
	if _pending_ability != TOXIN_BLOOM_ID:
		return
	if not _is_coord_in_bounds(coord):
		cancel_pending()
		return
	if not ResourceLedger.spend_bundle(TOXIN_BLOOM_COST):
		cancel_pending()
		return

	var payload := {
		"coord": coord,
		"radius_tiles": TOXIN_BLOOM_RADIUS,
		"damage": _get_toxin_damage()
	}
	EventBus.ability_used.emit(TOXIN_BLOOM_ID, payload)
	cancel_pending()


func _set_mode(mode: StringName, ability_id: StringName) -> void:
	if GameState.input_mode == mode and _pending_ability == ability_id:
		return
	GameState.input_mode = mode
	_pending_ability = ability_id
	EventBus.input_mode_changed.emit(mode)


func _is_coord_in_bounds(coord: Vector2i) -> bool:
	return coord.x >= 0 and coord.x < 32 and coord.y >= 0 and coord.y < 48


func _get_toxin_damage() -> float:
	if MetaModifiers.is_unlocked(&"toxin_potency"):
		return 5.0
	return TOXIN_BLOOM_DAMAGE
