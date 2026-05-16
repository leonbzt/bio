# Brief 08 — Discovery log UI (pause menu entry, list, unlock toast)

**Suggested agent**: ChatGPT 5.2 via Copilot. Route diff to Claude — UI contract + accessibility review.

Read first:
1. `docs/STORY_AND_TONE.md` — voice and discovery-log description.
2. `docs/briefs/phase_9/00_phase_8_recap.md` decision 5 (locked entries hidden, denominator only).
3. `docs/briefs/phase_9/06_discovery_log_triggers.md` — `EventBus.discovery_unlocked` signal.
4. `scripts/ui/pause_menu.gd` and `scenes/ui/pause_menu.tscn` (where the new entry button lives).
5. `scripts/autoloads/discovery_log.gd` — public API.

## Goal
Three UI deliverables:
1. **Pause menu entry**: a "Discovery Log" button that opens the log view, with the denominator visible on the button itself ("Discovery Log — 12 / 28").
2. **Discovery log view**: full-screen scrollable list of unlocked entries grouped by category, with a header showing the count.
3. **Unlock toast**: a brief HUD toast on `EventBus.discovery_unlocked` showing "New discovery: <title>", tap-to-open behavior.

Per phase decision 5: **locked entries are hidden from the list entirely.** Only the denominator hints they exist. No silhouettes, no redacted bodies, no titles.

## Scene 1 — pause menu wiring

### `scenes/ui/pause_menu.tscn` (modify)
Add a new Button under the existing menu VBox, between "Settings" and "Quit to Title" (or wherever fits the existing pattern):

```
DiscoveryLogButton (Button)
├── text = "Discovery Log"   # updated by code with denominator
└── pressed → open log view
```

### `scripts/ui/pause_menu.gd` (modify)
```gdscript
@onready var _discovery_button: Button = $Panel/Menu/DiscoveryLogButton

func _ready() -> void:
    # ... existing wiring ...
    _discovery_button.pressed.connect(_on_discovery_log_pressed)
    _refresh_discovery_label()
    EventBus.discovery_unlocked.connect(_on_discovery_unlocked)

func _refresh_discovery_label() -> void:
    var unlocked: int = DiscoveryLog.get_unlocked_count()
    var total: int = DiscoveryLog.get_total_count()
    _discovery_button.text = "Discovery Log — %d / %d" % [unlocked, total]

func _on_discovery_unlocked(_entry_id: StringName) -> void:
    _refresh_discovery_label()

func _on_discovery_log_pressed() -> void:
    var scene := preload("res://scenes/ui/discovery_log_screen.tscn")
    var instance := scene.instantiate()
    add_child(instance)    # overlay on top of pause menu
```

## Scene 2 — `scenes/ui/discovery_log_screen.tscn` (new)

```
DiscoveryLogScreen (Control, fills parent)
├── DimBackground (ColorRect, color = Color(0,0,0,0.85), MOUSE_FILTER_STOP)
└── Panel (PanelContainer, anchored full-rect with margins)
    └── VBox (VBoxContainer)
        ├── HeaderRow (HBoxContainer)
        │   ├── TitleLabel (Label, "Discovery Log")
        │   ├── Spacer
        │   ├── CountLabel (Label, "12 / 28")
        │   └── CloseButton (Button, "✕")
        ├── HSeparator
        └── EntriesScroll (ScrollContainer)
            └── EntriesVBox (VBoxContainer)
                # populated by code
```

Mobile sizing: 360×640 minus 12px margins on all sides. Panel takes the rest.

## Script — `scripts/ui/discovery_log_screen.gd` (new)

```gdscript
extends Control

@onready var _count_label: Label = $Panel/VBox/HeaderRow/CountLabel
@onready var _entries_vbox: VBoxContainer = $Panel/VBox/EntriesScroll/EntriesVBox
@onready var _close_button: Button = $Panel/VBox/HeaderRow/CloseButton

const _CATEGORY_HEADERS: Dictionary = {
    &"kingdom":   "Kingdoms",
    &"niche":     "Niches",
    &"node":      "Nodes",
    &"event":     "Events",
    &"milestone": "Milestones",
}

const _CATEGORY_ORDER: Array[StringName] = [
    &"kingdom", &"niche", &"node", &"event", &"milestone"
]


func _ready() -> void:
    _close_button.pressed.connect(_on_close)
    _refresh()
    EventBus.discovery_unlocked.connect(_on_discovery_unlocked)


func _refresh() -> void:
    _count_label.text = "%d / %d" % [
        DiscoveryLog.get_unlocked_count(),
        DiscoveryLog.get_total_count()
    ]
    for child in _entries_vbox.get_children():
        child.queue_free()

    var unlocked: Array[DiscoveryEntry] = DiscoveryLog.get_unlocked_entries()
    var by_category: Dictionary[StringName, Array] = {}
    for entry in unlocked:
        if not by_category.has(entry.category):
            by_category[entry.category] = []
        by_category[entry.category].append(entry)

    var first := true
    for category in _CATEGORY_ORDER:
        if not by_category.has(category):
            continue
        if not first:
            var sep := HSeparator.new()
            _entries_vbox.add_child(sep)
        first = false
        var header := Label.new()
        header.text = _CATEGORY_HEADERS.get(category, String(category).capitalize())
        header.add_theme_font_size_override("font_size", 18)
        _entries_vbox.add_child(header)
        var entries: Array = by_category[category]
        entries.sort_custom(func(a, b): return String(a.title) < String(b.title))
        for entry in entries:
            _entries_vbox.add_child(_build_entry_row(entry))


func _build_entry_row(entry: DiscoveryEntry) -> Control:
    var card := PanelContainer.new()
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color(0.10, 0.10, 0.12, 1.0)
    sb.corner_radius_top_left = 4
    sb.corner_radius_top_right = 4
    sb.corner_radius_bottom_left = 4
    sb.corner_radius_bottom_right = 4
    sb.content_margin_left = 10
    sb.content_margin_right = 10
    sb.content_margin_top = 8
    sb.content_margin_bottom = 8
    card.add_theme_stylebox_override("panel", sb)

    var vbox := VBoxContainer.new()
    card.add_child(vbox)

    var title := Label.new()
    title.text = entry.title
    title.add_theme_font_size_override("font_size", 15)
    title.add_theme_color_override("font_color", Color(0.92, 0.88, 0.72))
    vbox.add_child(title)

    var body := Label.new()
    body.text = entry.body
    body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body.add_theme_font_size_override("font_size", 12)
    body.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
    vbox.add_child(body)

    return card


func _on_discovery_unlocked(_entry_id: StringName) -> void:
    _refresh()


func _on_close() -> void:
    queue_free()
```

