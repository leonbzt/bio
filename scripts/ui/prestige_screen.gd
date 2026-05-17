extends Control

@export var skip_to_kingdom_select: bool = false

@onready var _summary_section: VBoxContainer = $Content/SummarySection
@onready var _tree_section: VBoxContainer = $Content/TreeSection
@onready var _kingdom_section: VBoxContainer = $Content/KingdomSection
@onready var _reward_label: Label = $Content/SummarySection/RewardLabel
@onready var _biomass_label: Label = $Content/SummarySection/BiomassLabel
@onready var _confirm_button: Button = $Content/SummarySection/ConfirmPrestigeButton
@onready var _balance_label: Label = $Content/TreeSection/BalanceLabel
@onready var _tree_canvas: Control = $Content/TreeSection/TreeScroll/TreeCanvas
@onready var _kingdom_buttons: VBoxContainer = $Content/KingdomSection/KingdomButtons

var _prestige_system: Node = null
var _active_kingdom_id: StringName = &""


func _ready() -> void:
	_confirm_button.pressed.connect(_on_confirm_prestige)
	if _prestige_system == null:
		_prestige_system = _get_prestige_system()
	_refresh_summary()
	if skip_to_kingdom_select:
		_show_kingdom_only()


func setup(prestige_system: Node) -> void:
	_prestige_system = prestige_system


func _on_confirm_prestige() -> void:
	if _prestige_system == null:
		return
	if _prestige_system.has_method("trigger_prestige"):
		_prestige_system.trigger_prestige()
	_refresh_tree()
	_show_tree()


func _refresh_summary() -> void:
	if _prestige_system == null:
		return
	var reward: int = _prestige_system.get_pending_reward()
	var earned: float = float(GameState.run_save.get("statistics", {}).get("total_biomass_earned", 0.0))
	_reward_label.text = "This run earned: %d EP" % reward
	_biomass_label.text = "Total biomass earned: %s" % FormatUtils.abbreviate(earned)


func _refresh_tree() -> void:
	if _prestige_system == null:
		return
	_balance_label.text = "Balance: %d EP" % _prestige_system.get_evolution_points_balance()
	if not _tree_canvas.has_meta("_setup_done"):
		_tree_canvas.set_meta("_setup_done", true)
		_tree_canvas.setup(_prestige_system)
		_tree_canvas.node_purchase_requested.connect(_on_node_purchase_requested)
	else:
		_tree_canvas.refresh()


func _on_node_purchase_requested(node_id: StringName) -> void:
	if _prestige_system.purchase_node(node_id):
		_refresh_tree()
		_refresh_kingdoms()


func _refresh_kingdoms() -> void:
	for child in _kingdom_buttons.get_children():
		child.queue_free()
	var kingdoms: Array = GameState.meta_save.get("unlocked_kingdoms", [])
	# Phase 12: filter by current era's available_kingdoms.
	var era: EraData = null
	if has_node("/root/EraSystem"):
		var era_system: Node = get_node("/root/EraSystem")
		if era_system.has_method("get_current_era"):
			era = era_system.get_current_era()
	if era != null and not era.available_kingdoms.is_empty():
		var filtered: Array = []
		for kid in kingdoms:
			if era.available_kingdoms.has(StringName(kid)):
				filtered.append(kid)
		kingdoms = filtered
	for kingdom_id in kingdoms:
		var button := Button.new()
		button.text = "Begin run as %s" % String(kingdom_id).capitalize()
		button.pressed.connect(func() -> void:
			_on_kingdom_button_pressed(StringName(kingdom_id))
		)
		_kingdom_buttons.add_child(button)
	if kingdoms.is_empty():
		var label := Label.new()
		label.text = "No kingdoms available in this era."
		_kingdom_buttons.add_child(label)


func _on_kingdom_button_pressed(kingdom_id: StringName) -> void:
	if _prestige_system == null:
		return
	if not _prestige_system.has_method("get_niches_for_kingdom"):
		_prestige_system.start_run(kingdom_id)
		_close()
		return
	var niches: Array = _prestige_system.get_niches_for_kingdom(kingdom_id, true)
	if niches.is_empty():
		# Kingdoms with no niches (currently only symbiosis) start directly.
		_prestige_system.start_run(kingdom_id)
		_close()
		return
	if niches.size() == 1:
		_prestige_system.start_run(kingdom_id, niches[0].id)
		_close()
		return
	_show_niche_subview(kingdom_id, niches)


func _show_niche_subview(kingdom_id: StringName, niches: Array) -> void:
	_active_kingdom_id = kingdom_id
	for child in _kingdom_buttons.get_children():
		child.queue_free()

	var back := Button.new()
	back.text = "Back"
	back.pressed.connect(func() -> void:
		_refresh_kingdoms()
	)
	_kingdom_buttons.add_child(back)

	for niche in niches:
		if niche == null:
			continue
		var button := Button.new()
		button.text = "%s - %s" % [niche.display_name, niche.description]
		button.pressed.connect(func() -> void:
			if _prestige_system != null:
				_prestige_system.start_run(kingdom_id, niche.id)
			_close()
		)
		_kingdom_buttons.add_child(button)


func _show_tree() -> void:
	_summary_section.visible = false
	_tree_section.visible = true
	_kingdom_section.visible = true
	_refresh_tree()
	_refresh_kingdoms()


func _show_kingdom_only() -> void:
	_summary_section.visible = false
	_tree_section.visible = false
	_kingdom_section.visible = true
	_refresh_kingdoms()


func _close() -> void:
	TickClock.resume()
	if get_tree().current_scene == null:
		queue_free()
		return
	var current_path := get_tree().current_scene.scene_file_path
	if current_path != "res://scenes/world/world.tscn":
		get_tree().change_scene_to_file("res://scenes/world/world.tscn")
	queue_free()


func _get_prestige_system() -> Node:
	var node := get_tree().get_first_node_in_group("prestige_system")
	if node != null:
		return node
	if has_node("/root/PrestigeSystem"):
		return get_node("/root/PrestigeSystem")
	return null
