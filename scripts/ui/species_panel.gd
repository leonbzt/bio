extends PanelContainer

const SPECIES_INDEX_PATH: String = "res://data/species/_index.tres"

var _species_by_id: Dictionary[StringName, SpeciesData] = {}
# Available section is collapsed by default — bottom bar stays minimal
# until the player opens it to introduce more species.
var _available_collapsed: bool = true

@onready var _introduced: HBoxContainer = $Margin/VBox/BottomBar/IntroducedScroll/IntroducedList
@onready var _available: VBoxContainer = $Margin/VBox/AvailableList
@onready var _available_header: Button = $Margin/VBox/BottomBar/AvailableHeader


func _ready() -> void:
	_build_species_index()
	_available_header.pressed.connect(_on_available_header_pressed)
	EventBus.run_started.connect(func(_k): _refresh_all())
	EventBus.run_loaded.connect(func(_v): _refresh_all())
	EventBus.resource_changed.connect(func(_r, _v): _refresh())
	_apply_collapsed_state()
	_refresh_all()


func _on_available_header_pressed() -> void:
	# Only the "Available" (introduce-new-species) section collapses.
	# Introduced buttons stay visible so the placement-target selector is
	# always accessible.
	_available_collapsed = not _available_collapsed
	_apply_collapsed_state()


func _apply_collapsed_state() -> void:
	_available.visible = not _available_collapsed
	_available_header.text = "Avail ▲" if _available_collapsed else "Avail ▼"
	_available_header.tooltip_text = (
		"Show species available to introduce" if _available_collapsed
		else "Hide available species"
	)


func _refresh_all() -> void:
	_apply_kingdom_theme()
	_refresh()


func _apply_kingdom_theme() -> void:
	var k: StringName = KingdomTheme.current_kingdom_id()
	if k == &"":
		return
	add_theme_stylebox_override("panel", KingdomTheme.panel_stylebox(k))


func _build_species_index() -> void:
	_species_by_id.clear()
	var index: SpeciesIndex = load(SPECIES_INDEX_PATH) as SpeciesIndex
	if index == null:
		return
	for species in index.species:
		if species != null:
			_species_by_id[species.id] = species


func _refresh() -> void:
	for child in _introduced.get_children():
		child.queue_free()
	for child in _available.get_children():
		child.queue_free()
	var in_run: Array = GameState.run_save.get("unlocked_species_in_run", []) as Array
	var unlocked: Array = GameState.meta_save.get("species_unlocked", []) as Array
	for species_id_str in in_run:
		var species: SpeciesData = _species_by_id.get(StringName(species_id_str), null)
		if species == null:
			continue
		_introduced.add_child(_build_introduced_row(species))
	for species_id_str in unlocked:
		if in_run.has(species_id_str):
			continue
		var species: SpeciesData = _species_by_id.get(StringName(species_id_str), null)
		if species == null:
			continue
		if not _is_species_era_available(species):
			continue
		_available.add_child(_build_available_row(species))


func _build_introduced_row(species: SpeciesData) -> Control:
	# Compact horizontal button for the bottom bar. Latin name moves to the
	# tooltip — there's no vertical room in a horizontal bar.
	var btn := Button.new()
	btn.text = species.display_name
	btn.custom_minimum_size = Vector2(0, 40)
	btn.modulate = species.tile_marker_color
	var is_active: bool = (GameState.placement_target_species_id == species.id)
	btn.disabled = is_active
	if species.latin_name != "":
		btn.tooltip_text = "%s\n%s" % [species.display_name, species.latin_name]
	# Per-button stylebox so the active species reads as "selected" instead of
	# just disabled. Selected = brighter border, slight outer glow via lightened.
	var sb := StyleBoxFlat.new()
	sb.bg_color = species.tile_marker_color.darkened(0.35)
	sb.border_color = species.tile_marker_color.lightened(0.25) if is_active else species.tile_marker_color.darkened(0.15)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(2)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("disabled", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	btn.add_theme_color_override("font_disabled_color", Color(1.0, 1.0, 0.85))
	btn.pressed.connect(func() -> void:
		GameState.placement_target_species_id = species.id
		EventBus.placement_target_changed.emit(String(species.id))
		_refresh()
	)
	return btn


func _build_available_row(species: SpeciesData) -> Control:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label := Label.new()
	label.text = species.display_name
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(label)
	if species.latin_name != "":
		var lat := Label.new()
		lat.text = species.latin_name
		lat.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lat.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		lat.add_theme_font_override("font", KingdomTheme.SMALL_FONT)
		lat.add_theme_font_size_override("font_size", KingdomTheme.SMALL_FONT_SIZE)
		lat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_child(lat)
	row.add_child(info)
	var button := Button.new()
	button.text = "Introduce"
	button.disabled = not ResourceLedger.can_afford(species.introduce_cost)
	button.pressed.connect(func() -> void:
		_introduce_species(species)
	)
	row.add_child(button)
	return row


func _introduce_species(species: SpeciesData) -> void:
	if species == null:
		return
	if not ResourceLedger.can_afford(species.introduce_cost):
		return
	ResourceLedger.spend_bundle(species.introduce_cost)
	var in_run: Array = GameState.run_save.get("unlocked_species_in_run", []) as Array
	if not in_run.has(String(species.id)):
		in_run.append(String(species.id))
		GameState.run_save["unlocked_species_in_run"] = in_run
	EventBus.species_introduced.emit(species.id)
	SaveSystem.save_now()
	_refresh()


func _is_species_era_available(species: SpeciesData) -> bool:
	if not has_node("/root/EraSystem"):
		return true
	var era_system: Node = get_node("/root/EraSystem")
	if not era_system.has_method("get_current_era"):
		return true
	var era: EraData = era_system.get_current_era()
	if era == null:
		return true
	if era.available_kingdoms.is_empty():
		return true
	return era.available_kingdoms.has(species.kingdom_id)
