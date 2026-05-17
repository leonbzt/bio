# Brief 04 — Multi-layer placement engine

**Suggested agent**: ChatGPT 5.2 via Copilot. Route diff to Claude — generalizes a Phase 6 system.

Read first:
1. `docs/briefs/phase_10/03_retire_symbiosis_kingdom.md` (must land first — clears the old symbiosis code).
2. `scripts/autoloads/game_state.gd` — `placement_target` is the current single-layer placement pointer.
3. `scripts/systems/plant_colonization.gd` + `fungi_colonization.gd` — the colonization handlers.
4. `scripts/ui/hud.gd` — layer-toggle UI (if it exists from Phase 6; or where to add it).

## Goal

Generalize the Phase 6 dual-layer placement (which was symbiosis-kingdom-only) to a N-layer engine driven by the active species' `layer_count` + `layer_species`. After this brief:
- A run with a single-layer species (everything except Lichen) places exactly as before (regression).
- A run with a layered species (Lichen, eventually Coral) lets the player tap to place tiles for each layer in rotation, with a HUD toggle to pick which layer is currently active.
- The colonization handlers (`plant_colonization.gd`, `fungi_colonization.gd`) are routed by the current `placement_target` regardless of the run's "primary" kingdom_id.

## Concepts

- **`run.kingdom_id`**: the run's primary kingdom (Plantae / Fungi / Animals — never Symbiosis again). Used for kingdom-wide queries (which evolution wing matters, which discovery-log fires, etc.).
- **`run.niche_id`**: the run's active niche. For Lichen runs: `niche_id == &"lichen"`.
- **`GameState.placement_target: StringName`**: the layer the next tile-tap will affect. For single-layer runs: equal to `run.kingdom_id`. For multi-layer: cycles through the `layer_species`' kingdom_ids.

## Outputs

### New autoload: `scripts/autoloads/multi_layer_placement.gd`

```gdscript
extends Node
##
## MultiLayerPlacementSystem — tracks the active placement layer for runs
## with layer_count > 1. Listens for run_started + species changes.
##

var _active_species: SpeciesData = null
# Layer index into active_species.layer_species (only meaningful when layer_count > 1).
var _current_layer_index: int = 0


func _ready() -> void:
    EventBus.run_started.connect(_on_run_started)
    EventBus.niche_changed.connect(_on_niche_changed)


func _on_run_started(_kingdom_id: StringName) -> void:
    _refresh_active_species()


func _on_niche_changed(_niche_id: StringName) -> void:
    _refresh_active_species()


func _refresh_active_species() -> void:
    var species: SpeciesData = _resolve_active_species()
    _active_species = species
    _current_layer_index = 0
    if species != null and species.layer_count > 1:
        _apply_layer(0)
    else:
        # Single-layer: placement_target = kingdom_id (Phase 6 behavior).
        GameState.placement_target = GameState.current_kingdom_id
        EventBus.placement_target_changed.emit(GameState.placement_target)


func _resolve_active_species() -> SpeciesData:
    # Look up the species via the current niche. NicheData.species_options[0]
    # is the canonical species for v1 (one species per niche).
    var niche_index := load("res://data/niches/_index.tres")
    if niche_index == null or not (niche_index is NicheIndex):
        return null
    for niche in (niche_index as NicheIndex).niches:
        if niche == null:
            continue
        if niche.id == GameState.current_niche_id:
            if niche.species_options.is_empty():
                return null
            return niche.species_options[0]
    return null


# Public API ---------------------------------------------------------------

# Returns true if the active run is multi-layer.
func is_layered() -> bool:
    return _active_species != null and _active_species.layer_count > 1


# Returns the layer count (1 if not layered).
func get_layer_count() -> int:
    if not is_layered():
        return 1
    return _active_species.layer_count


# Returns the current layer index (0-based, always 0 if not layered).
func get_current_layer() -> int:
    return _current_layer_index


# Returns the kingdom_id of the current layer.
func get_current_layer_kingdom() -> StringName:
    if not is_layered():
        return GameState.current_kingdom_id
    if _current_layer_index >= _active_species.layer_species.size():
        return GameState.current_kingdom_id
    return _active_species.layer_species[_current_layer_index].kingdom_id


# Cycle to the next layer. Wraps around. Emits placement_target_changed.
func cycle_layer() -> void:
    if not is_layered():
        return
    _current_layer_index = (_current_layer_index + 1) % _active_species.layer_count
    _apply_layer(_current_layer_index)


# Jump directly to a specific layer.
func set_layer(index: int) -> void:
    if not is_layered():
        return
    if index < 0 or index >= _active_species.layer_count:
        return
    _current_layer_index = index
    _apply_layer(index)


func _apply_layer(index: int) -> void:
    var layer_species: SpeciesData = _active_species.layer_species[index]
    GameState.placement_target = layer_species.kingdom_id
    EventBus.placement_target_changed.emit(GameState.placement_target)
```

