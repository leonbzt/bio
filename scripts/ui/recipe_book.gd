extends Control

const STRUCTURE_INDEX_PATH: String = "res://data/structures/_index.tres"

@onready var _panel: PanelContainer = $RecipePanel
@onready var _list: VBoxContainer = $RecipePanel/Margin/VBox/List
@onready var _close: Button = $RecipePanel/Margin/VBox/Header/CloseButton


func _ready() -> void:
	_close.pressed.connect(queue_free)
	EventBus.structure_promoted.connect(func(_id, _anchor): _build_entries())
	_build_entries()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var local_pos: Vector2 = _panel.get_local_mouse_position()
		if local_pos.x < 0 or local_pos.y < 0 or local_pos.x > _panel.size.x or local_pos.y > _panel.size.y:
			queue_free()


func _build_entries() -> void:
	for child in _list.get_children():
		child.queue_free()
	var index: StructureIndex = load(STRUCTURE_INDEX_PATH) as StructureIndex
	if index == null:
		return
	var discovered: Array = GameState.meta_save.get("structures_discovered", []) as Array
	for sd in index.structures:
		if sd == null:
			continue
		var is_known: bool = discovered.has(String(sd.id))
		_list.add_child(_build_entry(sd, is_known))


func _build_entry(sd: StructureData, known: bool) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _entry_stylebox(sd, known))
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
		pattern_text.add_theme_font_override("font", KingdomTheme.SMALL_FONT)
		pattern_text.add_theme_font_size_override("font_size", KingdomTheme.SMALL_FONT_SIZE)
		pattern_text.add_theme_color_override("font_color", Color(0.65, 0.75, 0.55))
		vbox.add_child(pattern_text)
	return panel


func _entry_stylebox(sd: StructureData, known: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.10, 0.12) if known else Color(0.06, 0.06, 0.08)
	sb.border_color = sd.halo_color if known else Color(0.25, 0.25, 0.28)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(2)
	sb.content_margin_left = 4
	sb.content_margin_right = 4
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	return sb


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
