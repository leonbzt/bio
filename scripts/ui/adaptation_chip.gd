extends HBoxContainer

@onready var _value_label: Label = $Value
@onready var _rate_label: Label = $Rate


func _ready() -> void:
	add_theme_constant_override("separation", 3)
	_rate_label.add_theme_font_override("font", KingdomTheme.SMALL_FONT)
	_rate_label.add_theme_font_size_override("font_size", KingdomTheme.SMALL_FONT_SIZE)
	_rate_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	AdaptationSystem.adaptation_changed.connect(_on_changed)
	EventBus.tick.connect(_on_tick_refresh)
	_refresh()


func _on_changed(_v: float) -> void:
	_refresh()


func _on_tick_refresh(_delta: float) -> void:
	_refresh_rate()


func _refresh() -> void:
	_value_label.text = "%s" % FormatUtils.abbreviate(AdaptationSystem.get_amount())
	_refresh_rate()


func _refresh_rate() -> void:
	var per_min: float = AdaptationSystem.get_per_minute_rate()
	_rate_label.text = "+%.1f/min" % per_min
