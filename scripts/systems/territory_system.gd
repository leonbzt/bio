extends Node

const _KINGDOM_DEFAULT_STARTERS: Dictionary[StringName, StringName] = {
	&"plantae": &"pioneer_grass",
	&"fungi": &"mycelium_thread",
	&"animals": &"common_grazer"
}

# Per-tile state: {occupants: {kingdom_id: species_id}, data: Dictionary}
var _tiles: Dictionary[Vector2i, Dictionary] = {}

@onready var _tile_grid: Node = get_node("../../TileGrid")


func _ready() -> void:
	EventBus.run_loaded.connect(_on_run_loaded)
	if not GameState.run_save.is_empty():
		_on_run_loaded(SaveSystem.SAVE_VERSION)


func _on_run_loaded(_save_version: int) -> void:
	_tiles.clear()
	if _tile_grid.has_method("clear_owned"):
		_tile_grid.clear_owned()
	var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
	var tiles_raw: Variant = run.get("tiles", [])
	if not (tiles_raw is Array):
		return
	for entry in tiles_raw:
		if not (entry is Dictionary):
			continue
		var coord_value: Variant = _parse_coord(entry.get("coord", []))
		if not (coord_value is Vector2i):
			continue
		var coord: Vector2i = coord_value
		var occupants_raw: Dictionary = entry.get("occupants", {}) as Dictionary
		var occupants: Dictionary = {}
		for kingdom in occupants_raw.keys():
			var species_id: StringName = StringName(occupants_raw[kingdom])
			if species_id == &"":
				continue
			occupants[StringName(kingdom)] = species_id
		var data: Dictionary = entry.get("data", {}) as Dictionary
		_tiles[coord] = {
			"occupants": occupants,
			"data": data
		}
		for kingdom_id in occupants.keys():
			if _tile_grid.has_method("set_occupant"):
				_tile_grid.set_occupant(coord, kingdom_id, occupants[kingdom_id])


func add_occupant(coord: Vector2i, kingdom_id: StringName, species_id: StringName) -> bool:
	if kingdom_id == &"" or species_id == &"":
		return false
	var entry: Dictionary = _ensure_entry(coord)
	var occupants: Dictionary = entry.get("occupants", {}) as Dictionary
	if occupants.has(kingdom_id):
		return false
	occupants[kingdom_id] = species_id
	entry["occupants"] = occupants
	_tiles[coord] = entry
	_set_tile_age(coord, _current_tick())  # Phase 15a: stamp tile age
	_bump_species_count(species_id, 1)     # Phase 15a: increment species count
	if _tile_grid.has_method("set_occupant"):
		_tile_grid.set_occupant(coord, kingdom_id, species_id)
	_sync_run_save()
	EventBus.tile_colonized.emit(coord, kingdom_id)
	return true


func get_occupant(coord: Vector2i, kingdom_id: StringName) -> StringName:
	if not _tiles.has(coord):
		return &""
	var occupants: Dictionary = _tiles[coord].get("occupants", {}) as Dictionary
	return StringName(occupants.get(kingdom_id, ""))


func remove_occupant(coord: Vector2i, kingdom_id: StringName, cause: StringName) -> void:
	if not _tiles.has(coord):
		return
	var entry: Dictionary = _tiles[coord]
	var occupants: Dictionary = entry.get("occupants", {}) as Dictionary
	if not occupants.has(kingdom_id):
		return
	var prev_species: StringName = StringName(occupants[kingdom_id])
	occupants.erase(kingdom_id)
	entry["occupants"] = occupants
	_tiles[coord] = entry
	_bump_species_count(prev_species, -1)  # Phase 15a: decrement species count
	if _tile_grid.has_method("clear_occupant"):
		_tile_grid.clear_occupant(coord, kingdom_id)
	_gc_if_empty(coord)
	_sync_run_save()
	EventBus.tile_lost.emit(coord, kingdom_id)


func get_occupants(coord: Vector2i) -> Dictionary:
	if not _tiles.has(coord):
		return {}
	return (_tiles[coord].get("occupants", {}) as Dictionary).duplicate()


func is_tile_occupied(coord: Vector2i) -> bool:
	if not _tiles.has(coord):
		return false
	var occupants: Dictionary = _tiles[coord].get("occupants", {}) as Dictionary
	return not occupants.is_empty()


