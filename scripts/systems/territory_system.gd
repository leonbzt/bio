extends Node

const _KINGDOM_DEFAULT_STARTERS: Dictionary[StringName, StringName] = {
	&"plantae": &"pioneer_grass",
	&"fungi": &"mycelium_thread",
	&"animals": &"common_grazer"
}

# Per-tile state: {occupants: {kingdom_id: species_id}, data: Dictionary}
# Single-species-per-tile invariant (locked 2026-05-22, save_version 18+):
# the occupants dict has AT MOST ONE entry. The map-of-kingdom shape is
# preserved for API compatibility with peek_occupants / get_occupant
# callers (mostly per-kingdom-adjacency checks across the codebase), but
# `add_occupant` rejects any placement on an already-occupied tile.
# See docs/MIGRATION_PLAN.md VM-A2 and docs/VISUAL_DIRECTION.md
# "Locked long-term canvas (2026-05-22)".
var _tiles: Dictionary[Vector2i, Dictionary] = {}

# Perf (Tier 2): inverted indices so get_*_occupied_coords is O(1) lookup,
# not O(N) full-grid scan. Maintained incrementally in add/remove/_on_run_loaded.
# Value dicts hold coord -> true (used as ordered sets).
var _species_to_coords: Dictionary[StringName, Dictionary] = {}
var _kingdom_to_coords: Dictionary[StringName, Dictionary] = {}

# Perf (Tier 2): _sync_run_save was called on every single occupant/tile_data
# mutation, fully reserializing all tiles each time. Now we mark dirty and
# flush at most once per process frame, plus immediately on save_now().
var _dirty: bool = false

# Perf (Tier 2): clusters only change on tile_colonized / tile_lost. Cache
# the array and invalidate on those events instead of rebuilding per tick.
var _clusters_cache: Array = []
var _clusters_dirty: bool = true

@onready var _tile_grid: Node = get_node("../../TileGrid")


func _ready() -> void:
	EventBus.run_loaded.connect(_on_run_loaded)
	EventBus.tile_colonized.connect(_on_tile_change)
	EventBus.tile_lost.connect(_on_tile_change)
	if not GameState.run_save.is_empty():
		_on_run_loaded(SaveSystem.SAVE_VERSION)


func _process(_delta: float) -> void:
	if _dirty:
		_flush_run_save()


func _on_tile_change(_coord: Vector2i, _kingdom_or_owner: StringName) -> void:
	_clusters_dirty = true


func _on_run_loaded(_save_version: int) -> void:
	_tiles.clear()
	_species_to_coords.clear()
	_kingdom_to_coords.clear()
	_clusters_dirty = true
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
			var species_id_2: StringName = occupants[kingdom_id]
			_index_add(coord, kingdom_id, species_id_2)
			if _tile_grid.has_method("set_occupant"):
				_tile_grid.set_occupant(coord, kingdom_id, species_id_2)
	_clusters_dirty = true


func add_occupant(coord: Vector2i, kingdom_id: StringName, species_id: StringName) -> bool:
	if kingdom_id == &"" or species_id == &"":
		return false
	var entry: Dictionary = _ensure_entry(coord)
	var occupants: Dictionary = entry.get("occupants", {}) as Dictionary
	# Single-species-per-tile invariant: reject if tile is already occupied
	# by ANY species (not just same-kingdom). Caller must remove first to
	# replace. Cohabitation (e.g. plantae + fungi on one tile) is no longer
	# possible — symbiosis becomes an adjacency interaction in VM-B3.
	if not occupants.is_empty():
		return false
	occupants[kingdom_id] = species_id
	entry["occupants"] = occupants
	_tiles[coord] = entry
	_index_add(coord, kingdom_id, species_id)
	_set_tile_age(coord, _current_tick())  # Phase 15a: stamp tile age
	_bump_species_count(species_id, 1)     # Phase 15a: increment species count
	if _tile_grid.has_method("set_occupant"):
		_tile_grid.set_occupant(coord, kingdom_id, species_id)
	_mark_dirty()
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
	_index_remove(coord, kingdom_id, prev_species)
	_bump_species_count(prev_species, -1)  # Phase 15a: decrement species count
	if _tile_grid.has_method("clear_occupant"):
		_tile_grid.clear_occupant(coord, kingdom_id)
	_gc_if_empty(coord)
	_mark_dirty()
	EventBus.tile_lost.emit(coord, kingdom_id)


# Returns a COPY of the occupants dict for callers that need to keep it.
# Hot paths should use peek_occupants() / has_kingdom_at() instead.
func get_occupants(coord: Vector2i) -> Dictionary:
	if not _tiles.has(coord):
		return {}
	return (_tiles[coord].get("occupants", {}) as Dictionary).duplicate()


# Perf (Tier 2): no-allocation accessor for read-only callers. The returned
# dict is the live internal map — DO NOT mutate it.
func peek_occupants(coord: Vector2i) -> Dictionary:
	if not _tiles.has(coord):
		return {}
	return _tiles[coord].get("occupants", {}) as Dictionary


func has_kingdom_at(coord: Vector2i, kingdom_id: StringName) -> bool:
	if not _tiles.has(coord):
		return false
	return (_tiles[coord].get("occupants", {}) as Dictionary).has(kingdom_id)


func is_tile_occupied(coord: Vector2i) -> bool:
	if not _tiles.has(coord):
		return false
	var occupants: Dictionary = _tiles[coord].get("occupants", {}) as Dictionary
	return not occupants.is_empty()


