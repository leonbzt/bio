extends Control
##
## Custom canvas that lays out evolution nodes by (wing, tier) and draws prereq lines.
##

const COL_WIDTH: int = 140
const ROW_HEIGHT: int = 120
const COL_GUTTER: int = 16
const NODE_WIDTH: int = 124
const NODE_HEIGHT: int = 92
const STACK_GAP: int = 8
const WINGS: Array[StringName] = [&"plantae", &"fungi", &"defense", &"hybrid", &"animals", &"meta"]
const WING_COLORS: Dictionary = {
	&"plantae": Color(0.35, 0.78, 0.42),
	&"fungi": Color(0.62, 0.42, 0.85),
	&"defense": Color(0.45, 0.62, 0.92),
	&"hybrid": Color(0.40, 0.78, 0.78),
	&"animals": Color(0.88, 0.68, 0.32),
	&"meta": Color(0.72, 0.72, 0.82)
}

var _prestige_system: Node
var _node_buttons: Dictionary[StringName, Button] = {}
var _node_positions: Dictionary[StringName, Vector2] = {}
var _node_by_id: Dictionary[StringName, EvolutionNodeData] = {}

signal node_purchase_requested(node_id: StringName)


# Returns the horizontal scroll offset (in canvas pixels) where a given wing's
# column starts. Used by the prestige screen's wing tabs to scroll to it.
func get_wing_x(wing: StringName) -> int:
	var idx: int = WINGS.find(wing)
	if idx < 0:
		return 0
	return COL_GUTTER + idx * (COL_WIDTH + COL_GUTTER)


func get_wing_color(wing: StringName) -> Color:
	return WING_COLORS.get(wing, Color(0.5, 0.5, 0.5))


func get_wings() -> Array[StringName]:
	return WINGS


func setup(prestige_system: Node) -> void:
	_prestige_system = prestige_system
	_rebuild()


func refresh() -> void:
	for id in _node_buttons:
		_restyle_button(_node_buttons[id], _node_by_id[id])
	queue_redraw()


func _rebuild() -> void:
	for child in get_children():
		child.queue_free()
	_node_buttons.clear()
	_node_positions.clear()
	_node_by_id.clear()
	if _prestige_system == null:
		return

	var by_cell: Dictionary[String, Array] = {}
	var max_tier: int = 1
	for node in _prestige_system.get_all_nodes():
		_node_by_id[node.id] = node
		var key := "%s:%d" % [String(node.wing), node.tier]
		if not by_cell.has(key):
			by_cell[key] = []
		by_cell[key].append(node)
		max_tier = maxi(max_tier, node.tier)

	# Compute max stack count for each tier across all wings, then derive each
	# tier's base Y so stacked nodes in shallower wings don't bleed into the
	# next tier's row. Earlier layout used a fixed ROW_HEIGHT which broke when
	# any tier had >1 node stacked in any wing.
	var tier_base_y: Dictionary[int, int] = {}
	var running_y: int = COL_GUTTER
	for tier in range(1, max_tier + 1):
		tier_base_y[tier] = running_y
		var max_stack: int = 1
		for wing in WINGS:
			var key := "%s:%d" % [String(wing), tier]
			var count: int = (by_cell.get(key, []) as Array).size()
			max_stack = maxi(max_stack, count)
		running_y += max_stack * (NODE_HEIGHT + STACK_GAP)

	var max_y := running_y
	for col_index in WINGS.size():
		var wing := WINGS[col_index]
		for tier in range(1, max_tier + 1):
			var key := "%s:%d" % [String(wing), tier]
			var nodes_in_cell: Array = by_cell.get(key, [])
			for stack_index in nodes_in_cell.size():
				var node: EvolutionNodeData = nodes_in_cell[stack_index]
				var pos := Vector2(
					COL_GUTTER + col_index * (COL_WIDTH + COL_GUTTER),
					tier_base_y[tier] + stack_index * (NODE_HEIGHT + STACK_GAP)
				)
				_node_positions[node.id] = pos
				var button := Button.new()
				button.position = pos
				button.custom_minimum_size = Vector2(NODE_WIDTH, NODE_HEIGHT)
				button.size = Vector2(NODE_WIDTH, NODE_HEIGHT)
				button.clip_text = true
				button.autowrap_mode = TextServer.AUTOWRAP_WORD
				add_child(button)
				_node_buttons[node.id] = button
				_restyle_button(button, node)
				button.pressed.connect(func() -> void:
					if not button.disabled:
						node_purchase_requested.emit(node.id)
				)
				max_y = max(max_y, int(pos.y + NODE_HEIGHT))

	custom_minimum_size = Vector2(
		WINGS.size() * COL_WIDTH + (WINGS.size() + 1) * COL_GUTTER,
		max_y + COL_GUTTER
	)
	queue_redraw()


