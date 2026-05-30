extends Control

@onready var _summary_section: VBoxContainer = $Content/SummarySection
@onready var _tree_section: VBoxContainer = $Content/TreeSection
@onready var _reward_label: Label = $Content/SummarySection/RewardLabel
@onready var _biomass_label: Label = $Content/SummarySection/BiomassLabel
@onready var _diversity_label: Label = $Content/SummarySection/DiversityLabel
@onready var _starter_label: Label = $Content/SummarySection/StarterLabel
@onready var _confirm_button: Button = $Content/SummarySection/ConfirmPrestigeButton
@onready var _tree_canvas: Control = $Content/TreeSection/TreeScroll/TreeCanvas

var _prestige_system: Node = null


func _ready() -> void:
	if _prestige_system == null:
		_prestige_system = _get_prestige_system()
	_confirm_button.text = "Begin next run"
	_confirm_button.pressed.connect(_on_begin_next_run_pressed)
	_tree_section.visible = true
	_refresh_summary()
	_refresh_history()


func setup(prestige_system: Node) -> void:
	_prestige_system = prestige_system


func _on_begin_next_run_pressed() -> void:
	if _prestige_system == null:
		return
	if _prestige_system.has_method("trigger_prestige"):
		_prestige_system.trigger_prestige()
	GameState.auto_start_run = true
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")


func _refresh_summary() -> void:
	var biomass: float = float(GameState.run_save.get("hero_biomass_lifetime_produced", 0.0))
	var reproductions: int = int(biomass / 100.0)
	var cycle_closed: bool = bool(GameState.run_save.get("cycle_closed", false))
	var reward: int = PrestigeSystem.calculate_prestige_reward(biomass, cycle_closed, 1.0)
	var prestige_count: int = int(GameState.meta_save.get("statistics", {}).get("prestige_count", 0))
	_reward_label.text = "Run #%d complete. Evolution earned: +%d." % [prestige_count + 1, reward]
	_biomass_label.text = "Biomass produced: %s" % FormatUtils.abbreviate(biomass)
	_diversity_label.text = "Reproductions: %d" % reproductions
	_starter_label.text = "Cycle closed: %s" % ("yes" if cycle_closed else "no")


func _refresh_history() -> void:
	if _tree_canvas.has_method("setup"):
		_tree_canvas.setup(_prestige_system)
	elif _tree_canvas.has_method("refresh"):
		_tree_canvas.refresh()


func _get_prestige_system() -> Node:
	var node := get_tree().get_first_node_in_group("prestige_system")
	if node != null:
		return node
	if has_node("/root/PrestigeSystem"):
		return get_node("/root/PrestigeSystem")
	return null
