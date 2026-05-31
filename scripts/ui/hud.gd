extends Control

const RATE_WINDOW_TICKS: int = 10

@onready var _ecosystem_label: Label = $TopBar/Margin/ColumnLayout/EcosystemNameLabel
@onready var _biomass_label: Label = $TopBar/Margin/ColumnLayout/BiomassCounter
@onready var _rate_label: Label = $TopBar/Margin/ColumnLayout/RateLabel
@onready var _pause_button: Button = $PauseButton
@onready var _tick_indicator: ColorRect = $TickIndicator
@onready var _pause_menu: Control = get_node("../PauseMenu")

var _rate_history: Array[float] = []
var _last_lifetime_biomass: float = 0.0
var _tick_flash: bool = false
var _goal_screen_opened: bool = false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_button.pressed.connect(_on_pause_pressed)
	EventBus.tick.connect(_on_tick)
	EventBus.run_started.connect(_on_run_started)
	EventBus.run_loaded.connect(_on_run_loaded)
	EventBus.cycle_closed.connect(_on_cycle_closed)
	EventBus.goal_met.connect(_on_goal_met)
	_install_resource_tooltips()
	_refresh_ecosystem_name()
	_last_lifetime_biomass = GameState.get_hero_biomass()
	_on_tick(0.0)
	_maybe_show_onboarding()


func _install_resource_tooltips() -> void:
	# Short tooltips — long single-line text gets cut off by Godot's default
	# tooltip width. Each line is wrapped manually so the popup stays
	# readable.
	if _biomass_label != null:
		_biomass_label.mouse_filter = Control.MOUSE_FILTER_STOP
		_biomass_label.tooltip_text = "Hero biomass.\nGoal: 15,000.\nHarvest tiles or let animals auto-collect."
	if _rate_label != null:
		_rate_label.mouse_filter = Control.MOUSE_FILTER_STOP
		_rate_label.tooltip_text = "Biomass gained per second.\nHarvest or place animals to increase."
	if _ecosystem_label != null:
		_ecosystem_label.mouse_filter = Control.MOUSE_FILTER_STOP
		_ecosystem_label.tooltip_text = "Coal Swamp\nCarboniferous wetland."


func _on_pause_pressed() -> void:
	if _pause_menu != null and _pause_menu.has_method("toggle"):
		_pause_menu.toggle()


func _on_run_started(_kingdom_id: StringName) -> void:
	_rate_history.clear()
	_last_lifetime_biomass = GameState.get_hero_biomass()
	_goal_screen_opened = false
	_refresh_ecosystem_name()
	_maybe_show_onboarding()


func _on_run_loaded(_save_version: int) -> void:
	_refresh_ecosystem_name()
	_last_lifetime_biomass = GameState.get_hero_biomass()
	_on_tick(0.0)
	_maybe_show_onboarding()


func _on_tick(_delta: float) -> void:
	var current: float = GameState.get_hero_biomass()
	var delta_biomass: float = current - _last_lifetime_biomass
	_last_lifetime_biomass = current
	_rate_history.push_back(delta_biomass)
	if _rate_history.size() > RATE_WINDOW_TICKS:
		_rate_history.pop_front()
	var per_tick_avg: float = 0.0
	for d in _rate_history:
		per_tick_avg += d
	per_tick_avg /= float(maxi(1, _rate_history.size()))
	var per_sec: float = per_tick_avg * TickClock.tick_hz
	_biomass_label.text = "Biomass: %s" % FormatUtils.abbreviate(current)
	_rate_label.text = "+%.1f/s" % per_sec if per_sec > 0.0 else "0.0/s"
	_tick_flash = not _tick_flash
	_tick_indicator.color = Color(0.9, 0.9, 0.9, 1.0) if _tick_flash else Color(0.45, 0.45, 0.45, 1.0)


func _on_cycle_closed() -> void:
	var top_bar: Control = $TopBar
	var tween: Tween = create_tween()
	tween.tween_property(top_bar, "modulate", Color(1.5, 1.3, 0.4), 0.15)
	tween.tween_property(top_bar, "modulate", Color(1.0, 1.0, 0.85), 0.15)
	tween.tween_property(top_bar, "modulate", Color(1.5, 1.3, 0.4), 0.15)
	tween.tween_interval(1.2)
	tween.tween_property(top_bar, "modulate", Color(1.0, 1.0, 1.0), 0.4)


func _on_goal_met() -> void:
	if _goal_screen_opened:
		return
	_goal_screen_opened = true
	TickClock.pause()
	var tween: Tween = create_tween()
	tween.tween_interval(2.0)
	tween.tween_callback(_open_prestige_screen)


func _open_prestige_screen() -> void:
	const PRESTIGE_SCENE_PATH: String = "res://scenes/ui/prestige_screen.tscn"
	var packed: PackedScene = load(PRESTIGE_SCENE_PATH) as PackedScene
	if packed == null:
		return
	var screen: Control = packed.instantiate() as Control
	var prestige_system: Node = get_tree().get_first_node_in_group("prestige_system")
	if prestige_system == null:
		prestige_system = get_node_or_null("/root/PrestigeSystem")
	if screen.has_method("setup") and prestige_system != null:
		screen.setup(prestige_system)
	get_parent().add_child(screen)


func _refresh_ecosystem_name() -> void:
	var eco_name: String = "Coal Swamp"
	if has_node("/root/EraSystem"):
		var era_system: Node = get_node("/root/EraSystem")
		if era_system.has_method("get_current_ecosystem"):
			var eco: EcosystemData = era_system.get_current_ecosystem()
			if eco != null:
				eco_name = eco.display_name
	_ecosystem_label.text = eco_name


func _maybe_show_onboarding() -> void:
	const ONBOARDING_SCENE_PATH: String = "res://scenes/ui/onboarding_overlay.tscn"
	var script: GDScript = load("res://scripts/ui/onboarding_overlay.gd") as GDScript
	if script == null or not script.should_show() or has_node("OnboardingOverlay"):
		return
	var packed: PackedScene = load(ONBOARDING_SCENE_PATH) as PackedScene
	if packed == null:
		return
	var instance: Node = packed.instantiate()
	instance.name = "OnboardingOverlay"
	add_child(instance)
