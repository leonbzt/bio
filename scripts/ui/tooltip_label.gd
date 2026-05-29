class_name TooltipLabel
extends Label
##
## Label subclass that returns a wrapping panel as its tooltip. Godot's
## default tooltip is a single un-wrapped line, which clips on the right
## side when text exceeds the screen width. Attach this script to any
## Label whose `tooltip_text` is more than ~40 chars.
##

const TOOLTIP_MAX_WIDTH: int = 320


func _make_custom_tooltip(for_text: String) -> Object:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.10, 0.12, 0.96)
	sb.border_color = Color(0.45, 0.45, 0.50, 1.0)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 7
	sb.content_margin_bottom = 7
	panel.add_theme_stylebox_override("panel", sb)
	var label := Label.new()
	label.text = for_text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(TOOLTIP_MAX_WIDTH, 0)
	label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.92))
	label.add_theme_font_size_override("font_size", 12)
	panel.add_child(label)
	return panel
