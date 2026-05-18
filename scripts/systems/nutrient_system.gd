extends Node

const BIOME_INDEX_PATH: String = "res://data/biomes/_index.tres"

var _biome_by_coord: Dictionary[Vector2i, BiomeData] = {}
var _biomes: Array[BiomeData] = []

@onready var _tile_grid: Node = get_node("../../TileGrid")
@onready var _territory: Node = get_node("../TerritorySystem")
@onready var _ambient: Node = get_node("../AmbientModifierSystem")


func _ready() -> void:
	_load_biomes()
	EventBus.run_loaded.connect(_on_run_loaded)
	EventBus.tick.connect(_on_tick)
	if not GameState.run_save.is_empty():
		_on_run_loaded(SaveSystem.SAVE_VERSION)


func _load_biomes() -> void:
	_biomes.clear()
	var index := load(BIOME_INDEX_PATH)
	if index == null or not (index is BiomeIndex):
		push_error("NutrientSystem: missing biome index at %s" % BIOME_INDEX_PATH)
		return
	_biomes = (index as BiomeIndex).biomes

	_biomes.sort_custom(func(a: BiomeData, b: BiomeData) -> bool:
		return String(a.id) < String(b.id)
	)


func _on_run_loaded(_save_version: int) -> void:
	if _biomes.is_empty():
		return
	var run: Dictionary
	if GameState.run_save is Dictionary:
		run = GameState.run_save
	else:
		run = {}
		GameState.run_save = run
	var map_raw: Variant = run.get("biome_map", {})
	var biome_map: Dictionary
	if map_raw is Dictionary and map_raw.size() > 0:
		biome_map = map_raw as Dictionary
	else:
		biome_map = _generate_biome_map()
		run["biome_map"] = biome_map
		GameState.run_save = run
		SaveSystem.save_now()

	_biome_by_coord.clear()
	for key in biome_map.keys():
		var biome_id: StringName = StringName(biome_map[key])
		var coord_value: Variant = _parse_coord_key(String(key))
		if not (coord_value is Vector2i):
			continue
		var coord: Vector2i = coord_value
		var biome: BiomeData = _find_biome(biome_id)
		if biome != null:
			_biome_by_coord[coord] = biome


func _on_tick(_delta_seconds: float) -> void:
	if not _territory.has_method("get_surface_owned_coords"):
		return
	var sun_mult: float = 1.0
	var nut_mult: float = 1.0
	if _ambient.has_method("get_multiplier"):
		sun_mult = float(_ambient.get_multiplier(&"sunlight_multiplier"))
		nut_mult = float(_ambient.get_multiplier(&"nutrient_multiplier"))
	var coords: Array[Vector2i] = _territory.get_surface_owned_coords()
	for coord in coords:
		var biome: BiomeData = _biome_by_coord.get(coord, null)
		if biome == null:
			continue
		if biome.sunlight_per_tick != 0.0:
			ResourceLedger.add(ResourceLedger.SUNLIGHT, biome.sunlight_per_tick * sun_mult)
		if biome.nutrient_per_tick != 0.0:
			ResourceLedger.add(ResourceLedger.NUTRIENTS, biome.nutrient_per_tick * nut_mult)
		if biome.decay_per_tick != 0.0:
			ResourceLedger.add(ResourceLedger.DECAY, biome.decay_per_tick)


func get_biome_at(coord: Vector2i) -> BiomeData:
	return _biome_by_coord.get(coord, null)


func _generate_biome_map() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = GameState.run_seed

	var width: int = int(_tile_grid.GRID_WIDTH)
	var height: int = int(_tile_grid.GRID_HEIGHT)
	var era_system := _get_era_system()
	var eco: EcosystemData = null
	if era_system != null:
		eco = era_system.get_current_ecosystem()

	var map: Dictionary = {}
	if eco == null or eco.biome_recipe.is_empty():
		for y in range(height):
			for x in range(width):
				var biome: BiomeData = _biomes[rng.randi_range(0, _biomes.size() - 1)]
				map["%d,%d" % [x, y]] = String(biome.id)
		return map

	var cluster_threshold: float = 1.0 - (1.0 / maxf(eco.biome_cluster_size, 1.0))
	for y in range(height):
		for x in range(width):
			var biome_id: StringName = &""
			if rng.randf() < cluster_threshold and (x > 0 or y > 0):
				var src_key: String = ""
				if x > 0 and rng.randf() < 0.5:
					src_key = "%d,%d" % [x - 1, y]
				elif y > 0:
					src_key = "%d,%d" % [x, y - 1]
				if src_key in map:
					biome_id = StringName(map[src_key])
			if biome_id == &"":
				biome_id = _weighted_pick(eco.biome_recipe, rng)
			map["%d,%d" % [x, y]] = String(biome_id)
	return map


func _weighted_pick(recipe: Dictionary, rng: RandomNumberGenerator) -> StringName:
	var total: float = 0.0
	for weight in recipe.values():
		total += float(weight)
	if total <= 0.0:
		return _biomes[0].id if not _biomes.is_empty() else &""
	var roll: float = rng.randf_range(0.0, total)
	for biome_id in recipe.keys():
		roll -= float(recipe[biome_id])
		if roll <= 0.0:
			return StringName(biome_id)
	return _biomes[0].id if not _biomes.is_empty() else &""


func _get_era_system() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null("EraSystem")


func _parse_coord_key(key: String) -> Variant:
	var parts := key.split(",", false)
	if parts.size() != 2:
		return null
	return Vector2i(int(parts[0]), int(parts[1]))


func _find_biome(biome_id: StringName) -> BiomeData:
	for biome in _biomes:
		if biome.id == biome_id:
			return biome
	return null
