extends Node

const SPECIES_ID: StringName = &"corpse"
const DEFAULT_DECAY_PER_TICK: float = 0.5
const DEFAULT_DECAY_TICKS: int = 30

var _corpses: Dictionary[Vector2i, Dictionary] = {}
var _next_corpse_id: int = 100_000
var _is_replaying: bool = false


func _ready() -> void:
	EventBus.tick.connect(_on_tick)
	EventBus.run_loaded.connect(_on_run_loaded)
	EventBus.replay_started.connect(_on_replay_started)
	EventBus.replay_finished.connect(_on_replay_finished)
	if not GameState.run_save.is_empty():
		_on_run_loaded(SaveSystem.SAVE_VERSION)


func spawn_corpse(coord: Vector2i, decay_per_tick: float = DEFAULT_DECAY_PER_TICK, ticks: int = DEFAULT_DECAY_TICKS) -> void:
	if _corpses.has(coord):
		var existing: Dictionary = _corpses[coord]
		existing["ticks_remaining"] = max(int(existing.get("ticks_remaining", 0)), ticks)
		_corpses[coord] = existing
		_sync_run_save()
		return

	var organism_id: int = _next_corpse_id
	_next_corpse_id += 1
	_corpses[coord] = {
		"ticks_remaining": ticks,
		"decay_per_tick": decay_per_tick,
		"organism_id": organism_id,
		"coord": coord
	}
	_sync_run_save()
	EventBus.organism_spawned.emit(organism_id, SPECIES_ID, coord)


func is_corpse_at(coord: Vector2i) -> bool:
	return _corpses.has(coord)


func _on_tick(_delta_seconds: float) -> void:
	if _is_replaying:
		return
	if _corpses.is_empty():
		return

	var expired: Array[Vector2i] = []
	for coord in _corpses.keys():
		var entry: Dictionary = _corpses[coord]
		var decay_per_tick: float = float(entry.get("decay_per_tick", DEFAULT_DECAY_PER_TICK))
		if decay_per_tick != 0.0:
			ResourceLedger.add(ResourceLedger.DECAY, decay_per_tick)
		var ticks_remaining: int = int(entry.get("ticks_remaining", 0)) - 1
		entry["ticks_remaining"] = ticks_remaining
		_corpses[coord] = entry
		if ticks_remaining <= 0:
			expired.append(coord)

	for coord in expired:
		var entry: Dictionary = _corpses.get(coord, {})
		if entry.has("organism_id"):
			EventBus.organism_died.emit(int(entry.get("organism_id", 0)), &"decomposed")
		_corpses.erase(coord)

	_sync_run_save()


func _on_run_loaded(_save_version: int) -> void:
	_corpses.clear()
	_next_corpse_id = 100_000

	var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
	var raw: Variant = run.get("organisms", [])
	if raw is Array:
		for entry in raw:
			if not (entry is Dictionary):
				continue
			var species_id := StringName(entry.get("species_id", ""))
			if species_id != SPECIES_ID:
				continue
			var coord_raw: Variant = entry.get("coord", [])
			if not (coord_raw is Array) or coord_raw.size() != 2:
				continue
			var coord := Vector2i(int(coord_raw[0]), int(coord_raw[1]))
			var organism_id := int(entry.get("organism_id", 0))
			var data: Dictionary = entry.get("data", {}) as Dictionary
			var ticks_remaining: int = int(data.get("decay_remaining_ticks", entry.get("hp", DEFAULT_DECAY_TICKS)))
			var decay_per_tick: float = float(data.get("decay_per_tick", DEFAULT_DECAY_PER_TICK))
			if organism_id <= 0 or ticks_remaining <= 0:
				continue
			_corpses[coord] = {
				"ticks_remaining": ticks_remaining,
				"decay_per_tick": decay_per_tick,
				"organism_id": organism_id,
				"coord": coord
			}
			_next_corpse_id = maxi(_next_corpse_id, organism_id + 1)

	_sync_run_save()


func _sync_run_save() -> void:
	var run: Dictionary
	if GameState.run_save is Dictionary:
		run = GameState.run_save
	else:
		run = {}
		GameState.run_save = run

	var existing: Array = run.get("organisms", []) as Array
	var kept: Array = []
	for entry in existing:
		if not (entry is Dictionary):
			continue
		if String(entry.get("species_id", "")) != String(SPECIES_ID):
			kept.append(entry)

	for coord in _corpses.keys():
		var c: Dictionary = _corpses[coord]
		kept.append({
			"organism_id": int(c.get("organism_id", 0)),
			"species_id": "corpse",
			"coord": [coord.x, coord.y],
			"hp": float(c.get("ticks_remaining", 0)),
			"data": {
				"decay_per_tick": float(c.get("decay_per_tick", DEFAULT_DECAY_PER_TICK)),
				"decay_remaining_ticks": int(c.get("ticks_remaining", 0))
			}
		})

	run["organisms"] = kept


func _on_replay_started(_ticks: int) -> void:
	_is_replaying = true


func _on_replay_finished() -> void:
	_is_replaying = false
