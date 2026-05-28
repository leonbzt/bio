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


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_button.pressed.connect(_on_pause_pressed)
	EventBus.tick.connect(_on_tick)
	EventBus.run_started.connect(_on_run_started)
	EventBus.run_loaded.connect(_on_run_loaded)
	EventBus.cycle_closed.connect(_on_cycle_closed)
	_install_resource_tooltips()
	_refresh_ecosystem_name()
	_last_lifetime_biomass = GameState.get_hero_biomass()
	_on_tick(0.0)
	_maybe_show_onboarding()


func _install_resource_tooltips() -> void:
	# Tooltips for the HUD labels. Labels default to MOUSE_FILTER_STOP in
	# Godot 4 so tooltip_text is enough to wire them up.
	if _biomass_label != null:
		_biomass_label.mouse_filter = Control.MOUSE_FILTER_STOP
		_biomass_label.tooltip_text = "Hero biomass — your run's progress.\nGoal: 100,000. Drops when you place new species (placement cost). Cycle closure boosts production ×1.5."
	if _rate_label != null:
		_rate_label.mouse_filter = Control.MOUSE_FILTER_STOP
		_rate_label.tooltip_text = "Production per second.\nRises as the trophic web closes. Stalls when an input pool is empty."
	if _ecosystem_label != null:
		_ecosystem_label.mouse_filter = Control.MOUSE_FILTER_STOP
		_ecosystem_label.tooltip_text = "Coal Swamp — a Carboniferous wetland.\nYour starting ecosystem."


func _on_pause_pressed() -> void:
	if _pause_menu != null and _pause_menu.has_method("toggle"):
		_pause_menu.toggle()


func _on_run_started(_kingdom_id: StringName) -> void:
	_rate_history.clear()
	_last_lifetime_biomass = GameState.get_hero_biomass()
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
	_biomass_label.text = FormatUtils.abbreviate(current)
	_rate_label.text = "+%.1f/s" % per_sec if per_sec > 0.0 else "0.0/s"
	_tick_flash = not _tick_flash
	_tick_indicator.color = Color(0.9, 0.9, 0.9, 1.0) if _tick_flash else Color(0.45, 0.45, 0.45, 1.0)


func _on_cycle_closed() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_biomass_label, "modulate", Color(1.3, 1.15, 0.6), 0.3)
	tween.tween_interval(1.4)
	tween.tween_property(_biomass_label, "modulate", Color(1.0, 1.0, 1.0), 0.3)


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
