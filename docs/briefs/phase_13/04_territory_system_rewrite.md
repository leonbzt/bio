# Brief 04 — TerritorySystem per-tile shape rewrite

**Suggested agent**: ChatGPT 5.2. Route diff to **Claude** — state correctness is the most fragile surface in the whole migration.

Read first:
1. `scripts/systems/territory_system.gd` — current shape (`surface_owner` / `subsurface_owner`).
2. `docs/SPECIES_MODEL.md` §Per-tile state — target shape (`occupants: Dictionary[StringName, StringName]`).
3. Every consumer of the current API: grep `get_surface_owner`, `get_subsurface_owner`, `add_surface`, `add_subsurface`, `get_surface_owned_coords`, `get_subsurface_owned_coords`, `get_owned_coords`. Expect hits in `growth_system`, `colonization_rules_registry`, `parasite_steal_system`, `parasite_decay_system`, `nutrient_system`, `herbivore_manager`, `animal_colonization`, `plant_colonization`, `fungi_colonization`, several UI files.

## Goal

Replace per-tile owner state with a `{kingdom_id → species_id}` dict. Keep the consumer API stable enough that brief 06 (rules) and brief 05 (growth) can land independently — i.e., add the new API first, deprecate the old, migrate consumers in subsequent briefs.

## New per-tile state

```gdscript
# Internal storage in TerritorySystem.
{
    Vector2i(x, y): {
        "occupants": {                       # kingdom_id → species_id
            &"plantae": &"pioneer_grass",
            &"fungi": &"mycelium_thread"
        },
        "data": {                            # arbitrary metadata (mycorrhizal_bond, parasite_decay_ticks, warmed_until_unix, etc.)
            "mycorrhizal_bond": true
        }
    }
}
```

Empty tiles are absent from the dict (existing GC behavior preserved).

## New API

```gdscript
# Returns true if added; false if slot already occupied or species_id invalid.
func add_occupant(coord: Vector2i, kingdom_id: StringName, species_id: StringName) -> bool

# Returns species_id at slot, or &"" if empty.
func get_occupant(coord: Vector2i, kingdom_id: StringName) -> StringName

# Removes the occupant of one slot. Emits tile_lost(coord, kingdom_id).
func remove_occupant(coord: Vector2i, kingdom_id: StringName, cause: StringName) -> void

# Returns the full occupants dict for a tile (or {}).
func get_occupants(coord: Vector2i) -> Dictionary

# Returns true if any species occupies the tile.
func is_tile_occupied(coord: Vector2i) -> bool

# Returns coords where kingdom_id slot is occupied (any species).
func get_kingdom_occupied_coords(kingdom_id: StringName) -> Array[Vector2i]

# Returns coords where the specific species occupies any slot.
func get_species_occupied_coords(species_id: StringName) -> Array[Vector2i]

# Returns all coords with any occupant.
func get_all_owned_coords() -> Array[Vector2i]
```

## Deprecated API (kept as shims during migration)

```gdscript
# Deprecated — returns kingdom_id of plantae or animals occupant (whichever
# is on the "surface"). Kept for backward-compat until briefs 05+06 migrate.
func get_surface_owner(coord: Vector2i) -> StringName:
    var occ: Dictionary = get_occupants(coord)
    if occ.has(&"animals"):
        return &"animals"
    if occ.has(&"plantae"):
        return &"plantae"
    return &""

func get_subsurface_owner(coord: Vector2i) -> StringName:
    if get_occupants(coord).has(&"fungi"):
        return &"fungi"
    return &""

# Deprecated — calls add_occupant with the kingdom's starter species.
func add_surface(coord: Vector2i, kingdom_id: StringName, variant: StringName = &"") -> bool:
    var species_id: StringName = _kingdom_starter(kingdom_id)
    if species_id == &"":
        return false
    return add_occupant(coord, kingdom_id, species_id)

func add_subsurface(coord: Vector2i, kingdom_id: StringName, variant: StringName = &"") -> bool:
    if kingdom_id != &"fungi":
        return false
    var species_id: StringName = _kingdom_starter(kingdom_id)
    return add_occupant(coord, kingdom_id, species_id)

# Deprecated — translate kingdom → coords.
func get_surface_owned_coords(kingdom_id: StringName = &"") -> Array[Vector2i]:
    if kingdom_id == &"":
        return get_all_owned_coords()
    return get_kingdom_occupied_coords(kingdom_id)

func get_subsurface_owned_coords(kingdom_id: StringName = &"") -> Array[Vector2i]:
    return get_kingdom_occupied_coords(kingdom_id == &"" ? &"fungi" : kingdom_id)

# Deprecated — replaced by GameState.run_save.starting_species_kingdom_id.
func get_owned_coords() -> Array[Vector2i]:
    var k: StringName = StringName(GameState.run_save.get("starting_species_kingdom_id", ""))
    if k == &"":
        return []
    return get_kingdom_occupied_coords(k)
```

