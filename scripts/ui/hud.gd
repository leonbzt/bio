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
var _prev_per_sec: float = 0.0

var _grade_label: Label = null
var _goal_bar: ColorRect = null
var _goal_bar_fill: ColorRect = null


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_button.pressed.connect(_on_pause_pressed)
	EventBus.tick.connect(_on_tick)
	EventBus.run_started.connect(_on_run_started)
	EventBus.run_loaded.connect(_on_run_loaded)
	EventBus.cycle_closed.connect(_on_cycle_closed)
	EventBus.goal_met.connect(_on_goal_met)
	EventBus.offline_summary.connect(_on_offline_summary)
	_build_grade_label()
	_build_goal_bar()
	_install_resource_tooltips()
	_refresh_ecosystem_name()
	_last_lifetime_biomass = GameState.get_hero_biomass()
	_on_tick(0.0)
	_maybe_show_onboarding()


func _build_grade_label() -> void:
	_grade_label = Label.new()
	_grade_label.text = ""
	_grade_label.add_theme_font_size_override("font_size", 18)
	_grade_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	_grade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_grade_label.mouse_filter = Control.MOUSE_FILTER_STOP
	_grade_label.tooltip_text = "Ecosystem grade"
	var col: VBoxContainer = $TopBar/Margin/ColumnLayout
	col.add_child(_grade_label)
	col.move_child(_grade_label, _ecosystem_label.get_index() + 1)


func _build_goal_bar() -> void:
	_goal_bar = ColorRect.new()
	_goal_bar.color = Color(0.2, 0.2, 0.2, 0.6)
	_goal_bar.custom_minimum_size = Vector2(0, 4)
	_goal_bar_fill = ColorRect.new()
	_goal_bar_fill.color = Color(0.4, 0.85, 0.4, 0.9)
	_goal_bar_fill.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	_goal_bar_fill.anchor_right = 0.0
	_goal_bar.add_child(_goal_bar_fill)
	_goal_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	_goal_bar.tooltip_text = "Sustain +%.1f/s for %d ticks to complete" % [
		RunGoalSystem.THROUGHPUT_THRESHOLD, RunGoalSystem.SUSTAINED_TICKS_TARGET
	]
	var col: VBoxContainer = $TopBar/Margin/ColumnLayout
	col.add_child(_goal_bar)


func _install_resource_tooltips() -> void:
	if _biomass_label != null:
		_biomass_label.mouse_filter = Control.MOUSE_FILTER_STOP
		_biomass_label.tooltip_text = "Biomass wallet.\nSpend to place species."
	if _rate_label != null:
		_rate_label.mouse_filter = Control.MOUSE_FILTER_STOP
		_rate_label.tooltip_text = "Biomass throughput per second.\nSustain +%.1f/s to win." % RunGoalSystem.THROUGHPUT_THRESHOLD
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

	_rate_label.text = ("+%.1f/s" % per_sec) if per_sec > 0.0 else "0.0/s"
	_rate_label.add_theme_font_size_override("font_size", 22)
	var trend_color: Color = Color(0.55, 0.95, 0.55)
	if _prev_per_sec > 0.01:
		if per_sec > _prev_per_sec * 1.05:
			_rate_label.text += " ^"
			trend_color = Color(0.40, 1.0, 0.40)
		elif per_sec < _prev_per_sec * 0.95:
			_rate_label.text += " v"
			trend_color = Color(0.95, 0.40, 0.40)
	_prev_per_sec = per_sec
	_rate_label.add_theme_color_override("font_color", trend_color)

	_biomass_label.text = "Wallet: %s" % FormatUtils.abbreviate(current)
	_biomass_label.add_theme_font_size_override("font_size", 14)

	_update_goal_bar()
	_update_grade()

	_tick_flash = not _tick_flash
	_tick_indicator.color = Color(0.9, 0.9, 0.9, 1.0) if _tick_flash else Color(0.45, 0.45, 0.45, 1.0)


func _update_goal_bar() -> void:
	if _goal_bar_fill == null:
		return
	var progress: float = RunGoalSystem.get_progress()
	_goal_bar_fill.anchor_right = progress
	if progress >= 1.0:
		_goal_bar_fill.color = Color(0.9, 0.85, 0.3, 0.9)
	elif progress > 0.0:
		_goal_bar_fill.color = Color(0.4, 0.85, 0.4, 0.9)
	else:
		_goal_bar_fill.color = Color(0.4, 0.85, 0.4, 0.9)
	_goal_bar.tooltip_text = "Goal: sustain +%.1f/s — %d/%d ticks" % [
		RunGoalSystem.THROUGHPUT_THRESHOLD,
		RunGoalSystem.get_sustained_ticks(),
		RunGoalSystem.SUSTAINED_TICKS_TARGET
	]


func _update_grade() -> void:
	if _grade_label == null:
		return
	if not has_node("/root/EcosystemScoring"):
		_grade_label.text = ""
		return
	var scoring: Node = get_node("/root/EcosystemScoring")
	if not scoring.has_method("get_grade"):
		_grade_label.text = ""
		return
	var grade: String = scoring.get_grade()
	_grade_label.text = grade
	var breakdown: Dictionary = scoring.get_breakdown() if scoring.has_method("get_breakdown") else {}
	_grade_label.tooltip_text = "Grade: %s\nThroughput: %d%%  Diversity: %d%%  Sustain: %d%%" % [
		grade,
		int(float(breakdown.get("throughput", 0.0)) * 100),
		int(float(breakdown.get("diversity", 0.0)) * 100),
		int(float(breakdown.get("sustainability", 0.0)) * 100),
	]
	match grade:
		"S":
			_grade_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		"A":
			_grade_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		"B":
			_grade_label.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))
		"C":
			_grade_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		_:
			_grade_label.add_theme_color_override("font_color", Color(0.9, 0.35, 0.35))


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


func _on_offline_summary(biomass_gained: float) -> void:
	if biomass_gained <= 0.0:
		return
	var banner := Label.new()
	banner.text = "While you were away: +%s biomass" % FormatUtils.abbreviate(biomass_gained)
	banner.add_theme_font_size_override("font_size", 16)
	banner.add_theme_color_override("font_color", Color(0.85, 0.95, 0.70))
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	banner.offset_top = 110.0
	banner.offset_left = -160.0
	banner.offset_right = 160.0
	banner.modulate.a = 0.0
	add_child(banner)
	var tween := create_tween()
	tween.tween_property(banner, "modulate:a", 1.0, 0.3)
	tween.tween_interval(2.5)
	tween.tween_property(banner, "modulate:a", 0.0, 0.5)
	tween.tween_callback(banner.queue_free)


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
