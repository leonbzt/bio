extends Node

const SPECIES_INDEX_PATH: String = "res://data/species/_index.tres"
# Phase 15a: cost scaling factor
const COST_GROWTH_FACTOR: float = 1.05


func evaluate(coord: Vector2i, species: SpeciesData) -> Dictionary:
	if species == null:
		return _invalid()
	var fog: Node = _get_fog_system()
	if fog != null and fog.has_method("is_revealed") and not fog.is_revealed(coord):
		return _invalid()
	var obstacles: Node = _get_obstacle_system()
	if obstacles != null and obstacles.has_method("is_obstacle") and obstacles.is_obstacle(coord):
		return _invalid()
	match species.placement_rule:
		&"adjacent_empty":
			return _rule_adjacent_empty(coord, species)
		&"fungi_substrate":
			return _rule_fungi_substrate(coord, species)
		&"parasitic_plantae":
			return _rule_parasitic_plantae(coord, species)
		&"mycorrhizal_fungi":
			return _rule_mycorrhizal_fungi(coord, species)
		&"animal_anchor":
			return _rule_animal_anchor(coord, species)
		&"recipe":
			return _rule_recipe(coord, species)
		_:
			push_warning("ColonizationRulesRegistry: unknown rule %s" % String(species.placement_rule))
			return _invalid()


func _invalid() -> Dictionary:
	return {"valid": false, "cost": {}, "data": {}, "placements": []}


func _rule_adjacent_empty(coord: Vector2i, species: SpeciesData) -> Dictionary:
	var territory: Node = _get_territory()
	if territory == null:
		return _invalid()
	var kingdom_id: StringName = species.kingdom_id
	if territory.get_occupant(coord, kingdom_id) != &"":
		return _invalid()

	var owned: Array[Vector2i] = territory.get_kingdom_occupied_coords(kingdom_id)
	# Phase 14a: pioneer-tagged species can start and spread without adjacency.
	if species.tags.has(&"pioneer"):
		var pioneer_cost: Dictionary = _scaled_cost(species) if not owned.is_empty() else species.colonize_cost.duplicate()
		if MetaModifiers.is_unlocked(&"thrifty_growth"):
			for k in pioneer_cost.keys():
				pioneer_cost[k] = maxf(0.0, float(pioneer_cost[k]) - 1.0)
		if owned.is_empty():
			pioneer_cost = {}
		return {
			"valid": true,
			"cost": pioneer_cost,
			"data": {},
			"placements": [{
				"coord": coord,
				"kingdom_id": kingdom_id,
				"species_id": species.id,
				"data": {}
			}]
		}

	# Note: `successor` is intentionally a no-op in Phase 14a; it follows the
	# standard adjacent-empty flow until tile-history predicates land.
	if owned.size() > 0:
		var owned_set: Dictionary = {}
		for c in owned:
			owned_set[c] = true
		var has_neighbor: bool = false
		for n in neighbors(coord):
			if owned_set.has(n):
				has_neighbor = true
				break
		if not has_neighbor:
			return _invalid()

	var cost: Dictionary = _scaled_cost(species) if not owned.is_empty() else species.colonize_cost.duplicate()
	if MetaModifiers.is_unlocked(&"thrifty_growth"):
		for k in cost.keys():
			cost[k] = maxf(0.0, float(cost[k]) - 1.0)
	if owned.is_empty():
		cost = {}
	return {
		"valid": true,
		"cost": cost,
		"data": {},
		"placements": [{
			"coord": coord,
			"kingdom_id": kingdom_id,
			"species_id": species.id,
			"data": {}
		}]
	}


