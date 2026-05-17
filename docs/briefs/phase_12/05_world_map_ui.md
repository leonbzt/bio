# Brief 05 — World map UI + flow integration

**Suggested agent**: ChatGPT 5.2. Route diff to Claude — mobile layout + flow refactor.

Read first:
1. `docs/briefs/phase_12/04_era_system_autoload.md` (must land first).
2. `scripts/ui/prestige_screen.gd` — the existing kingdom-select flow this replaces.
3. `scripts/ui/main_menu.gd` — title screen entry point.
4. `scenes/ui/hud.tscn` for theme reference.

## Goal
Replace the "Begin run as Plantae/Fungi/..." button stack with a **World Map** screen that the player sees:
- Immediately after prestige confirmation.
- From the title screen "Play" button.
- From the pause menu "Play" / "Continue" button (new entry).

The world map shows:
- Era tabs at the top (locked eras shown disabled with a small lock badge).
- Below: a 3×N grid of ecosystem tiles for the selected era. Each tile shows name, 1-line flavor, completion ✓/✗, required niche/kingdom hint.
- Tapping an ecosystem confirms it; the player then enters the kingdom/niche cascade pre-filtered by `era.available_kingdoms`.

## Scene: `scenes/ui/world_map.tscn`

```
WorldMap (Control, fills parent)
├── Backdrop (ColorRect, anchored full, tinted by current era's tint_color)
├── Header (HBoxContainer, anchored top)
│   ├── Title (Label, "World Map")
│   ├── Spacer
│   └── CloseButton (Button, "✕")
├── EraTabs (HBoxContainer, below header)
│   └── (per-era buttons added in code)
├── EcosystemGrid (GridContainer, 1 column on mobile)
│   └── (per-ecosystem panels added in code)
└── ContinueButton (Button, anchored bottom, disabled until an ecosystem is picked, text "Continue →")
```

Apply `assets/ui/theme.tres` to root.

## Script: `scripts/ui/world_map.gd`

