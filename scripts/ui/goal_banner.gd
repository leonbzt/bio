extends PanelContainer
##
## Per-run goal banner — restyled as a "coal gauge" for Coal Swamp.
## Procedural styling only (no art assets yet): dark earthen panel, taller
## bar with coal-vein fill colors. The visual swaps to a warm "met" tint
## when the gauge fills.
##

@onready var _goal_text: Label = $VBox/GoalText
@onready var _progress_label: Label = $VBox/ProgressLabel
@onready var _progress_bar: ProgressBar = $VBox/ProgressBar

# Panel tints — dark earthen sediment, brighter when goal is met.
const PANEL_BG_NORMAL: Color = Color(0.16, 0.13, 0.10, 1.0)        # damp peat
const PANEL_BG_MET: Color = Color(0.30, 0.20, 0.08, 1.0)            # amber-burnt
const PANEL_BORDER_NORMAL: Color = Color(0.32, 0.27, 0.20, 1.0)
const PANEL_BORDER_MET: Color = Color(0.95, 0.75, 0.30, 1.0)

# Bar colors — empty seam vs. accumulated coal.
const BAR_BG: Color = Color(0.10, 0.08, 0.07, 1.0)                  # carved-out earth
const BAR_BG_BORDER: Color = Color(0.22, 0.18, 0.14, 1.0)
const BAR_FILL: Color = Color(0.07, 0.07, 0.09, 1.0)                # coal black with cold undertone
const BAR_FILL_HIGHLIGHT: Color = Color(0.20, 0.18, 0.22, 1.0)
const BAR_FILL_MET: Color = Color(0.90, 0.55, 0.18, 1.0)            # ember orange


func _ready() -> void:
	EventBus.goal_progress_changed.connect(_on_progress_changed)
	EventBus.goal_met.connect(_on_goal_met)
	EventBus.run_started.connect(_on_run_started)
	EventBus.run_loaded.connect(func(_v): _refresh_initial())
	_style_progress_bar(false)
	_refresh_initial()


func _refresh_initial() -> void:
	var goal: PerRunGoalData = RunGoalSystem.get_active_goal()
	if goal == null:
		visible = false
		return
	visible = true
	_goal_text.text = goal.display_text
	var value: float = RunGoalSystem.get_progress()
	_progress_label.text = "%d / %d" % [int(value), int(goal.target)]
	_progress_bar.max_value = goal.target
	_progress_bar.value = value
	_apply_tint(RunGoalSystem.is_met())


func _on_progress_changed(progress: Dictionary) -> void:
	var value: float = float(progress.get("value", 0.0))
	var target: float = float(progress.get("target", 0.0))
	_progress_label.text = "%d / %d" % [int(value), int(target)]
	_progress_bar.max_value = target
	_progress_bar.value = value


func _on_goal_met() -> void:
	_apply_tint(true)
	_style_progress_bar(true)
	# Brief warm flash + a slow ember pulse so the player feels the win.
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1.35, 1.20, 0.95, 1.0), 0.25)
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.45)


func _on_run_started(_kingdom: StringName) -> void:
	_style_progress_bar(false)
	_refresh_initial()


func _apply_tint(met: bool) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = PANEL_BG_MET if met else PANEL_BG_NORMAL
	sb.border_color = PANEL_BORDER_MET if met else PANEL_BORDER_NORMAL
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_bottom_right = 4
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	add_theme_stylebox_override("panel", sb)


func _style_progress_bar(met: bool) -> void:
	# Taller bar (14 px vs default 4) so the fill reads as substance, not a hairline.
	_progress_bar.custom_minimum_size = Vector2(0, 14)
	# Background — carved-out seam.
	var bg := StyleBoxFlat.new()
	bg.bg_color = BAR_BG
	bg.border_color = BAR_BG_BORDER
	bg.border_width_left = 1
	bg.border_width_right = 1
	bg.border_width_top = 1
	bg.border_width_bottom = 1
	bg.corner_radius_top_left = 2
	bg.corner_radius_top_right = 2
	bg.corner_radius_bottom_left = 2
	bg.corner_radius_bottom_right = 2
	_progress_bar.add_theme_stylebox_override("background", bg)
	# Fill — coal seam, or ember orange when met.
	var fill := StyleBoxFlat.new()
	fill.bg_color = BAR_FILL_MET if met else BAR_FILL
	fill.border_color = BAR_FILL_HIGHLIGHT
	fill.border_width_top = 1
	fill.border_width_bottom = 1
	fill.corner_radius_top_left = 2
	fill.corner_radius_top_right = 2
	fill.corner_radius_bottom_left = 2
	fill.corner_radius_bottom_right = 2
	_progress_bar.add_theme_stylebox_override("fill", fill)