func _rule_fungi_substrate(coord: Vector2i, species: SpeciesData) -> Dictionary:
	var territory: Node = _get_territory()
	if territory == null:
		return _invalid()
	var kingdom_id: StringName = species.kingdom_id
	if territory.get_occupant(coord, kingdom_id) != &"":
		return _invalid()
	var owned: Array[Vector2i] = territory.get_kingdom_occupied_coords(kingdom_id)

	# Phase 14a: pioneer-tagged fungi can colonize bare tiles without substrate.
	if species.tags.has(&"pioneer"):
		var pioneer_cost: Dictionary = _scaled_cost_with_traits(species)
		if owned.is_empty():
			pioneer_cost = {}
		return _single(coord, species, pioneer_cost, {})

	if owned.is_empty():
		return _single(coord, species, {}, {})

	if territory.get_occupant(coord, &"plantae") != &"":
		return _single(coord, species, _scaled_cost_with_traits(species), {})
	if _is_corpse_at(coord):
		return _single(coord, species, _scaled_cost_with_traits(species), {})

	var owned_set: Dictionary = {}
	for c in owned:
		owned_set[c] = true
	for offset in neighbors(coord):
		if owned_set.has(offset):
			return _single(coord, species, _scaled_cost_with_traits(species), {})

	if MetaModifiers.is_unlocked(&"spore_distribution"):
		var charges: int = _get_spore_distribution_charges()
		if charges > 0 and _has_line_of_sight(coord, owned):
			_set_spore_distribution_charges(charges - 1)
			return _single(coord, species, _scaled_cost_with_traits(species), {})

	return _invalid()


func _rule_parasitic_plantae(coord: Vector2i, species: SpeciesData) -> Dictionary:
	var territory: Node = _get_territory()
	if territory == null:
		return _invalid()
	var kingdom_id: StringName = species.kingdom_id
	if territory.get_occupant(coord, kingdom_id) != &"":
		return _invalid()
	var owned: Array[Vector2i] = territory.get_kingdom_occupied_coords(kingdom_id)
	if owned.is_empty():
		return _single(coord, species, {}, {"parasite_decay_ticks": 30})

	var has_neighbor: bool = false
	for n in neighbors(coord):
		var occ: Dictionary = territory.get_occupants(n)
		if not occ.is_empty():
			has_neighbor = true
			break
	if not has_neighbor:
		return _invalid()
	var cost: Dictionary = _scaled_cost(species)
	if MetaModifiers.is_unlocked(&"thrifty_growth"):
		for k in cost.keys():
			cost[k] = maxf(0.0, float(cost[k]) - 1.0)
	return _single(coord, species, cost, {"parasite_decay_ticks": 30})


func _rule_mycorrhizal_fungi(coord: Vector2i, species: SpeciesData) -> Dictionary:
	var territory: Node = _get_territory()
	if territory == null:
		return _invalid()
	var kingdom_id: StringName = species.kingdom_id
	if territory.get_occupant(coord, kingdom_id) != &"":
		return _invalid()
	var plant_at_or_adjacent: bool = territory.get_occupant(coord, &"plantae") != &""
	if not plant_at_or_adjacent:
		for n in neighbors(coord):
			if territory.get_occupant(n, &"plantae") != &"":
				plant_at_or_adjacent = true
				break
	if not plant_at_or_adjacent:
		return _invalid()
	var data := {}
	if territory.get_occupant(coord, &"plantae") != &"":
		data["mycorrhizal_bond"] = true
	return _single(coord, species, _scaled_cost_with_traits(species), data)


func _rule_animal_anchor(coord: Vector2i, species: SpeciesData) -> Dictionary:
	var territory: Node = _get_territory()
	if territory == null:
		return _invalid()
	var kingdom_id: StringName = species.kingdom_id
	if territory.get_occupant(coord, kingdom_id) != &"":
		return _invalid()
	var owned: Array[Vector2i] = territory.get_kingdom_occupied_coords(kingdom_id)
	if owned.is_empty():
		return _single(coord, species, {}, {})
	var has_neighbor: bool = false
	for n in neighbors(coord):
		var occ: Dictionary = territory.get_occupants(n)
		if not occ.is_empty():
			has_neighbor = true
			break
	if not has_neighbor:
		return _invalid()
	return _single(coord, species, _scaled_cost_with_traits(species), {})


