extends PanelContainer

const SPECIES_INDEX_PATH: String = "res://data/species/_index.tres"
# Bottom-dock margins. Kept here so _apply_dock_layout can re-assert them
# whenever the viewport resizes (HTML5 builds report a stale parent size at
# _ready, which positioned the panel below the visible area).
const DOCK_MARGIN_X: float = 4.0
const DOCK_MARGIN_BOTTOM: float = 4.0
const DOCK_COLLAPSED_HEIGHT: float = 56.0

# Commissioned per-kingdom icons. Missing entries fall back to the
# species name's first letter as a glyph.
const KINGDOM_ICON_PATHS: Dictionary = {
	&"fungi":   "res://assets/art/kingdoms/fungi.png",
	&"plantae": "res://assets/art/kingdoms/plantae.png",
}

var _species_by_id: Dictionary[StringName, SpeciesData] = {}
var _kingdom_icon_cache: Dictionary[StringName, Texture2D] = {}
var _available_collapsed: bool = true

@onready var _introduced: HBoxContainer = $Margin/VBox/BottomBar/IntroducedScroll/IntroducedList
@onready var _available: VBoxContainer = $Margin/VBox/AvailableList
@onready var _available_header: Button = $Margin/VBox/BottomBar/AvailableHeader


func _ready() -> void:
	_build_species_index()
	_available_header.pressed.connect(_on_available_header_pressed)
	EventBus.run_started.connect(func(_k): _refresh_all())
	EventBus.run_loaded.connect(func(_v): _refresh_all())
	EventBus.species_leveled.connect(func(_id, _level): _refresh())
	EventBus.placement_target_changed.connect(func(_id): _refresh())
	AdaptationSystem.adaptation_changed.connect(func(_a): _update_levelup_buttons())
	EventBus.tick.connect(_update_available_affordability)
	_apply_dock_layout()
	call_deferred("_apply_dock_layout")
	get_viewport().size_changed.connect(_apply_dock_layout)
	_apply_collapsed_state()
	_refresh_all()


func _apply_dock_layout() -> void:
	set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	offset_left = DOCK_MARGIN_X
	offset_right = -DOCK_MARGIN_X
	offset_bottom = -DOCK_MARGIN_BOTTOM
	offset_top = -(DOCK_COLLAPSED_HEIGHT + DOCK_MARGIN_BOTTOM)
	grow_vertical = Control.GROW_DIRECTION_BEGIN


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


func _update_levelup_buttons() -> void:
	for row in _introduced.get_children():
		if not (row is VBoxContainer):
			continue
		for child in (row as VBoxContainer).get_children():
			if not (child is Button):
				continue
			var button: Button = child
			if not button.has_meta("species_id"):
				continue
			var sid: StringName = StringName(button.get_meta("species_id"))
			button.disabled = not AdaptationSystem.can_level_up(sid)


func _update_available_affordability(_delta: float) -> void:
	for row in _available.get_children():
		if not (row is Control):
			continue
		for child in (row as Control).get_children():
			if not (child is Button):
				continue
			var button: Button = child
			if not button.has_meta("biomass_cost"):
				continue
			var cost: float = float(button.get_meta("biomass_cost", 0.0))
			button.disabled = not GameState.can_afford_hero_biomass(cost)


func _kingdom_icon(kingdom_id: StringName) -> Texture2D:
	if _kingdom_icon_cache.has(kingdom_id):
		return _kingdom_icon_cache[kingdom_id]
	var path: String = String(KINGDOM_ICON_PATHS.get(kingdom_id, ""))
	if path == "" or not ResourceLoader.exists(path):
		_kingdom_icon_cache[kingdom_id] = null
		return null
	var tex := load(path) as Texture2D
	_kingdom_icon_cache[kingdom_id] = tex
	return tex


