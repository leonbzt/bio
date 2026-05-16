extends Node

const SPECIES_INDEX_PATH: String = "res://data/species/_index.tres"
const STARTER_SPECIES_BY_KINGDOM := {
	&"plantae": &"pioneer_grass",
	&"fungi": &"mycelium_thread"
}

var _all_species: Dictionary[StringName, SpeciesData] = {}

@onready var _territory: Node = get_node("../TerritorySystem")
@onready var _nutrients: Node = get_node("../NutrientSystem")
@onready var _ambient: Node = get_node("../AmbientModifierSystem")


func _ready() -> void:
	_load_species_index()
	EventBus.tick.connect(_on_tick)


func _load_species_index() -> void:
	_all_species.clear()
	var index := load(SPECIES_INDEX_PATH)
	if index == null or not (index is SpeciesIndex):
		push_error("GrowthSystem: missing species index at %s" % SPECIES_INDEX_PATH)
		return
	for species in (index as SpeciesIndex).species:
		if species == null:
			continue
		_all_species[species.id] = species


func _on_tick(_delta_seconds: float) -> void:
	if _all_species.is_empty():
		return
	var kingdom_id: StringName = GameState.current_kingdom_id
	if kingdom_id == &"plantae" or kingdom_id == &"fungi":
		_tick_single_kingdom(kingdom_id)
	elif kingdom_id == &"symbiosis":
		_tick_symbiosis()


func _tick_single_kingdom(kingdom_id: StringName) -> void:
	var species_id: StringName = STARTER_SPECIES_BY_KINGDOM.get(kingdom_id, StringName())
	if species_id == StringName():
		return
	var species: SpeciesData = _all_species.get(species_id, null)
	if species == null:
		return
	var coords: Array[Vector2i]
	if kingdom_id == &"fungi":
		coords = _territory.get_subsurface_owned_coords(&"fungi")
	else:
		coords = _territory.get_surface_owned_coords(&"plantae")
	_apply_yields(species, coords, kingdom_id, 1.0)


func _tick_symbiosis() -> void:
	var plant_species: SpeciesData = _all_species.get(&"pioneer_grass", null)
	var fungi_species: SpeciesData = _all_species.get(&"mycelium_thread", null)
	if plant_species == null and fungi_species == null:
		return
	var surface_coords: Array[Vector2i] = []
	var subsurface_coords: Array[Vector2i] = []
	if plant_species != null:
		surface_coords = _territory.get_surface_owned_coords(&"plantae")
	if fungi_species != null:
		subsurface_coords = _territory.get_subsurface_owned_coords(&"fungi")
	if plant_species != null:
		_apply_yields(plant_species, surface_coords, &"plantae", 1.0, true)
	if fungi_species != null:
		_apply_yields(fungi_species, subsurface_coords, &"fungi", 1.0, true)


func _apply_yields(
	species: SpeciesData,
	coords: Array[Vector2i],
	kingdom_id: StringName,
	base_mult: float,
	apply_symbiosis_bonus: bool = false
) -> void:
	if species == null or coords.is_empty():
		return
	var trait_mods: Dictionary = _compute_trait_modifiers(species)
	var meta_mult: float = _get_meta_growth_multiplier() if kingdom_id == &"plantae" else 1.0
	var extra_biomass: float = 0.0
	if MetaModifiers.is_unlocked(&"endophytic_bridge"):
		for coord in coords:
			if _is_endophytic_partner(coord, kingdom_id):
				extra_biomass += 0.2

	for resource_id in species.tick_yield.keys():
		var resource_key: StringName = StringName(resource_id)
		var base_yield: float = float(species.tick_yield[resource_id])
		if base_yield == 0.0:
			continue
		var total: float = 0.0
		var sun_mult: float = 1.0
		if _ambient.has_method("get_multiplier"):
			sun_mult = float(_ambient.get_multiplier(&"sunlight_multiplier"))
		for coord in coords:
			var per_tile: float = base_yield * base_mult
			if resource_key == &"biomass":
				var biome: BiomeData = _nutrients.get_biome_at(coord)
				if biome == null:
					continue
				per_tile *= biome.sunlight_per_tick * sun_mult
				per_tile *= _get_niche_yield_multiplier()
				per_tile *= (1.0 + float(trait_mods.get(&"biomass_per_tile", 0.0)))
				per_tile *= meta_mult
				if kingdom_id == &"plantae" and MetaModifiers.is_unlocked(&"soil_memory"):
					per_tile *= 1.15
				if _is_tile_mycorrhizal_boosted(coord):
					per_tile *= 1.30
			elif resource_key == &"decay":
				per_tile *= (1.0 + float(trait_mods.get(&"decay_per_tile", 0.0)))
			elif resource_key == &"spores":
				per_tile *= (1.0 + float(trait_mods.get(&"spore_per_tile", 0.0)))


			if apply_symbiosis_bonus and _is_tile_symbiotic(coord):
				per_tile *= (1.0 + _get_symbiosis_bonus())
			elif apply_symbiosis_bonus and MetaModifiers.is_unlocked(&"wood_wide_web"):
				if _is_adjacent_to_symbiotic(coord):
					per_tile *= 1.15

			total += per_tile
		if total > 0.0:
			ResourceLedger.add(resource_key, total)
	if extra_biomass > 0.0:
		ResourceLedger.add(ResourceLedger.BIOMASS, extra_biomass)


func _is_tile_symbiotic(coord: Vector2i) -> bool:
	return _territory.get_surface_owner(coord) == &"plantae" and _territory.get_subsurface_owner(coord) == &"fungi"


func _is_adjacent_to_symbiotic(coord: Vector2i) -> bool:
	for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if _is_tile_symbiotic(coord + offset):
			return true
	return false


func _is_endophytic_partner(coord: Vector2i, kingdom_id: StringName) -> bool:
	if kingdom_id == &"plantae":
		return _is_adjacent_to_fungi(coord)
	if kingdom_id == &"fungi":
		return _is_adjacent_to_plantae(coord)
	return false


func _is_adjacent_to_fungi(coord: Vector2i) -> bool:
	for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if _territory.get_subsurface_owner(coord + offset) == &"fungi":
			return true
	return false


func _is_adjacent_to_plantae(coord: Vector2i) -> bool:
	for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if _territory.get_surface_owner(coord + offset) == &"plantae":
			return true
	return false


func _compute_trait_modifiers(species: SpeciesData) -> Dictionary:
	var mods: Dictionary = {}
	for trait_item: TraitData in species.base_traits:
		if trait_item == null:
			continue
		for key in trait_item.modifiers.keys():
			var key_name: StringName = StringName(key)
			mods[key_name] = mods.get(key_name, 0.0) + float(trait_item.modifiers.get(key, 0.0))
	return mods


func _get_meta_growth_multiplier() -> float:
	if MetaModifiers.is_unlocked(&"efficient_photosynthesis"):
		return 1.2
	return 1.0


func _get_symbiosis_bonus() -> float:
	if MetaModifiers.is_unlocked(&"mutualism"):
		return 0.50
	return 0.30


func _get_niche_yield_multiplier() -> float:
	if GameState.current_niche_id == &"parasite_plantae":
		return 2.0
	return 1.0


func _is_tile_mycorrhizal_boosted(coord: Vector2i) -> bool:
	if GameState.current_niche_id != &"mycorrhizal_fungi":
		return false
	return _territory.get_surface_owner(coord) == &"plantae" and _territory.get_subsurface_owner(coord) == &"fungi"
