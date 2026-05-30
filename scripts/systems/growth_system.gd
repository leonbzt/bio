extends Node

const SPECIES_INDEX_PATH: String = "res://data/species/_index.tres"
const DEBUG_BIOME_AFFINITY: bool = false
const _TICK_EFFECT_HANDLERS: Dictionary = {
	&"parasite_steal": "_effect_parasite_steal",
	&"corpse_decay": "_effect_corpse_decay",
	&"mycorrhizal_bond_apply": "_effect_mycorrhizal_bond_apply"
}

# Phase 15a: tile maturation constants
const SPROUTING_DURATION: int = 15
const MATURE_DURATION: int = 45
const CYCLE_CLOSURE_CONFIRM_TICKS: int = 5

var _all_species: Dictionary[StringName, SpeciesData] = {}
var _cached_tick: int = 0
var _species_throttle_cache: Dictionary[StringName, float] = {}
var _closure_ticks_held: int = 0

@onready var _territory: Node = get_node("../TerritorySystem")
@onready var _nutrients: Node = get_node("../NutrientSystem")
@onready var _ambient: Node = get_node("../AmbientModifierSystem")


func _ready() -> void:
	_load_species_index()
	EventBus.tick.connect(_on_tick)
	EventBus.run_started.connect(_on_run_started)


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
	# Perf (Tier 2): pin the current tick once per tick instead of re-reading
	# GameState.run_save["statistics"] inside every per-tile maturation check.
	_cached_tick = _read_current_tick()
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
	_check_cycle_closure()


func _apply_yields(species: SpeciesData, coords: Array[Vector2i], base_mult: float) -> void:
	if species == null or coords.is_empty():
		return
	var input_throttle: float = _compute_input_throttle(species, coords.size())
	_species_throttle_cache[species.id] = input_throttle
	if input_throttle <= 0.0:
		return
	_spend_inputs(species, coords.size(), input_throttle)
	base_mult *= input_throttle
	if bool(GameState.run_save.get("cycle_closed", false)):
		base_mult *= 1.5
	var kingdom_id: StringName = species.kingdom_id
	var trait_mods: Dictionary = _compute_trait_modifiers(species)
	var produced_hero_biomass: float = 0.0

	for resource_id in species.tick_yield.keys():
		var resource_key: StringName = StringName(resource_id)
		var base_yield: float = float(species.tick_yield[resource_id])
		if base_yield == 0.0:
			continue
		var total: float = 0.0
		var sun_mult: float = 1.0
		var biomass_mult: float = 1.0
		if _ambient.has_method("get_multiplier"):
			sun_mult = float(_ambient.get_multiplier(&"sunlight_multiplier"))
			biomass_mult = float(_ambient.get_multiplier(&"biomass_multiplier"))
		for coord in coords:
			var per_tile: float = base_yield * base_mult
			# Phase 15a: tile maturation multiplier.
			var age_ticks: int = _cached_tick - _territory.get_tile_placed_tick(coord)
			var maturation_mult: float = _maturation_yield_multiplier(age_ticks)
			per_tile *= maturation_mult
			var affinity_mult: float = 1.0
			var affinity_biome_id: StringName = &""
			if resource_key == &"biomass":
				var biome: BiomeData = _nutrients.get_biome_at(coord)
				if biome == null:
					continue
				if kingdom_id == &"fungi":
					per_tile *= (1.0 + float(trait_mods.get(&"biomass_per_tile", 0.0)))
					if biome.chemosynthesis_per_tick > 0.0:
						per_tile *= (1.0 + biome.chemosynthesis_per_tick)
					if _is_tile_mycorrhizal_bonded(coord):
						per_tile *= 1.20
					affinity_mult = float(species.biome_affinity.get(biome.id, 1.0))
					affinity_biome_id = biome.id
					per_tile *= affinity_mult
				else:
					per_tile *= biome.sunlight_per_tick * sun_mult
					if biome.chemosynthesis_per_tick > 0.0:
						per_tile += base_yield * base_mult * biome.chemosynthesis_per_tick * 0.5
					per_tile *= (1.0 + float(trait_mods.get(&"biomass_per_tile", 0.0)))
					if _is_tile_mycorrhizal_bonded(coord):
						per_tile *= 1.20
					affinity_mult = float(species.biome_affinity.get(biome.id, 1.0))
					affinity_biome_id = biome.id
					per_tile *= affinity_mult
					if bool(_territory.get_tile_data(coord, "structure_mycorrhizal_hub", false)):
						per_tile *= 1.50
					if bool(_territory.get_tile_data(coord, "structure_old_growth", false)):
						per_tile *= 2.00
					if bool(_territory.get_tile_data(coord, "structure_fern_grove", false)):
						per_tile *= 1.30
				per_tile *= biomass_mult
			elif resource_key == &"decay":
				per_tile *= (1.0 + float(trait_mods.get(&"decay_per_tile", 0.0)))
				if _is_tile_mycorrhizal_bonded(coord):
					per_tile *= 1.20
			elif resource_key == &"spores":
				per_tile *= (1.0 + float(trait_mods.get(&"spore_per_tile", 0.0)))
			# Phase 15a: ancient fertilizer aura
			if resource_key == &"biomass" and _has_ancient_neighbor_of_same_kingdom(coord, kingdom_id):
				per_tile *= 1.05
			if _is_tile_symbiotic(coord):
				per_tile *= 1.30
			if DEBUG_BIOME_AFFINITY and resource_key == &"biomass" and affinity_biome_id != &"" and affinity_mult != 1.0:
				print("[GrowthSystem] %s on %s: affinity=%.2f per_tile=%.3f" % [species.id, affinity_biome_id, affinity_mult, per_tile])
			# Phase 15c: per-run species evolution level multiplier.
			per_tile *= AdaptationSystem.species_level_multiplier(species.id)
			# Phase 15a: apply per-resource multiplier from the registry.
			per_tile *= ResourceLedger.get_multiplier(resource_key)
			total += per_tile
		if total > 0.0:
			ResourceLedger.add(resource_key, total)
			if kingdom_id == &"plantae" and resource_key == ResourceLedger.BIOMASS:
				produced_hero_biomass += total
	if produced_hero_biomass > 0.0:
		_add_hero_lifetime_biomass(produced_hero_biomass)


