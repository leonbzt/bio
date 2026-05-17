# Brief 02 — Tile history persistence (TerritorySystem + API)

**Suggested agent**: ChatGPT 5.2 via Copilot. Route diff to Claude — touches a system contract.

Read first:
1. `docs/briefs/phase_11/00_phase_11_entry.md` decision 3 (`meta.tile_history` keying).
2. `scripts/systems/territory_system.gd` — current `add_surface`/`add_subsurface` are the write points.
3. `scripts/autoloads/save_system.gd` — `meta.tile_history` must already be in default save (brief 01).
4. `scripts/autoloads/game_state.gd` — where the meta accessor lives.

## Goal
Every time a tile gains a kingdom in any layer, record that kingdom in `meta.tile_history[coord_key]`. This survives prestige (per brief 01, `_reset_run_state` does NOT clear it). Expose two public read methods so other systems (yield bonuses, rendering) can query history without grepping the dictionary directly.

## Outputs

### Extend `scripts/systems/territory_system.gd`

Add a private helper that updates the meta dict and dedups:

```gdscript
func _record_history(coord: Vector2i, kingdom_id: StringName) -> void:
    if kingdom_id == &"":
        return
    var meta: Dictionary = GameState.meta_save
    var history: Dictionary = meta.get("tile_history", {}) as Dictionary
    var key: String = "%d,%d" % [coord.x, coord.y]
    var entry_raw: Variant = history.get(key, [])
    var entry: Array = entry_raw as Array
    var kid_str: String = String(kingdom_id)
    if not entry.has(kid_str):
        entry.append(kid_str)
        history[key] = entry
        meta["tile_history"] = history
        # Save is debounced — let the natural save_now in add_surface/subsurface persist this.
```

Call it from `add_surface` and `add_subsurface` after the owner has been set successfully:

```gdscript
func add_surface(coord: Vector2i, kingdom_id: StringName, variant: StringName = &"") -> bool:
    # ... existing checks + state updates ...
    entry["surface_owner"] = kingdom_id
    # ... existing data + tile_grid updates ...
    _record_history(coord, kingdom_id)    # NEW — must come before _sync_run_save so meta is persisted together
    _sync_run_save()
    EventBus.tile_colonized.emit(coord, kingdom_id)
    return true
```

Same pattern in `add_subsurface`.

Add public read methods at the end of the class:

```gdscript
func get_tile_history(coord: Vector2i) -> Array[StringName]:
    var meta: Dictionary = GameState.meta_save
    var history: Dictionary = meta.get("tile_history", {}) as Dictionary
    var key: String = "%d,%d" % [coord.x, coord.y]
    var raw: Variant = history.get(key, [])
    if not (raw is Array):
        return []
    var result: Array[StringName] = []
    for kid in raw:
        result.append(StringName(kid))
    return result


func tile_has_history(coord: Vector2i, kingdom_id: StringName) -> bool:
    var meta: Dictionary = GameState.meta_save
    var history: Dictionary = meta.get("tile_history", {}) as Dictionary
    var key: String = "%d,%d" % [coord.x, coord.y]
    var raw: Variant = history.get(key, [])
    if not (raw is Array):
        return false
    return (raw as Array).has(String(kingdom_id))
```

### `_sync_run_save` is the persistence trigger

`_sync_run_save` writes `run.tiles` and indirectly triggers `SaveSystem.save_now` via the calling system's save chain. Since `meta.tile_history` is read live from `GameState.meta_save`, and `SaveSystem._build_save_dict` reads from `GameState.meta_save`, no additional code path is needed — the next `save_now` call captures the updated history.

**Sanity**: confirm by inspecting `save.json` after colonizing a tile — `meta.tile_history` should have a new entry.

## ARCHITECTURE.md updates

§5 system map — extend the `TerritorySystem` row to mention history persistence.
§9 save schema history — append v8 → v9 row.

## Tests

Append to `tests/test_territory_system.gd` (create if it doesn't exist, mirroring `test_save_system.gd`):

```gdscript
func test_add_surface_records_history() -> void:
    GameState.meta_save = {"tile_history": {}}
    GameState.run_save = {"tiles": []}
    var ts: Node = preload("res://scripts/systems/territory_system.gd").new()
    # Stand-in TileGrid that no-ops the setter calls so add_surface can complete.
    ts._tile_grid = _make_noop_tile_grid()
    ts.add_surface(Vector2i(3, 4), &"plantae")
    var history: Array = GameState.meta_save["tile_history"]["3,4"]
    assert_true(history.has("plantae"))


func test_history_survives_prestige() -> void:
    GameState.meta_save = {"tile_history": {"1,1": ["fungi"]}}
    GameState.run_save = {"tiles": []}
    PrestigeSystem._reset_run_state()
    # Tile history must NOT be cleared.
    assert_true(GameState.meta_save["tile_history"].has("1,1"))
    assert_true(GameState.meta_save["tile_history"]["1,1"].has("fungi"))


func test_history_dedups_repeat_colonization() -> void:
    GameState.meta_save = {"tile_history": {}}
    GameState.run_save = {"tiles": []}
    var ts: Node = preload("res://scripts/systems/territory_system.gd").new()
    ts._tile_grid = _make_noop_tile_grid()
    ts.add_surface(Vector2i(0, 0), &"plantae")
    # Simulate tile lost + re-colonized
    ts.remove_surface(Vector2i(0, 0), &"test")
    ts.add_surface(Vector2i(0, 0), &"plantae")
    assert_eq(GameState.meta_save["tile_history"]["0,0"].size(), 1)
```

(Helper `_make_noop_tile_grid` returns a `Node` with stub `set_surface_owner`/`set_subsurface_owner` methods.)

## Acceptance criteria
- [ ] Colonizing a tile records the kingdom in `meta.tile_history`.
- [ ] `get_tile_history(coord)` returns the recorded kingdoms.
- [ ] `tile_has_history(coord, kingdom_id)` returns true/false correctly.
- [ ] Re-colonizing the same tile with the same kingdom does NOT duplicate the entry.
- [ ] Both surface and subsurface colonization record into the same per-coord history.
- [ ] Prestige preserves `meta.tile_history` (regression: `_reset_run_state` already does not touch meta, just confirm).
- [ ] Inspect `save.json` after a play session: `meta.tile_history` is populated.

## Out of scope
- Rendering the history (brief 03).
- Yield logic that reads history (brief 03 also handles soil_memory refactor).
- A "tile inspect" tooltip showing history (deferred, brief 00 out-of-scope list).
- Removing tiles from history when they're lost — history is append-only by design (the world remembers).
