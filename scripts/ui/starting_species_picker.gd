extends Control

const SPECIES_INDEX_PATH: String = "res://data/species/_index.tres"

var ecosystem: EcosystemData
var _species_by_id: Dictionary[StringName, SpeciesData] = {}

@onready var _title: Label = $Panel/VBox/Title
@onready var _description: Label = $Panel/VBox/Description
@onready var _scroll: ScrollContainer = $Panel/VBox/SpeciesScroll
@onready var _grid: GridContainer = $Panel/VBox/SpeciesScroll/SpeciesGrid
@onready var _vbox: VBoxContainer = $Panel/VBox
@onready var _cancel: Button = $Panel/VBox/Actions/CancelButton

var _empty_label: Label = null


func _ready() -> void:
	_cancel.pressed.connect(queue_free)
	_build_species_index()
	_refresh()


func _build_species_index() -> void:
	_species_by_id.clear()
	var index: SpeciesIndex = load(SPECIES_INDEX_PATH) as SpeciesIndex
	if index == null:
		return
	for species in index.species:
		if species != null:
			_species_by_id[species.id] = species


func _refresh() -> void:
	for child in _grid.get_children():
		child.queue_free()
	if _empty_label != null:
		_empty_label.queue_free()
		_empty_label = null
	if ecosystem == null:
		return
	_title.text = ecosystem.display_name
	_description.text = ecosystem.description
	var candidates: Array[SpeciesData] = _get_candidates()
	if candidates.is_empty():
		_scroll.visible = false
		_empty_label = Label.new()
		_empty_label.text = "No eligible species unlocked for this ecosystem.\nUnlock more species in the evolution tree."
		_empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_empty_label.add_theme_color_override("font_color", Color(0.85, 0.75, 0.55))
		_empty_label.custom_minimum_size = Vector2(0, 80)
		_empty_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_vbox.add_child(_empty_label)
		_vbox.move_child(_empty_label, _scroll.get_index())
		return
	_scroll.visible = true
	for species in candidates:
		_grid.add_child(_build_card(species))


func _get_candidates() -> Array[SpeciesData]:
	var result: Array[SpeciesData] = []
	if ecosystem == null:
		return result
	var unlocked: Array = GameState.meta_save.get("species_unlocked", []) as Array
	var filter: Array[StringName] = ecosystem.starting_species_filter
	if filter.is_empty():
		for species_id in unlocked:
			var species: SpeciesData = _species_by_id.get(StringName(species_id), null)
			if species != null:
				result.append(species)
	else:
		for species_id in filter:
			if not unlocked.has(String(species_id)):
				continue
			var species: SpeciesData = _species_by_id.get(species_id, null)
			if species != null:
				result.append(species)
	return result


func _build_card(species: SpeciesData) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(140, 90)
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	var name := Label.new()
	name.text = species.display_name
	vbox.add_child(name)
	if species.latin_name != "":
		var lat := Label.new()
		lat.text = species.latin_name
		lat.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		lat.add_theme_font_size_override("font_size", 10)
		vbox.add_child(lat)
	var kingdom := Label.new()
	kingdom.text = String(species.kingdom_id).capitalize()
	vbox.add_child(kingdom)
	var desc := Label.new()
	desc.text = species.description
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)
	var begin := Button.new()
	begin.text = "Begin"
	begin.pressed.connect(func() -> void:
		_begin_run(species)
	)
	vbox.add_child(begin)
	return panel


func _begin_run(species: SpeciesData) -> void:
	if species == null or ecosystem == null:
		return
	GameState.run_save["starting_species_id"] = String(species.id)
	GameState.run_save["unlocked_species_in_run"] = [String(species.id)]
	GameState.run_save["starting_species_kingdom_id"] = String(species.kingdom_id)
	GameState.placement_target_species_id = species.id
	if has_node("/root/EraSystem"):
		var era_system: Node = get_node("/root/EraSystem")
		if era_system.has_method("set_current_ecosystem"):
			era_system.set_current_ecosystem(ecosystem.id)
	PrestigeSystem.start_run(species)
	get_tree().change_scene_to_file("res://scenes/world/world.tscn")
