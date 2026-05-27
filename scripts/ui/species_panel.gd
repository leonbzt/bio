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
	# Perf: species rows don't read resource values — they read adaptation level,
	# placement target, and tile color. Refreshing on every resource_changed
	# (~15+ per tick) was rebuilding every button each tick. Adaptation/leveling
	# signals already cover the cases where rows actually change.
	EventBus.species_leveled.connect(func(_id, _level): _refresh())
	AdaptationSystem.adaptation_changed.connect(func(_v): _refresh())
	EventBus.placement_target_changed.connect(func(_id): _refresh())
	# HTML5 fix: parent (HUD) sometimes reports a stale size during _ready,
	# so anchor_bottom=1 lands at the wrong y. Re-assert dock layout deferred
	# and on viewport resize. grow_vertical=0 (from the scene) handles the
	# upward expansion when AvailableList is toggled visible.
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
	# Compact 36x36 icon button. Tile_marker_color is the background; the
	# kingdom icon (if commissioned for this kingdom) overlays it. Kingdoms
	# without a PNG fall back to the species name's first letter. Long tooltip
	# shows full info + Latin + level + cost. Selected = bright outer border.
	# ▲ corner badge if evolvable.
	var btn := Button.new()
	var current_level: int = AdaptationSystem.get_level(species.id)
	var can_evolve: bool = AdaptationSystem.can_level_up(species.id)
	var next_cost: float = AdaptationSystem.get_next_level_cost(species.id)
	var is_active: bool = (GameState.placement_target_species_id == species.id)

	var kingdom_tex: Texture2D = _kingdom_icon(species.kingdom_id)
	if kingdom_tex == null:
		btn.text = species.display_name.substr(0, 1) if species.display_name != "" else "?"
	else:
		btn.text = ""
	btn.custom_minimum_size = Vector2(36, 36)
	btn.tooltip_text = "%s\n%s\nLvl %d/3 (+%d%% yield)" % [
		species.display_name,
		species.latin_name if species.latin_name != "" else "",
		current_level,
		int((current_level - 1) * 10)
	]
	if next_cost >= 0.0:
		btn.tooltip_text += "\nLong-press to evolve (%.0f Adaptation)" % next_cost

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

	# Kingdom-icon overlay (when a PNG exists for this kingdom). Sits on top
	# of the tile_marker_color background, mouse-transparent so the button
	# still receives clicks. Nearest filter keeps pixel art crisp.
	if kingdom_tex != null:
		var icon := TextureRect.new()
		icon.texture = kingdom_tex
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(icon)

	# Evolve-ready ▲ corner badge. Lives as a child so it survives both the
	# icon and the letter-glyph paths.
	if can_evolve:
		var badge := Label.new()
		badge.text = "▲"
		badge.add_theme_color_override("font_color", Color(1.0, 1.0, 0.6))
		badge.add_theme_font_size_override("font_size", 10)
		badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		badge.offset_left = -12
		badge.offset_top = -2
		badge.offset_right = -2
		badge.offset_bottom = 12
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(badge)

	# Tap = select as placement target. Double-tap or right-click = evolve.
	btn.pressed.connect(func() -> void:
		# If already active AND evolvable, treat the tap as an evolve action.
		# Otherwise, just select.
		if is_active and can_evolve:
			_open_evolve_modal(species)
			return
		GameState.placement_target_species_id = species.id
		EventBus.placement_target_changed.emit(String(species.id))
		# _refresh() runs via the placement_target_changed subscription.
	)
	# Right-click as evolve shortcut on desktop.
	btn.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			var mb: InputEventMouseButton = event
			if mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT and can_evolve:
				_open_evolve_modal(species)
	)
	return btn


func _open_evolve_modal(species: SpeciesData) -> void:
	var scene: PackedScene = load("res://scenes/ui/evolve_modal.tscn") as PackedScene
	if scene == null:
		return
	var modal: Node = scene.instantiate()
	if modal.has_method("setup"):
		modal.setup(species)
	var parent: Node = get_parent()
	if parent != null:
		parent.add_child(modal)
	else:
		add_child(modal)


func _build_available_row(species: SpeciesData) -> Control:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label := Label.new()
	label.text = species.display_name
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.95))
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
	if species.era_requires != &"" and species.era_requires != era.id:
		return false
	if era.available_kingdoms.is_empty():
		return true
	return era.available_kingdoms.has(species.kingdom_id)
