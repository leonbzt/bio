extends Node

const KINGDOM_ID: StringName = &"plantae"
const BASE_COLONIZE_COST: float = 5.0

@onready var _territory: Node = get_node("../TerritorySystem")


func _ready() -> void:
	EventBus.tile_tapped.connect(_on_tile_tapped)


func _on_tile_tapped(coord: Vector2i) -> void:
	if GameState.input_mode != GameState.INPUT_MODE_COLONIZE:
		return
	if not _is_active():
		return
	if _territory.get_surface_owner(coord) != &"":
		return
	var owned: Array[Vector2i] = _territory.get_surface_owned_coords(KINGDOM_ID)
	if owned.size() > 0 and not _is_adjacent_to_owned_surface(coord, owned):
		return
	if owned.size() > 0:
		if not ResourceLedger.spend_bundle(_get_cost()):
			return
	var ok: bool = _territory.add_surface(coord, KINGDOM_ID)
	if ok:
		SaveSystem.save_now()


func _is_adjacent_to_owned_surface(coord: Vector2i, owned: Array[Vector2i]) -> bool:
	var owned_map: Dictionary = {}
	for item in owned:
		owned_map[item] = true
	for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if owned_map.has(coord + offset):
			return true
	return false


func _get_cost() -> Dictionary:
	var cost: float = BASE_COLONIZE_COST
	if MetaModifiers.is_unlocked(&"thrifty_growth"):
		cost = 4.0
	return {ResourceLedger.BIOMASS: cost}


func _is_active() -> bool:
	if GameState.current_kingdom_id == KINGDOM_ID:
		return true
	if GameState.current_kingdom_id == &"symbiosis" and GameState.placement_target == KINGDOM_ID:
		return true
	return false
