extends Node

const NICHE_INDEX_PATH: String = "res://data/niches/_index.tres"

var is_layered: bool = false
var _niches_by_id: Dictionary[StringName, NicheData] = {}


func _ready() -> void:
	_build_niche_index()
	EventBus.run_started.connect(_on_run_started)
	EventBus.niche_changed.connect(_on_niche_changed)
	EventBus.run_loaded.connect(_on_run_loaded)
	_sync_from_state()


func is_layered_run() -> bool:
	return is_layered


func _build_niche_index() -> void:
	_niches_by_id.clear()
	var index := load(NICHE_INDEX_PATH)
	if index == null or not (index is NicheIndex):
		return
	for niche in (index as NicheIndex).niches:
		if niche == null:
			continue
		_niches_by_id[niche.id] = niche


func _sync_from_state() -> void:
	_update_layering(GameState.current_kingdom_id, GameState.current_niche_id)


func _on_run_started(kingdom_id: StringName) -> void:
	_update_layering(kingdom_id, GameState.current_niche_id)


func _on_niche_changed(niche_id: StringName) -> void:
	_update_layering(GameState.current_kingdom_id, niche_id)


func _on_run_loaded(_save_version: int) -> void:
	_update_layering(GameState.current_kingdom_id, GameState.current_niche_id)


func _update_layering(kingdom_id: StringName, niche_id: StringName) -> void:
	if kingdom_id == &"":
		is_layered = false
		if GameState.placement_target != &"":
			GameState.placement_target = &""
			EventBus.placement_target_changed.emit(&"")
		return

	var layered: bool = false
	if niche_id != &"" and _niches_by_id.has(niche_id):
		var niche: NicheData = _niches_by_id[niche_id]
		layered = niche.expects_layered
	is_layered = layered

	if not layered:
		if GameState.placement_target != kingdom_id:
			GameState.placement_target = kingdom_id
			EventBus.placement_target_changed.emit(kingdom_id)
		return

	if GameState.placement_target != &"plantae" and GameState.placement_target != &"fungi":
		GameState.placement_target = &"plantae"
		EventBus.placement_target_changed.emit(&"plantae")
