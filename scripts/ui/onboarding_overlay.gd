extends Control
##
## First-run onboarding — full-screen overlay with one tip at a time.
## Tap anywhere to advance. State persisted in meta.onboarding_step
## (-1 = done, 0..STEPS.size()-1 = current).
##

const STEPS: Array[String] = [
	"Tap any tile to colonize it. Start near the center of the map.",
	"Resources accumulate on the left ← watch biomass tick up over time.",
	"Pick a species from the buttons at the bottom to choose what to place.",
	"Tap [Recipes] (top-right) to see structure patterns you can form.",
	"When ready, tap [Menu] → Prestige to earn EP and start a new generation."
]

@onready var _backdrop: ColorRect = $Backdrop
@onready var _bubble: PanelContainer = $Bubble
@onready var _body: Label = $Bubble/Margin/VBox/Body
@onready var _step_label: Label = $Bubble/Margin/VBox/StepLabel
@onready var _next_btn: Button = $Bubble/Margin/VBox/Actions/NextButton
@onready var _skip_btn: Button = $Bubble/Margin/VBox/Actions/SkipButton

var _current: int = 0


static func should_show() -> bool:
	# Don't bother veterans — only show on first-ever play.
	var stats: Dictionary = GameState.meta_save.get("statistics", {}) as Dictionary
	if int(stats.get("prestige_count", 0)) > 0:
		return false
	return int(GameState.meta_save.get("onboarding_step", 0)) >= 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_current = int(GameState.meta_save.get("onboarding_step", 0))
	if _current < 0:
		queue_free()
		return
	_next_btn.pressed.connect(_advance)
	_skip_btn.pressed.connect(_skip)
	_backdrop.gui_input.connect(_on_backdrop_input)
	_refresh()


func _on_backdrop_input(event: InputEvent) -> void:
	# Tap anywhere on the backdrop also advances.
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_advance()
	elif event is InputEventScreenTouch:
		if (event as InputEventScreenTouch).pressed:
			_advance()


func _advance() -> void:
	_current += 1
	if _current >= STEPS.size():
		_finish()
		return
	GameState.meta_save["onboarding_step"] = _current
	SaveSystem.save_now()
	_refresh()


func _skip() -> void:
	_finish()


func _finish() -> void:
	GameState.meta_save["onboarding_step"] = -1
	SaveSystem.save_now()
	queue_free()


func _refresh() -> void:
	_body.text = STEPS[_current]
	_step_label.text = "%d / %d" % [_current + 1, STEPS.size()]
	_next_btn.text = "Next" if _current < STEPS.size() - 1 else "Got it!"