func get_kingdom_occupied_coords(kingdom_id: StringName) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for coord in _tiles.keys():
		var occupants: Dictionary = _tiles[coord].get("occupants", {}) as Dictionary
		if occupants.has(kingdom_id):
			result.append(coord)
	return result


func get_species_occupied_coords(species_id: StringName) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for coord in _tiles.keys():
		var occupants: Dictionary = _tiles[coord].get("occupants", {}) as Dictionary
		for kingdom_id in occupants.keys():
			if StringName(occupants[kingdom_id]) == species_id:
				result.append(coord)
				break
	return result


func get_all_owned_coords() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for coord in _tiles.keys():
		var occupants: Dictionary = _tiles[coord].get("occupants", {}) as Dictionary
		if not occupants.is_empty():
			result.append(coord)
	return result


# DEPRECATED — see brief 04.
func get_surface_owner(coord: Vector2i) -> StringName:
	var occ: Dictionary = get_occupants(coord)
	if occ.has(&"animals"):
		return &"animals"
	if occ.has(&"plantae"):
		return &"plantae"
	return &""


# DEPRECATED — see brief 04.
func get_subsurface_owner(coord: Vector2i) -> StringName:
	if get_occupants(coord).has(&"fungi"):
		return &"fungi"
	return &""


# DEPRECATED — see brief 04.
func add_surface(coord: Vector2i, kingdom_id: StringName, variant: StringName = &"") -> bool:
	var species_id: StringName = _kingdom_starter(kingdom_id)
	if species_id == &"":
		return false
	return add_occupant(coord, kingdom_id, species_id)


# DEPRECATED — see brief 04.
func add_subsurface(coord: Vector2i, kingdom_id: StringName, variant: StringName = &"") -> bool:
	if kingdom_id != &"fungi":
		return false
	var species_id: StringName = _kingdom_starter(kingdom_id)
	return add_occupant(coord, kingdom_id, species_id)


# DEPRECATED — see brief 04.
func remove_surface(coord: Vector2i, cause: StringName) -> void:
	var owner: StringName = get_surface_owner(coord)
	if owner != &"":
		remove_occupant(coord, owner, cause)


# DEPRECATED — see brief 04.
func remove_subsurface(coord: Vector2i, cause: StringName) -> void:
	remove_occupant(coord, &"fungi", cause)


# DEPRECATED — see brief 04.
func get_surface_owned_coords(kingdom_id: StringName = &"") -> Array[Vector2i]:
	if kingdom_id == &"":
		var result: Array[Vector2i] = []
		for coord in _tiles.keys():
			var occ: Dictionary = _tiles[coord].get("occupants", {}) as Dictionary
			if occ.has(&"plantae") or occ.has(&"animals"):
				result.append(coord)
		return result
	return get_kingdom_occupied_coords(kingdom_id)


# DEPRECATED — see brief 04.
func get_subsurface_owned_coords(kingdom_id: StringName = &"") -> Array[Vector2i]:
	return get_kingdom_occupied_coords(kingdom_id if kingdom_id != &"" else &"fungi")


# DEPRECATED — see brief 04.
func get_owned_coords() -> Array[Vector2i]:
	var kingdom_id: StringName = StringName(GameState.run_save.get("starting_species_kingdom_id", ""))
	if kingdom_id == &"":
		return []
	return get_kingdom_occupied_coords(kingdom_id)


func reset_run() -> void:
	_tiles.clear()
	if _tile_grid.has_method("clear_owned"):
		_tile_grid.clear_owned()
	_sync_run_save()


func set_tile_data(coord: Vector2i, key: String, value: Variant) -> void:
	var entry: Dictionary = _ensure_entry(coord)
	var data: Dictionary = entry.get("data", {}) as Dictionary
	data[key] = value
	entry["data"] = data
	_tiles[coord] = entry
	_sync_run_save()


func get_tile_data(coord: Vector2i, key: String, default = null) -> Variant:
	if not _tiles.has(coord):
		return default
	var data: Dictionary = _tiles[coord].get("data", {}) as Dictionary
	return data.get(key, default)


func _ensure_entry(coord: Vector2i) -> Dictionary:
	if not _tiles.has(coord):
		_tiles[coord] = {
			"occupants": {},
			"data": {}
		}
	return _tiles[coord]