```gdscript
extends Control

const ERA_TAB_ACTIVE: Color = Color(1.0, 1.0, 0.85, 1.0)
const ERA_TAB_INACTIVE: Color = Color(0.65, 0.65, 0.65, 1.0)
const ERA_TAB_LOCKED: Color = Color(0.4, 0.4, 0.4, 0.6)

@onready var _backdrop: ColorRect = $Backdrop
@onready var _era_tabs: HBoxContainer = $EraTabs
@onready var _ecosystem_grid: GridContainer = $EcosystemGrid
@onready var _continue: Button = $ContinueButton
@onready var _close: Button = $Header/CloseButton

var _selected_era_id: StringName = &""
var _selected_ecosystem_id: StringName = &""
var _prestige_system: Node = null


func _ready() -> void:
    _close.pressed.connect(_on_close)
    _continue.pressed.connect(_on_continue)
    EventBus.era_changed.connect(func(_id): _refresh())
    EventBus.ecosystem_completed.connect(func(_id): _refresh())
    _prestige_system = get_tree().get_first_node_in_group("prestige_system")
    _selected_era_id = EraSystem.get_current_era().id if EraSystem.get_current_era() != null else &""
    _selected_ecosystem_id = StringName(GameState.meta_save.get("current_ecosystem_id", ""))
    _refresh()


func _refresh() -> void:
    _refresh_backdrop()
    _refresh_era_tabs()
    _refresh_ecosystem_grid()
    _refresh_continue()


func _refresh_backdrop() -> void:
    var era := EraSystem.get_era(_selected_era_id)
    if era != null:
        _backdrop.color = era.tint_color


func _refresh_era_tabs() -> void:
    for child in _era_tabs.get_children():
        child.queue_free()
    for era_id in _ordered_era_ids():
        var era := EraSystem.get_era(era_id)
        if era == null:
            continue
        var button := Button.new()
        button.text = era.display_name
        var unlocked: bool = EraSystem.is_era_unlocked(era_id)
        button.disabled = not unlocked
        var captured_id := era_id
        button.pressed.connect(func() -> void:
            _selected_era_id = captured_id
            _selected_ecosystem_id = &""
            _refresh()
        )
        if not unlocked:
            button.modulate = ERA_TAB_LOCKED
            button.text = "🔒 %s" % era.display_name
        elif era_id == _selected_era_id:
            button.modulate = ERA_TAB_ACTIVE
        else:
            button.modulate = ERA_TAB_INACTIVE
        _era_tabs.add_child(button)


func _refresh_ecosystem_grid() -> void:
    for child in _ecosystem_grid.get_children():
        child.queue_free()
    for eco in EraSystem.get_ecosystems_in_era(_selected_era_id):
        var card := _build_ecosystem_card(eco)
        _ecosystem_grid.add_child(card)


func _build_ecosystem_card(eco: EcosystemData) -> PanelContainer:
    var card := PanelContainer.new()
    card.custom_minimum_size = Vector2(0, 80)
    var sb := StyleBoxFlat.new()
    var done: bool = EraSystem.is_ecosystem_complete(eco.id)
    sb.bg_color = Color(0.15, 0.20, 0.15) if done else Color(0.15, 0.15, 0.18)
    sb.corner_radius_top_left = 4
    sb.corner_radius_top_right = 4
    sb.corner_radius_bottom_left = 4
    sb.corner_radius_bottom_right = 4
    sb.content_margin_left = 8
    sb.content_margin_right = 8
    sb.content_margin_top = 6
    sb.content_margin_bottom = 6
    card.add_theme_stylebox_override("panel", sb)

    var vbox := VBoxContainer.new()
    card.add_child(vbox)

    var title := Label.new()
    title.text = ("✓ " if done else "") + eco.display_name
    title.add_theme_color_override("font_color", Color(0.95, 0.9, 0.6) if done else Color(0.95, 0.95, 0.95))
    vbox.add_child(title)

    var desc := Label.new()
    desc.text = eco.description
    desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    desc.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
    vbox.add_child(desc)

    var goal := Label.new()
    goal.text = _goal_string(eco)
    goal.add_theme_color_override("font_color", Color(0.7, 0.85, 0.6))
    vbox.add_child(goal)

    var captured_id := eco.id
    card.gui_input.connect(func(event: InputEvent) -> void:
        if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
            _selected_ecosystem_id = captured_id
            _refresh_continue()
        elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
            _selected_ecosystem_id = captured_id
            _refresh_continue()
    )

    if eco.id == _selected_ecosystem_id:
        sb.border_width_left = 2
        sb.border_width_right = 2
        sb.border_width_top = 2
        sb.border_width_bottom = 2
        sb.border_color = Color(0.95, 0.85, 0.4, 1.0)

    return card


func _goal_string(eco: EcosystemData) -> String:
    var goal: String = "%s %d" % [String(eco.completion_criterion).capitalize(), int(eco.completion_target)]
    if eco.completion_required_niche != &"":
        goal += " · requires %s niche" % String(eco.completion_required_niche).capitalize()
    elif eco.completion_required_kingdom != &"":
        goal += " · requires %s kingdom" % String(eco.completion_required_kingdom).capitalize()
    return goal


func _refresh_continue() -> void:
    _continue.disabled = _selected_ecosystem_id == &""


func _ordered_era_ids() -> Array[StringName]:
    # Iterate the era index in declared order. Stable.
    var era_index := load("res://data/eras/_index.tres")
    if era_index == null or not (era_index is EraIndex):
        return []
    var result: Array[StringName] = []
    for era in (era_index as EraIndex).eras:
        if era != null:
            result.append(era.id)
    return result


func _on_close() -> void:
    queue_free()


func _on_continue() -> void:
    if _selected_ecosystem_id == &"":
        return
    EraSystem.set_current_ecosystem(_selected_ecosystem_id)
    # Hand off to existing kingdom/niche cascade in prestige_screen.
    if _prestige_system == null:
        return
    var scene := preload("res://scenes/ui/prestige_screen.tscn")
    var screen := scene.instantiate()
    if screen.has_method("setup"):
        screen.setup(_prestige_system)
    # The prestige_screen normally renders summary + tree + kingdom select.
    # In world-map flow we want it to skip straight to kingdom-select with the era filter applied.
    if screen.has_method("set_skip_to_kingdom_select"):
        screen.set_skip_to_kingdom_select(true)
    elif "skip_to_kingdom_select" in screen:
        screen.skip_to_kingdom_select = true
    get_parent().add_child(screen)
    queue_free()
```

