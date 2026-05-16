# Brief 05 — Tree visualization UI rebuild (single scrollable canvas)

**Suggested agent**: ChatGPT 5.2 via Copilot. Route diff to Claude — mobile layout + accessibility review.

Read first:
1. `docs/PROGRESSION_WEB.md` § Visualization.
2. `docs/briefs/phase_9/00_phase_8_recap.md` decision 1 (single scrollable canvas — no tabs).
3. `scripts/ui/prestige_screen.gd` current implementation (`_refresh_tree`).
4. `scenes/ui/prestige_screen.tscn` (existing layout — `TreeSection/TreeGrid`).

## Goal
Replace the flat `GridContainer` tree view with a **scrollable canvas** that:
- Lays out nodes in 4 wing columns (Plantae | Fungi | Hybrid | Animals) by 3 tier rows.
- Draws prereq lines between nodes through `Control._draw()`.
- Color-codes wings (green / violet / teal / amber) and lines (colored by destination wing).
- Shows greyed-out future nodes with informative tooltips ("Requires: X, Y, played run as Z").
- Pans both axes — portrait 360×640 will not fit the full web; scroll on overflow.

## Scene changes (`scenes/ui/prestige_screen.tscn`)

Replace `TreeSection/TreeGrid` (the `GridContainer`) with this subtree:

```
TreeSection (VBoxContainer)
├── BalanceLabel (existing)
└── TreeScroll (ScrollContainer)
    ├── horizontal_scroll_mode = AUTO
    ├── vertical_scroll_mode = AUTO
    ├── custom_minimum_size = Vector2(360, 420)
    └── TreeCanvas (Control — custom_minimum_size set programmatically)
        └── (node buttons added in code as children)
```

`TreeCanvas` is the custom drawer. It owns:
- A dict `_node_buttons: Dictionary[StringName, Control]` for hit-testing prereq lines.
- A custom `_draw()` that iterates all nodes and draws prereq lines.

## Layout math

Constants in `scripts/ui/evolution_tree_canvas.gd`:

```gdscript
const COL_WIDTH: int = 110
const ROW_HEIGHT: int = 96
const COL_GUTTER: int = 8
const NODE_WIDTH: int = 100
const NODE_HEIGHT: int = 76
const WINGS: Array[StringName] = [&"plantae", &"fungi", &"hybrid", &"animals"]
const WING_COLORS: Dictionary[StringName, Color] = {
    &"plantae": Color(0.35, 0.78, 0.42),
    &"fungi":   Color(0.62, 0.42, 0.85),
    &"hybrid":  Color(0.40, 0.78, 0.78),
    &"animals": Color(0.88, 0.68, 0.32),
}
```

Position formula per node:
```
col_index = WINGS.find(node.wing)        # 0..3, defaults to last if missing
row_index = node.tier - 1                # 0..2
x = COL_GUTTER + col_index * (COL_WIDTH + COL_GUTTER)
y = COL_GUTTER + row_index * ROW_HEIGHT
```

Multiple nodes in the same (wing, tier) cell stack vertically inside that cell with 4px gaps. Use a per-cell `Array[EvolutionNodeData]` accumulator pass to compute stack offsets before placement.

Canvas `custom_minimum_size`:
```
width  = 4 * COL_WIDTH + 5 * COL_GUTTER                                              # ~472
height = max_row_height_used = COL_GUTTER + 3 * ROW_HEIGHT + per-cell stack overflow # ~300+
```

This overflows the 360px screen width — that's expected. ScrollContainer handles it.

## New file: `scripts/ui/evolution_tree_canvas.gd`

```gdscript
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
    &"fungi":   Color(0.62, 0.42, 0.85),
    &"hybrid":  Color(0.40, 0.78, 0.78),
    &"animals": Color(0.88, 0.68, 0.32),
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
    # Called after a purchase to update colors / enabled state. Does not relayout.
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


func _build_tooltip(node, owned, prereqs_ok, kingdoms_ok, affordable, cost) -> String:
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
```

## `scripts/ui/prestige_screen.gd` updates

Replace `_refresh_tree` with:

```gdscript
@onready var _tree_canvas: Control = $Content/TreeSection/TreeScroll/TreeCanvas

func _refresh_tree() -> void:
    if _prestige_system == null:
        return
    _balance_label.text = "Balance: %d EP" % _prestige_system.get_evolution_points_balance()
    if not _tree_canvas.has_meta("_setup_done"):
        _tree_canvas.set_meta("_setup_done", true)
        _tree_canvas.setup(_prestige_system)
        _tree_canvas.node_purchase_requested.connect(_on_node_purchase_requested)
    else:
        _tree_canvas.refresh()


func _on_node_purchase_requested(node_id: StringName) -> void:
    if _prestige_system.purchase_node(node_id):
        _refresh_tree()
        _refresh_kingdoms()
```

Delete the old `_prereqs_met` helper (logic moved into the canvas).

## Mobile considerations

- Touch targets: 100×76 px easily exceeds the 44×44 floor.
- The canvas is ~472×400 on 22 nodes. ScrollContainer with both axes auto-scrolls.
- Tooltips on mobile: Godot's default `tooltip_text` shows on long-press. Acceptable for v1.
- Pan inertia: enable `ScrollContainer.scroll_deadzone = 0` and rely on Godot's default kinetic scroll.

## Acceptance criteria
- [ ] Prestige screen tree section shows nodes laid out in 4 columns (Plantae|Fungi|Hybrid|Animals) × 3 rows.
- [ ] Wing colors match the table (green/violet/teal/amber).
- [ ] Prereq lines visible between connected nodes; cross-wing lines colored by destination wing.
- [ ] Locked nodes (insufficient prereq) appear darkened; gated nodes (insufficient `kingdoms_played`) appear darkened with informative tooltip.
- [ ] Long-press shows tooltip with prereqs + required kingdoms_played.
- [ ] ScrollContainer pans both axes smoothly on Android.
- [ ] Buying a node updates colors immediately + redraws lines (`refresh()` after purchase).
- [ ] No regressions: existing prestige flow (summary → tree → kingdom select) intact.

## Out of scope
- Animations (node-purchase pulse, line-grow effects) — deferred to a polish phase.
- Pinch-to-zoom — explicitly skipped, ScrollContainer pan is enough for 22 nodes.
- Mini-map — overkill at this node count.
- Discovery log UI (brief 08).
