extends Node

const KINGDOM_ID: StringName = &"fungi"
const SPECIES_PATH: String = "res://data/species/mycelium_thread.tres"

@onready var _territory: Node = get_node("../TerritorySystem")
@onready var _corpses: Node = get_node("../CorpseSystem")

var _species: SpeciesData


func _ready() -> void:
	_species = load(SPECIES_PATH) as SpeciesData
	if _species == null:
		push_error("FungiColonization: missing %s" % SPECIES_PATH)
	EventBus.tile_tapped.connect(_on_tile_tapped)


func _on_tile_tapped(coord: Vector2i) -> void:
	if GameState.input_mode != GameState.INPUT_MODE_COLONIZE:
		return
	if GameState.current_kingdom_id != KINGDOM_ID:
		return
	if _species == null:
		return
	if _territory.get_subsurface_owner(coord) != &"":
		return
	if not _is_substrate_valid(coord):
		return

	var owned: Array[Vector2i] = _territory.get_subsurface_owned_coords(KINGDOM_ID)
	if owned.size() > 0:
		var cost: Dictionary = _get_cost()
		if not ResourceLedger.spend_bundle(cost):
			return

	var ok: bool = _territory.add_subsurface(coord, KINGDOM_ID)
	if ok:
		SaveSystem.save_now()


func _is_substrate_valid(coord: Vector2i) -> bool:
	var owned: Array[Vector2i] = _territory.get_subsurface_owned_coords(KINGDOM_ID)
	if owned.is_empty():
		return true
	if _territory.get_surface_owner(coord) == &"plantae":
		return true
	if _corpses.has_method("is_corpse_at") and _corpses.is_corpse_at(coord):
		return true

	var owned_set: Dictionary = {}
	for c in owned:
		owned_set[c] = true
	for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if owned_set.has(coord + offset):
			return true
	return false


func _get_cost() -> Dictionary:
	var cost: Dictionary = _species.colonize_cost.duplicate()
	var discount: float = 0.0
	for t in _species.base_traits:
		discount += float(t.modifiers.get("colonize_cost", 0.0))
	if discount != 0.0:
		for key in cost.keys():
			cost[key] = maxf(0.0, float(cost[key]) * (1.0 + discount))
	return cost
