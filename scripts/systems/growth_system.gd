extends Node

const SPECIES_INDEX_PATH: String = "res://data/species/_index.tres"
const STARTER_SPECIES_BY_KINGDOM := {
	&"plantae": &"pioneer_grass",
	&"fungi": &"mycelium_thread"
}

var _all_species: Dictionary[StringName, SpeciesData] = {}
var _active_species: SpeciesData = null
var _trait_modifier_sum: Dictionary[StringName, float] = {}

@onready var _territory: Node = get_node("../TerritorySystem")
@onready var _nutrients: Node = get_node("../NutrientSystem")


func _ready() -> void:
	_load_species_index()
	EventBus.tick.connect(_on_tick)
	EventBus.run_loaded.connect(_on_run_loaded)
	EventBus.run_started.connect(_on_run_started)
	if not GameState.run_save.is_empty():
		_on_run_loaded(SaveSystem.SAVE_VERSION)


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


func _on_run_loaded(_save_version: int) -> void:
	_select_active_species()


func _on_run_started(_kingdom_id: StringName) -> void:
	_select_active_species()


func _select_active_species() -> void:
	_active_species = null
	_trait_modifier_sum.clear()
	if _all_species.is_empty():
		return
	var kingdom_id: StringName = GameState.current_kingdom_id
	var species_id: StringName = STARTER_SPECIES_BY_KINGDOM.get(kingdom_id, StringName())
	if species_id == StringName():
		push_warning("GrowthSystem: no starter species for kingdom %s" % String(kingdom_id))
		return
	var selected: SpeciesData = _all_species.get(species_id, null)
	if selected == null:
		push_error("GrowthSystem: missing species %s" % String(species_id))
		return
	_active_species = selected
	_rebuild_trait_modifiers()


func _rebuild_trait_modifiers() -> void:
	_trait_modifier_sum.clear()
	if _active_species == null:
		return
	for trait_item: TraitData in _active_species.base_traits:
		if trait_item == null:
			continue
		for key in trait_item.modifiers.keys():
			var key_name: StringName = StringName(key)
			var value: float = float(trait_item.modifiers.get(key, 0.0))
			_trait_modifier_sum[key_name] = _trait_modifier_sum.get(key_name, 0.0) + value


func _on_tick(_delta_seconds: float) -> void:
	if _active_species == null:
		return

	var coords: Array[Vector2i]
	var is_fungi: bool = _active_species.kingdom_id == &"fungi"
	if is_fungi:
		coords = _territory.get_subsurface_owned_coords(&"fungi")
	else:
		coords = _territory.get_surface_owned_coords(_active_species.kingdom_id)
	if coords.is_empty():
		return

	var meta_mult: float = _get_meta_growth_multiplier()
	if is_fungi:
		meta_mult = 1.0

	for resource_id in _active_species.tick_yield.keys():
		var resource_key: StringName = StringName(resource_id)
		var base_yield: float = float(_active_species.tick_yield[resource_id])
		if base_yield == 0.0:
			continue
		var total: float = 0.0
		for coord in coords:
			var multiplier: float = 1.0
			if resource_key == &"biomass":
				var biome: BiomeData = _nutrients.get_biome_at(coord)
				if biome == null:
					continue
				multiplier *= biome.sunlight_per_tick
				multiplier *= (1.0 + _trait_modifier_sum.get(&"biomass_per_tile", 0.0))
				multiplier *= meta_mult
			elif resource_key == &"decay":
				multiplier *= (1.0 + _trait_modifier_sum.get(&"decay_per_tile", 0.0))
			elif resource_key == &"spores":
				multiplier *= (1.0 + _trait_modifier_sum.get(&"spore_per_tile", 0.0))
			total += base_yield * multiplier
		if total > 0.0:
			ResourceLedger.add(resource_key, total)


func _get_meta_growth_multiplier() -> float:
	if MetaModifiers.is_unlocked(&"efficient_photosynthesis"):
		return 1.2
	return 1.0
