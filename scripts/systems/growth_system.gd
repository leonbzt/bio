extends Node

const SPECIES_INDEX_PATH: String = "res://data/species/_index.tres"
const NICHE_INDEX_PATH: String = "res://data/niches/_index.tres"
const STARTER_SPECIES_BY_KINGDOM := {
	&"plantae": &"pioneer_grass",
	&"fungi": &"mycelium_thread",
	&"animals": &"common_grazer"
}

var _all_species: Dictionary[StringName, SpeciesData] = {}
var _niches_by_id: Dictionary[StringName, NicheData] = {}

@onready var _territory: Node = get_node("../TerritorySystem")
@onready var _nutrients: Node = get_node("../NutrientSystem")
@onready var _ambient: Node = get_node("../AmbientModifierSystem")


func _ready() -> void:
	_load_species_index()
	_load_niche_index()
	EventBus.tick.connect(_on_tick)
	EventBus.ability_used.connect(_on_ability_used)


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


func _load_niche_index() -> void:
	_niches_by_id.clear()
	var index := load(NICHE_INDEX_PATH)
	if index == null or not (index is NicheIndex):
		return
	for niche in (index as NicheIndex).niches:
		if niche == null:
			continue
		_niches_by_id[niche.id] = niche


func _on_tick(_delta_seconds: float) -> void:
	if _all_species.is_empty():
		return
	var kingdom_id: StringName = GameState.current_kingdom_id
	if kingdom_id == &"":
		return
	_tick_kingdom(kingdom_id)


func _resolve_active_species(kingdom_id: StringName) -> SpeciesData:
	var niche_id: StringName = GameState.current_niche_id
	if niche_id != &"" and _niches_by_id.has(niche_id):
		var niche: NicheData = _niches_by_id[niche_id]
		if not niche.species_options.is_empty():
			return niche.species_options[0]
	var fallback: StringName = STARTER_SPECIES_BY_KINGDOM.get(kingdom_id, StringName())
	if fallback == StringName():
		return null
	return _all_species.get(fallback, null)


func _get_coords_for_kingdom(kingdom_id: StringName) -> Array[Vector2i]:
	if kingdom_id == &"fungi":
		return _territory.get_subsurface_owned_coords(&"fungi")
	return _territory.get_surface_owned_coords(kingdom_id)


func _tick_kingdom(kingdom_id: StringName) -> void:
	var species: SpeciesData = _resolve_active_species(kingdom_id)
	if species == null:
		return
	if species.layer_count > 1 and not species.layer_species.is_empty():
		for layer_id in species.layer_species:
			var layered_species: SpeciesData = _all_species.get(layer_id, null)
			if layered_species == null:
				continue
			var coords := _get_coords_for_kingdom(layered_species.kingdom_id)
			_apply_yields(layered_species, coords, layered_species.kingdom_id, 1.0)
		return
	var coords := _get_coords_for_kingdom(kingdom_id)
	_apply_yields(species, coords, kingdom_id, 1.0)


func _apply_yields(
	species: SpeciesData,
	coords: Array[Vector2i],
	kingdom_id: StringName,
	base_mult: float
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
				var local_sun_mult := sun_mult
				if _is_tile_warmed(coord) and _ambient.has_method("get_event_multiplier"):
					var cool_mult: float = float(_ambient.get_event_multiplier(&"cool_spell", &"sunlight_multiplier"))
					if cool_mult > 0.0:
						local_sun_mult = sun_mult / cool_mult
				per_tile *= biome.sunlight_per_tick * local_sun_mult
				per_tile *= _get_niche_yield_multiplier()
				per_tile *= (1.0 + float(trait_mods.get(&"biomass_per_tile", 0.0)))
				per_tile *= meta_mult
				if kingdom_id == &"plantae" and MetaModifiers.is_unlocked(&"soil_memory"):
					per_tile *= 1.15
				if _is_tile_mycorrhizal_bonded(coord):
					per_tile *= 1.20
			elif resource_key == &"decay":
				per_tile *= (1.0 + float(trait_mods.get(&"decay_per_tile", 0.0)))
				if _is_tile_mycorrhizal_bonded(coord):
					per_tile *= 1.20
			elif resource_key == &"spores":
				per_tile *= (1.0 + float(trait_mods.get(&"spore_per_tile", 0.0)))

			if _is_tile_symbiotic(coord):
				per_tile *= (1.0 + _get_symbiosis_bonus())
			elif MetaModifiers.is_unlocked(&"wood_wide_web") and _is_adjacent_to_symbiotic(coord):
				per_tile *= 1.15

			total += per_tile
		if total > 0.0:
			ResourceLedger.add(resource_key, total)
	if extra_biomass > 0.0:
		ResourceLedger.add(ResourceLedger.BIOMASS, extra_biomass)


func _on_ability_used(id: StringName, payload: Dictionary) -> void:
	if id != &"bundle":
		return
	var coord: Vector2i = payload.get("coord", Vector2i.ZERO)
	var duration: float = float(payload.get("magnitude", 0.0))
	if duration <= 0.0:
		return
	var until: int = int(Time.get_unix_time_from_system() + duration)
	for offset in [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		_territory.set_tile_data(coord + offset, "warmed_until_unix", until)


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


func _is_tile_warmed(coord: Vector2i) -> bool:
	var until: int = int(_territory.get_tile_data(coord, "warmed_until_unix", 0))
	return until > int(Time.get_unix_time_from_system())


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
	return 1.0


func _is_tile_mycorrhizal_bonded(coord: Vector2i) -> bool:
	return bool(_territory.get_tile_data(coord, "mycorrhizal_bond", false))
