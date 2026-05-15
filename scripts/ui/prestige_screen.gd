extends Control

@export var skip_to_kingdom_select: bool = false

@onready var _summary_section: VBoxContainer = $Content/SummarySection
@onready var _tree_section: VBoxContainer = $Content/TreeSection
@onready var _kingdom_section: VBoxContainer = $Content/KingdomSection
@onready var _reward_label: Label = $Content/SummarySection/RewardLabel
@onready var _biomass_label: Label = $Content/SummarySection/BiomassLabel
@onready var _confirm_button: Button = $Content/SummarySection/ConfirmPrestigeButton
@onready var _balance_label: Label = $Content/TreeSection/BalanceLabel
@onready var _tree_grid: GridContainer = $Content/TreeSection/TreeGrid
@onready var _kingdom_buttons: VBoxContainer = $Content/KingdomSection/KingdomButtons

var _prestige_system: Node = null


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
	for child in _tree_grid.get_children():
		child.queue_free()
	for node in _prestige_system.get_all_nodes():
		var button := Button.new()
		button.text = "%s (%d EP)" % [node.display_name, int(node.meta_cost.get("evolution_points", 0))]
		button.disabled = true
		var prereqs_ok: bool = _prereqs_met(node)
		var owned: bool = _prestige_system.is_node_unlocked(node.id)
		var balance: int = _prestige_system.get_evolution_points_balance()
		var cost: int = int(node.meta_cost.get("evolution_points", 0))
		if owned:
			button.text = "%s (Owned)" % node.display_name
			button.disabled = true
		elif prereqs_ok and balance >= cost:
			button.disabled = false
			button.pressed.connect(func() -> void:
				if _prestige_system.purchase_node(node.id):
					_refresh_tree()
					_refresh_kingdoms()
			)
		elif prereqs_ok:
			button.text = "%s (%d EP)" % [node.display_name, cost]
			button.disabled = true
		else:
			button.text = "%s (Locked)" % node.display_name
			button.disabled = true
		_tree_grid.add_child(button)


func _refresh_kingdoms() -> void:
	for child in _kingdom_buttons.get_children():
		child.queue_free()
	var kingdoms: Array = GameState.meta_save.get("unlocked_kingdoms", [])
	for kingdom_id in kingdoms:
		var button := Button.new()
		button.text = "Begin run as %s" % String(kingdom_id).capitalize()
		button.pressed.connect(func() -> void:
			if _prestige_system != null:
				_prestige_system.start_run(StringName(kingdom_id))
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


func _prereqs_met(node: EvolutionNodeData) -> bool:
	if _prestige_system == null:
		return false
	for prereq in node.prerequisites:
		if not _prestige_system.is_node_unlocked(prereq):
			return false
	return true


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
