extends Control

const SPECIES_INDEX_PATH: String = "res://data/species/_index.tres"
const ROLES: Array[StringName] = [&"producer", &"harvester", &"recycler"]

var ecosystem: EcosystemData
var _species_by_id: Dictionary[StringName, SpeciesData] = {}
var _team: Dictionary = {}
var _active_role: StringName = &""

@onready var _title: Label = $Panel/VBox/Title
@onready var _description: Label = $Panel/VBox/Description
@onready var _scroll: ScrollContainer = $Panel/VBox/SpeciesScroll
@onready var _grid: GridContainer = $Panel/VBox/SpeciesScroll/SpeciesGrid
@onready var _vbox: VBoxContainer = $Panel/VBox
@onready var _cancel: Button = $Panel/VBox/Actions/CancelButton

var _slots_container: HBoxContainer = null
var _slot_buttons: Dictionary = {}
var _begin_button: Button = null


func _ready() -> void:
	_cancel.pressed.connect(queue_free)
	_build_species_index()
	_build_team_ui()
	_active_role = &"producer"
	_refresh()


func _build_species_index() -> void:
	_species_by_id.clear()
	var index: SpeciesIndex = load(SPECIES_INDEX_PATH) as SpeciesIndex
	if index == null:
		return
	for species in index.species:
		if species != null:
			_species_by_id[species.id] = species


func _build_team_ui() -> void:
	_slots_container = HBoxContainer.new()
	_slots_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_slots_container.add_theme_constant_override("separation", 8)
	for role in ROLES:
		var slot := Button.new()
		slot.custom_minimum_size = Vector2(100, 60)
		slot.text = SpeciesStats.role_label(role)
		slot.add_theme_font_size_override("font_size", 13)
		var sb := StyleBoxFlat.new()
		sb.bg_color = SpeciesStats.role_color(role).darkened(0.55)
		sb.border_color = SpeciesStats.role_color(role).darkened(0.2)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(4)
		sb.content_margin_left = 6
		sb.content_margin_right = 6
		sb.content_margin_top = 4
		sb.content_margin_bottom = 4
		slot.add_theme_stylebox_override("normal", sb)
		var hover_sb := sb.duplicate() as StyleBoxFlat
		hover_sb.border_color = SpeciesStats.role_color(role)
		slot.add_theme_stylebox_override("hover", hover_sb)
		slot.pressed.connect(_on_slot_pressed.bind(role))
		_slot_buttons[role] = slot
		_slots_container.add_child(slot)
	_vbox.add_child(_slots_container)
	_vbox.move_child(_slots_container, _description.get_index() + 1)

	_begin_button = Button.new()
	_begin_button.text = "Begin Run"
	_begin_button.custom_minimum_size = Vector2(0, 40)
	_begin_button.disabled = true
	_begin_button.pressed.connect(_on_begin_pressed)
	var actions: HBoxContainer = $Panel/VBox/Actions
	actions.add_child(_begin_button)


func _on_slot_pressed(role: StringName) -> void:
	_active_role = role
	_refresh()


func _refresh() -> void:
	for child in _grid.get_children():
		child.queue_free()
	if ecosystem == null:
		return
	_title.text = ecosystem.display_name
	_description.text = "Pick one species per role"
	_update_slot_visuals()
	var candidates: Array[SpeciesData] = _get_candidates_for_role(_active_role)
	if candidates.is_empty():
		var empty := Label.new()
		empty.text = "No %s species unlocked" % SpeciesStats.role_label(_active_role)
		empty.add_theme_color_override("font_color", Color(0.85, 0.75, 0.55))
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_grid.add_child(empty)
	else:
		for species in candidates:
			_grid.add_child(_build_card(species))
	_begin_button.disabled = _team.size() < ROLES.size()