## Unlock toast — new file: `scripts/ui/discovery_toast.gd`

A lightweight self-dismissing toast that lives in the HUD root. Drives via `EventBus.discovery_unlocked`.

### Scene `scenes/ui/discovery_toast.tscn`

```
DiscoveryToast (Control)
└── Panel (PanelContainer, anchored bottom-center)
    └── HBox (HBoxContainer)
        ├── IconLabel (Label, "✦")
        ├── VBox
        │   ├── Label1 (Label, "New discovery")
        │   └── Label2 (Label, entry title — fills dynamically)
        └── (entire panel pressable via Button-as-overlay or Area2D-on-Control)
```

Add to the existing HUD scene: `scenes/world/hud.tscn` → add a `DiscoveryToast` child near the top of the tree so it renders above gameplay.

### Script

```gdscript
extends Control

@onready var _panel: PanelContainer = $Panel
@onready var _title_label: Label = $Panel/HBox/VBox/Label2

const FADE_IN_TIME: float = 0.2
const HOLD_TIME: float = 3.0
const FADE_OUT_TIME: float = 0.4

var _queue: Array[StringName] = []
var _showing: bool = false


func _ready() -> void:
    _panel.modulate.a = 0.0
    _panel.visible = false
    EventBus.discovery_unlocked.connect(_on_discovery_unlocked)
    gui_input.connect(_on_gui_input)


func _on_discovery_unlocked(entry_id: StringName) -> void:
    _queue.append(entry_id)
    if not _showing:
        _show_next()


func _show_next() -> void:
    if _queue.is_empty():
        _showing = false
        return
    _showing = true
    var entry_id: StringName = _queue.pop_front()
    var entry: DiscoveryEntry = null
    for e in DiscoveryLog.get_all_entries():
        if e.id == entry_id:
            entry = e
            break
    if entry == null:
        _show_next()
        return
    _title_label.text = entry.title
    _panel.visible = true
    var tween := create_tween()
    tween.tween_property(_panel, "modulate:a", 1.0, FADE_IN_TIME)
    tween.tween_interval(HOLD_TIME)
    tween.tween_property(_panel, "modulate:a", 0.0, FADE_OUT_TIME)
    tween.tween_callback(func() -> void:
        _panel.visible = false
        _show_next()
    )


func _on_gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
        # Tap-to-open: pause the game and open discovery log overlay.
        get_tree().paused = true
        var scene := preload("res://scenes/ui/discovery_log_screen.tscn")
        get_tree().current_scene.add_child(scene.instantiate())
```

## ARCHITECTURE.md update

§5 (System map): add the new UI scenes. §7 (Signals): no new signals — `discovery_unlocked` was added in brief 02/06.

## Acceptance criteria
- [ ] Pause menu shows "Discovery Log — N / 28" button; N updates on unlocks.
- [ ] Tapping opens the log overlay. Entries grouped by category in order: Kingdoms, Niches, Nodes, Events, Milestones.
- [ ] Locked entries do not appear in any form.
- [ ] Close button (✕) dismisses overlay; underlying pause menu still shown.
- [ ] HUD toast appears on `discovery_unlocked` with title + "New discovery" prefix, auto-dismisses after ~3.6s.
- [ ] Multiple unlocks in quick succession queue and show one at a time (no overlap).
- [ ] Tapping the toast pauses the game and opens the log overlay.
- [ ] Mobile: log overlay is readable at 360×640; body text wraps; ScrollContainer pans vertically; touch targets ≥44px.
- [ ] Cold load with 0 unlocks: button says "Discovery Log — 0 / 28", opening it shows an empty list (no headers, no rows, no error).

## Out of scope
- Sound on unlock (audio system could add a one-shot SFX later — note for Phase 11 polish).
- Search/filter inside the log (overkill at 28 entries).
- Sharing / screenshot affordance.
- Era-transition full-screen passages (Phase 11 has its own UI design).
- "Recently unlocked" sort within categories — alphabetical-by-title is fine.
