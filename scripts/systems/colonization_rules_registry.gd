extends Node

# Returns {"valid": bool, "cost": Dictionary, "data": Dictionary}.
func evaluate(rule: StringName, coord: Vector2i, kingdom_id: StringName, species: SpeciesData, niche: NicheData) -> Dictionary:
	match rule:
		&"adjacent_empty":
			return _rule_adjacent_empty(coord, kingdom_id, species, niche)
		&"fungi_substrate":
			return _rule_fungi_substrate(coord, kingdom_id, species, niche)
		&"parasitic_plantae":
			return _rule_parasitic_plantae(coord, kingdom_id, species, niche)
		&"mycorrhizal_fungi":
			return _rule_mycorrhizal_fungi(coord, kingdom_id, species, niche)
		_:
			push_warning("ColonizationRulesRegistry: unknown rule %s" % String(rule))
			return {"valid": false, "cost": {}, "data": {}}


func _rule_adjacent_empty(coord: Vector2i, kingdom_id: StringName, species: SpeciesData, niche: NicheData) -> Dictionary:
	var territory: Node = _get_territory()
	if territory == null:
		return {"valid": false, "cost": {}, "data": {}}
	if territory.get_surface_owner(coord) != &"":
		return {"valid": false, "cost": {}, "data": {}}

	var owned: Array[Vector2i] = territory.get_surface_owned_coords(kingdom_id)
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
			return {"valid": false, "cost": {}, "data": {}}

	var cost: Dictionary
	if not niche.cost_override.is_empty():
		cost = niche.cost_override.duplicate()
	else:
		cost = species.colonize_cost.duplicate()
	if MetaModifiers.is_unlocked(&"thrifty_growth"):
		for k in cost.keys():
			cost[k] = maxf(0.0, float(cost[k]) - 1.0)
	if owned.is_empty():
		cost = {}

	return {"valid": true, "cost": cost, "data": {}}


func _rule_fungi_substrate(coord: Vector2i, kingdom_id: StringName, species: SpeciesData, niche: NicheData) -> Dictionary:
	var territory: Node = _get_territory()
	if territory == null:
		return {"valid": false, "cost": {}, "data": {}}
	if territory.get_subsurface_owner(coord) != &"":
		return {"valid": false, "cost": {}, "data": {}}

	var owned: Array[Vector2i] = territory.get_subsurface_owned_coords(kingdom_id)
	if owned.is_empty():
		return {"valid": true, "cost": {}, "data": {}}
	if territory.get_surface_owner(coord) == &"plantae":
		return {"valid": true, "cost": _apply_trait_cost_modifiers(_resolve_cost(species, niche), species), "data": {}}
	if _is_corpse_at(coord):
		return {"valid": true, "cost": _apply_trait_cost_modifiers(_resolve_cost(species, niche), species), "data": {}}

	var owned_set: Dictionary = {}
	for c in owned:
		owned_set[c] = true
	for offset in neighbors(coord):
		if owned_set.has(offset):
			return {"valid": true, "cost": _apply_trait_cost_modifiers(_resolve_cost(species, niche), species), "data": {}}

	return {"valid": false, "cost": {}, "data": {}}


func _rule_parasitic_plantae(coord: Vector2i, kingdom_id: StringName, species: SpeciesData, niche: NicheData) -> Dictionary:
	var territory: Node = _get_territory()
	if territory == null:
		return {"valid": false, "cost": {}, "data": {}}
	if territory.get_surface_owner(coord) != &"":
		return {"valid": false, "cost": {}, "data": {}}

	var owned: Array[Vector2i] = territory.get_surface_owned_coords(kingdom_id)
	if owned.is_empty():
		return {"valid": true, "cost": {}, "data": {"parasite_decay_ticks": 30}}

	var has_neighbor: bool = false
	for n in neighbors(coord):
		if territory.get_surface_owner(n) != &"" or territory.get_subsurface_owner(n) != &"":
			has_neighbor = true
			break
	if not has_neighbor:
		return {"valid": false, "cost": {}, "data": {}}

	var cost: Dictionary = _resolve_cost(species, niche)
	if MetaModifiers.is_unlocked(&"thrifty_growth"):
		for k in cost.keys():
			cost[k] = maxf(0.0, float(cost[k]) - 1.0)

	return {"valid": true, "cost": cost, "data": {"parasite_decay_ticks": 30}}


func _rule_mycorrhizal_fungi(coord: Vector2i, kingdom_id: StringName, species: SpeciesData, niche: NicheData) -> Dictionary:
	var territory: Node = _get_territory()
	if territory == null:
		return {"valid": false, "cost": {}, "data": {}}
	if territory.get_subsurface_owner(coord) != &"":
		return {"valid": false, "cost": {}, "data": {}}

	var owned: Array[Vector2i] = territory.get_subsurface_owned_coords(kingdom_id)
	var plant_at_or_adjacent: bool = territory.get_surface_owner(coord) == &"plantae"
	if not plant_at_or_adjacent:
		for n in neighbors(coord):
			if territory.get_surface_owner(n) == &"plantae":
				plant_at_or_adjacent = true
				break

	if owned.is_empty():
		if not plant_at_or_adjacent:
			return {"valid": false, "cost": {}, "data": {}}
		return {"valid": true, "cost": {}, "data": {}}

	var owned_set: Dictionary = {}
	for c in owned:
		owned_set[c] = true
	var has_neighbor: bool = plant_at_or_adjacent
	if not has_neighbor:
		for n in neighbors(coord):
			if owned_set.has(n):
				has_neighbor = true
				break
	if not has_neighbor:
		return {"valid": false, "cost": {}, "data": {}}

	var cost: Dictionary = _apply_trait_cost_modifiers(_resolve_cost(species, niche), species)
	return {"valid": true, "cost": cost, "data": {}}


func neighbors(coord: Vector2i) -> Array[Vector2i]:
	return [
		coord + Vector2i.LEFT,
		coord + Vector2i.RIGHT,
		coord + Vector2i.UP,
		coord + Vector2i.DOWN
	]


func _get_territory() -> Node:
	return get_tree().root.get_node_or_null("World/Systems/TerritorySystem")


func _get_corpses() -> Node:
	return get_tree().root.get_node_or_null("World/Systems/CorpseSystem")


func _is_corpse_at(coord: Vector2i) -> bool:
	var corpses: Node = _get_corpses()
	if corpses == null:
		return false
	if corpses.has_method("is_corpse_at"):
		return corpses.is_corpse_at(coord)
	return false


func _resolve_cost(species: SpeciesData, niche: NicheData) -> Dictionary:
	if not niche.cost_override.is_empty():
		return niche.cost_override.duplicate()
	return species.colonize_cost.duplicate()


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
