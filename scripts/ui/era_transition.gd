extends Control
##
## Era transition narrative passage. Full-screen black backdrop with the
## destination era's transition_narrative fading in slowly. 2-second guard
## window before taps can dismiss.
##

const FADE_IN_TIME: float = 1.5
const GUARD_WINDOW: float = 2.0
const HINT_FADE_IN_TIME: float = 0.8
const FADE_OUT_TIME: float = 0.4

@onready var _backdrop: ColorRect = $Backdrop
@onready var _narrative_label: Label = $NarrativeContainer/NarrativeLabel
@onready var _hint_label: Label = $HintLabel

var _can_dismiss: bool = false
var _narrative_text: String = ""


func setup(narrative: String) -> void:
	_narrative_text = narrative


func _ready() -> void:
	z_index = 100
	_narrative_label.text = _narrative_text
	_narrative_label.modulate.a = 0.0
	_hint_label.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_narrative_label, "modulate:a", 1.0, FADE_IN_TIME)
	tween.tween_interval(GUARD_WINDOW)
	tween.tween_callback(_enable_dismiss)
	tween.parallel().tween_property(_hint_label, "modulate:a", 0.8, HINT_FADE_IN_TIME)
	gui_input.connect(_on_input)
	TickClock.pause()


func _enable_dismiss() -> void:
	_can_dismiss = true


func _on_input(event: InputEvent) -> void:
	if not _can_dismiss:
		return
	var pressed: bool = false
	if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		pressed = true
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		pressed = true
	if pressed:
		_dismiss()


func _dismiss() -> void:
	TickClock.resume()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, FADE_OUT_TIME)
	tween.tween_callback(func() -> void: queue_free())