func _gc_if_empty(coord: Vector2i) -> void:
	if not _tiles.has(coord):
		return
	var entry: Dictionary = _tiles[coord]
	var occupants: Dictionary = entry.get("occupants", {}) as Dictionary
	if not occupants.is_empty():
		return
	_tiles.erase(coord)
	if _tile_grid.has_method("clear_all_occupants"):
		_tile_grid.clear_all_occupants(coord)


func _parse_coord(raw: Variant) -> Variant:
	if not (raw is Array) or raw.size() != 2:
		return null
	return Vector2i(int(raw[0]), int(raw[1]))


func _sync_run_save() -> void:
	var run: Dictionary
	if GameState.run_save is Dictionary:
		run = GameState.run_save
	else:
		run = {}
		GameState.run_save = run
	var tiles_array: Array = []
	for coord in _tiles.keys():
		var entry: Dictionary = _tiles[coord] as Dictionary
		var occupants: Dictionary = entry.get("occupants", {}) as Dictionary
		if occupants.is_empty():
			continue
		var serialized: Dictionary = {}
		for kingdom_id in occupants.keys():
			serialized[String(kingdom_id)] = String(occupants[kingdom_id])
		tiles_array.append({
			"coord": [coord.x, coord.y],
			"occupants": serialized,
			"data": entry.get("data", {})
		})
	run["tiles"] = tiles_array


func _kingdom_starter(kingdom_id: StringName) -> StringName:
	return _KINGDOM_DEFAULT_STARTERS.get(kingdom_id, &"")


# Phase 15a: tile age and species count tracking
func _set_tile_age(coord: Vector2i, tick: int) -> void:
	var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
	var ages: Dictionary = run.get("tile_ages", {}) as Dictionary
	ages["%d,%d" % [coord.x, coord.y]] = tick
	run["tile_ages"] = ages


func get_tile_placed_tick(coord: Vector2i) -> int:
	var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
	var ages: Dictionary = run.get("tile_ages", {}) as Dictionary
	return int(ages.get("%d,%d" % [coord.x, coord.y], _current_tick()))


func _bump_species_count(species_id: StringName, delta: int) -> void:
	var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
	var counts: Dictionary = run.get("species_tile_counts", {}) as Dictionary
	var sp_key: String = String(species_id)
	counts[sp_key] = maxi(0, int(counts.get(sp_key, 0)) + delta)
	run["species_tile_counts"] = counts


func get_species_tile_count(species_id: StringName) -> int:
	var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
	var counts: Dictionary = run.get("species_tile_counts", {}) as Dictionary
	return int(counts.get(String(species_id), 0))


func _current_tick() -> int:
	var stats: Dictionary = GameState.run_save.get("statistics", {}) as Dictionary
	return int(stats.get("tick_count", 0))


# Phase 15a: detect connected clusters of tiles
# Returns Array of clusters; each cluster is {species_id, kingdom_id, coords: Array[Vector2i]}.
# Connected via 4-neighbor adjacency, sharing the same species in the same kingdom slot.
func get_clusters() -> Array:
	var visited: Dictionary[String, bool] = {}
	var clusters: Array = []
	for coord in _tiles.keys():
		var occ: Dictionary = _tiles[coord].get("occupants", {}) as Dictionary
		for kingdom_id in occ.keys():
			var species_id: StringName = StringName(occ[kingdom_id])
			# Use composite key for visited tracking across kingdoms on same tile.
			var visit_key: String = "%d,%d:%s" % [coord.x, coord.y, String(kingdom_id)]
			if visited.has(visit_key):
				continue
			var cluster_coords: Array[Vector2i] = _flood_fill(coord, kingdom_id, species_id, visited, visit_key)
			if not cluster_coords.is_empty():
				clusters.append({
					"species_id": species_id,
					"kingdom_id": kingdom_id,
					"coords": cluster_coords
				})
	return clusters


func _flood_fill(start: Vector2i, kingdom_id: StringName, species_id: StringName,
				 visited: Dictionary, _seed_key: String) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var stack: Array[Vector2i] = [start]
	while not stack.is_empty():
		var c: Vector2i = stack.pop_back()
		var k: String = "%d,%d:%s" % [c.x, c.y, String(kingdom_id)]
		if visited.has(k):
			continue
		visited[k] = true
		var occ: Dictionary = _tiles.get(c, {}).get("occupants", {}) as Dictionary
		if StringName(occ.get(kingdom_id, &"")) != species_id:
			continue
		out.append(c)
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			stack.push_back(c + offset)
	return out
