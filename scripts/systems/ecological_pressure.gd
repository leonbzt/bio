extends Node

const MIN_TILES_BEFORE_EVENTS: int = 3
const TRIGGER_CHECK_INTERVAL_TICKS: int = 30
const TRIGGER_PROBABILITY: float = 0.4
const HERBIVORE_PRESSURE_THRESHOLD: float = 0.6
const EVENT_INDEX_PATH: String = "res://data/events/_index.tres"

var _events_by_id: Dictionary[StringName, EventData] = {}
var _active: Array[Dictionary] = []
var _ticks_until_check: int = TRIGGER_CHECK_INTERVAL_TICKS
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _is_replaying: bool = false

@onready var _territory: Node = get_node("../TerritorySystem")


func _ready() -> void:
	_load_events()
	_rng.seed = int(GameState.run_seed) ^ int(Time.get_unix_time_from_system())
	EventBus.tick.connect(_on_tick)
	EventBus.run_loaded.connect(_on_run_loaded)
	EventBus.replay_started.connect(_on_replay_started)
	EventBus.replay_finished.connect(_on_replay_finished)
	if not GameState.run_save.is_empty():
		_on_run_loaded(SaveSystem.SAVE_VERSION)


func _load_events() -> void:
	_events_by_id.clear()
	var index := load(EVENT_INDEX_PATH)
	if index == null or not (index is EventIndex):
		push_error("EcologicalPressure: missing event index at %s" % EVENT_INDEX_PATH)
		return
	for event_data in (index as EventIndex).events:
		if event_data == null:
			continue
		_events_by_id[event_data.id] = event_data


func _on_run_loaded(_save_version: int) -> void:
	_active.clear()
	_ticks_until_check = TRIGGER_CHECK_INTERVAL_TICKS

	var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
	var entries_raw: Variant = run.get("active_events", [])
	if entries_raw is Array:
		for entry in entries_raw:
			if not (entry is Dictionary):
				continue
			var event_id := StringName(entry.get("id", ""))
			if event_id == StringName() or not _events_by_id.has(event_id):
				continue
			var ticks_remaining := int(entry.get("ticks_remaining", 0))
			if ticks_remaining <= 0:
				continue
			var payload: Dictionary = entry.get("payload", {}) as Dictionary
			_active.append({
				"id": event_id,
				"ticks_remaining": ticks_remaining,
				"payload": payload
			})
			EventBus.event_started.emit(event_id, payload)

	_sync_run_save()


func _on_tick(_delta_seconds: float) -> void:
	if _is_replaying:
		return

	var still_active: Array[Dictionary] = []
	for entry in _active:
		var ticks_remaining: int = int(entry.get("ticks_remaining", 0)) - 1
		var event_id := StringName(entry.get("id", ""))
		if ticks_remaining <= 0:
			if event_id != StringName():
				EventBus.event_resolved.emit(event_id, &"expired")
			continue
		entry["ticks_remaining"] = ticks_remaining
		still_active.append(entry)
	_active = still_active
	_sync_run_save()

	_ticks_until_check -= 1
	if _ticks_until_check <= 0:
		_ticks_until_check = TRIGGER_CHECK_INTERVAL_TICKS
		_maybe_trigger()


func _maybe_trigger() -> void:
	if _active.size() > 0:
		return
	if not _territory.has_method("get_owned_coords"):
		return
	var owned_count: int = _territory.get_owned_coords().size()
	if owned_count < _get_min_tiles_before_events():
		return
	if _rng.randf() >= TRIGGER_PROBABILITY:
		return

	var total_weight: float = 0.0
	for event_data in _events_by_id.values():
		total_weight += maxf(0.0, event_data.trigger_weight)
	if total_weight <= 0.0:
		return

	var roll: float = _rng.randf_range(0.0, total_weight)
	var picked: EventData = null
	for event_data in _events_by_id.values():
		roll -= maxf(0.0, event_data.trigger_weight)
		if roll <= 0.0:
			picked = event_data
			break
	if picked == null:
		return

	var kingdom_required: String = String(picked.payload.get("kingdom_required", ""))
	if kingdom_required != "" and String(GameState.current_kingdom_id) != kingdom_required:
		return

	if picked.id == &"herbivore_wave" and owned_count < 6:
		return

	var payload: Dictionary = picked.payload.duplicate(true)
	_active.append({
		"id": picked.id,
		"ticks_remaining": picked.duration_ticks,
		"payload": payload
	})
	_sync_run_save()
	EventBus.event_started.emit(picked.id, payload)


func _get_min_tiles_before_events() -> int:
	if MetaModifiers.is_unlocked(&"pioneer_resilience"):
		return 5
	return MIN_TILES_BEFORE_EVENTS


func resolve_event(id: StringName, outcome: StringName) -> void:
	var remaining: Array[Dictionary] = []
	for entry in _active:
		var event_id := StringName(entry.get("id", ""))
		if event_id == id:
			EventBus.event_resolved.emit(id, outcome)
			continue
		remaining.append(entry)
	_active = remaining
	_sync_run_save()


func is_event_active(id: StringName) -> bool:
	for entry in _active:
		if StringName(entry.get("id", "")) == id:
			return true
	return false


func _sync_run_save() -> void:
	var run: Dictionary
	if GameState.run_save is Dictionary:
		run = GameState.run_save
	else:
		run = {}
		GameState.run_save = run

	var events_array: Array = []
	for entry in _active:
		var event_id := StringName(entry.get("id", ""))
		if event_id == StringName():
			continue
		var ticks_remaining := int(entry.get("ticks_remaining", 0))
		var payload: Dictionary = entry.get("payload", {}) as Dictionary
		events_array.append({
			"id": String(event_id),
			"ticks_remaining": ticks_remaining,
			"payload": payload
		})
	run["active_events"] = events_array


func _on_replay_started(_ticks: int) -> void:
	_is_replaying = true


func _on_replay_finished() -> void:
	_is_replaying = false
