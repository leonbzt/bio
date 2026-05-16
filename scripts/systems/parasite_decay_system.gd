extends Node

const PARASITE_NICHE_ID: StringName = &"parasite_plantae"
const NEIGHBOR_THRESHOLD: int = 2
const MAX_DECAY_TICKS: int = 30

@onready var _territory: Node = get_node("../TerritorySystem")
var _is_replaying: bool = false


func _ready() -> void:
	EventBus.tick.connect(_on_tick)
	EventBus.replay_started.connect(func(_n): _is_replaying = true)
	EventBus.replay_finished.connect(func(): _is_replaying = false)


func _on_tick(_delta: float) -> void:
	if _is_replaying:
		return
	if GameState.current_niche_id != PARASITE_NICHE_ID:
		return

	var owned: Array[Vector2i] = _territory.get_surface_owned_coords(&"plantae")
	if owned.size() <= 1:
		return

	var owned_set: Dictionary = {}
	for c in owned:
		owned_set[c] = true

	var to_remove: Array[Vector2i] = []
	for coord in owned:
		var neighbor_count: int = 0
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if owned_set.has(coord + offset):
				neighbor_count += 1

		var ticks: int = int(_territory.get_tile_data(coord, "parasite_decay_ticks", MAX_DECAY_TICKS))
		if neighbor_count >= NEIGHBOR_THRESHOLD:
			if ticks < MAX_DECAY_TICKS:
				_territory.set_tile_data(coord, "parasite_decay_ticks", MAX_DECAY_TICKS)
		else:
			ticks -= 1
			if ticks <= 0:
				to_remove.append(coord)
			else:
				_territory.set_tile_data(coord, "parasite_decay_ticks", ticks)

	for coord in to_remove:
		_territory.remove_surface(coord, &"parasite_wither")
