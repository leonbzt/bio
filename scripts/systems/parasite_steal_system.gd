extends Node

const PARASITE_NICHE_ID: StringName = &"parasitic_plantae"
const STEAL_PER_NEIGHBOR: float = 0.2

@onready var _territory: Node = get_node("../TerritorySystem")

var _parasitic_targets: Dictionary[StringName, bool] = {}
var _is_replaying: bool = false


func _ready() -> void:
	_load_parasitic_targets()
	EventBus.tick.connect(_on_tick)
	EventBus.replay_started.connect(func(_n): _is_replaying = true)
	EventBus.replay_finished.connect(func(): _is_replaying = false)


func _load_parasitic_targets() -> void:
	_parasitic_targets.clear()
	var index := load("res://data/niches/_index.tres")
	if index == null or not (index is NicheIndex):
		return
	for niche in (index as NicheIndex).niches:
		if niche == null:
			continue
		if niche.id != PARASITE_NICHE_ID:
			continue
		for target_id in niche.parasitic_targets:
			_parasitic_targets[target_id] = true


func _on_tick(_delta: float) -> void:
	if _is_replaying:
		return
	if GameState.current_niche_id != PARASITE_NICHE_ID:
		return
	if _parasitic_targets.is_empty():
		return

	var owned: Array[Vector2i] = _territory.get_surface_owned_coords(&"plantae")
	if owned.is_empty():
		return

	var total_bonus: float = 0.0
	for coord in owned:
		var neighbor_count: int = 0
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var neighbor: Vector2i = coord + offset
			var surface_owner: StringName = _territory.get_surface_owner(neighbor)
			var subsurface_owner: StringName = _territory.get_subsurface_owner(neighbor)
			if _parasitic_targets.has(surface_owner) or _parasitic_targets.has(subsurface_owner):
				neighbor_count += 1
		if neighbor_count > 0:
			total_bonus += STEAL_PER_NEIGHBOR * float(neighbor_count)
	if total_bonus > 0.0:
		ResourceLedger.add(ResourceLedger.BIOMASS, total_bonus)