func _rule_recipe(coord: Vector2i, species: SpeciesData) -> Dictionary:
	if species.recipe_components.is_empty():
		push_warning("Recipe species %s has no components" % String(species.id))
		return _invalid()
	var territory: Node = _get_territory()
	if territory == null:
		return _invalid()
	var combined_placements: Array = []
	var combined_cost: Dictionary = species.colonize_cost.duplicate()
	var data_carry: Dictionary = {}
	for component_id in species.recipe_components:
		var component: SpeciesData = _species_lookup(component_id)
		if component == null:
			return _invalid()
		var sub: Dictionary = evaluate(coord, component)
		if not bool(sub.get("valid", false)):
			return _invalid()
		if territory.get_occupant(coord, component.kingdom_id) != &"":
			return _invalid()
		for key in (sub.get("cost", {}) as Dictionary).keys():
			combined_cost[key] = float(combined_cost.get(key, 0.0)) + float(sub["cost"][key])
		for key in (sub.get("data", {}) as Dictionary).keys():
			data_carry[key] = sub["data"][key]
		for placement in sub.get("placements", []):
			combined_placements.append(placement)
	return {
		"valid": true,
		"cost": combined_cost,
		"data": data_carry,
		"placements": combined_placements
	}


func _single(coord: Vector2i, species: SpeciesData, cost: Dictionary, data: Dictionary) -> Dictionary:
	return {
		"valid": true,
		"cost": cost,
		"data": data,
		"placements": [{
			"coord": coord,
			"kingdom_id": species.kingdom_id,
			"species_id": species.id,
			"data": data
		}]
	}


func neighbors(coord: Vector2i) -> Array[Vector2i]:
	return [
		coord + Vector2i.LEFT,
		coord + Vector2i.RIGHT,
		coord + Vector2i.UP,
		coord + Vector2i.DOWN
	]


func _get_territory() -> Node:
	return get_tree().root.get_node_or_null("World/Systems/TerritorySystem")


func _get_fog_system() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null("World/Systems/FogSystem")


func _get_obstacle_system() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null("World/Systems/ObstacleSystem")


func _get_corpses() -> Node:
	return get_tree().root.get_node_or_null("World/Systems/CorpseSystem")


func _is_corpse_at(coord: Vector2i) -> bool:
	var corpses: Node = _get_corpses()
	if corpses == null:
		return false
	if corpses.has_method("is_corpse_at"):
		return corpses.is_corpse_at(coord)
	return false


func _apply_trait_cost_modifiers(cost: Dictionary, species: SpeciesData) -> Dictionary:
	var total_modifier: float = 0.0
	for trait_item in species.base_traits:
		if trait_item == null:
			continue
		total_modifier += float(trait_item.modifiers.get("colonize_cost", 0.0))
	if total_modifier == 0.0:
		return cost
	for key in cost.keys():
		cost[key] = maxf(0.0, float(cost[key]) * (1.0 + total_modifier))
	return cost


func _get_spore_distribution_charges() -> int:
	var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
	return int(run.get("spore_distribution_charges", 0))


func _set_spore_distribution_charges(value: int) -> void:
	if GameState.run_save is Dictionary:
		GameState.run_save["spore_distribution_charges"] = maxi(0, value)
		SaveSystem.save_now()


func _has_line_of_sight(coord: Vector2i, owned: Array[Vector2i]) -> bool:
	for c in owned:
		if c.x == coord.x or c.y == coord.y:
			return true
	return false


func _species_lookup(species_id: StringName) -> SpeciesData:
	var index: SpeciesIndex = load(SPECIES_INDEX_PATH) as SpeciesIndex
	if index == null:
		return null
	for sp in index.species:
		if sp.id == species_id:
			return sp
	return null


# Phase 15a: scale cost based on number of owned tiles of this species
func _scaled_cost(species: SpeciesData) -> Dictionary:
	var base: Dictionary = species.colonize_cost.duplicate()
	var n: int = _get_territory().get_species_tile_count(species.id)
	var mult: float = pow(COST_GROWTH_FACTOR, float(n))
	var scaled: Dictionary = {}
	for resource_id in base.keys():
		scaled[resource_id] = float(base[resource_id]) * mult
	return scaled


# Phase 15a: apply trait modifiers then scale for owned count
func _scaled_cost_with_traits(species: SpeciesData) -> Dictionary:
	var cost: Dictionary = _scaled_cost(species)
	return _apply_trait_cost_modifiers(cost, species)