func _update_slot_visuals() -> void:
	for role in ROLES:
		var slot: Button = _slot_buttons[role]
		var selected: SpeciesData = _team.get(role, null)
		if selected != null:
			slot.text = selected.display_name
		else:
			slot.text = SpeciesStats.role_label(role)
		var sb: StyleBoxFlat
		if role == _active_role:
			sb = StyleBoxFlat.new()
			sb.bg_color = SpeciesStats.role_color(role).darkened(0.3)
			sb.border_color = SpeciesStats.role_color(role)
			sb.set_border_width_all(3)
		else:
			sb = StyleBoxFlat.new()
			sb.bg_color = SpeciesStats.role_color(role).darkened(0.55)
			sb.border_color = SpeciesStats.role_color(role).darkened(0.2)
			sb.set_border_width_all(2)
		sb.set_corner_radius_all(4)
		sb.content_margin_left = 6
		sb.content_margin_right = 6
		sb.content_margin_top = 4
		sb.content_margin_bottom = 4
		slot.add_theme_stylebox_override("normal", sb)
		slot.add_theme_stylebox_override("hover", sb)


func _get_candidates_for_role(role: StringName) -> Array[SpeciesData]:
	var result: Array[SpeciesData] = []
	if ecosystem == null:
		return result
	var unlocked: Array = GameState.meta_save.get("species_unlocked", []) as Array
	var era_id: StringName = ecosystem.era_id
	for species_id in unlocked:
		var species: SpeciesData = _species_by_id.get(StringName(species_id), null)
		if species == null:
			continue
		if species.role != role:
			continue
		if species.era_requires != &"" and species.era_requires != era_id:
			continue
		result.append(species)
	return result


func _build_card(species: SpeciesData) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(140, 90)
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	var name_lbl := Label.new()
	name_lbl.text = species.display_name
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 0.95))
	vbox.add_child(name_lbl)

	var stats: Dictionary = SpeciesStats.derive(species)
	var stat_lbl := Label.new()
	stat_lbl.text = "P:%d C:%d R:%d S:%d" % [
		stats["production"], stats["consumption"],
		stats["resistance"], stats["spread"]
	]
	stat_lbl.add_theme_font_size_override("font_size", 11)
	stat_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.65))
	vbox.add_child(stat_lbl)

	if stats["special_name"] != "":
		var sp_lbl := Label.new()
		sp_lbl.text = "%s: %d" % [stats["special_name"], stats["special_value"]]
		sp_lbl.add_theme_font_size_override("font_size", 11)
		sp_lbl.add_theme_color_override("font_color", SpeciesStats.role_color(species.role))
		vbox.add_child(sp_lbl)

	var desc := Label.new()
	desc.text = species.description
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", Color(0.75, 0.75, 0.7))
	vbox.add_child(desc)

	var is_selected: bool = (_team.get(species.role, null) == species)
	var select := Button.new()
	select.text = "Selected" if is_selected else "Select"
	select.disabled = is_selected
	select.pressed.connect(func() -> void:
		_select_species(species)
	)
	vbox.add_child(select)
	return panel


func _select_species(species: SpeciesData) -> void:
	_team[species.role] = species
	var next_empty: StringName = &""
	for role in ROLES:
		if not _team.has(role):
			next_empty = role
			break
	if next_empty != &"":
		_active_role = next_empty
	_refresh()


func _on_begin_pressed() -> void:
	if _team.size() < ROLES.size() or ecosystem == null:
		return
	var team: Array[SpeciesData] = []
	for role in ROLES:
		team.append(_team[role])
	_begin_team_run(team)


func _begin_team_run(team: Array[SpeciesData]) -> void:
	var ids: Array = []
	for species in team:
		ids.append(String(species.id))
	GameState.run_save["team"] = ids
	GameState.run_save["unlocked_species_in_run"] = ids.duplicate()
	GameState.run_save["starting_species_id"] = ids[0]
	GameState.run_save["starting_species_kingdom_id"] = String(team[0].kingdom_id)
	GameState.placement_target_species_id = team[0].id
	if has_node("/root/EraSystem"):
		var era_system: Node = get_node("/root/EraSystem")
		if era_system.has_method("set_current_ecosystem"):
			era_system.set_current_ecosystem(ecosystem.id)
	PrestigeSystem.start_team_run(team)
	get_tree().change_scene_to_file("res://scenes/world/world.tscn")