func _build_introduced_row(species: SpeciesData) -> Control:
	var container := VBoxContainer.new()
	container.alignment = BoxContainer.ALIGNMENT_CENTER

	var btn := Button.new()
	var is_active: bool = (GameState.placement_target_species_id == species.id)

	var kingdom_tex: Texture2D = _kingdom_icon(species.kingdom_id)
	if kingdom_tex == null:
		btn.text = species.display_name.substr(0, 1) if species.display_name != "" else "?"
	else:
		btn.text = ""
	btn.custom_minimum_size = Vector2(48, 48)

	var level: int = AdaptationSystem.get_level(species.id)
	var next_cost: float = AdaptationSystem.get_next_level_cost(species.id)
	var level_tip: String = "Lv.%d" % level
	if next_cost >= 0.0:
		level_tip += " | Next: %.0f adapt" % next_cost
	else:
		level_tip += " (max)"
	var stats_tip: String = SpeciesStats.stat_summary(species)
	btn.tooltip_text = "%s [%s]\n%s\n%s\n%s\n\n%s" % [
		species.display_name,
		SpeciesStats.role_label(species.role),
		species.latin_name if species.latin_name != "" else "",
		level_tip,
		stats_tip,
		species.description if species.description != "" else ""
	]

	var sb := StyleBoxFlat.new()
	sb.bg_color = species.tile_marker_color.darkened(0.30 if not is_active else 0.05)
	sb.border_color = (species.tile_marker_color.lightened(0.35) if is_active
		else species.tile_marker_color.darkened(0.10))
	sb.set_border_width_all(2 if not is_active else 3)
	sb.set_corner_radius_all(2)
	sb.content_margin_left = 4
	sb.content_margin_right = 4
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("disabled", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_disabled_color", Color(1.0, 1.0, 0.85))

	if kingdom_tex != null:
		var icon := TextureRect.new()
		icon.texture = kingdom_tex
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(icon)

	# Level badge — bottom-right corner of the icon button
	var level_label := Label.new()
	level_label.text = "%d" % level
	level_label.add_theme_font_size_override("font_size", 10)
	level_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.7))
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	level_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(level_label)

	btn.pressed.connect(func() -> void:
		GameState.placement_target_species_id = species.id
		EventBus.placement_target_changed.emit(String(species.id))
	)
	container.add_child(btn)

	var role_lbl := Label.new()
	role_lbl.text = SpeciesStats.role_label(species.role)
	role_lbl.add_theme_font_size_override("font_size", 9)
	role_lbl.add_theme_color_override("font_color", SpeciesStats.role_color(species.role))
	role_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(role_lbl)

	if next_cost >= 0.0:
		var up_btn := Button.new()
		up_btn.text = "+"
		up_btn.custom_minimum_size = Vector2(48, 20)
		up_btn.tooltip_text = "Level up: %.0f adaptation" % next_cost
		up_btn.disabled = not AdaptationSystem.can_level_up(species.id)
		up_btn.set_meta("species_id", species.id)
		up_btn.add_theme_font_size_override("font_size", 12)
		up_btn.pressed.connect(func() -> void:
			_show_stat_choice_popup(species)
		)
		container.add_child(up_btn)

	return container


func _build_available_row(species: SpeciesData) -> Control:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Tooltip on the whole row so the hover zone is wide enough to read on.
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	var cost: float = _get_biomass_cost(species)
	row.tooltip_text = "%s [%s]\n%s\n%s\n\n%s\n\nCost: %.0f biomass" % [
		species.display_name,
		SpeciesStats.role_label(species.role),
		species.latin_name if species.latin_name != "" else "",
		SpeciesStats.stat_summary(species),
		species.description if species.description != "" else "",
		cost
	]
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_row := HBoxContainer.new()
	var label := Label.new()
	label.text = species.display_name
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.95))
	name_row.add_child(label)
	var role_tag := Label.new()
	role_tag.text = SpeciesStats.role_label(species.role)
	role_tag.add_theme_font_size_override("font_size", 11)
	role_tag.add_theme_color_override("font_color", SpeciesStats.role_color(species.role))
	name_row.add_child(role_tag)
	info.add_child(name_row)
	var derived: Dictionary = SpeciesStats.derive(species)
	var stat_lbl := Label.new()
	stat_lbl.text = "P:%d C:%d" % [derived["production"], derived["consumption"]]
	stat_lbl.add_theme_font_size_override("font_size", 11)
	stat_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.55))
	info.add_child(stat_lbl)
	row.add_child(info)
	var button := Button.new()
	button.text = "Introduce"
	button.set_meta("biomass_cost", cost)
	button.disabled = not GameState.can_afford_hero_biomass(cost)
	button.pressed.connect(func() -> void:
		_introduce_species(species)
	)
	row.add_child(button)
	return row


