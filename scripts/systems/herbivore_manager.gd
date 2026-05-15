extends Node

const HERBIVORE_SPECIES_ID: StringName = &"herbivore"

@export var herbivore_scene: PackedScene

@onready var _territory: Node = get_node("../TerritorySystem")
@onready var _tile_grid: Node = get_node("../../TileGrid")
@onready var _organisms_parent: Node2D = get_node("../../Organisms")
@onready var _pressure: Node = get_node("../EcologicalPressure")

var _herbivores: Array[Herbivore] = []
var _state_by_id: Dictionary[int, Dictionary] = {}
var _next_organism_id: int = 1
var _is_replaying: bool = false
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _wave_payload: Dictionary = {}
var _logged_no_tiles: bool = false


func _ready() -> void:
	_rng.seed = int(GameState.run_seed) ^ int(Time.get_unix_time_from_system())
	EventBus.event_started.connect(_on_event_started)
	EventBus.event_resolved.connect(_on_event_resolved)
	EventBus.tick.connect(_on_tick)
	EventBus.ability_used.connect(_on_ability_used)
	EventBus.replay_started.connect(_on_replay_started)
	EventBus.replay_finished.connect(_on_replay_finished)
	EventBus.run_loaded.connect(_on_run_loaded)
	if _has_saved_organisms():
		_on_run_loaded(SaveSystem.SAVE_VERSION)


func _has_saved_organisms() -> bool:
	if not (GameState.run_save is Dictionary):
		return false
	var raw: Variant = GameState.run_save.get("organisms", [])
	return raw is Array and (raw as Array).size() > 0


func _on_event_started(event_id: StringName, payload: Dictionary) -> void:
	if event_id != &"herbivore_wave":
		return
	_wave_payload = payload
	if herbivore_scene == null:
		push_error("HerbivoreManager: herbivore_scene is not assigned.")
		return
	if _herbivores.size() > 0:
		return

	var spawn_count: int = int(payload.get("spawn_count", 0))
	var hp: float = float(payload.get("hp", 2.0))
	for _i in range(spawn_count):
		var coord := _random_edge_coord()
		_spawn_herbivore(coord, hp)

	_sync_run_save()


func _on_event_resolved(event_id: StringName, outcome: StringName) -> void:
	if event_id != &"herbivore_wave":
		return
	_despawn_all(outcome)
	_wave_payload = {}


func _on_tick(_delta_seconds: float) -> void:
	if _is_replaying:
		return
	if _herbivores.is_empty():
		return
	if not _territory.has_method("get_surface_owned_coords"):
		return

	var owned_coords: Array[Vector2i] = _territory.get_surface_owned_coords()
	if owned_coords.is_empty():
		if not _logged_no_tiles:
			push_warning("HerbivoreManager: no owned tiles during herbivore wave.")
			_logged_no_tiles = true
		return
	_logged_no_tiles = false

	var chew_ticks: int = _get_payload_int("chew_ticks", 4)
	var speed_ticks: int = _get_payload_int("speed_ticks", 2)

	for herbivore in _herbivores:
		var state := _get_state(herbivore.organism_id)
		if owned_coords.has(herbivore.coord):
			state["chew_ticks"] = int(state.get("chew_ticks", 0)) + 1
			state["move_ticks"] = 0
			if int(state["chew_ticks"]) >= chew_ticks:
				state["chew_ticks"] = 0
				if _territory.has_method("remove_surface"):
					_territory.remove_surface(herbivore.coord, &"herbivore")
			continue

		state["move_ticks"] = int(state.get("move_ticks", 0)) + 1
		state["chew_ticks"] = 0
		if int(state["move_ticks"]) >= speed_ticks:
			state["move_ticks"] = 0
			var target := _nearest_owned(herbivore.coord, owned_coords)
			var next_coord := _step_toward(herbivore.coord, target)
			herbivore.set_coord(next_coord, _coord_to_world(next_coord))

	_sync_run_save()


func _on_ability_used(ability_id: StringName, payload: Dictionary) -> void:
	if ability_id != &"toxin_bloom":
		return
	if _herbivores.is_empty():
		return

	var target: Vector2i = payload.get("coord", Vector2i.ZERO)
	var radius: int = int(payload.get("radius_tiles", 0))
	var damage: float = float(payload.get("damage", 0.0))
	if radius <= 0 or damage <= 0.0:
		return

	var survivors: Array[Herbivore] = []
	for herbivore in _herbivores:
		var distance: int = abs(herbivore.coord.x - target.x) + abs(herbivore.coord.y - target.y)
		if distance <= radius:
			var remaining := herbivore.take_damage(damage)
			if remaining <= 0.0:
				EventBus.organism_died.emit(herbivore.organism_id, &"toxin_bloom")
				_state_by_id.erase(herbivore.organism_id)
				herbivore.queue_free()
				continue
		survivors.append(herbivore)
	_herbivores = survivors
	_sync_run_save()

	if _herbivores.is_empty() and _pressure.has_method("is_event_active"):
		if _pressure.is_event_active(&"herbivore_wave") and _pressure.has_method("resolve_event"):
			_pressure.resolve_event(&"herbivore_wave", &"defeated")


