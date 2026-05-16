extends Node

const SURFACE_PLANTAE: StringName = &"plantae"
const SUBSURFACE_FUNGI: StringName = &"fungi"

# Per-tile state: {surface_owner, subsurface_owner, data}
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
	if tiles_raw is Array:
		for entry in tiles_raw:
			if not (entry is Dictionary):
				continue
			var coord_value: Variant = _parse_coord(entry.get("coord", []))
			if not (coord_value is Vector2i):
				continue
			var coord: Vector2i = coord_value
			var surface_owner: StringName = StringName(entry.get("surface_owner", ""))
			var subsurface_owner: StringName = StringName(entry.get("subsurface_owner", ""))
			var data: Dictionary = entry.get("data", {}) as Dictionary
			var surface_variant: StringName = StringName(data.get("surface_variant", ""))
			var subsurface_variant: StringName = StringName(data.get("subsurface_variant", ""))
			_tiles[coord] = {
				"surface_owner": surface_owner,
				"subsurface_owner": subsurface_owner,
				"data": data
			}
			if surface_owner != &"" and _tile_grid.has_method("set_surface_owner"):
				_tile_grid.set_surface_owner(coord, surface_owner, surface_variant)
			if subsurface_owner != &"" and _tile_grid.has_method("set_subsurface_owner"):
				_tile_grid.set_subsurface_owner(coord, subsurface_owner, subsurface_variant)


func add_surface(coord: Vector2i, kingdom_id: StringName, variant: StringName = &"") -> bool:
	var entry: Dictionary = _ensure_entry(coord)
	if entry.get("surface_owner", &"") != &"":
		return false
	entry["surface_owner"] = kingdom_id
	var data: Dictionary = entry.get("data", {}) as Dictionary
	if variant != &"":
		data["surface_variant"] = String(variant)
	else:
		data.erase("surface_variant")
	entry["data"] = data
	if _tile_grid.has_method("set_surface_owner"):
		_tile_grid.set_surface_owner(coord, kingdom_id, variant)
	_sync_run_save()
	EventBus.tile_colonized.emit(coord, kingdom_id)
	return true


func add_subsurface(coord: Vector2i, kingdom_id: StringName, variant: StringName = &"") -> bool:
	var entry: Dictionary = _ensure_entry(coord)
	if entry.get("subsurface_owner", &"") != &"":
		return false
	entry["subsurface_owner"] = kingdom_id
	var data: Dictionary = entry.get("data", {}) as Dictionary
	if variant != &"":
		data["subsurface_variant"] = String(variant)
	else:
		data.erase("subsurface_variant")
	entry["data"] = data
	if _tile_grid.has_method("set_subsurface_owner"):
		_tile_grid.set_subsurface_owner(coord, kingdom_id, variant)
	_sync_run_save()
	EventBus.tile_colonized.emit(coord, kingdom_id)
	return true


func remove_surface(coord: Vector2i, cause: StringName) -> void:
	if not _tiles.has(coord):
		return
	var entry: Dictionary = _tiles[coord]
	var prev: StringName = entry.get("surface_owner", &"")
	if prev == &"":
		return
	entry["surface_owner"] = &""
	var data: Dictionary = entry.get("data", {}) as Dictionary
	data.erase("surface_variant")
	entry["data"] = data
	if _tile_grid.has_method("set_surface_owner"):
		_tile_grid.set_surface_owner(coord, &"")
	_gc_if_empty(coord)
	_sync_run_save()
	EventBus.tile_lost.emit(coord, prev)


func remove_subsurface(coord: Vector2i, cause: StringName) -> void:
	if not _tiles.has(coord):
		return
	var entry: Dictionary = _tiles[coord]
	var prev: StringName = entry.get("subsurface_owner", &"")
	if prev == &"":
		return
	entry["subsurface_owner"] = &""
	var data: Dictionary = entry.get("data", {}) as Dictionary
	data.erase("subsurface_variant")
	entry["data"] = data
	if _tile_grid.has_method("set_subsurface_owner"):
		_tile_grid.set_subsurface_owner(coord, &"")
	_gc_if_empty(coord)
	_sync_run_save()
	EventBus.tile_lost.emit(coord, prev)


func get_surface_owner(coord: Vector2i) -> StringName:
	if not _tiles.has(coord):
		return &""
	return _tiles[coord].get("surface_owner", &"")


func get_subsurface_owner(coord: Vector2i) -> StringName:
	if not _tiles.has(coord):
		return &""
	return _tiles[coord].get("subsurface_owner", &"")


func get_surface_owned_coords(kingdom_id: StringName = &"") -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for coord in _tiles.keys():
		var owner: StringName = _tiles[coord].get("surface_owner", &"")
		if owner == &"":
			continue
		if kingdom_id != &"" and owner != kingdom_id:
			continue
		result.append(coord)
	return result


func get_subsurface_owned_coords(kingdom_id: StringName = &"") -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for coord in _tiles.keys():
		var owner: StringName = _tiles[coord].get("subsurface_owner", &"")
		if owner == &"":
			continue
		if kingdom_id != &"" and owner != kingdom_id:
			continue
		result.append(coord)
	return result


func get_owned_coords() -> Array[Vector2i]:
	if GameState.current_kingdom_id == SUBSURFACE_FUNGI:
		return get_subsurface_owned_coords(SUBSURFACE_FUNGI)
	return get_surface_owned_coords(SURFACE_PLANTAE)


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
	_sync_run_save()


func get_tile_data(coord: Vector2i, key: String, default = null) -> Variant:
	if not _tiles.has(coord):
		return default
	var data: Dictionary = _tiles[coord].get("data", {}) as Dictionary
	return data.get(key, default)


func _ensure_entry(coord: Vector2i) -> Dictionary:
	if not _tiles.has(coord):
		_tiles[coord] = {
			"surface_owner": &"",
			"subsurface_owner": &"",
			"data": {}
		}
	return _tiles[coord]


func _gc_if_empty(coord: Vector2i) -> void:
	if not _tiles.has(coord):
		return
	var entry: Dictionary = _tiles[coord]
	if entry.get("surface_owner", &"") != &"":
		return
	if entry.get("subsurface_owner", &"") != &"":
		return
	_tiles.erase(coord)


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
		var surface_owner: StringName = entry.get("surface_owner", &"")
		var subsurface_owner: StringName = entry.get("subsurface_owner", &"")
		var data: Dictionary = entry.get("data", {}) as Dictionary
		tiles_array.append({
			"coord": [coord.x, coord.y],
			"surface_owner": String(surface_owner),
			"subsurface_owner": String(subsurface_owner),
			"data": data
		})
	run["tiles"] = tiles_array
