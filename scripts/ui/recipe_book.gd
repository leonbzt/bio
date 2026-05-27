extends Control
##
## Field Guide — three-tabbed reference: Species / Structures / Biomes.
## Was the structure-recipe modal; broadened so the player has one place to
## look up everything in the world. Discovery state still gates Structures
## (known patterns vs ??? silhouettes). Species/Biomes show full info.
##

const STRUCTURE_INDEX_PATH: String = "res://data/structures/_index.tres"
const SPECIES_INDEX_PATH: String = "res://data/species/_index.tres"
const BIOME_INDEX_PATH: String = "res://data/biomes/_index.tres"

const TAB_SPECIES: StringName = &"species"
const TAB_STRUCTURES: StringName = &"structures"
const TAB_BIOMES: StringName = &"biomes"

@onready var _panel: PanelContainer = $RecipePanel
@onready var _list: VBoxContainer = $RecipePanel/Margin/VBox/Scroll/List
@onready var _close: Button = $RecipePanel/Margin/VBox/Header/CloseButton
@onready var _tab_species: Button = $RecipePanel/Margin/VBox/Tabs/SpeciesTab
@onready var _tab_structures: Button = $RecipePanel/Margin/VBox/Tabs/StructuresTab
@onready var _tab_biomes: Button = $RecipePanel/Margin/VBox/Tabs/BiomesTab

var _current_tab: StringName = TAB_SPECIES


func _ready() -> void:
	_close.pressed.connect(queue_free)
	_tab_species.pressed.connect(func(): _set_tab(TAB_SPECIES))
	_tab_structures.pressed.connect(func(): _set_tab(TAB_STRUCTURES))
	_tab_biomes.pressed.connect(func(): _set_tab(TAB_BIOMES))
	EventBus.structure_promoted.connect(func(_id, _anchor):
		if _current_tab == TAB_STRUCTURES:
			_build_entries()
	)
	_set_tab(_current_tab)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var local_pos: Vector2 = _panel.get_local_mouse_position()
		if local_pos.x < 0 or local_pos.y < 0 or local_pos.x > _panel.size.x or local_pos.y > _panel.size.y:
			queue_free()


func _set_tab(tab: StringName) -> void:
	_current_tab = tab
	_refresh_tab_styling()
	_build_entries()


func _refresh_tab_styling() -> void:
	# Active tab is rendered solid; inactive tabs use the theme's flat style.
	_tab_species.flat = _current_tab != TAB_SPECIES
	_tab_structures.flat = _current_tab != TAB_STRUCTURES
	_tab_biomes.flat = _current_tab != TAB_BIOMES


func _build_entries() -> void:
	for child in _list.get_children():
		child.queue_free()
	match _current_tab:
		TAB_SPECIES:
			_build_species_entries()
		TAB_STRUCTURES:
			_build_structures_entries()
		TAB_BIOMES:
			_build_biomes_entries()


# --- Species ---------------------------------------------------------------

func _build_species_entries() -> void:
	var index: SpeciesIndex = load(SPECIES_INDEX_PATH) as SpeciesIndex
	if index == null:
		return
	var unlocked: Array = GameState.meta_save.get("species_unlocked", []) as Array
	for species in index.species:
		if species == null:
			continue
		var is_known: bool = unlocked.has(String(species.id))
		_list.add_child(_build_species_entry(species, is_known))