func get_species_throttle(species_id: StringName) -> float:
	return float(_species_throttle_cache.get(species_id, 1.0))


func _on_run_started(_kingdom_id: StringName) -> void:
	_species_throttle_cache.clear()
	_closure_ticks_held = 0


func _add_hero_lifetime_biomass(amount: float) -> void:
	if amount <= 0.0:
		return
	var current: float = float(GameState.run_save.get("hero_biomass_lifetime_produced", 0.0))
	GameState.run_save["hero_biomass_lifetime_produced"] = current + amount


func _check_cycle_closure() -> void:
	if bool(GameState.run_save.get("cycle_closed", false)):
		return
	var has_plant: bool = _territory.get_kingdom_tile_count(&"plantae") > 0
	var has_fungus: bool = _territory.get_kingdom_tile_count(&"fungi") > 0
	var has_animal: bool = _territory.get_kingdom_tile_count(&"animals") > 0
	if not (has_plant and has_fungus and has_animal):
		_closure_ticks_held = 0
		return
	# Earlier draft required all three pools > 0 each tick. In steady-state
	# closure the pools dip to ~0 when consumption catches production, which
	# was resetting the 5-tick confirm and preventing the event from firing.
	# Trust the placement signal: 3 kingdoms placed + 5 ticks = closed.
	_closure_ticks_held += 1
	if _closure_ticks_held >= CYCLE_CLOSURE_CONFIRM_TICKS:
		GameState.run_save["cycle_closed"] = true
		EventBus.cycle_closed.emit()
		SaveSystem.save_now()


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
			var occ: Dictionary = _territory.peek_occupants(neighbor)
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
	# Single-species-per-tile means plants and fungi can't co-occupy a tile.
	# The bond fires on adjacency: for each mycorrhizal tile, tag any cardinal
	# plant neighbor so GrowthSystem can apply the +20% yield and the bond
	# overlay can draw the golden link.
	for coord in coords:
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var neighbor: Vector2i = coord + offset
			var occ: Dictionary = _territory.peek_occupants(neighbor)
			if occ.has(&"plantae") and not bool(_territory.get_tile_data(neighbor, "mycorrhizal_bond", false)):
				_territory.set_tile_data(neighbor, "mycorrhizal_bond", true)


func _is_tile_symbiotic(coord: Vector2i) -> bool:
	var occ: Dictionary = _territory.peek_occupants(coord)
	return occ.has(&"plantae") and occ.has(&"fungi")


func _compute_trait_modifiers(species: SpeciesData) -> Dictionary:
	var mods: Dictionary = {}
	for trait_item: TraitData in species.base_traits:
		if trait_item == null:
			continue
		for key in trait_item.modifiers.keys():
			var key_name: StringName = StringName(key)
			mods[key_name] = mods.get(key_name, 0.0) + float(trait_item.modifiers.get(key, 0.0))
	return mods


func _is_tile_mycorrhizal_bonded(coord: Vector2i) -> bool:
	return bool(_territory.get_tile_data(coord, "mycorrhizal_bond", false))




# Phase 15a: maturation yield multiplier
func _maturation_yield_multiplier(age_ticks: int) -> float:
	if age_ticks < SPROUTING_DURATION:
		return 0.5
	if age_ticks < SPROUTING_DURATION + MATURE_DURATION:
		return 1.0
	return 1.3


# Phase 15a: check if neighbor has ancient tile of same kingdom
func _has_ancient_neighbor_of_same_kingdom(coord: Vector2i, kingdom_id: StringName) -> bool:
	for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var neighbor: Vector2i = coord + offset
		var occ: Dictionary = _territory.peek_occupants(neighbor)
		if not occ.has(kingdom_id):
			continue
		var neighbor_age: int = _cached_tick - _territory.get_tile_placed_tick(neighbor)
		if neighbor_age >= SPROUTING_DURATION + MATURE_DURATION:
			return true
	return false


func _read_current_tick() -> int:
	var stats: Dictionary = GameState.run_save.get("statistics", {}) as Dictionary
	return int(stats.get("tick_count", 0))


func _compute_input_throttle(species: SpeciesData, num_tiles: int) -> float:
	if species.consume_input.is_empty() or num_tiles <= 0:
		return 1.0
	var throttle: float = 1.0
	for resource_id in species.consume_input.keys():
		var rate: float = float(species.consume_input[resource_id])
		if rate <= 0.0:
			continue
		var needed: float = rate * float(num_tiles)
		var available: float = ResourceLedger.get_amount(StringName(resource_id))
		if available < needed:
			throttle = minf(throttle, available / needed)
	return throttle


func _spend_inputs(species: SpeciesData, num_tiles: int, throttle: float) -> void:
	if species.consume_input.is_empty() or throttle <= 0.0 or num_tiles <= 0:
		return
	for resource_id in species.consume_input.keys():
		var rate: float = float(species.consume_input[resource_id])
		if rate <= 0.0:
			continue
		var spent: float = rate * float(num_tiles) * throttle
		if spent > 0.0:
			ResourceLedger.add(StringName(resource_id), -spent)