func _on_run_loaded(_save_version: int) -> void:
	_despawn_all(&"loaded", false, false)
	_state_by_id.clear()
	_next_organism_id = 1

	var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
	var raw: Variant = run.get("organisms", [])
	if raw is Array:
		for entry in raw:
			if not (entry is Dictionary):
				continue
			var species_id := StringName(entry.get("species_id", ""))
			if species_id != HERBIVORE_SPECIES_ID:
				continue
			var coord_raw: Variant = entry.get("coord", [])
			if not (coord_raw is Array) or coord_raw.size() != 2:
				continue
			var coord := Vector2i(int(coord_raw[0]), int(coord_raw[1]))
			var organism_id := int(entry.get("organism_id", 0))
			var hp: float = float(entry.get("hp", 0.0))
			if organism_id <= 0 or hp <= 0.0:
				continue
			var herbivore := _instantiate_herbivore(organism_id, coord, hp)
			if herbivore == null:
				continue
			var data: Dictionary = entry.get("data", {}) as Dictionary
			_state_by_id[organism_id] = {
				"move_ticks": int(data.get("move_ticks", 0)),
				"chew_ticks": int(data.get("chew_ticks", 0))
			}
			_next_organism_id = maxi(_next_organism_id, organism_id + 1)

	var active_events: Variant = run.get("active_events", [])
	if active_events is Array:
		for event_entry in active_events:
			if event_entry is Dictionary and StringName(event_entry.get("id", "")) == &"herbivore_wave":
				_wave_payload = event_entry.get("payload", {}) as Dictionary
				break

	_sync_run_save()


func _spawn_herbivore(coord: Vector2i, hp: float) -> void:
	var herbivore := _instantiate_herbivore(_next_organism_id, coord, hp)
	if herbivore == null:
		return
	_state_by_id[_next_organism_id] = {"move_ticks": 0, "chew_ticks": 0}
	EventBus.organism_spawned.emit(_next_organism_id, HERBIVORE_SPECIES_ID, coord)
	_next_organism_id += 1


func _instantiate_herbivore(organism_id: int, coord: Vector2i, hp: float) -> Herbivore:
	if herbivore_scene == null:
		return null
	var node := herbivore_scene.instantiate()
	if node == null or not (node is Herbivore):
		return null
	var herbivore: Herbivore = node as Herbivore
	herbivore.organism_id = organism_id
	herbivore.species_id = HERBIVORE_SPECIES_ID
	herbivore.hp = hp
	herbivore.set_coord(coord, _coord_to_world(coord))
	_organisms_parent.add_child(herbivore)
	_herbivores.append(herbivore)
	return herbivore


func _despawn_all(cause: StringName, emit_signals: bool = true, sync_save: bool = true) -> void:
	for herbivore in _herbivores:
		if emit_signals:
			EventBus.organism_died.emit(herbivore.organism_id, cause)
		herbivore.queue_free()
	_herbivores.clear()
	_state_by_id.clear()
	if sync_save:
		_sync_run_save()


func _sync_run_save() -> void:
	var run: Dictionary
	if GameState.run_save is Dictionary:
		run = GameState.run_save
	else:
		run = {}
		GameState.run_save = run

	var organisms_array: Array = []
	for herbivore in _herbivores:
		var state: Dictionary = _state_by_id.get(herbivore.organism_id, {})
		organisms_array.append({
			"organism_id": herbivore.organism_id,
			"species_id": String(herbivore.species_id),
			"coord": [herbivore.coord.x, herbivore.coord.y],
			"hp": herbivore.hp,
			"data": {
				"move_ticks": int(state.get("move_ticks", 0)),
				"chew_ticks": int(state.get("chew_ticks", 0))
			}
		})
	run["organisms"] = organisms_array


func _get_state(organism_id: int) -> Dictionary:
	if not _state_by_id.has(organism_id):
		_state_by_id[organism_id] = {"move_ticks": 0, "chew_ticks": 0}
	return _state_by_id[organism_id]


func _nearest_owned(coord: Vector2i, owned: Array[Vector2i]) -> Vector2i:
	var best: Vector2i = owned[0]
	var best_dist: int = 1_000_000
	for owned_coord in owned:
		var dist: int = abs(owned_coord.x - coord.x) + abs(owned_coord.y - coord.y)
		if dist < best_dist:
			best_dist = dist
			best = owned_coord
	return best


func _step_toward(current: Vector2i, target: Vector2i) -> Vector2i:
	if current.x < target.x:
		return Vector2i(current.x + 1, current.y)
	if current.x > target.x:
		return Vector2i(current.x - 1, current.y)
	if current.y < target.y:
		return Vector2i(current.x, current.y + 1)
	if current.y > target.y:
		return Vector2i(current.x, current.y - 1)
	return current


func _coord_to_world(coord: Vector2i) -> Vector2:
	var local_pos: Vector2 = _tile_grid.map_to_local(coord)
	return _tile_grid.to_global(local_pos)


func _random_edge_coord() -> Vector2i:
	var width: int = int(_tile_grid.GRID_WIDTH)
	var height: int = int(_tile_grid.GRID_HEIGHT)
	var side: int = _rng.randi_range(0, 3)
	match side:
		0:
			return Vector2i(0, _rng.randi_range(0, height - 1))
		1:
			return Vector2i(width - 1, _rng.randi_range(0, height - 1))
		2:
			return Vector2i(_rng.randi_range(0, width - 1), 0)
		_:
			return Vector2i(_rng.randi_range(0, width - 1), height - 1)


func _get_payload_int(key: String, fallback: int) -> int:
	return int(_wave_payload.get(key, fallback))


func _on_replay_started(_ticks: int) -> void:
	_is_replaying = true


func _on_replay_finished() -> void:
	_is_replaying = false