Register in `project.godot` after `RunGoalSystem`:
```
MultiLayerPlacementSystem="*uid://<new_uid>"
```

(Use the same uid-style pattern that fixes the autoload-global issue.)

### HUD layer toggle

Add a `LayerToggle` HBoxContainer to the HUD. Visible only when `MultiLayerPlacementSystem.is_layered()` returns true. One button per layer, with the active layer highlighted.

```gdscript
@onready var _layer_toggle: HBoxContainer = $LayerToggle
@onready var _placement: Node = MultiLayerPlacementSystem  # autoload


func _ready() -> void:
    EventBus.run_started.connect(_refresh_layer_toggle)
    EventBus.niche_changed.connect(func(_n): _refresh_layer_toggle(GameState.current_kingdom_id))
    EventBus.placement_target_changed.connect(func(_t): _highlight_active_layer())
    _refresh_layer_toggle(GameState.current_kingdom_id)


func _refresh_layer_toggle(_kingdom_id: StringName) -> void:
    for child in _layer_toggle.get_children():
        child.queue_free()
    if not _placement.is_layered():
        _layer_toggle.visible = false
        return
    _layer_toggle.visible = true
    for i in _placement.get_layer_count():
        var button := Button.new()
        var kingdom: StringName = _placement._active_species.layer_species[i].kingdom_id
        button.text = String(kingdom).capitalize()
        var idx: int = i
        button.pressed.connect(func() -> void: _placement.set_layer(idx))
        _layer_toggle.add_child(button)
    _highlight_active_layer()


func _highlight_active_layer() -> void:
    if not _placement.is_layered():
        return
    var active: int = _placement.get_current_layer()
    var children: Array = _layer_toggle.get_children()
    for i in children.size():
        var b: Button = children[i]
        b.modulate = Color(1.2, 1.2, 1.0, 1.0) if i == active else Color(1.0, 1.0, 1.0, 1.0)
```

### Colonization handler updates (defensive)

`plant_colonization.gd` and `fungi_colonization.gd` already react to `tile_tapped` and dispatch based on `placement_target` (or kingdom_id). Verify they read `GameState.placement_target` (not `current_kingdom_id`) when deciding to act. If they read `current_kingdom_id`, change to `placement_target`.

Specifically: a Lichen run has `current_kingdom_id = &"fungi"` but `placement_target` may be `&"plantae"` (when the player has the surface layer active). The plant colonization handler must respond to plant-layer taps; the fungi handler must respond to fungi-layer taps. Routing happens via `placement_target`.

## Acceptance criteria
- [ ] Single-layer runs unchanged (Plantae photosynthesizer, Fungi decomposer regress correctly).
- [ ] On a Lichen run (after brief 05 lands), HUD layer toggle shows two buttons: "Fungi" and "Plantae".
- [ ] Tap a tile with Fungi layer active → subsurface fungi colonization fires.
- [ ] Tap the Plantae button → `placement_target = &"plantae"` → tap a tile → surface plantae colonization fires.
- [ ] `MultiLayerPlacementSystem.is_layered()` returns true only when the active species' `layer_count > 1`.
- [ ] Layer toggle hidden during single-layer runs.

## Out of scope
- Lichen content (brief 05).
- Multi-layer-aware yield logic in `GrowthSystem` (brief 05 — niche-start hook for Lichen specifies the yield model).
- 3+ layer UI optimization (Phase 14 with Coral).
- Per-layer separate ability bars (Phase 14+ if needed).
