extends Node

const OBSTACLE_RATE: float = 0.05
const GRID_W: int = 32
const GRID_H: int = 48
const START_CLEAR_RADIUS: int = 3

var _obstacles: Dictionary[Vector2i, bool] = {}

@onready var _tile_grid: Node = get_node("../../TileGrid")
@onready var _territory: Node = get_node("../TerritorySystem")


func _ready() -> void:
	EventBus.run_loaded.connect(_on_run_loaded)
	if not GameState.run_save.is_empty():
		_on_run_loaded(SaveSystem.SAVE_VERSION)


func _on_run_loaded(_v: int) -> void:
	_obstacles.clear()
	var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
	var raw: Array = run.get("obstacles", []) as Array
	if raw.is_empty():
		if int(GameState.run_seed) != 0:
			var generated: Array = _generate_obstacles(int(GameState.run_seed))
			for s in generated:
				_obstacles[_parse_coord(String(s))] = true
			run["obstacles"] = generated
			GameState.run_save = run
			SaveSystem.save_now()
	else:
		for s in raw:
			_obstacles[_parse_coord(String(s))] = true

	if _territory.has_method("is_tile_occupied"):
		var kept: Array[Vector2i] = []
		for c in _obstacles.keys():
			if _territory.is_tile_occupied(c):
				continue
			kept.append(c)
		_obstacles.clear()
		for c in kept:
			_obstacles[c] = true

	_push_to_tile_grid()


func is_obstacle(coord: Vector2i) -> bool:
	return _obstacles.has(coord)


static func _generate_obstacles(seed: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var out: Array = []
	var cx: int = int(GRID_W / 2)
	var cy: int = int(GRID_H / 2)
	for y in range(GRID_H):
		for x in range(GRID_W):
			if abs(x - cx) <= START_CLEAR_RADIUS and abs(y - cy) <= START_CLEAR_RADIUS:
				continue
			if rng.randf() < OBSTACLE_RATE:
				out.append("%d,%d" % [x, y])
	return out


func _push_to_tile_grid() -> void:
	if not _tile_grid.has_method("set_obstacles"):
		return
	var arr: Array[Vector2i] = []
	for c in _obstacles.keys():
		arr.append(c)
	_tile_grid.set_obstacles(arr)


func _parse_coord(s: String) -> Vector2i:
	var parts := s.split(",", false)
	if parts.size() != 2:
		return Vector2i.ZERO
	return Vector2i(int(parts[0]), int(parts[1]))
