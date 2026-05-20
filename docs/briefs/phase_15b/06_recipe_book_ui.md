# Brief 06 — Recipe book UI

**Suggested agent**: ChatGPT 5.2. Route diff to Claude.

Read first:
1. `docs/briefs/phase_15b/05_structure_detector.md` — StructureData schema + discovered list.
2. `scripts/ui/biome_legend.gd` — small panel UI pattern to mirror.
3. `scripts/autoloads/kingdom_theme.gd` — fonts + colors.

## Goal

Add a HUD icon that opens a small Recipe Book panel listing all 4 starter structures. Each entry shows either the full pattern + bonus description (if discovered) or a silhouette + hint (if undiscovered).

## Recipe book scene

`scenes/ui/recipe_book.tscn` (new) — a modal-ish panel:

```
RecipeBook (PanelContainer, anchored center, ~280×360)
  Margin (MarginContainer)
    VBox
      Header (HBox)
        Title "Structures"
        CloseButton "X"
      List (VBoxContainer)
        (one entry per structure, built dynamically)
```

Each entry (built dynamically):

```
EntryPanel (PanelContainer)
  VBox
    HBox
      ColorRect (small halo color swatch)
      Label (display_name or "???")
    Label (description or hint, autowrap, small font)
    Label (pattern brief like "3×3 fungi w/ 4+ adjacent plantae" or "???")
```

## Script

`scripts/ui/recipe_book.gd`:

```gdscript
extends PanelContainer

const STRUCTURE_INDEX_PATH: String = "res://data/structures/_index.tres"

@onready var _list: VBoxContainer = $Margin/VBox/List
@onready var _close: Button = $Margin/VBox/Header/CloseButton


func _ready() -> void:
    _close.pressed.connect(queue_free)
    _build_entries()


func _build_entries() -> void:
    for child in _list.get_children():
        child.queue_free()
    var index: StructureIndex = load(STRUCTURE_INDEX_PATH) as StructureIndex
    if index == null:
        return
    var discovered: Array = GameState.meta_save.get("structures_discovered", []) as Array
    for sd in index.structures:
        if sd == null:
            continue
        var is_known: bool = discovered.has(String(sd.id))
        _list.add_child(_build_entry(sd, is_known))


func _build_entry(sd: StructureData, known: bool) -> Control:
    var panel := PanelContainer.new()
    panel.add_theme_stylebox_override("panel", _entry_stylebox(sd, known))
    var vbox := VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 2)
    panel.add_child(vbox)

    var header := HBoxContainer.new()
    header.add_theme_constant_override("separation", 4)
    var swatch := ColorRect.new()
    swatch.custom_minimum_size = Vector2(12, 12)
    swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    swatch.color = sd.halo_color if known else Color(0.4, 0.4, 0.4)
    header.add_child(swatch)
    var title := Label.new()
    title.text = sd.display_name if known else "???"
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(title)
    vbox.add_child(header)

    var desc := Label.new()
    desc.text = sd.description if known else _silhouette_hint(sd)
    desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    desc.add_theme_font_override("font", KingdomTheme.SMALL_FONT)
    desc.add_theme_font_size_override("font_size", KingdomTheme.SMALL_FONT_SIZE)
    desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8) if known else Color(0.5, 0.5, 0.5))
    vbox.add_child(desc)

    if known:
        var pattern_text := Label.new()
        pattern_text.text = _format_pattern(sd)
        pattern_text.add_theme_font_override("font", KingdomTheme.SMALL_FONT)
        pattern_text.add_theme_font_size_override("font_size", KingdomTheme.SMALL_FONT_SIZE)
        pattern_text.add_theme_color_override("font_color", Color(0.65, 0.75, 0.55))
        vbox.add_child(pattern_text)
    return panel


func _entry_stylebox(sd: StructureData, known: bool) -> StyleBoxFlat:
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color(0.10, 0.10, 0.12) if known else Color(0.06, 0.06, 0.08)
    sb.border_color = sd.halo_color if known else Color(0.25, 0.25, 0.28)
    sb.set_border_width_all(1)
    sb.set_corner_radius_all(2)
    sb.content_margin_left = 4
    sb.content_margin_right = 4
    sb.content_margin_top = 3
    sb.content_margin_bottom = 3
    return sb


func _silhouette_hint(sd: StructureData) -> String:
    # Cryptic hint based on pattern_type — enough to nudge, not enough to spoil.
    match sd.pattern_type:
        &"block_NxM_same_species":
            return "Some say a thick patch of one kind brings the form."
        &"ring_radius_N":
            return "A circle of similar around a hollow center."
        &"square_NxM_with_adjacent":
            return "Two kingdoms must touch in numbers."
        &"area_on_biome":
            return "The right soil + the right neighbors."
        _:
            return "Unknown form."


func _format_pattern(sd: StructureData) -> String:
    var p: Dictionary = sd.pattern_params
    match sd.pattern_type:
        &"block_NxM_same_species":
            return "Pattern: %dx%d block, same species, %s kingdom" % [
                int(p.get("width", 0)), int(p.get("height", 0)),
                String(p.get("kingdom_id", ""))
            ]
        &"square_NxM_with_adjacent":
            return "Pattern: %dx%d %s block, ≥%d adjacent %s" % [
                int(p.get("width", 0)), int(p.get("height", 0)),
                String(p.get("kingdom_id", "")), int(p.get("min_adjacent", 0)),
                String(p.get("adjacent_kingdom_id", ""))
            ]
        &"ring_radius_N":
            return "Pattern: hollow ring radius %d, %s kingdom" % [
                int(p.get("radius", 0)), String(p.get("kingdom_id", ""))
            ]
        &"area_on_biome":
            return "Pattern: %dx%d %s block on %s biome%s" % [
                int(p.get("width", 0)), int(p.get("height", 0)),
                String(p.get("kingdom_id", "")), String(p.get("biome_id", "")),
                " + corpse adj" if p.get("require_adjacent_corpse", false) else ""
            ]
        _:
            return "Pattern: ???"
```

