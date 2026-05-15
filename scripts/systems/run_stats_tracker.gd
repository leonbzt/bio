extends Node

var _last_biomass: float = 0.0
var _stats: Dictionary = {}


func _ready() -> void:
	EventBus.resource_changed.connect(_on_resource_changed)
	EventBus.tile_colonized.connect(_on_tile_colonized)
	EventBus.event_resolved.connect(_on_event_resolved)
	EventBus.run_loaded.connect(_on_run_loaded)
	if _has_save_state():
		_on_run_loaded(SaveSystem.SAVE_VERSION)


func _has_save_state() -> bool:
	if not (GameState.run_save is Dictionary):
		return false
	return GameState.run_save.has("statistics")


func _on_run_loaded(_save_version: int) -> void:
	_stats = _get_run_stats()
	_last_biomass = ResourceLedger.get_amount(ResourceLedger.BIOMASS)


func _on_resource_changed(resource_id: StringName, new_amount: float) -> void:
	if resource_id != ResourceLedger.BIOMASS:
		return
	var delta: float = new_amount - _last_biomass
	_last_biomass = new_amount
	if delta <= 0.0:
		return
	_stats["total_biomass_earned"] = float(_stats.get("total_biomass_earned", 0.0)) + delta
	_sync_run_save()


func _on_tile_colonized(_coord: Vector2i, _owner_id: StringName) -> void:
	_stats["tiles_colonized"] = int(_stats.get("tiles_colonized", 0)) + 1
	_sync_run_save()


func _on_event_resolved(_event_id: StringName, outcome: StringName) -> void:
	if outcome != &"defeated":
		return
	_stats["waves_defeated"] = int(_stats.get("waves_defeated", 0)) + 1
	_sync_run_save()


func reset_run() -> void:
	_stats = {
		"total_biomass_earned": 0.0,
		"tiles_colonized": 0,
		"waves_defeated": 0
	}
	_sync_run_save()
	_last_biomass = ResourceLedger.get_amount(ResourceLedger.BIOMASS)


func _get_run_stats() -> Dictionary:
	var run: Dictionary
	if GameState.run_save is Dictionary:
		run = GameState.run_save
	else:
		run = {}
		GameState.run_save = run
	var stats_raw: Variant = run.get("statistics", {})
	var stats: Dictionary
	if stats_raw is Dictionary:
		stats = stats_raw as Dictionary
	else:
		stats = {}
		run["statistics"] = stats
	if not stats.has("total_biomass_earned"):
		stats["total_biomass_earned"] = 0.0
	if not stats.has("tiles_colonized"):
		stats["tiles_colonized"] = 0
	if not stats.has("waves_defeated"):
		stats["waves_defeated"] = 0
	return stats


func _sync_run_save() -> void:
	var run: Dictionary
	if GameState.run_save is Dictionary:
		run = GameState.run_save
	else:
		run = {}
		GameState.run_save = run
	run["statistics"] = _stats
