class_name TooltipButton
extends Button
##
## Button subclass that returns a wrapping tooltip instead of Godot's default
## single-line label. Used by the evolution tree (and any other long-tooltip
## surfaces) so node descriptions don't fall off-screen.
##

const TOOLTIP_MAX_WIDTH: int = 280


func _make_custom_tooltip(for_text: String) -> Object:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.10, 0.12, 0.96)
	sb.border_color = Color(0.45, 0.45, 0.50, 1.0)
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", sb)
	var label := Label.new()
	label.text = for_text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(TOOLTIP_MAX_WIDTH, 0)
	label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.92))
	panel.add_child(label)
	return panel
