extends Control

const ERA_TAB_ACTIVE: Color = Color(1.0, 1.0, 0.85, 1.0)
const ERA_TAB_INACTIVE: Color = Color(0.65, 0.65, 0.65, 1.0)
const ERA_TAB_LOCKED: Color = Color(0.4, 0.4, 0.4, 0.6)

@onready var _backdrop: ColorRect = $Backdrop
@onready var _era_tabs: HBoxContainer = $Layout/EraTabs
@onready var _ecosystem_grid: GridContainer = $Layout/EcosystemScroll/EcosystemGrid
@onready var _continue: Button = $Layout/ContinueButton
@onready var _close: Button = $Header/CloseButton

var _selected_era_id: StringName = &""


func _ready() -> void:
	_close.pressed.connect(_on_close)
	_continue.visible = false
	EventBus.era_changed.connect(func(_id): _refresh())
	EventBus.ecosystem_completed.connect(func(_id): _refresh())
	var era_system: Node = _get_era_system()
	if era_system != null:
		var current_era: EraData = era_system.get_current_era()
		if current_era != null:
			_selected_era_id = current_era.id
	_refresh()


func _refresh() -> void:
	_refresh_backdrop()
	_refresh_era_tabs()
	_refresh_ecosystem_grid()


func _refresh_backdrop() -> void:
	var era_system: Node = _get_era_system()
	if era_system == null:
		return
	var era: EraData = era_system.get_era(_selected_era_id)
	if era != null:
		_backdrop.color = era.tint_color


func _refresh_era_tabs() -> void:
	for child in _era_tabs.get_children():
		child.queue_free()
	var era_system: Node = _get_era_system()
	if era_system == null:
		return
	for era in era_system.get_all_eras():
		if era == null:
			continue
		var button := Button.new()
		var unlocked: bool = era_system.is_era_unlocked(era.id)
		# HTML5: pixel fonts don't ship the 🔒 emoji glyph — use ASCII marker.
		button.text = ("[X] %s" % era.display_name) if not unlocked else era.display_name
		button.disabled = not unlocked
		var captured_id: StringName = era.id
		button.pressed.connect(func() -> void:
			_selected_era_id = captured_id
			_refresh()
		)
		if not unlocked:
			button.modulate = ERA_TAB_LOCKED
		elif era.id == _selected_era_id:
			button.modulate = ERA_TAB_ACTIVE
		else:
			button.modulate = ERA_TAB_INACTIVE
		_era_tabs.add_child(button)


func _refresh_ecosystem_grid() -> void:
	for child in _ecosystem_grid.get_children():
		child.queue_free()
	var era_system: Node = _get_era_system()
	if era_system == null:
		return
	for eco in era_system.get_ecosystems_in_era(_selected_era_id):
		_ecosystem_grid.add_child(_build_ecosystem_card(eco))


func _build_ecosystem_card(eco: EcosystemData) -> PanelContainer:
	var era_system: Node = _get_era_system()
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 76)
	var sb := StyleBoxFlat.new()
	var done: bool = era_system != null and era_system.is_ecosystem_complete(eco.id)
	sb.bg_color = Color(0.15, 0.20, 0.15) if done else Color(0.15, 0.15, 0.18)
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_bottom_right = 4
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	card.add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	card.add_child(vbox)
	var title := Label.new()
	# HTML5: ✓ is outside pixel-font glyph coverage — use ASCII tag.
	title.text = ("[OK] " if done else "") + eco.display_name
	title.add_theme_color_override("font_color", Color(0.95, 0.9, 0.6) if done else Color(0.95, 0.95, 0.95))
	vbox.add_child(title)
	var desc := Label.new()
	desc.text = eco.description
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	vbox.add_child(desc)
	var goal := Label.new()
	goal.text = _goal_string(eco)
	goal.add_theme_color_override("font_color", Color(0.7, 0.85, 0.6))
	vbox.add_child(goal)

	card.gui_input.connect(func(event: InputEvent) -> void:
		var pressed: bool = false
		if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
			pressed = true
		elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
			pressed = true
		if pressed:
			_on_ecosystem_card_pressed(eco)
	)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	return card


func _goal_string(eco: EcosystemData) -> String:
	var goal: String = "%s %d" % [String(eco.completion_criterion).capitalize().replace("_", " "), int(eco.completion_target)]
	if eco.completion_required_species != &"":
		goal += " · %s" % String(eco.completion_required_species).capitalize()
	elif eco.completion_required_biome != &"":
		goal += " · %s biome" % String(eco.completion_required_biome).capitalize()
	return goal


func _on_ecosystem_card_pressed(ecosystem: EcosystemData) -> void:
	var picker_scene := load("res://scenes/ui/starting_species_picker.tscn") as PackedScene
	if picker_scene == null:
		return
	var picker := picker_scene.instantiate()
	if picker == null:
		return
	picker.ecosystem = ecosystem
	add_child(picker)


func _get_era_system() -> Node:
	if has_node("/root/EraSystem"):
		return get_node("/root/EraSystem")
	return null


func _on_close() -> void:
	queue_free()