func _build_species_entry(sp: SpeciesData, known: bool) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _entry_stylebox(sp.tile_marker_color, known))
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 4)
	var swatch := ColorRect.new()
	swatch.custom_minimum_size = Vector2(12, 12)
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	swatch.color = sp.tile_marker_color if known else Color(0.4, 0.4, 0.4)
	header.add_child(swatch)
	var title := Label.new()
	title.text = sp.display_name if known else "???"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1.0, 1.0, 0.95))
	header.add_child(title)
	if sp.kingdom_id != &"" and known:
		var kingdom := Label.new()
		kingdom.text = String(sp.kingdom_id).capitalize()
		kingdom.add_theme_font_override("font", KingdomTheme.SMALL_FONT)
		kingdom.add_theme_font_size_override("font_size", KingdomTheme.SMALL_FONT_SIZE)
		kingdom.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		header.add_child(kingdom)
	vbox.add_child(header)

	if known and sp.latin_name != "":
		var latin := Label.new()
		latin.text = sp.latin_name
		latin.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		latin.add_theme_font_override("font", KingdomTheme.SMALL_FONT)
		latin.add_theme_font_size_override("font_size", KingdomTheme.SMALL_FONT_SIZE)
		latin.add_theme_color_override("font_color", Color(0.65, 0.65, 0.55))
		vbox.add_child(latin)

	var desc := Label.new()
	desc.text = sp.description if known else "Not yet discovered."
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_override("font", KingdomTheme.SMALL_FONT)
	desc.add_theme_font_size_override("font_size", KingdomTheme.SMALL_FONT_SIZE)
	desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8) if known else Color(0.5, 0.5, 0.5))
	vbox.add_child(desc)

	if known:
		var yield_text: String = _format_species_yield(sp)
		if yield_text != "":
			var yields := Label.new()
			yields.text = yield_text
			yields.add_theme_font_override("font", KingdomTheme.SMALL_FONT)
			yields.add_theme_font_size_override("font_size", KingdomTheme.SMALL_FONT_SIZE)
			yields.add_theme_color_override("font_color", Color(0.65, 0.75, 0.55))
			vbox.add_child(yields)
	return panel


func _format_species_yield(sp: SpeciesData) -> String:
	if sp.tick_yield.is_empty():
		return ""
	var parts: Array[String] = []
	for r in sp.tick_yield.keys():
		var v: float = float(sp.tick_yield[r])
		if v == 0.0:
			continue
		parts.append("%s +%.1f" % [String(r).capitalize(), v])
	if parts.is_empty():
		return ""
	return "Yield/tick: " + ", ".join(parts)


# --- Structures ------------------------------------------------------------

func _build_structures_entries() -> void:
	var index: StructureIndex = load(STRUCTURE_INDEX_PATH) as StructureIndex
	if index == null:
		return
	var discovered: Array = GameState.meta_save.get("structures_discovered", []) as Array
	for sd in index.structures:
		if sd == null:
			continue
		var is_known: bool = discovered.has(String(sd.id))
		_list.add_child(_build_structure_entry(sd, is_known))


func _build_structure_entry(sd: StructureData, known: bool) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _entry_stylebox(sd.halo_color, known))
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 4)
	var swatch := ColorRect.new()
	swatch.custom_minimum_size = Vector2(12, 12)
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	swatch.color = sd.halo_color if known else Color(0.4, 0.4, 0.4)
	header.add_child(swatch)
	var title := Label.new()
	title.text = sd.display_name if known else "???"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1.0, 1.0, 0.95))
	header.add_child(title)
	vbox.add_child(header)

	var desc := Label.new()
	desc.text = sd.description if known else _silhouette_hint(sd)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_override("font", KingdomTheme.SMALL_FONT)
	desc.add_theme_font_size_override("font_size", KingdomTheme.SMALL_FONT_SIZE)
	desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8) if known else Color(0.5, 0.5, 0.5))
	vbox.add_child(desc)

	if known:
		var pattern_text := Label.new()
		pattern_text.text = _format_pattern(sd)
		pattern_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		pattern_text.add_theme_font_override("font", KingdomTheme.SMALL_FONT)
		pattern_text.add_theme_font_size_override("font_size", KingdomTheme.SMALL_FONT_SIZE)
		pattern_text.add_theme_color_override("font_color", Color(0.65, 0.75, 0.55))
		vbox.add_child(pattern_text)
	return panel


func _silhouette_hint(sd: StructureData) -> String:
	match sd.pattern_type:
		&"block_NxM_same_species":
			return "Some say a thick patch of one kind brings the form."
		&"ring_radius_N":
			return "A circle of similar around a hollow center."
		&"square_NxM_with_adjacent":
			return "Two kingdoms must touch in numbers."
		&"area_on_biome":
			return "The right soil + the right neighbors."
		_:
			return "Unknown form."


