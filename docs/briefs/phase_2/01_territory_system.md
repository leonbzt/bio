# Brief 01 — TerritorySystem + TileInputRouter

**Suggested agent**: ChatGPT 5.2 via Copilot.

Read first:
1. `docs/ARCHITECTURE.md` — sections 3 (`EventBus` signals especially `tile_tapped`, `tile_colonized`, `tile_lost`), 5 (system map), 6 (scene composition), 7 (input model).
2. `scripts/autoloads/event_bus.gd` — to confirm new signal names.
3. `scripts/entities/tile_grid.gd` — to confirm grid dimensions and `set_cell(layer, ...)` usage.
4. `scripts/autoloads/game_state.gd` — for `run_save.tiles` shape (see `_build_default_save()` in `save_system.gd`).

## Goal
Two new systems:

1. **`TileInputRouter`** — detects single-finger taps on the world (not on UI), converts screen → tile coord, emits `EventBus.tile_tapped(coord)`. Distinguishes tap from drag by tracking total motion distance.

2. **`TerritorySystem`** — owns the live tile-ownership state. On `tile_tapped`, validates colonization (adjacency + resource cost) and emits `tile_colonized`. On `run_loaded`, hydrates state from `GameState.run_save.tiles`. Mutations also write back to `GameState.run_save.tiles` so saves capture state.

Ownership is rendered as an overlay layer on the existing TileMap (layer 1).

## Outputs (create)
- `scripts/systems/tile_input_router.gd`
- `scripts/systems/territory_system.gd`
- Modifications to `scenes/world/world.tscn` to add both nodes under `Systems`.
- Modifications to `scripts/entities/tile_grid.gd` to support a layer-1 overlay (add a second atlas tile in a contrasting brighter green).

## TileInputRouter — implementation notes
- `Node` attached to world. Uses `_unhandled_input` so UI eats events first.
- On `InputEventScreenTouch` with `pressed = true`: record `_press_pos: Vector2`, `_press_index: int`, `_moved: float = 0.0`.
- On `InputEventScreenDrag`: if `index == _press_index`, add `event.relative.length()` to `_moved`.
- On `InputEventScreenTouch` with `pressed = false` and `index == _press_index`: if `_moved <= 8.0` (px), treat as tap.
- Tap → convert screen position to tile coord via `TileGrid.local_to_map(TileGrid.to_local(get_tree().root.get_camera_2d().get_global_mouse_position()))`. Clamp to grid bounds; if out of range, ignore.
- Emit `EventBus.tile_tapped(coord)`.
- Multi-touch: pinch (size ≥ 2 simultaneous) → cancel tap detection.
- Desktop mouse: same path via `InputEventMouseButton` (left) for testing in editor.

## TerritorySystem — implementation notes
- `Node`. Two responsibilities: live state + colonization logic.
- Backing store: `var _tiles: Dictionary[Vector2i, Dictionary] = {}`. Entry shape mirrors save: `{"owner_id": StringName, "data": Dictionary}`.
- Define a const `COLONIZE_COST: Dictionary = {ResourceLedger.BIOMASS: 5.0}` for now. This will move into `KingdomData`/`SpeciesData` in later phases — for Phase 2 it stays inline. Add a `# TODO Phase 4: move into KingdomData` comment.
- `OWNER_ID: StringName = &"plantae"` const for now. Same TODO note.
- On `_ready()`: connect `EventBus.run_loaded.connect(_on_run_loaded)`, `EventBus.tile_tapped.connect(_on_tile_tapped)`.
- `_on_run_loaded(_v)`: clear `_tiles`. Iterate `GameState.run_save.get("tiles", [])`, populate `_tiles`, and call `_paint_overlay(coord, owner_id)` for each. Do NOT emit `tile_colonized` during hydration — that would re-trigger downstream systems for tiles that aren't fresh.
- `_on_tile_tapped(coord)`:
  - If `_tiles.has(coord)`: ignore (already owned).
  - If `not _is_adjacent_to_owned(coord)` AND `_tiles.size() > 0`: ignore. (Bootstrap: if zero tiles owned, first tap allowed anywhere.)
  - If `not ResourceLedger.spend_bundle(COLONIZE_COST)`: ignore (insufficient).
  - Otherwise: insert into `_tiles`, write-through to `GameState.run_save.tiles`, paint overlay, emit `EventBus.tile_colonized(coord, OWNER_ID)`.
- `_is_adjacent_to_owned(coord)`: check 4-neighbor (N/S/E/W) presence in `_tiles`.
- Provide `func reset_run() -> void`: clears `_tiles`, repaints overlay (clear layer 1), updates `GameState.run_save.tiles`. Called by PrestigeSystem in Phase 4 — public method only.
- Write-through: a helper `_sync_run_save()` rebuilds `GameState.run_save["tiles"]` from `_tiles` after every mutation. Keeps save in sync without explicit "before save" hooks.

## TileGrid overlay
- Add a second atlas tile in `_build_tileset()`: brighter green (e.g. `#6cb86c`) with same 16×16 size. Use `atlas.create_tile(Vector2i(1, 0))` and define a const `OVERLAY_ATLAS_COORD := Vector2i(1, 0)`.
- Expose `func set_owned(coord: Vector2i, owned: bool)`:
  - `owned = true` → `set_cell(1, coord, SOURCE_ID, OVERLAY_ATLAS_COORD)`
  - `owned = false` → `erase_cell(1, coord)`
- Layer 0 (base) stays untouched.

## Acceptance criteria
- [ ] Tapping a tile with no prior ownership colonizes it (first tap = bootstrap).
- [ ] Subsequent colonization requires adjacency (N/S/E/W only — no diagonals).
- [ ] Each colonization costs 5 biomass via `spend_bundle`. Insufficient biomass = no-op.
- [ ] Owned tiles display the brighter overlay.
- [ ] After app restart, owned tiles persist visually and in `_tiles` (verified by inspecting `GameState.run_save.tiles` in the debugger).
- [ ] `tile_colonized` fires exactly once per real colonization, never during hydration.
- [ ] No direct system imports — only autoloads + EventBus.
- [ ] Pan/zoom still work (TileInputRouter doesn't eat drag events).

## Out of scope
- Multiple kingdoms (one OWNER_ID for now).
- Tile data (`data` field stays empty `{}` — used by Phase 5+ for per-tile biome assignment, fungus/plant coexistence).
- Visual polish — colored squares only.
