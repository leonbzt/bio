extends Node
##
## GrowthSystem — Phase 18: local flow production.
## Each tile has an output buffer. Production fills the buffer. Buffers
## drain via player harvest (species panel button) or animal auto-harvest.
## Hero biomass increases ONLY on extraction.
##

const SPECIES_INDEX_PATH: String = "res://data/species/_index.tres"
const _TICK_EFFECT_HANDLERS: Dictionary = {
	&"parasite_steal": "_effect_parasite_steal",
	&"corpse_decay": "_effect_corpse_decay",
	&"mycorrhizal_bond_apply": "_effect_mycorrhizal_bond_apply"
}

const SPROUTING_DURATION: int = 15
const MATURE_DURATION: int = 45
const CYCLE_CLOSURE_CONFIRM_TICKS: int = 5

const BUFFER_CAP_BASE: float = 20.0
const SOIL_START: float = 60.0
const AMBIENT_FLOOR: float = 0.20

const _CARDINAL: Array[Vector2i] = [
	Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN
]

var _all_species: Dictionary[StringName, SpeciesData] = {}
var _cached_tick: int = 0
var _closure_ticks_held: int = 0

var _output_buffers: Dictionary = {}
var _soil_nutrients: Dictionary = {}
var _input_satisfaction: Dictionary = {}

@onready var _territory: Node = get_node("../TerritorySystem")
@onready var _nutrients: Node = get_node("../NutrientSystem")


func _ready() -> void:
	_load_species_index()
	EventBus.tick.connect(_on_tick)
	EventBus.run_started.connect(_on_run_started)
	EventBus.tile_colonized.connect(_on_tile_colonized)
	EventBus.tile_lost.connect(_on_tile_lost)


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


func _on_tile_colonized(coord: Vector2i, _owner_id: StringName) -> void:
	_output_buffers[coord] = {}
	_soil_nutrients[coord] = SOIL_START
	_input_satisfaction[coord] = 1.0


func _on_tile_lost(coord: Vector2i, _prev_owner_id: StringName) -> void:
	_output_buffers.erase(coord)
	_soil_nutrients.erase(coord)
	_input_satisfaction.erase(coord)


func get_tile_buffer(coord: Vector2i) -> Dictionary:
	return _output_buffers.get(coord, {})


func get_tile_input_satisfaction(coord: Vector2i) -> float:
	return float(_input_satisfaction.get(coord, 1.0))


func get_buffer_cap(_coord: Vector2i) -> float:
	return BUFFER_CAP_BASE


func get_tile_buffer_fill(coord: Vector2i) -> float:
	var buf: Dictionary = _output_buffers.get(coord, {})
	var total: float = 0.0
	for v in buf.values():
		total += float(v)
	if BUFFER_CAP_BASE <= 0.0:
		return 0.0
	return minf(total / BUFFER_CAP_BASE, 1.0)


func drain_tile_buffer(coord: Vector2i) -> Dictionary:
	var buf: Dictionary = _output_buffers.get(coord, {})
	if buf.is_empty():
		return {}
	var drained: Dictionary = buf.duplicate()
	buf.clear()
	_output_buffers[coord] = buf
	return drained


func _on_tick(_delta_seconds: float) -> void:
	if _all_species.is_empty():
		return
	_cached_tick = _read_current_tick()

	var all_coords: Array = _territory.get_all_owned_coords() if _territory != null else []
	if all_coords.is_empty():
		_check_cycle_closure()
		return

	for coord in all_coords:
		_tick_tile(coord)

	_symbiotic_auto_transfer(all_coords)

	var unlocked: Array = GameState.run_save.get("unlocked_species_in_run", []) as Array
	for species_id_str in unlocked:
		var species: SpeciesData = _all_species.get(StringName(species_id_str), null)
		if species == null or species.placement_rule == &"recipe":
			continue
		var species_coords: Array[Vector2i] = _territory.get_species_occupied_coords(species.id)
		if not species_coords.is_empty():
			_apply_tick_effects(species, species_coords)

	_check_cycle_closure()


func _tick_tile(coord: Vector2i) -> void:
	var occ: Dictionary = _territory.peek_occupants(coord)
	if occ.is_empty():
		return
	var kingdom_id: StringName = occ.keys()[0]
	var species_id: StringName = occ[kingdom_id]
	var species: SpeciesData = _all_species.get(species_id, null)
	if species == null or species.placement_rule == &"recipe":
		return

	if not _output_buffers.has(coord):
		_output_buffers[coord] = {}
		_soil_nutrients[coord] = SOIL_START

	var throttle: float = _compute_local_throttle(coord, species)
	_input_satisfaction[coord] = throttle

	if throttle <= 0.0:
		return

	var consumed: Dictionary = _consume_local_inputs(coord, species, throttle)
	_produce_to_buffer(coord, species, kingdom_id, throttle)

	if kingdom_id == &"animals":
		var b_consumed: float = float(consumed.get(&"biomass", 0.0))
		if b_consumed > 0.0:
			_add_hero_lifetime_biomass(b_consumed)


