extends Control

@onready var _summary_section: VBoxContainer = $Content/SummarySection
@onready var _tree_section: VBoxContainer = $Content/TreeSection
@onready var _reward_label: Label = $Content/SummarySection/RewardLabel
@onready var _biomass_label: Label = $Content/SummarySection/BiomassLabel
@onready var _diversity_label: Label = $Content/SummarySection/DiversityLabel
@onready var _starter_label: Label = $Content/SummarySection/StarterLabel
@onready var _confirm_button: Button = $Content/SummarySection/ConfirmPrestigeButton
@onready var _balance_label: Label = $Content/TreeSection/BalanceLabel
@onready var _tree_canvas: Control = $Content/TreeSection/TreeScroll/TreeCanvas
@onready var _close_button: Button = $Content/TreeSection/CloseButton

var _prestige_system: Node = null
var _last_summary: Dictionary = {}


func _ready() -> void:
	_confirm_button.pressed.connect(_on_confirm_prestige)
	_close_button.pressed.connect(_close)
	if _prestige_system == null:
		_prestige_system = _get_prestige_system()
	_refresh_summary()


func setup(prestige_system: Node) -> void:
	_prestige_system = prestige_system


func _on_confirm_prestige() -> void:
	if _prestige_system == null:
		return
	var earned: float = float(GameState.run_save.get("statistics", {}).get("total_biomass_earned", 0.0))
	var diversity: int = int((GameState.run_save.get("unlocked_species_in_run", []) as Array).size())
	var starter: String = String(GameState.run_save.get("starting_species_id", ""))
	var reward: int = PrestigeSystem.calculate_prestige_reward(earned, diversity)
	if _prestige_system.has_method("trigger_prestige"):
		_prestige_system.trigger_prestige()
	_last_summary = {
		"evolution_points_earned": reward,
		"total_biomass_earned": earned,
		"species_cultivated": diversity,
		"starting_species_id": starter
	}
	_refresh_tree()
	_show_tree()


func _refresh_summary() -> void:
	if _prestige_system == null:
		return
	var reward: int = _prestige_system.get_pending_reward()
	var earned: float = float(GameState.run_save.get("statistics", {}).get("total_biomass_earned", 0.0))
	var diversity: int = int((GameState.run_save.get("unlocked_species_in_run", []) as Array).size())
	var starter: String = String(GameState.run_save.get("starting_species_id", "")).replace("_", " ").capitalize()
	var diversity_mult: float = 1.0
	if diversity >= 3:
		diversity_mult = 1.2
	elif diversity == 2:
		diversity_mult = 1.1
	_reward_label.text = "You earned %d EP." % reward
	_biomass_label.text = "Total biomass: %s" % FormatUtils.abbreviate(earned)
	_diversity_label.text = "Species cultivated: %d (×%.1f diversity bonus)" % [diversity, diversity_mult]
	_starter_label.text = "Beginning: %s" % starter


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


func _show_tree() -> void:
	_summary_section.visible = false
	_tree_section.visible = true
	_refresh_tree()


func _close() -> void:
	TickClock.resume()
	queue_free()


func _get_prestige_system() -> Node:
	var node := get_tree().get_first_node_in_group("prestige_system")
	if node != null:
		return node
	if has_node("/root/PrestigeSystem"):
		return get_node("/root/PrestigeSystem")
	return null
