extends Node

const KINGDOM_ID: StringName = &"animals"
@onready var _territory: Node = get_node("../TerritorySystem")
@onready var _rules: Node = get_node("/root/ColonizationRulesRegistry")

var _niches_by_id: Dictionary[StringName, NicheData] = {}


func _ready() -> void:
	_build_niche_index()
	EventBus.tile_tapped.connect(_on_tile_tapped)


func _on_tile_tapped(coord: Vector2i) -> void:
	if GameState.input_mode != GameState.INPUT_MODE_COLONIZE:
		return
	if not _is_active():
		return
	var niche: NicheData = _get_active_niche()
	if niche == null:
		return
	var species: SpeciesData = _get_species_for_niche(niche)
	if species == null:
		return
	var result: Dictionary = _rules.evaluate(
		niche.colonization_rule,
		coord,
		KINGDOM_ID,
		species,
		niche
	)
	if not result.get("valid", false):
		return
	var cost: Dictionary = result.get("cost", {}) as Dictionary
	if not cost.is_empty() and not ResourceLedger.spend_bundle(cost):
		return
	var ok: bool = _territory.add_surface(coord, KINGDOM_ID, niche.tile_variant)
	if ok:
		var data_extras: Dictionary = result.get("data", {}) as Dictionary
		for key in data_extras.keys():
			_territory.set_tile_data(coord, String(key), data_extras[key])
		SaveSystem.save_now()


func _is_active() -> bool:
	if GameState.current_kingdom_id == KINGDOM_ID:
		return true
	if GameState.placement_target == KINGDOM_ID:
		return true
	return false


func _build_niche_index() -> void:
	_niches_by_id.clear()
	var index := load("res://data/niches/_index.tres")
	if index == null or not (index is NicheIndex):
		push_error("AnimalColonization: missing niche index")
		return
	for niche in (index as NicheIndex).niches:
		if niche == null:
			continue
		_niches_by_id[niche.id] = niche


func _get_active_niche() -> NicheData:
	if GameState.current_niche_id != &"" and _niches_by_id.has(GameState.current_niche_id):
		var current: NicheData = _niches_by_id[GameState.current_niche_id]
		if current.kingdom_id == KINGDOM_ID:
			return current
	for niche in _niches_by_id.values():
		if niche.kingdom_id == KINGDOM_ID:
			return niche
	push_error("AnimalColonization: no niche available for kingdom %s" % String(KINGDOM_ID))
	return null


func _get_species_for_niche(niche: NicheData) -> SpeciesData:
	if niche.species_options.is_empty():
		push_error("AnimalColonization: niche %s has no species" % String(niche.id))
		return null
	return niche.species_options[0]