Each deprecated function gets a one-line `# DEPRECATED — see brief 04` comment. Phase 14 deletes them after all consumers are migrated.

## Tile data API (unchanged shape, kept verbatim)

```gdscript
func set_tile_data(coord: Vector2i, key: String, value: Variant) -> void
func get_tile_data(coord: Vector2i, key: String, default = null) -> Variant
```

These are untouched — they operate on the per-tile `data` dict regardless of occupant shape.

## Save load + persistence

`_on_run_loaded` reads the v12 `tiles` array (shape from brief 01):

```gdscript
func _on_run_loaded(_save_version: int) -> void:
    _tiles.clear()
    if _tile_grid.has_method("clear_owned"):
        _tile_grid.clear_owned()

    var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
    var tiles_raw: Variant = run.get("tiles", [])
    if not (tiles_raw is Array):
        return
    for entry in tiles_raw:
        if not (entry is Dictionary):
            continue
        var coord_value: Variant = _parse_coord(entry.get("coord", []))
        if not (coord_value is Vector2i):
            continue
        var coord: Vector2i = coord_value
        var occupants_raw: Dictionary = entry.get("occupants", {}) as Dictionary
        var occupants: Dictionary = {}
        for k in occupants_raw.keys():
            occupants[StringName(k)] = StringName(occupants_raw[k])
        var data: Dictionary = entry.get("data", {}) as Dictionary
        _tiles[coord] = {
            "occupants": occupants,
            "data": data
        }
        # Push to TileGrid for rendering (rendering update in brief 09).
        for kingdom_id in occupants.keys():
            if _tile_grid.has_method("set_occupant"):
                _tile_grid.set_occupant(coord, kingdom_id, occupants[kingdom_id])
```

`_sync_run_save` serializes to the same v12 shape:

```gdscript
func _sync_run_save() -> void:
    var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
    var tiles_array: Array = []
    for coord in _tiles.keys():
        var entry: Dictionary = _tiles[coord] as Dictionary
        var occupants: Dictionary = entry.get("occupants", {}) as Dictionary
        if occupants.is_empty():
            continue
        var serialized: Dictionary = {}
        for k in occupants.keys():
            serialized[String(k)] = String(occupants[k])
        tiles_array.append({
            "coord": [coord.x, coord.y],
            "occupants": serialized,
            "data": entry.get("data", {})
        })
    run["tiles"] = tiles_array
    GameState.run_save = run
```

## Signal contract

- `EventBus.tile_colonized.emit(coord, kingdom_id)` — kept; emitted on `add_occupant` (kingdom_id of the new occupant).
- `EventBus.tile_lost.emit(coord, kingdom_id)` — kept; emitted on `remove_occupant`.
- **No new signals.** Consumers that care about species-specific colonization read `get_occupant(coord, kingdom_id)` after the signal fires.

## Starter-species helper

```gdscript
const _KINGDOM_DEFAULT_STARTERS: Dictionary[StringName, StringName] = {
    &"plantae": &"pioneer_grass",
    &"fungi": &"mycelium_thread",
    &"animals": &"common_grazer"
}

func _kingdom_starter(kingdom_id: StringName) -> StringName:
    return _KINGDOM_DEFAULT_STARTERS.get(kingdom_id, &"")
```

This is the fallback used by deprecated `add_surface` / `add_subsurface`. Brief 06's new colonization paths call `add_occupant(coord, kingdom_id, species_id)` directly with the actual species the player picked.

## Acceptance criteria

- [ ] New API methods (`add_occupant`, `get_occupant`, `remove_occupant`, `get_occupants`, `is_tile_occupied`, `get_kingdom_occupied_coords`, `get_species_occupied_coords`, `get_all_owned_coords`) all implemented + return correct values.
- [ ] Deprecated API methods still work as shims (callers continue to function until briefs 05+06 migrate them).
- [ ] Save load + save round-trip preserves all occupants and tile data.
- [ ] `EventBus.tile_colonized` + `tile_lost` fire on add/remove.
- [ ] Empty tiles GC'd as before.
- [ ] No regression: a Phase 12 plantae run loads and ticks correctly via the deprecated API shims.

## Out of scope

- Migrating consumers (`growth_system`, `colonization_rules_registry`, `parasite_steal_system`, etc.) to the new API — briefs 05, 06.
- Rendering update on TileGrid (brief 09 — `set_occupant` is a new method TileGrid implements there).
- Multi-species visual coexistence rules (brief 09).
- Deleting deprecated API methods (Phase 14).