func _introduce_species(species: SpeciesData) -> void:
	if species == null:
		return
	var cost: float = _get_biomass_cost(species)
	if not GameState.spend_hero_biomass(cost):
		return
	var in_run: Array = GameState.run_save.get("unlocked_species_in_run", []) as Array
	if not in_run.has(String(species.id)):
		in_run.append(String(species.id))
		GameState.run_save["unlocked_species_in_run"] = in_run
	EventBus.species_introduced.emit(species.id)
	SaveSystem.save_now()
	_refresh()


func _get_biomass_cost(species: SpeciesData) -> float:
	if species == null:
		return 0.0
	var base: float = float(species.introduce_cost.get("biomass", 0.0))
	var spread_boost: int = AdaptationSystem.get_stat_boost(species.id, &"spread")
	return base * (1.0 - 0.10 * float(spread_boost))


func _is_species_era_available(species: SpeciesData) -> bool:
	if not has_node("/root/EraSystem"):
		return true
	var era_system: Node = get_node("/root/EraSystem")
	if not era_system.has_method("get_current_era"):
		return true
	var era: EraData = era_system.get_current_era()
	if era == null:
		return true
	if species.era_requires != &"" and species.era_requires != era.id:
		return false
	if era.available_kingdoms.is_empty():
		return true
	return era.available_kingdoms.has(species.kingdom_id)


func _show_stat_choice_popup(species: SpeciesData) -> void:
	var existing: Node = get_node_or_null("StatChoicePopup")
	if existing != null:
		existing.queue_free()

	var popup := PanelContainer.new()
	popup.name = "StatChoicePopup"
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.12, 0.15, 0.95)
	sb.border_color = Color(0.5, 0.5, 0.5)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	popup.add_theme_stylebox_override("panel", sb)
	popup.set_anchors_preset(Control.PRESET_CENTER)
	popup.offset_left = -80
	popup.offset_right = 80
	popup.offset_top = -90
	popup.offset_bottom = 90

	var vbox := VBoxContainer.new()
	var title_lbl := Label.new()
	title_lbl.text = "Level up %s" % species.display_name
	title_lbl.add_theme_font_size_override("font_size", 14)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 0.9))
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_lbl)

	var stat_labels: Dictionary = {
		&"production": "Production",
		&"efficiency": "Efficiency",
		&"resistance": "Resistance",
		&"spread": "Spread",
	}
	var derived: Dictionary = SpeciesStats.derive(species)
	var stat_base_map: Dictionary = {
		&"production": derived["production"],
		&"efficiency": 10 - derived["consumption"],
		&"resistance": derived["resistance"],
		&"spread": derived["spread"],
	}

	for stat_name in AdaptationSystem.STAT_NAMES:
		var current_boost: int = AdaptationSystem.get_stat_boost(species.id, stat_name)
		var base_val: int = int(stat_base_map.get(stat_name, 5))
		var current_val: int = base_val + current_boost
		var next_val: int = current_val + 1
		var stat_btn := Button.new()
		stat_btn.text = "%s: %d -> %d" % [stat_labels[stat_name], current_val, next_val]
		stat_btn.custom_minimum_size = Vector2(0, 32)
		stat_btn.add_theme_font_size_override("font_size", 13)
		stat_btn.pressed.connect(func() -> void:
			AdaptationSystem.level_up_stat(species.id, stat_name)
			popup.queue_free()
			_refresh()
		)
		vbox.add_child(stat_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.add_theme_font_size_override("font_size", 11)
	cancel_btn.pressed.connect(popup.queue_free)
	vbox.add_child(cancel_btn)

	popup.add_child(vbox)
	add_child(popup)
