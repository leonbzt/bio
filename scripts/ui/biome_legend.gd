extends HBoxContainer
##
## Compact biome legend — one chip per biome present on the current map.
## Each chip shows a color swatch + biome name; tap/hover for the impact summary.
##

const BIOME_INDEX_PATH: String = "res://data/biomes/_index.tres"
const SWATCH_SIZE: int = 10

var _biomes_by_id: Dictionary[StringName, BiomeData] = {}


func _ready() -> void:
	add_theme_constant_override("separation", 6)
	_load_biomes()
	EventBus.run_loaded.connect(_on_run_loaded)
	EventBus.era_changed.connect(func(_e): _refresh())
	var fog: Node = _get_fog_system()
	if fog != null and fog.has_signal("fog_updated"):
		fog.fog_updated.connect(func(): call_deferred("_refresh"))
	_refresh()


func _load_biomes() -> void:
	_biomes_by_id.clear()
	var index: BiomeIndex = load(BIOME_INDEX_PATH) as BiomeIndex
	if index == null:
		return
	for b in index.biomes:
		if b != null:
			_biomes_by_id[b.id] = b


func _on_run_loaded(_v: int) -> void:
	# Defer to next idle so NutrientSystem has populated the biome map first.
	call_deferred("_refresh")


func _refresh() -> void:
	for child in get_children():
		child.queue_free()
	var present_ids: Array[StringName] = _unique_biomes_in_play()
	if present_ids.is_empty():
		return
	for biome_id in present_ids:
		var biome: BiomeData = _biomes_by_id.get(biome_id, null)
		if biome == null:
			continue
		add_child(_build_chip(biome))


func _unique_biomes_in_play() -> Array[StringName]:
	var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
	var biome_map: Dictionary = run.get("biome_map", {}) as Dictionary
	var fog: Node = _get_fog_system()
	var seen: Dictionary[StringName, bool] = {}
	for k in biome_map.keys():
		var coord: Vector2i = _parse_coord_key(String(k))
		if fog != null and fog.has_method("is_revealed") and not fog.is_revealed(coord):
			continue
		seen[StringName(biome_map[k])] = true
	var result: Array[StringName] = []
	for k in seen.keys():
		result.append(k)
	result.sort_custom(func(a, b): return String(a) < String(b))
	return result


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


func _build_chip(biome: BiomeData) -> Control:
	var chip := HBoxContainer.new()
	chip.add_theme_constant_override("separation", 3)
	chip.mouse_filter = Control.MOUSE_FILTER_STOP
	chip.tooltip_text = _tooltip_text(biome)

	var swatch := ColorRect.new()
	swatch.custom_minimum_size = Vector2(SWATCH_SIZE, SWATCH_SIZE)
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	swatch.color = _biome_swatch_color(biome.id)
	chip.add_child(swatch)

	var name_label := Label.new()
	name_label.text = biome.display_name
	name_label.add_theme_font_override("font", KingdomTheme.SMALL_FONT)
	name_label.add_theme_font_size_override("font_size", KingdomTheme.SMALL_FONT_SIZE)
	name_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	chip.add_child(name_label)

	# Compact impact pips — one per significant resource.
	var impact_label := Label.new()
	impact_label.text = _impact_string(biome)
	impact_label.add_theme_font_override("font", KingdomTheme.SMALL_FONT)
	impact_label.add_theme_font_size_override("font_size", KingdomTheme.SMALL_FONT_SIZE)
	impact_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	chip.add_child(impact_label)

	return chip


func _biome_swatch_color(biome_id: StringName) -> Color:
	# Match the in-grid atlas tile body colors (tile_grid.gd).
	match biome_id:
		&"tundra": return Color8(0xa5, 0xc8, 0xee)
		&"mineral_vent": return Color8(0x3a, 0x3a, 0x40)
		&"swamp": return Color8(0x5a, 0x70, 0x2a)
		&"grassland": return Color8(0x78, 0x95, 0x4a)
		&"rich_soil": return Color8(0x6a, 0x55, 0x38)
		&"forest_edge": return Color8(0x4a, 0x6a, 0x35)
		_: return Color(0.6, 0.6, 0.6)


func _impact_string(biome: BiomeData) -> String:
	var bits: Array[String] = []
	if biome.sunlight_per_tick >= 0.7:
		bits.append("☀")
	elif biome.sunlight_per_tick > 0.0 and biome.sunlight_per_tick < 0.4:
		bits.append("☁")
	if biome.nutrient_per_tick >= 0.35:
		bits.append("✦")
	if biome.decay_per_tick >= 0.35:
		bits.append("☣")
	if biome.chemosynthesis_per_tick >= 0.3:
		bits.append("⚒")
	if bits.is_empty():
		return ""
	return " ".join(bits)


func _tooltip_text(biome: BiomeData) -> String:
	var parts: Array[String] = []
	parts.append(biome.display_name)
	parts.append("Sun: %.1f · Nutrients: %.1f · Decay: %.1f" % [
		biome.sunlight_per_tick, biome.nutrient_per_tick, biome.decay_per_tick
	])
	if biome.chemosynthesis_per_tick > 0.0:
		parts.append("Chemosynthesis: %.1f" % biome.chemosynthesis_per_tick)
	return "\n".join(parts)