func _restyle_button(button: Button, node: EvolutionNodeData) -> void:
	var owned: bool = _prestige_system.is_node_unlocked(node.id)
	var prereqs_ok: bool = _all_prereqs_unlocked(node)
	var kingdoms_ok: bool = (
		not _prestige_system.has_method("get_unsatisfied_kingdoms")
		or _prestige_system.get_unsatisfied_kingdoms(node.id).is_empty()
	)
	var purchasable: bool = (
		not _prestige_system.has_method("is_node_purchasable")
		or _prestige_system.is_node_purchasable(node)
	)
	var block_reason: String = ""
	if _prestige_system.has_method("get_node_purchase_block_reason"):
		block_reason = _prestige_system.get_node_purchase_block_reason(node.id)
	var cost: int = int(node.meta_cost.get("evolution_points", 0))
	var balance: int = _prestige_system.get_evolution_points_balance()
	var affordable: bool = balance >= cost
	var wing_color: Color = WING_COLORS.get(node.wing, Color(0.5, 0.5, 0.5))

	var sb := StyleBoxFlat.new()
	sb.bg_color = wing_color.darkened(0.15)
	# Sharp corners + 2px chunky borders, matches the identity system's
	# pixel-aesthetic. Light on top/left, dark on bottom/right for depth.
	sb.corner_radius_top_left = 2
	sb.corner_radius_top_right = 2
	sb.corner_radius_bottom_left = 2
	sb.corner_radius_bottom_right = 2
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_top = 2
	sb.border_width_bottom = 2
	sb.border_color = wing_color.darkened(0.35)
	sb.set_border_width_all(2)
	# Add 4px content margin so text doesn't kiss the borders.
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4

	var label_name: String = node.display_name
	if not owned and node.requires_era != &"":
		label_name = "%s [%s]" % [label_name, _era_badge(node.requires_era)]
	var font_color: Color = Color(0.95, 0.95, 0.95)
	# HTML5: ✓ ★ 🔒 fall outside pixel-font glyph coverage and render as
	# boxes-with-hex on web. Use ASCII tokens instead.
	if owned:
		button.text = "%s\n[OK]" % label_name
		button.disabled = true
		sb.bg_color = wing_color
		sb.border_color = wing_color.lightened(0.4)
		font_color = Color(1.0, 1.0, 1.0)
	elif prereqs_ok and kingdoms_ok and purchasable and affordable:
		button.text = "%s\nEP %d" % [label_name, cost]
		button.disabled = false
		sb.bg_color = wing_color.darkened(0.1)
		sb.border_color = wing_color.lightened(0.25)
		font_color = Color(1.0, 1.0, 0.85)   # warm cream highlights affordable
	elif prereqs_ok and kingdoms_ok and purchasable:
		button.text = "%s\nEP %d" % [label_name, cost]
		button.disabled = true
		sb.bg_color = wing_color.darkened(0.4)
		sb.border_color = wing_color.darkened(0.2)
		font_color = Color(0.75, 0.75, 0.65)
	else:
		button.text = "%s\n[X]" % label_name
		button.disabled = true
		sb.bg_color = wing_color.darkened(0.6)
		sb.border_color = wing_color.darkened(0.4)
		font_color = Color(0.55, 0.55, 0.55)

	button.add_theme_stylebox_override("normal", sb)
	button.add_theme_stylebox_override("disabled", sb)
	button.add_theme_stylebox_override("hover", sb)
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_disabled_color", font_color)
	button.add_theme_color_override("font_hover_color", font_color)
	button.tooltip_text = _build_tooltip(node, owned, prereqs_ok, kingdoms_ok, purchasable, affordable, cost, block_reason)


func _build_tooltip(node: EvolutionNodeData, owned: bool, prereqs_ok: bool, kingdoms_ok: bool, purchasable: bool, affordable: bool, cost: int, block_reason: String) -> String:
	var lines := [node.display_name, ""]
	lines.append(node.description)
	if owned:
		lines.append("")
		lines.append("Purchased.")
		return "\n".join(lines)
	lines.append("")
	lines.append("Cost: %d EP" % cost)
	if not prereqs_ok:
		var missing_names := []
		for prereq in node.prerequisites:
			if not _prestige_system.is_node_unlocked(prereq):
				missing_names.append(String(prereq))
		lines.append("Requires: %s" % ", ".join(missing_names))
	if not kingdoms_ok:
		var missing_k: Array = _prestige_system.get_unsatisfied_kingdoms(node.id)
		var pretty: Array = []
		for k in missing_k:
			pretty.append(String(k).capitalize())
		lines.append("Played run as: %s" % ", ".join(pretty))
	if prereqs_ok and kingdoms_ok and not purchasable:
		if block_reason == "requires_era":
			lines.append("Requires %s era." % String(node.requires_era).capitalize())
		elif block_reason == "requires_first_transition":
			lines.append("Requires first era transition.")
		elif block_reason == "coming_phase_15":
			lines.append("Coming in Phase 15.")
	if prereqs_ok and kingdoms_ok and purchasable and not affordable:
		lines.append("Insufficient EP.")
	return "\n".join(lines)


func _all_prereqs_unlocked(node: EvolutionNodeData) -> bool:
	for prereq in node.prerequisites:
		if not _prestige_system.is_node_unlocked(prereq):
			return false
	return true


func _draw() -> void:
	if _prestige_system == null:
		return
	for node in _prestige_system.get_all_nodes():
		if not _node_positions.has(node.id):
			continue
		var to_center: Vector2 = _node_positions[node.id] + Vector2(NODE_WIDTH / 2, NODE_HEIGHT / 2)
		var dest_color: Color = WING_COLORS.get(node.wing, Color(0.6, 0.6, 0.6))
		for prereq_id in node.prerequisites:
			if not _node_positions.has(prereq_id):
				continue
			var from_center: Vector2 = _node_positions[prereq_id] + Vector2(NODE_WIDTH / 2, NODE_HEIGHT / 2)
			var alpha: float = 1.0 if _prestige_system.is_node_unlocked(prereq_id) else 0.35
			var color := Color(dest_color.r, dest_color.g, dest_color.b, alpha)
			draw_line(from_center, to_center, color, 2.0, true)


func _era_badge(era_id: StringName) -> String:
	var upper: String = String(era_id).to_upper()
	if upper.length() <= 4:
		return upper
	return upper.substr(0, 4)
