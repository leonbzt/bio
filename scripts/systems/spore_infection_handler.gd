extends Node

const EVENT_ID: StringName = &"spore_infection"
const KINGDOM_ID: StringName = &"fungi"

@onready var _territory: Node = get_node("../TerritorySystem")
@onready var _tile_grid: Node = get_node("../../TileGrid")

var _spread_counter: int = 0
var _spread_every: int = 5
var _is_active: bool = false
var _is_replaying: bool = false
var _culled_set: Dictionary[Vector2i, bool] = {}


func _ready() -> void:
	EventBus.event_started.connect(_on_event_started)
	EventBus.event_resolved.connect(_on_event_resolved)
	EventBus.tick.connect(_on_tick)
	EventBus.ability_used.connect(_on_ability_used)
	EventBus.replay_started.connect(func(_n): _is_replaying = true)
	EventBus.replay_finished.connect(func(): _is_replaying = false)


func _on_event_started(event_id: StringName, payload: Dictionary) -> void:
	if event_id != EVENT_ID:
		return
	_is_active = true
	_spread_counter = 0
	_spread_every = int(payload.get("spread_every_ticks", 5))
	_culled_set.clear()


func _on_event_resolved(event_id: StringName, _outcome: StringName) -> void:
	if event_id != EVENT_ID:
		return
	_is_active = false
	_culled_set.clear()


func _on_ability_used(id: StringName, payload: Dictionary) -> void:
	if id != &"cull":
		return
	var coord: Vector2i = payload.get("coord", Vector2i.ZERO)
	var radius: int = int(payload.get("radius_tiles", 0))
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			_culled_set[Vector2i(coord.x + dx, coord.y + dy)] = true


func _on_tick(_delta: float) -> void:
	if not _is_active or _is_replaying:
		return
	if GameState.current_kingdom_id != KINGDOM_ID:
		return
	_spread_counter += 1
	if _spread_counter < _spread_every:
		return
	_spread_counter = 0
	_try_spread_one()


func _try_spread_one() -> void:
	var owned: Array[Vector2i] = _territory.get_subsurface_owned_coords(KINGDOM_ID)
	if owned.is_empty():
		return
	var seen: Dictionary = {}
	for c in owned:
		seen[c] = true
	for c in owned:
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var neighbor: Vector2i = c + offset
			if neighbor.x < 0 or neighbor.y < 0:
				continue
			if neighbor.x >= int(_tile_grid.GRID_WIDTH) or neighbor.y >= int(_tile_grid.GRID_HEIGHT):
				continue
			if seen.has(neighbor):
				continue
			if _culled_set.has(neighbor):
				continue
			if _territory.get_subsurface_owner(neighbor) != &"":
				continue
			_territory.add_subsurface(neighbor, KINGDOM_ID)
			return
