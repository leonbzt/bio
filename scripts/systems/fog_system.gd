extends Node

signal fog_updated()

const REVEAL_RADIUS: int = 2

var _revealed: Dictionary[Vector2i, bool] = {}

@onready var _tile_grid: Node = get_node("../../TileGrid")
@onready var _territory: Node = get_node("../TerritorySystem")


func _ready() -> void:
	EventBus.run_loaded.connect(_on_run_loaded)
	EventBus.tile_colonized.connect(_on_tile_colonized)
	if not GameState.run_save.is_empty():
		_on_run_loaded(SaveSystem.SAVE_VERSION)


func _on_run_loaded(_v: int) -> void:
	_revealed.clear()
	var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
	var raw: Array = run.get("fog_revealed", []) as Array
	for k in raw:
		var coord: Vector2i = _parse_coord(String(k))
		_revealed[coord] = true
	if _revealed.is_empty():
		var cx: int = int(_tile_grid.GRID_WIDTH / 2)
		var cy: int = int(_tile_grid.GRID_HEIGHT / 2)
		reveal_area(Vector2i(cx, cy), REVEAL_RADIUS)
		return
	_push_to_tile_grid()
	fog_updated.emit()


func _on_tile_colonized(coord: Vector2i, _owner_id: StringName) -> void:
	reveal_area(coord, REVEAL_RADIUS)


func reveal_area(center: Vector2i, radius: int) -> void:
	var newly_revealed: Array[Vector2i] = []
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var c: Vector2i = Vector2i(center.x + dx, center.y + dy)
			if not _is_in_bounds(c):
				continue
			if _revealed.has(c):
				continue
			_revealed[c] = true
			newly_revealed.append(c)
	if newly_revealed.is_empty():
		return
	_persist()
	if _tile_grid.has_method("reveal_tiles"):
		_tile_grid.reveal_tiles(newly_revealed)
	fog_updated.emit()


func is_revealed(coord: Vector2i) -> bool:
	return _revealed.has(coord)


func get_revealed_count() -> int:
	return _revealed.size()


func _is_in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < _tile_grid.GRID_WIDTH and c.y < _tile_grid.GRID_HEIGHT


func _persist() -> void:
	var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
	var arr: Array = []
	for c in _revealed.keys():
		arr.append("%d,%d" % [c.x, c.y])
	run["fog_revealed"] = arr


func _push_to_tile_grid() -> void:
	if not _tile_grid.has_method("set_fog_state"):
		return
	var arr: Array[Vector2i] = []
	for c in _revealed.keys():
		arr.append(c)
	_tile_grid.set_fog_state(arr)


func _parse_coord(s: String) -> Vector2i:
	var parts := s.split(",", false)
	if parts.size() != 2:
		return Vector2i.ZERO
	return Vector2i(int(parts[0]), int(parts[1]))