func _compute_local_throttle(coord: Vector2i, species: SpeciesData) -> float:
	if species.consume_input.is_empty():
		return 1.0

	var throttle: float = 1.0
	var soil: float = float(_soil_nutrients.get(coord, 0.0))

	for resource_id in species.consume_input.keys():
		var rid: StringName = StringName(resource_id)
		var needed: float = float(species.consume_input[resource_id])
		if needed <= 0.0:
			continue
		var available: float = 0.0

		for offset in _CARDINAL:
			var neighbor: Vector2i = coord + offset
			var nbuf: Dictionary = _output_buffers.get(neighbor, {})
			available += float(nbuf.get(rid, 0.0))

		if rid == &"nutrients" and soil > 0.0:
			available += minf(soil, needed)

		if available < needed:
			throttle = minf(throttle, available / needed)

	if soil <= 0.0 and throttle < AMBIENT_FLOOR:
		throttle = AMBIENT_FLOOR

	return throttle


func _consume_local_inputs(coord: Vector2i, species: SpeciesData, throttle: float) -> Dictionary:
	var consumed: Dictionary = {}
	if species.consume_input.is_empty() or throttle <= 0.0:
		return consumed

	for resource_id in species.consume_input.keys():
		var rid: StringName = StringName(resource_id)
		var needed: float = float(species.consume_input[resource_id]) * throttle
		if needed <= 0.0:
			continue

		var total_taken: float = 0.0

		if rid == &"nutrients":
			var soil: float = float(_soil_nutrients.get(coord, 0.0))
			var from_soil: float = minf(soil, needed)
			if from_soil > 0.0:
				_soil_nutrients[coord] = maxf(0.0, soil - from_soil)
				needed -= from_soil
				total_taken += from_soil

		if needed > 0.0:
			var sources: Array = []
			var total_available: float = 0.0
			for offset in _CARDINAL:
				var neighbor: Vector2i = coord + offset
				var nbuf: Dictionary = _output_buffers.get(neighbor, {})
				var avail: float = float(nbuf.get(rid, 0.0))
				if avail > 0.0:
					sources.append([neighbor, avail])
					total_available += avail

			if total_available > 0.0:
				for source in sources:
					var neighbor: Vector2i = source[0]
					var avail: float = source[1]
					var fraction: float = avail / total_available
					var take: float = minf(needed * fraction, avail)
					_output_buffers[neighbor][rid] = maxf(0.0, float(_output_buffers[neighbor].get(rid, 0.0)) - take)
					total_taken += take

		if total_taken > 0.0:
			consumed[rid] = total_taken

	return consumed


func _produce_to_buffer(coord: Vector2i, species: SpeciesData, kingdom_id: StringName, throttle: float) -> void:
	var buf: Dictionary = _output_buffers.get(coord, {})
	var cap: float = get_buffer_cap(coord)

	var buf_total: float = 0.0
	for v in buf.values():
		buf_total += float(v)

	if buf_total >= cap:
		return

	var base_mult: float = throttle
	if bool(GameState.run_save.get("cycle_closed", false)):
		base_mult *= 1.5

	var age_ticks: int = _cached_tick - _territory.get_tile_placed_tick(coord)
	var maturation_mult: float = _maturation_yield_multiplier(age_ticks)
	var trait_mods: Dictionary = _compute_trait_modifiers(species)
	var level_mult: float = AdaptationSystem.species_level_multiplier(species.id)

	for resource_id in species.tick_yield.keys():
		var resource_key: StringName = StringName(resource_id)
		var base_yield: float = float(species.tick_yield[resource_id])
		if base_yield == 0.0:
			continue

		var per_tile: float = base_yield * base_mult * maturation_mult * level_mult

		var biome: BiomeData = _nutrients.get_biome_at(coord) if _nutrients != null else null
		if biome != null:
			per_tile *= float(species.biome_affinity.get(biome.id, 1.0))
			if resource_key == &"biomass" and kingdom_id != &"fungi":
				per_tile *= biome.sunlight_per_tick

		if resource_key == &"biomass":
			per_tile *= (1.0 + float(trait_mods.get(&"biomass_per_tile", 0.0)))
		elif resource_key == &"decay":
			per_tile *= (1.0 + float(trait_mods.get(&"decay_per_tile", 0.0)))
		elif resource_key == &"spores":
			per_tile *= (1.0 + float(trait_mods.get(&"spore_per_tile", 0.0)))

		if _is_tile_mycorrhizal_bonded(coord):
			per_tile *= 1.20

		if resource_key == &"biomass" and kingdom_id != &"fungi":
			if bool(_territory.get_tile_data(coord, "structure_mycorrhizal_hub", false)):
				per_tile *= 1.50
			if bool(_territory.get_tile_data(coord, "structure_old_growth", false)):
				per_tile *= 2.00
			if bool(_territory.get_tile_data(coord, "structure_fern_grove", false)):
				per_tile *= 1.30

		if resource_key == &"biomass" and _has_ancient_neighbor_of_same_kingdom(coord, kingdom_id):
			per_tile *= 1.05

		var room: float = cap - buf_total
		if room <= 0.0:
			break
		var added: float = minf(per_tile, room)
		buf[resource_key] = float(buf.get(resource_key, 0.0)) + added
		buf_total += added

	_output_buffers[coord] = buf


