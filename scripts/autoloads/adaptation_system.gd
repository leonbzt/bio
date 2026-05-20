extends Node
##
## Adaptation — per-run strategic currency. Accumulates passively from
## cluster size, biome diversity, and active species. Spent on per-run
## species evolution levels.
##

signal adaptation_changed(new_amount: float)

const TICKS_PER_MINUTE: float = 60.0
const RATE_PER_CLUSTER_TILE: float = 1.0
const MIN_CLUSTER_SIZE: int = 5
const RATE_PER_BIOME: float = 0.5
const RATE_PER_SPECIES: float = 0.25
const MAX_LEVEL: int = 3
const LEVEL_YIELD_BONUS: float = 0.10
const LEVEL_UP_COSTS: Array[float] = [
	0.0,
	5.0,
	15.0
]


func _ready() -> void:
	EventBus.tick.connect(_on_tick)


func get_amount() -> float:
	return float(GameState.run_save.get("adaptation", 0.0))


func get_per_minute_rate() -> float:
	return _compute_per_tick_rate() * TICKS_PER_MINUTE


func can_afford(cost: float) -> bool:
	return get_amount() >= cost


func spend(amount: float) -> bool:
	if not can_afford(amount):
		return false
	_set_amount(get_amount() - amount)
	return true


func get_level(species_id: StringName) -> int:
	var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
	var levels: Dictionary = run.get("species_levels", {}) as Dictionary
	return int(levels.get(String(species_id), 1))


func get_next_level_cost(species_id: StringName) -> float:
	var current: int = get_level(species_id)
	if current >= MAX_LEVEL:
		return -1.0
	return LEVEL_UP_COSTS[current]


func can_level_up(species_id: StringName) -> bool:
	var cost: float = get_next_level_cost(species_id)
	if cost < 0.0:
		return false
	return can_afford(cost)


func level_up(species_id: StringName) -> bool:
	var cost: float = get_next_level_cost(species_id)
	if cost < 0.0:
		return false
	if not spend(cost):
		return false
	var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
	var levels: Dictionary = run.get("species_levels", {}) as Dictionary
	var sp_key: String = String(species_id)
	levels[sp_key] = int(levels.get(sp_key, 1)) + 1
	run["species_levels"] = levels
	GameState.run_save = run
	EventBus.species_leveled.emit(species_id, levels[sp_key])
	SaveSystem.save_now()
	return true


func species_level_multiplier(species_id: StringName) -> float:
	var level: int = get_level(species_id)
	return 1.0 + (LEVEL_YIELD_BONUS * float(level - 1))


func _on_tick(_delta: float) -> void:
	var per_tick: float = _compute_per_tick_rate()
	if per_tick <= 0.0:
		return
	_set_amount(get_amount() + per_tick)


func _compute_per_tick_rate() -> float:
	var per_minute: float = 0.0
	per_minute += float(_cluster_tile_count()) * RATE_PER_CLUSTER_TILE
	per_minute += float(_distinct_biomes_present()) * RATE_PER_BIOME
	per_minute += float(_active_species_count()) * RATE_PER_SPECIES
	return per_minute / TICKS_PER_MINUTE


func _cluster_tile_count() -> int:
	var territory: Node = _get_territory()
	if territory == null or not territory.has_method("get_clusters"):
		return 0
	var total: int = 0
	for cluster in territory.get_clusters():
		var size: int = (cluster["coords"] as Array).size()
		if size >= MIN_CLUSTER_SIZE:
			total += size
	return total


func _distinct_biomes_present() -> int:
	var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
	var biome_map: Dictionary = run.get("biome_map", {}) as Dictionary
	var fog: Node = _get_fog_system()
	var seen: Dictionary = {}
	for k in biome_map.keys():
		var coord: Vector2i = _parse_coord_key(String(k))
		if fog != null and fog.has_method("is_revealed") and not fog.is_revealed(coord):
			continue
		seen[String(biome_map[k])] = true
	return seen.size()


func _active_species_count() -> int:
	var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
	var unlocked: Array = run.get("unlocked_species_in_run", []) as Array
	return unlocked.size()


func _set_amount(value: float) -> void:
	var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
	run["adaptation"] = maxf(0.0, value)
	GameState.run_save = run
	adaptation_changed.emit(run["adaptation"])


func _get_territory() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null("World/Systems/TerritorySystem")


func _get_fog_system() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null("World/Systems/FogSystem")


func _parse_coord_key(s: String) -> Vector2i:
	var parts := s.split(",", false)
	if parts.size() != 2:
		return Vector2i.ZERO
	return Vector2i(int(parts[0]), int(parts[1]))