## Integration with `prestige_screen.gd`

`prestige_screen.gd` already has `@export var skip_to_kingdom_select: bool`. After ecosystem-pick, world map sets this true and the screen renders only the kingdom panel.

Modify `_refresh_kingdoms()` in `prestige_screen.gd` to filter by era:

```gdscript
func _refresh_kingdoms() -> void:
    for child in _kingdom_buttons.get_children():
        child.queue_free()
    var kingdoms: Array = GameState.meta_save.get("unlocked_kingdoms", [])
    # Phase 12: filter by current era's available_kingdoms.
    var era: EraData = EraSystem.get_current_era()
    if era != null and not era.available_kingdoms.is_empty():
        var filtered: Array = []
        for kid in kingdoms:
            if era.available_kingdoms.has(StringName(kid)):
                filtered.append(kid)
        kingdoms = filtered
    for kingdom_id in kingdoms:
        # ... existing button creation ...
```

If no kingdoms remain after filtering (rare edge case), show a message: "No playable kingdoms in this era. Try another era."

## Title screen + pause menu entry points

### `scripts/ui/main_menu.gd`

The "Play" / "Continue" button currently navigates to world.tscn. Add a step: instead, navigate to world.tscn AND once it's loaded, instantiate WorldMap on top of HUD. Or: have the title screen instantiate the world_map scene directly before loading world.

Simplest: title screen "Play" button → load world.tscn, then in world.tscn `_ready`, if `meta.current_ecosystem_id != ""` and `is_run_active` is false, instantiate WorldMap on the HUD layer.

Alternatively: change MainMenu to instantiate WorldMap inline before loading world.

Pick whichever fits the existing scene-loading pattern more cleanly.

### `scripts/ui/pause_menu.gd`

Add a "World Map" button:
```gdscript
@onready var _world_map_button: Button = $Panel/VBox/WorldMapButton

func _ready() -> void:
    # ... existing wiring ...
    _world_map_button.pressed.connect(_on_world_map_pressed)

func _on_world_map_pressed() -> void:
    var scene := preload("res://scenes/ui/world_map.tscn")
    var map := scene.instantiate()
    get_parent().add_child(map)
    close()
```

Add the corresponding node to `pause_menu.tscn` (between PrestigeButton and ResumeButton).

## Acceptance criteria
- [ ] After prestige confirmation, world map opens.
- [ ] Cryogenian tab is selected by default on first run.
- [ ] 3 Cryogenian ecosystem cards visible. Tapping one selects it (yellow border).
- [ ] Continue button disabled until ecosystem picked, enabled once.
- [ ] Tapping Continue: world map closes, prestige_screen opens directly on kingdom-select with only Fungi available.
- [ ] Picking Fungi → niche selector → run starts.
- [ ] During the run, `EraSystem.get_current_ecosystem().id` matches the selected ecosystem.
- [ ] After ecosystem completion + prestige: completed ecosystem card shows "✓" + greyed-out, era tab still active.
- [ ] After all 3 Cryogenian ecosystems complete: Devonian tab becomes selectable (no longer locked icon). `era_transition_started` signal fires (brief 06 catches it for narrative passage).

## Out of scope
- Narrative passage UI (brief 06).
- Era-locked-kingdom filter (brief 07 makes it stricter at prestige_system level).
- Mass extinction event (brief 08).
