extends Control
##
## Custom canvas that lays out evolution nodes by (wing, tier) and draws prereq lines.
##

const COL_WIDTH: int = 110
const ROW_HEIGHT: int = 96
const COL_GUTTER: int = 8
const NODE_WIDTH: int = 100
const NODE_HEIGHT: int = 76
const STACK_GAP: int = 4
const WINGS: Array[StringName] = [&"plantae", &"fungi", &"hybrid", &"animals"]
const WING_COLORS: Dictionary = {
	&"plantae": Color(0.35, 0.78, 0.42),
	&"fungi": Color(0.62, 0.42, 0.85),
	&"hybrid": Color(0.40, 0.78, 0.78),
	&"animals": Color(0.88, 0.68, 0.32)
}

var _prestige_system: Node
var _node_buttons: Dictionary[StringName, Button] = {}
var _node_positions: Dictionary[StringName, Vector2] = {}
var _node_by_id: Dictionary[StringName, EvolutionNodeData] = {}

signal node_purchase_requested(node_id: StringName)


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
	for node in _prestige_system.get_all_nodes():
		_node_by_id[node.id] = node
		var key := "%s:%d" % [String(node.wing), node.tier]
		if not by_cell.has(key):
			by_cell[key] = []
		by_cell[key].append(node)

	var max_y := 0
	for col_index in WINGS.size():
		var wing := WINGS[col_index]
		for tier in [1, 2, 3]:
			var key := "%s:%d" % [String(wing), tier]
			var nodes_in_cell: Array = by_cell.get(key, [])
			for stack_index in nodes_in_cell.size():
				var node: EvolutionNodeData = nodes_in_cell[stack_index]
				var pos := Vector2(
					COL_GUTTER + col_index * (COL_WIDTH + COL_GUTTER),
					COL_GUTTER + (tier - 1) * ROW_HEIGHT + stack_index * (NODE_HEIGHT / 2 + STACK_GAP)
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
	var cost: int = int(node.meta_cost.get("evolution_points", 0))
	var balance: int = _prestige_system.get_evolution_points_balance()
	var affordable: bool = balance >= cost
	var wing_color: Color = WING_COLORS.get(node.wing, Color(0.5, 0.5, 0.5))

	var sb := StyleBoxFlat.new()
	sb.bg_color = wing_color
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_top = 2
	sb.border_width_bottom = 2
	sb.border_color = wing_color.lightened(0.3)

	if owned:
		button.text = "%s\n(Owned)" % node.display_name
		button.disabled = true
		sb.bg_color = wing_color.lightened(0.4)
	elif prereqs_ok and kingdoms_ok and affordable:
		button.text = "%s\n%d EP" % [node.display_name, cost]
		button.disabled = false
	elif prereqs_ok and kingdoms_ok:
		button.text = "%s\n%d EP" % [node.display_name, cost]
		button.disabled = true
		sb.bg_color = wing_color.darkened(0.25)
	else:
		button.text = "%s\n(Locked)" % node.display_name
		button.disabled = true
		sb.bg_color = wing_color.darkened(0.5)

	button.add_theme_stylebox_override("normal", sb)
	button.add_theme_stylebox_override("disabled", sb)
	button.add_theme_stylebox_override("hover", sb)
	button.tooltip_text = _build_tooltip(node, owned, prereqs_ok, kingdoms_ok, affordable, cost)


func _build_tooltip(node: EvolutionNodeData, owned: bool, prereqs_ok: bool, kingdoms_ok: bool, affordable: bool, cost: int) -> String:
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
	if prereqs_ok and kingdoms_ok and not affordable:
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
