extends PanelContainer

@onready var _goal_text: Label = $VBox/GoalText
@onready var _progress_label: Label = $VBox/ProgressLabel
@onready var _progress_bar: ProgressBar = $VBox/ProgressBar

const MET_TINT: Color = Color(0.9, 0.85, 0.3, 1.0)
const NORMAL_TINT: Color = Color(0.3, 0.3, 0.35, 1.0)


func _ready() -> void:
	EventBus.goal_progress_changed.connect(_on_progress_changed)
	EventBus.goal_met.connect(_on_goal_met)
	EventBus.run_started.connect(_on_run_started)
	EventBus.run_loaded.connect(func(_v): _refresh_initial())
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
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1.2, 1.2, 1.0, 1.0), 0.2)
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.4)


func _on_run_started(_kingdom: StringName) -> void:
	_refresh_initial()


func _apply_tint(met: bool) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = MET_TINT if met else NORMAL_TINT
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_bottom_right = 4
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	add_theme_stylebox_override("panel", sb)
