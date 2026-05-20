extends PanelContainer

@onready var _label: Label = $Margin/Label
var _pending_text: String = ""


func _ready() -> void:
	if _pending_text != "":
		_label.text = _pending_text
		_pending_text = ""


func set_text(text: String) -> void:
	if _label == null:
		_pending_text = text
		return
	_label.text = text


func play(duration: float = 2.5) -> void:
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.15)
	tween.tween_interval(duration)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)
