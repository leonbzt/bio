extends Control

@onready var _summary_section: VBoxContainer = $Content/SummarySection
@onready var _tree_section: VBoxContainer = $Content/TreeSection
@onready var _reward_label: Label = $Content/SummarySection/RewardLabel
@onready var _biomass_label: Label = $Content/SummarySection/BiomassLabel
@onready var _diversity_label: Label = $Content/SummarySection/DiversityLabel
@onready var _starter_label: Label = $Content/SummarySection/StarterLabel
@onready var _confirm_button: Button = $Content/SummarySection/ConfirmPrestigeButton
@onready var _balance_label: Label = $Content/TreeSection/BalanceLabel
@onready var _wing_tabs: HBoxContainer = $Content/TreeSection/WingTabs
@onready var _tree_scroll: ScrollContainer = $Content/TreeSection/TreeScroll
@onready var _tree_canvas: Control = $Content/TreeSection/TreeScroll/TreeCanvas
@onready var _close_button: Button = $Content/TreeSection/CloseButton

var _prestige_system: Node = null
var _last_summary: Dictionary = {}
var _prestige_committed: bool = false


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
	var extinction_bonus: int = _pending_extinction_bonus()
	var reward: int = PrestigeSystem.calculate_prestige_reward(earned, diversity) + extinction_bonus
	if _prestige_system.has_method("trigger_prestige"):
		_prestige_system.trigger_prestige()
	_last_summary = {
		"evolution_points_earned": reward,
		"extinction_bonus": extinction_bonus,
		"total_biomass_earned": earned,
		"species_cultivated": diversity,
		"starting_species_id": starter
	}
	_prestige_committed = true
	_refresh_tree()
	_show_tree()


func _refresh_summary() -> void:
	if _prestige_system == null:
		return
	var base_reward: int = _prestige_system.get_pending_reward()
	var extinction_bonus: int = _pending_extinction_bonus()
	var reward: int = base_reward + extinction_bonus
	var earned: float = float(GameState.run_save.get("statistics", {}).get("total_biomass_earned", 0.0))
	var diversity: int = int((GameState.run_save.get("unlocked_species_in_run", []) as Array).size())
	var starter: String = String(GameState.run_save.get("starting_species_id", "")).replace("_", " ").capitalize()
	var diversity_mult: float = 1.0
	if diversity >= 3:
		diversity_mult = 1.2
	elif diversity == 2:
		diversity_mult = 1.1
	_reward_label.text = "You earned %d EP." % reward
	if extinction_bonus > 0:
		_reward_label.text += "\n+25 EP Extinction Survivor bonus (you cultivated the first generation after the great dying)"
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
		_build_wing_tabs()
	else:
		_tree_canvas.refresh()


func _build_wing_tabs() -> void:
	for child in _wing_tabs.get_children():
		child.queue_free()
	if not _tree_canvas.has_method("get_wings"):
		return
	for wing in _tree_canvas.get_wings():
		var btn := Button.new()
		btn.text = String(wing).capitalize()
		btn.custom_minimum_size = Vector2(50, 24)
		btn.add_theme_font_size_override("font_size", 10)
		var sb := StyleBoxFlat.new()
		sb.bg_color = _tree_canvas.get_wing_color(wing).darkened(0.3)
		sb.border_color = _tree_canvas.get_wing_color(wing)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(2)
		sb.content_margin_left = 4
		sb.content_margin_right = 4
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.add_theme_stylebox_override("pressed", sb)
		btn.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
		var captured_wing: StringName = wing
		btn.pressed.connect(func() -> void:
			var x: int = _tree_canvas.get_wing_x(captured_wing)
			_tree_scroll.scroll_horizontal = x
		)
		_wing_tabs.add_child(btn)


func _on_node_purchase_requested(node_id: StringName) -> void:
	if _prestige_system.purchase_node(node_id):
		_refresh_tree()


func _show_tree() -> void:
	_summary_section.visible = false
	_tree_section.visible = true
	_refresh_tree()


func _close() -> void:
	TickClock.resume()
	if _prestige_committed:
		# In-game prestige just wiped the run; the player needs to choose
		# their next ecosystem + starter before there's anything to return to.
		# Hop through the main menu, which auto-opens the world map on _ready.
		GameState.auto_open_world_map = true
		get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")
		return
	queue_free()


func _get_prestige_system() -> Node:
	var node := get_tree().get_first_node_in_group("prestige_system")
	if node != null:
		return node
	if has_node("/root/PrestigeSystem"):
		return get_node("/root/PrestigeSystem")
	return null


func _pending_extinction_bonus() -> int:
	var pe: Dictionary = GameState.meta_save.get("post_extinction", {}) as Dictionary
	if pe.is_empty():
		return 0
	var to_era: String = String(pe.get("to_era_id", ""))
	var current_era: String = String(GameState.meta_save.get("current_era_id", ""))
	if to_era != current_era:
		return 0
	var completed: Array = GameState.meta_save.get("first_run_in_era_completed", []) as Array
	if completed.has(to_era):
		return 0
	return 25
