# Brief 02 — TerritorySystem refactor + tile grid layers + PlantColonization split

**Suggested agent**: ChatGPT 5.2 via Copilot. The biggest brief in Phase 5 — read end to end before starting. **Route diff to Claude** when complete.

Read first:
1. `docs/ARCHITECTURE.md` § 3 (tile shape), § 5 (system map — TerritorySystem, PlantColonization roles), § 7a (catch-up).
2. `scripts/systems/territory_system.gd` — current single-layer implementation.
3. `scripts/entities/tile_grid.gd` — current single-overlay implementation.
4. `scripts/systems/herbivore_manager.gd` — calls `_territory.lose_tile` and `get_owned_coords`. **These callers must keep working.**

## Goal
1. Strip TerritorySystem of input handling. It becomes a pure state holder with explicit per-layer mutators and queries.
2. Move the tap-handling logic into a new `PlantColonization` system that listens to `tile_tapped` only when the current kingdom is plantae.
3. Update `tile_grid.gd` to render two overlay layers (plant green and fungi violet) on top of the base.

## Outputs (modify)
- `scripts/systems/territory_system.gd` — major rewrite.
- `scripts/entities/tile_grid.gd` — add second overlay atlas + per-kingdom setters.
- `scripts/systems/herbivore_manager.gd` — update calls (see "Caller migration" below).

## Outputs (create)
- `scripts/systems/plant_colonization.gd`
- Modification to `scenes/world/world.tscn` — add `PlantColonization` node under `Systems`, *before* TerritorySystem (so on input it can call the now-passive TerritorySystem).

## TileGrid changes

### Two overlay layers
```gdscript
# tile_grid.gd
const ATLAS_BASE := Vector2i(0, 0)
const ATLAS_PLANTAE := Vector2i(1, 0)        # existing brighter green
const ATLAS_FUNGI := Vector2i(2, 0)          # new — violet/purple

const LAYER_BASE := 0
const LAYER_SURFACE := 1
const LAYER_SUBSURFACE := 2
```

In `_build_tileset()`, create three tiles in the atlas:
- (0,0) base green
- (1,0) brighter green (already there)
- (2,0) violet `#7a5fa8` with the same 1px border style

Replace `set_owned(coord, owned)` with kingdom-aware setters:
```gdscript
func set_surface_owner(coord: Vector2i, kingdom_id: StringName) -> void:
    if String(kingdom_id) == "":
        erase_cell(LAYER_SURFACE, coord)
    elif kingdom_id == &"plantae":
        set_cell(LAYER_SURFACE, coord, SOURCE_ID, ATLAS_PLANTAE)
    # add other surface-occupying kingdoms here later


func set_subsurface_owner(coord: Vector2i, kingdom_id: StringName) -> void:
    if String(kingdom_id) == "":
        erase_cell(LAYER_SUBSURFACE, coord)
    elif kingdom_id == &"fungi":
        set_cell(LAYER_SUBSURFACE, coord, SOURCE_ID, ATLAS_FUNGI)


func clear_owned() -> void:
    clear_layer(LAYER_SURFACE)
    clear_layer(LAYER_SUBSURFACE)
```

Note: the current callers use `set_owned(coord, bool)` — kept for backward compatibility through brief 02, but no longer used after this brief lands. Remove it.

## TerritorySystem rewrite

### State
```gdscript
const SURFACE_PLANTAE: StringName = &"plantae"
const SUBSURFACE_FUNGI: StringName = &"fungi"

# Per-tile state: {"surface_owner": StringName, "subsurface_owner": StringName, "data": Dictionary}
var _tiles: Dictionary[Vector2i, Dictionary] = {}

@onready var _tile_grid: Node = get_node("../../TileGrid")
```

### Public mutators (called by colonization systems and HerbivoreManager)
```gdscript
func add_surface(coord: Vector2i, kingdom_id: StringName) -> bool:
    var entry: Dictionary = _ensure_entry(coord)
    if entry["surface_owner"] != &"":
        return false
    entry["surface_owner"] = kingdom_id
    _tile_grid.set_surface_owner(coord, kingdom_id)
    _sync_run_save()
    EventBus.tile_colonized.emit(coord, kingdom_id)
    return true


func add_subsurface(coord: Vector2i, kingdom_id: StringName) -> bool:
    var entry: Dictionary = _ensure_entry(coord)
    if entry["subsurface_owner"] != &"":
        return false
    entry["subsurface_owner"] = kingdom_id
    _tile_grid.set_subsurface_owner(coord, kingdom_id)
    _sync_run_save()
    EventBus.tile_colonized.emit(coord, kingdom_id)
    return true


func remove_surface(coord: Vector2i, cause: StringName) -> void:
    if not _tiles.has(coord):
        return
    var entry: Dictionary = _tiles[coord]
    var prev: StringName = entry.get("surface_owner", &"")
    if prev == &"":
        return
    entry["surface_owner"] = &""
    _tile_grid.set_surface_owner(coord, &"")
    _gc_if_empty(coord)
    _sync_run_save()
    EventBus.tile_lost.emit(coord, prev)


func remove_subsurface(coord: Vector2i, cause: StringName) -> void:
    # mirror of remove_surface
    ...
```

