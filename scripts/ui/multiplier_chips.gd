extends HBoxContainer
##
## Phase 15a: Compact row of per-resource multiplier chips. Updates live as sources change.
##

const TRACKED_RESOURCES: Array[StringName] = [
	&"biomass", &"spores", &"decay", &"nutrients"
]
var _chips_by_resource: Dictionary[StringName, Control] = {}


func _ready() -> void:
	add_theme_constant_override("separation", 6)
	EventBus.resource_multiplier_changed.connect(_on_multiplier_changed)
	for resource_id in TRACKED_RESOURCES:
		var chip := _build_chip(resource_id)
		_chips_by_resource[resource_id] = chip
		add_child(chip)
	_refresh_all()


func _on_multiplier_changed(resource_id: StringName, _value: float) -> void:
	if _chips_by_resource.has(resource_id):
		_update_chip(resource_id)


func _refresh_all() -> void:
	for resource_id in TRACKED_RESOURCES:
		_update_chip(resource_id)


func _update_chip(resource_id: StringName) -> void:
	var chip: Control = _chips_by_resource[resource_id]
	var value: float = ResourceLedger.get_multiplier(resource_id)
	var label: Label = chip.get_node("Value") as Label
	label.text = "×%.1f" % value
	# Dim if neutral, accentuate if >1.
	label.modulate = Color(1.0, 1.0, 1.0) if value > 1.0 else Color(0.6, 0.6, 0.6)
	chip.tooltip_text = _build_tooltip(resource_id)


func _build_chip(resource_id: StringName) -> Control:
	var chip := HBoxContainer.new()
	chip.add_theme_constant_override("separation", 3)
	chip.mouse_filter = Control.MOUSE_FILTER_STOP
	var swatch := ColorRect.new()
	swatch.custom_minimum_size = Vector2(8, 8)
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	swatch.color = KingdomTheme.resource_color(resource_id)
	chip.add_child(swatch)
	var value := Label.new()
	value.name = "Value"
	value.text = "×1.0"
	value.add_theme_font_override("font", KingdomTheme.SMALL_FONT)
	value.add_theme_font_size_override("font_size", KingdomTheme.SMALL_FONT_SIZE)
	chip.add_child(value)
	return chip


func _build_tooltip(resource_id: StringName) -> String:
	var breakdown: Array = ResourceLedger.get_multiplier_breakdown(resource_id)
	if breakdown.is_empty():
		return "%s — no active multipliers" % String(resource_id).capitalize()
	var lines: Array[String] = ["%s multipliers:" % String(resource_id).capitalize()]
	for entry in breakdown:
		lines.append("  %s: ×%.2f" % [entry["source"], entry["value"]])
	return "\n".join(lines)