func _format_pattern(sd: StructureData) -> String:
	var p: Dictionary = sd.pattern_params
	match sd.pattern_type:
		&"block_NxM_same_species":
			return "Pattern: %dx%d block, same species, %s kingdom" % [
				int(p.get("width", 0)), int(p.get("height", 0)),
				String(p.get("kingdom_id", ""))
			]
		&"square_NxM_with_adjacent":
			return "Pattern: %dx%d %s block, >=%d adjacent %s" % [
				int(p.get("width", 0)), int(p.get("height", 0)),
				String(p.get("kingdom_id", "")), int(p.get("min_adjacent", 0)),
				String(p.get("adjacent_kingdom_id", ""))
			]
		&"ring_radius_N":
			return "Pattern: hollow ring radius %d, %s kingdom" % [
				int(p.get("radius", 0)), String(p.get("kingdom_id", ""))
			]
		&"area_on_biome":
			return "Pattern: %dx%d %s block on %s biome%s" % [
				int(p.get("width", 0)), int(p.get("height", 0)),
				String(p.get("kingdom_id", "")), String(p.get("biome_id", "")),
				" + corpse adj" if p.get("require_adjacent_corpse", false) else ""
			]
		_:
			return "Pattern: ???"


# --- Biomes ----------------------------------------------------------------

func _build_biomes_entries() -> void:
	var index: BiomeIndex = load(BIOME_INDEX_PATH) as BiomeIndex
	if index == null:
		return
	for biome in index.biomes:
		if biome == null:
			continue
		_list.add_child(_build_biome_entry(biome))


func _build_biome_entry(b: BiomeData) -> Control:
	var swatch_color: Color = _biome_swatch_color(b.id)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _entry_stylebox(swatch_color, true))
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 4)
	var swatch := ColorRect.new()
	swatch.custom_minimum_size = Vector2(12, 12)
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	swatch.color = swatch_color
	header.add_child(swatch)
	var title := Label.new()
	title.text = b.display_name
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1.0, 1.0, 0.95))
	header.add_child(title)
	vbox.add_child(header)

	var stats := Label.new()
	stats.text = _format_biome_stats(b)
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats.add_theme_font_override("font", KingdomTheme.SMALL_FONT)
	stats.add_theme_font_size_override("font_size", KingdomTheme.SMALL_FONT_SIZE)
	stats.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(stats)
	return panel


func _format_biome_stats(b: BiomeData) -> String:
	var parts: Array[String] = []
	parts.append("Sun %.1f" % b.sunlight_per_tick)
	parts.append("Nut %.1f" % b.nutrient_per_tick)
	parts.append("Dec %.1f" % b.decay_per_tick)
	if b.chemosynthesis_per_tick > 0.0:
		parts.append("Chm %.1f" % b.chemosynthesis_per_tick)
	return " / ".join(parts)


func _biome_swatch_color(biome_id: StringName) -> Color:
	# Kept in sync with biome_legend.gd / tile_grid.gd atlas body colors.
	match biome_id:
		&"tundra": return Color8(0xa5, 0xc8, 0xee)
		&"mineral_vent": return Color8(0x3a, 0x3a, 0x40)
		&"swamp": return Color8(0x5a, 0x70, 0x2a)
		&"grassland": return Color8(0x78, 0x95, 0x4a)
		&"rich_soil": return Color8(0x6a, 0x55, 0x38)
		&"forest_edge": return Color8(0x4a, 0x6a, 0x35)
		_: return Color(0.6, 0.6, 0.6)


# --- Shared ----------------------------------------------------------------

func _entry_stylebox(border: Color, known: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.10, 0.12) if known else Color(0.06, 0.06, 0.08)
	sb.border_color = border if known else Color(0.25, 0.25, 0.28)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(2)
	sb.content_margin_left = 4
	sb.content_margin_right = 4
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	return sb
