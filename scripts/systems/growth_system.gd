extends Node

const ACTIVE_SPECIES_PATH: String = "res://data/species/pioneer_grass.tres"
# TODO Phase 4: species selection

var _species: SpeciesData = null
var _biomass_per_tile_modifier: float = 0.0

@onready var _territory: Node = get_node("../TerritorySystem")
@onready var _nutrients: Node = get_node("../NutrientSystem")


func _ready() -> void:
	_species = _load_species()
	_biomass_per_tile_modifier = _compute_biomass_modifier()
	EventBus.tick.connect(_on_tick)


func _load_species() -> SpeciesData:
	var res := load(ACTIVE_SPECIES_PATH)
	if res == null or not (res is SpeciesData):
		push_error("GrowthSystem: failed to load species %s" % ACTIVE_SPECIES_PATH)
		return null
	return res as SpeciesData


func _compute_biomass_modifier() -> float:
	if _species == null:
		return 0.0
	var total: float = 0.0
	for trait_item: TraitData in _species.base_traits:
		var value_raw: Variant = trait_item.modifiers.get("biomass_per_tile", 0.0)
		total += float(value_raw)
	return total


func _on_tick(_delta_seconds: float) -> void:
	if _species == null:
		return
	if not _territory.has_method("get_surface_owned_coords"):
		return
	if not _nutrients.has_method("get_biome_at"):
		return

	var base_yield: float = float(_species.tick_yield.get("biomass", 0.0))
	if base_yield <= 0.0:
		return

	var coords: Array[Vector2i] = _territory.get_surface_owned_coords()
	var total: float = 0.0
	for coord in coords:
		var biome: BiomeData = _nutrients.get_biome_at(coord)
		if biome == null:
			continue
		total += base_yield * biome.sunlight_per_tick * (1.0 + _biomass_per_tile_modifier) * _get_meta_growth_multiplier()

	if total > 0.0:
		ResourceLedger.add(ResourceLedger.BIOMASS, total)


func _get_meta_growth_multiplier() -> float:
	if MetaModifiers.is_unlocked(&"efficient_photosynthesis"):
		return 1.2
	return 1.0