func get_kingdom_occupied_coords(kingdom_id: StringName) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var set_dict: Dictionary = _kingdom_to_coords.get(kingdom_id, {}) as Dictionary
	for coord in set_dict.keys():
		result.append(coord)
	return result


func get_species_occupied_coords(species_id: StringName) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var set_dict: Dictionary = _species_to_coords.get(species_id, {}) as Dictionary
	for coord in set_dict.keys():
		result.append(coord)
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
	var occ: Dictionary = peek_occupants(coord)
	if occ.has(&"animals"):
		return &"animals"
	if occ.has(&"plantae"):
		return &"plantae"
	return &""


# DEPRECATED — see brief 04.
func get_subsurface_owner(coord: Vector2i) -> StringName:
	if peek_occupants(coord).has(&"fungi"):
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
		var plant_coords: Dictionary = _kingdom_to_coords.get(&"plantae", {}) as Dictionary
		var animal_coords: Dictionary = _kingdom_to_coords.get(&"animals", {}) as Dictionary
		var seen: Dictionary = {}
		var result: Array[Vector2i] = []
		for coord in plant_coords.keys():
			seen[coord] = true
			result.append(coord)
		for coord in animal_coords.keys():
			if not seen.has(coord):
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
	_species_to_coords.clear()
	_kingdom_to_coords.clear()
	_clusters_cache.clear()
	_clusters_dirty = true
	if _tile_grid.has_method("clear_owned"):
		_tile_grid.clear_owned()
	_mark_dirty()


func set_tile_data(coord: Vector2i, key: String, value: Variant) -> void:
	var entry: Dictionary = _ensure_entry(coord)
	var data: Dictionary = entry.get("data", {}) as Dictionary
	data[key] = value
	entry["data"] = data
	_tiles[coord] = entry
	_mark_dirty()


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


func _mark_dirty() -> void:
	_dirty = true
	_clusters_dirty = true


# Called by SaveSystem.save_now() before serializing, so on-disk state always
# reflects the latest mutations even if a frame hasn't ticked yet.
func flush_to_save_immediate() -> void:
	if _dirty:
		_flush_run_save()


func _flush_run_save() -> void:
	_dirty = false
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


func _index_add(coord: Vector2i, kingdom_id: StringName, species_id: StringName) -> void:
	if not _species_to_coords.has(species_id):
		_species_to_coords[species_id] = {}
	(_species_to_coords[species_id] as Dictionary)[coord] = true
	if not _kingdom_to_coords.has(kingdom_id):
		_kingdom_to_coords[kingdom_id] = {}
	(_kingdom_to_coords[kingdom_id] as Dictionary)[coord] = true


func _index_remove(coord: Vector2i, kingdom_id: StringName, species_id: StringName) -> void:
	var sp_set: Dictionary = _species_to_coords.get(species_id, {}) as Dictionary
	if sp_set.has(coord):
		sp_set.erase(coord)
		if sp_set.is_empty():
			_species_to_coords.erase(species_id)
	var k_set: Dictionary = _kingdom_to_coords.get(kingdom_id, {}) as Dictionary
	if k_set.has(coord):
		k_set.erase(coord)
		if k_set.is_empty():
			_kingdom_to_coords.erase(kingdom_id)


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


# Phase 15a: detect connected clusters of tiles.
# Returns Array of clusters; each cluster is {species_id, kingdom_id, coords: Array[Vector2i]}.
# Connected via 4-neighbor adjacency, sharing the same species in the same kingdom slot.
# Perf (Tier 2): result is cached and only recomputed when _clusters_dirty.
func get_clusters() -> Array:
	if not _clusters_dirty:
		return _clusters_cache
	_clusters_dirty = false
	_clusters_cache = _compute_clusters()
	return _clusters_cache


func _compute_clusters() -> Array:
	# Visited keyed by Vector2i in a nested per-kingdom dict — avoids the
	# per-cell string allocation the old "%d,%d:%s" key used.
	var visited_by_kingdom: Dictionary[StringName, Dictionary] = {}
	var clusters: Array = []
	for coord in _tiles.keys():
		var occ: Dictionary = _tiles[coord].get("occupants", {}) as Dictionary
		for kingdom_id in occ.keys():
			var visited: Dictionary = visited_by_kingdom.get(kingdom_id, {}) as Dictionary
			if visited.has(coord):
				continue
			if not visited_by_kingdom.has(kingdom_id):
				visited_by_kingdom[kingdom_id] = visited
			var species_id: StringName = StringName(occ[kingdom_id])
			var cluster_coords: Array[Vector2i] = _flood_fill(coord, kingdom_id, species_id, visited)
			if not cluster_coords.is_empty():
				clusters.append({
					"species_id": species_id,
					"kingdom_id": kingdom_id,
					"coords": cluster_coords
				})
	return clusters


func _flood_fill(start: Vector2i, kingdom_id: StringName, species_id: StringName,
				 visited: Dictionary) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var stack: Array[Vector2i] = [start]
	while not stack.is_empty():
		var c: Vector2i = stack.pop_back()
		if visited.has(c):
			continue
		visited[c] = true
		var occ: Dictionary = _tiles.get(c, {}).get("occupants", {}) as Dictionary
		if StringName(occ.get(kingdom_id, &"")) != species_id:
			continue
		out.append(c)
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			stack.push_back(c + offset)
	return out
