extends Node

const SPECIES_INDEX_PATH: String = "res://data/species/_index.tres"
const DEBUG_BIOME_AFFINITY: bool = false
const _TICK_EFFECT_HANDLERS: Dictionary = {
	&"parasite_steal": "_effect_parasite_steal",
	&"corpse_decay": "_effect_corpse_decay",
	&"mycorrhizal_bond_apply": "_effect_mycorrhizal_bond_apply"
}

var _all_species: Dictionary[StringName, SpeciesData] = {}

@onready var _territory: Node = get_node("../TerritorySystem")
@onready var _nutrients: Node = get_node("../NutrientSystem")
@onready var _ambient: Node = get_node("../AmbientModifierSystem")


func _ready() -> void:
	_load_species_index()
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


func _on_tick(_delta_seconds: float) -> void:
	if _all_species.is_empty():
		return
	var unlocked: Array = GameState.run_save.get("unlocked_species_in_run", []) as Array
	if unlocked.is_empty():
		return
	for species_id_str in unlocked:
		var species: SpeciesData = _all_species.get(StringName(species_id_str), null)
		if species == null:
			continue
		if species.placement_rule == &"recipe":
			continue
		var coords: Array[Vector2i] = _territory.get_species_occupied_coords(species.id)
		if coords.is_empty():
			continue
		_apply_yields(species, coords, 1.0)
		_apply_tick_effects(species, coords)


func _apply_yields(species: SpeciesData, coords: Array[Vector2i], base_mult: float) -> void:
	if species == null or coords.is_empty():
		return
	var kingdom_id: StringName = species.kingdom_id
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
			var affinity_mult: float = 1.0
			var affinity_biome_id: StringName = &""
			if resource_key == &"biomass":
				if kingdom_id == &"fungi":
					per_tile *= (1.0 + float(trait_mods.get(&"biomass_per_tile", 0.0)))
					if _is_tile_mycorrhizal_bonded(coord):
						per_tile *= 1.20
					var biome_for_affinity: BiomeData = _nutrients.get_biome_at(coord)
					if biome_for_affinity != null:
						affinity_mult = float(species.biome_affinity.get(biome_for_affinity.id, 1.0))
						affinity_biome_id = biome_for_affinity.id
						per_tile *= affinity_mult
				else:
					var biome: BiomeData = _nutrients.get_biome_at(coord)
					if biome == null:
						continue
					var local_sun_mult := sun_mult
					if _is_tile_warmed(coord) and _ambient.has_method("get_event_multiplier"):
						var cool_mult: float = float(_ambient.get_event_multiplier(&"cool_spell", &"sunlight_multiplier"))
						if cool_mult > 0.0:
							local_sun_mult = sun_mult / cool_mult
					per_tile *= biome.sunlight_per_tick * local_sun_mult
					per_tile *= (1.0 + float(trait_mods.get(&"biomass_per_tile", 0.0)))
					per_tile *= meta_mult
					if kingdom_id == &"plantae" and MetaModifiers.is_unlocked(&"soil_memory"):
						per_tile *= 1.15
					if _is_tile_mycorrhizal_bonded(coord):
						per_tile *= 1.20
					affinity_mult = float(species.biome_affinity.get(biome.id, 1.0))
					affinity_biome_id = biome.id
					per_tile *= affinity_mult
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
			if DEBUG_BIOME_AFFINITY and resource_key == &"biomass" and affinity_biome_id != &"" and affinity_mult != 1.0:
				print("[GrowthSystem] %s on %s: affinity=%.2f per_tile=%.3f" % [species.id, affinity_biome_id, affinity_mult, per_tile])
			total += per_tile
		if total > 0.0:
			ResourceLedger.add(resource_key, total)
	if extra_biomass > 0.0:
		ResourceLedger.add(ResourceLedger.BIOMASS, extra_biomass)


func _apply_tick_effects(species: SpeciesData, coords: Array[Vector2i]) -> void:
	if species.tick_effects.is_empty():
		return
	for effect_id in species.tick_effects:
		var method_name: String = _TICK_EFFECT_HANDLERS.get(effect_id, "")
		if method_name == "" or not has_method(method_name):
			continue
		call(method_name, species, coords)


func _effect_parasite_steal(species: SpeciesData, coords: Array[Vector2i]) -> void:
	var targets: Array[StringName] = species.placement_targets
	if targets.is_empty():
		return
	var total_bonus: float = 0.0
	for coord in coords:
		var neighbor_count: int = 0
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var neighbor: Vector2i = coord + offset
			var occ: Dictionary = _territory.get_occupants(neighbor)
			for kingdom_id in targets:
				if occ.has(kingdom_id):
					neighbor_count += 1
					break
		if neighbor_count > 0:
			total_bonus += 0.2 * float(neighbor_count)
	if total_bonus > 0.0:
		ResourceLedger.add(ResourceLedger.BIOMASS, total_bonus)


func _effect_corpse_decay(_species: SpeciesData, _coords: Array[Vector2i]) -> void:
	pass


func _effect_mycorrhizal_bond_apply(_species: SpeciesData, coords: Array[Vector2i]) -> void:
	for coord in coords:
		var occ: Dictionary = _territory.get_occupants(coord)
		if occ.has(&"plantae") and not bool(_territory.get_tile_data(coord, "mycorrhizal_bond", false)):
			_territory.set_tile_data(coord, "mycorrhizal_bond", true)


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
	var occ: Dictionary = _territory.get_occupants(coord)
	return occ.has(&"plantae") and occ.has(&"fungi")


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
		var occ: Dictionary = _territory.get_occupants(coord + offset)
		if occ.has(&"fungi"):
			return true
	return false


func _is_adjacent_to_plantae(coord: Vector2i) -> bool:
	for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var occ: Dictionary = _territory.get_occupants(coord + offset)
		if occ.has(&"plantae"):
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


func _is_tile_mycorrhizal_bonded(coord: Vector2i) -> bool:
	return bool(_territory.get_tile_data(coord, "mycorrhizal_bond", false))