func _symbiotic_auto_transfer(all_coords: Array) -> void:
	for coord in all_coords:
		var occ: Dictionary = _territory.peek_occupants(coord)
		if not occ.has(&"fungi"):
			continue
		var species_id: StringName = occ[&"fungi"]
		var species: SpeciesData = _all_species.get(species_id, null)
		if species == null:
			continue
		if not species.tick_effects.has(&"mycorrhizal_bond_apply"):
			continue

		var buf: Dictionary = _output_buffers.get(coord, {})
		var n_avail: float = float(buf.get(&"nutrients", 0.0))
		if n_avail <= 0.0:
			continue

		var plant_neighbors: Array[Vector2i] = []
		for offset in _CARDINAL:
			var neighbor: Vector2i = coord + offset
			var nocc: Dictionary = _territory.peek_occupants(neighbor)
			if nocc.has(&"plantae"):
				plant_neighbors.append(neighbor)

		if plant_neighbors.is_empty():
			continue

		var per_plant: float = n_avail / float(plant_neighbors.size())
		for plant_coord in plant_neighbors:
			_soil_nutrients[plant_coord] = float(_soil_nutrients.get(plant_coord, 0.0)) + per_plant
		buf[&"nutrients"] = 0.0


func _on_run_started(_kingdom_id: StringName) -> void:
	_output_buffers.clear()
	_soil_nutrients.clear()
	_input_satisfaction.clear()
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
	for coord in coords:
		var buf: Dictionary = _output_buffers.get(coord, {})
		var cap: float = get_buffer_cap(coord)
		var buf_total: float = 0.0
		for v in buf.values():
			buf_total += float(v)
		for offset in _CARDINAL:
			var neighbor: Vector2i = coord + offset
			var occ: Dictionary = _territory.peek_occupants(neighbor)
			var is_target: bool = false
			for kingdom_id in targets:
				if occ.has(kingdom_id):
					is_target = true
					break
			if not is_target:
				continue
			var nbuf: Dictionary = _output_buffers.get(neighbor, {})
			var steal: float = minf(0.2, float(nbuf.get(&"biomass", 0.0)))
			if steal > 0.0 and buf_total < cap:
				nbuf[&"biomass"] = maxf(0.0, float(nbuf.get(&"biomass", 0.0)) - steal)
				buf[&"biomass"] = float(buf.get(&"biomass", 0.0)) + steal
				buf_total += steal
		_output_buffers[coord] = buf


func _effect_corpse_decay(_species: SpeciesData, _coords: Array[Vector2i]) -> void:
	pass


func _effect_mycorrhizal_bond_apply(_species: SpeciesData, coords: Array[Vector2i]) -> void:
	for coord in coords:
		for offset in _CARDINAL:
			var neighbor: Vector2i = coord + offset
			var occ: Dictionary = _territory.peek_occupants(neighbor)
			if occ.has(&"plantae") and not bool(_territory.get_tile_data(neighbor, "mycorrhizal_bond", false)):
				_territory.set_tile_data(neighbor, "mycorrhizal_bond", true)


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


func _maturation_yield_multiplier(age_ticks: int) -> float:
	if age_ticks < SPROUTING_DURATION:
		return 0.5
	if age_ticks < SPROUTING_DURATION + MATURE_DURATION:
		return 1.0
	return 1.3


func _has_ancient_neighbor_of_same_kingdom(coord: Vector2i, kingdom_id: StringName) -> bool:
	for offset in _CARDINAL:
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
