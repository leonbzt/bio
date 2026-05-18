extends PanelContainer

const SPECIES_INDEX_PATH: String = "res://data/species/_index.tres"

var _species_by_id: Dictionary[StringName, SpeciesData] = {}

@onready var _introduced: VBoxContainer = $VBox/IntroducedList
@onready var _available: VBoxContainer = $VBox/AvailableList


func _ready() -> void:
	_build_species_index()
	EventBus.run_started.connect(func(_k): _refresh())
	EventBus.run_loaded.connect(func(_v): _refresh())
	EventBus.resource_changed.connect(func(_r, _v): _refresh())
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
	var row := HBoxContainer.new()
	var btn := Button.new()
	btn.text = species.display_name
	btn.modulate = species.tile_marker_color
	btn.disabled = GameState.placement_target_species_id == species.id
	btn.pressed.connect(func() -> void:
		GameState.placement_target_species_id = species.id
		EventBus.placement_target_changed.emit(String(species.id))
		_refresh()
	)
	row.add_child(btn)
	return row


func _build_available_row(species: SpeciesData) -> Control:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = species.display_name
	row.add_child(label)
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