### Public queries
```gdscript
func get_surface_owner(coord: Vector2i) -> StringName:
    if not _tiles.has(coord):
        return &""
    return _tiles[coord].get("surface_owner", &"")


func get_subsurface_owner(coord: Vector2i) -> StringName:
    if not _tiles.has(coord):
        return &""
    return _tiles[coord].get("subsurface_owner", &"")


func get_surface_owned_coords(kingdom_id: StringName = &"") -> Array[Vector2i]:
    # If kingdom_id is empty, return any-surface-owned. Else filter.
    var result: Array[Vector2i] = []
    for coord in _tiles.keys():
        var owner: StringName = _tiles[coord].get("surface_owner", &"")
        if owner == &"":
            continue
        if kingdom_id != &"" and owner != kingdom_id:
            continue
        result.append(coord)
    return result


func get_subsurface_owned_coords(kingdom_id: StringName = &"") -> Array[Vector2i]:
    # mirror
    ...


# Backward-compat for code not yet updated: returns surface coords if plantae run,
# subsurface if fungi run. Prefer the explicit getters above going forward.
func get_owned_coords() -> Array[Vector2i]:
    if GameState.current_kingdom_id == &"fungi":
        return get_subsurface_owned_coords(&"fungi")
    return get_surface_owned_coords(&"plantae")
```

### Hydration (`_on_run_loaded`)
Read each tile entry, set both layers in `_tiles` and on the grid:
```gdscript
for entry in tiles_raw:
    if not (entry is Dictionary):
        continue
    var coord := _parse_coord(entry.get("coord"))
    if coord == null:
        continue
    var surface_owner := StringName(entry.get("surface_owner", ""))
    var subsurface_owner := StringName(entry.get("subsurface_owner", ""))
    var data: Dictionary = entry.get("data", {}) as Dictionary
    _tiles[coord] = {"surface_owner": surface_owner, "subsurface_owner": subsurface_owner, "data": data}
    if surface_owner != &"":
        _tile_grid.set_surface_owner(coord, surface_owner)
    if subsurface_owner != &"":
        _tile_grid.set_subsurface_owner(coord, subsurface_owner)
```

### `_sync_run_save()`
Rebuild `run.tiles` using the new shape — `surface_owner` / `subsurface_owner` / `data`.

### `_gc_if_empty(coord)` and `_ensure_entry(coord)` helpers
- `_ensure_entry`: create the dict with both owners empty if it doesn't exist yet.
- `_gc_if_empty`: if both owners are `&""` after a removal, erase the entry to keep `_tiles` lean.

### Remove
- `OWNER_ID` const (now defined per-layer constants).
- `BASE_COLONIZE_COST` and `_get_colonize_cost()` — moves to PlantColonization.
- `_on_tile_tapped`, `_is_adjacent_to_owned` — move to PlantColonization.
- `lose_tile` (already mostly unused except by HerbivoreManager — update its callers per below).

## PlantColonization new file

```gdscript
extends Node

const KINGDOM_ID: StringName = &"plantae"
const BASE_COLONIZE_COST: float = 5.0

@onready var _territory: Node = get_node("../TerritorySystem")


func _ready() -> void:
    EventBus.tile_tapped.connect(_on_tile_tapped)


func _on_tile_tapped(coord: Vector2i) -> void:
    if GameState.input_mode != GameState.INPUT_MODE_COLONIZE:
        return
    if GameState.current_kingdom_id != KINGDOM_ID:
        return
    if _territory.get_surface_owner(coord) != &"":
        return  # already owned at the surface
    var owned: Array[Vector2i] = _territory.get_surface_owned_coords(KINGDOM_ID)
    if owned.size() > 0 and not _is_adjacent_to_owned_surface(coord, owned):
        return
    if owned.size() > 0:
        if not ResourceLedger.spend_bundle(_get_cost()):
            return
    var ok: bool = _territory.add_surface(coord, KINGDOM_ID)
    if ok:
        SaveSystem.save_now()


func _is_adjacent_to_owned_surface(coord: Vector2i, owned: Array[Vector2i]) -> bool:
    var s := {}
    for c in owned:
        s[c] = true
    for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
        if s.has(coord + offset):
            return true
    return false


func _get_cost() -> Dictionary:
    var cost: float = BASE_COLONIZE_COST
    if MetaModifiers.is_unlocked(&"thrifty_growth"):
        cost = 4.0
    return {ResourceLedger.BIOMASS: cost}
```

## Caller migration

### HerbivoreManager
- Replace `_territory.lose_tile(coord, ...)` with `_territory.remove_surface(coord, ...)`. Herbivores only attack the surface layer.
- Replace `_territory.get_owned_coords()` with `_territory.get_surface_owned_coords()` when searching for targets to chew. (Or leave `get_owned_coords` calls; the backward-compat shim handles them, but explicit is better.)

### NutrientSystem
- `get_owned_coords` calls: still work via shim. Prefer `get_surface_owned_coords()` (since biome yields go to plants currently). Phase 5 brief 04 (growth routing) will revisit this for fungi yields.

### GrowthSystem
- Same — works via shim. Brief 04 rewrites this.

### Tests
Add `tests/test_territory_system.gd` (or expand existing) covering:
- `add_surface` + `add_subsurface` on same tile (both succeed; both layers visible).
- `remove_surface` leaves subsurface intact; tile entry kept until both empty.
- `_gc_if_empty` removes the entry when both layers cleared.

## Acceptance criteria
- [ ] On existing plantae save: app launches, tiles render with green overlay only.
- [ ] Tapping a tile in a plantae run still colonizes (cost, adjacency, bootstrap all work via PlantColonization).
- [ ] `_territory.add_subsurface(coord, &"fungi")` adds violet overlay without affecting plant overlay.
- [ ] Herbivore Wave still chews tiles (`remove_surface` → tile_lost fires → biomass yield drops).
- [ ] No `owner_id` references remain in the codebase (`grep -rn "owner_id" scripts/` should return nothing apart from save migration code).
- [ ] Save schema on disk uses `surface_owner`/`subsurface_owner` keys.

## Out of scope
- FungiColonization (brief 06).
- GrowthSystem kingdom routing (brief 04).
- CorpseSystem (brief 05).