## HUD trigger

Add a small "Recipes" button in the HUD top-right (near menu button area). On press, instantiates `recipe_book.tscn` and adds it as a child of the HUD root.

```gdscript
# In hud.gd or pause_menu.gd:
@onready var _recipes_button: Button = $RecipesButton  # add to hud.tscn

func _ready() -> void:
    # ... existing setup ...
    _recipes_button.pressed.connect(_open_recipe_book)


func _open_recipe_book() -> void:
    if has_node("RecipeBookInstance"):
        return    # already open
    var scene: PackedScene = load("res://scenes/ui/recipe_book.tscn") as PackedScene
    var instance: Node = scene.instantiate()
    instance.name = "RecipeBookInstance"
    add_child(instance)
```

Add to `hud.tscn` a Button node "RecipesButton" in a spot that's clear of other UI (e.g., top-right corner, below menu/identity strip).

## Listening for newly discovered structures

When `EventBus.structure_promoted` fires, the meta list updates and the recipe book — if open — should refresh. Add to `recipe_book.gd._ready`:

```gdscript
EventBus.structure_promoted.connect(func(_id, _anchor): _build_entries())
```

And ideally a small toast: "Structure discovered: Mycorrhizal Hub" — but defer to brief 07 or future polish.

## Acceptance criteria

- [ ] HUD has a "Recipes" button.
- [ ] Tap opens recipe_book panel showing all 4 starter structures.
- [ ] Undiscovered structures show "???" + cryptic hint + grey swatch.
- [ ] Discovered structures show full name + description + pattern + halo color swatch.
- [ ] Close button + tap outside dismisses panel.
- [ ] Panel auto-refreshes when a new structure is discovered.
- [ ] Reopening panel reflects current state.

## Out of scope

- Visual preview / ASCII-art of the pattern in the entry.
- Filter / search within the recipe book.
- Animations on discovery moment (Phase 16+).
- Cross-link to wiki / discovery log entries.
