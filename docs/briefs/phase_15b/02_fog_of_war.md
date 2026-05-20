# Brief 02 — Fog of war (system + render)

**Suggested agent**: ChatGPT 5.2. Route diff to **Claude** — perf-sensitive on 1500-tile grid.

Read first:
1. `scripts/entities/tile_grid.gd` — existing fill/border/edge overlay pattern.
2. `scripts/systems/territory_system.gd.add_occupant` — colonization hook for reveal.

## Goal

Tiles start hidden behind a dark overlay. Colonizing a tile reveals it + the surrounding 4×4 area (radius 2 in each direction). Revealed stays revealed for the run; resets on prestige.

Reveal radius = 2 in each direction → 5×5 = 25 tiles revealed per placement (5 wide × 5 tall including center). (Phrased "4×4" colloquially per the user's spec; effectively radius 2.)

## New system

`scripts/systems/fog_system.gd` (mounted under World/Systems):

```gdscript
extends Node

const REVEAL_RADIUS: int = 2

var _revealed: Dictionary[Vector2i, bool] = {}

@onready var _tile_grid: Node = get_node("../../TileGrid")
@onready var _territory: Node = get_node("../TerritorySystem")


func _ready() -> void:
    EventBus.run_loaded.connect(_on_run_loaded)
    EventBus.tile_colonized.connect(_on_tile_colonized)
    if not GameState.run_save.is_empty():
        _on_run_loaded(SaveSystem.SAVE_VERSION)


func _on_run_loaded(_v: int) -> void:
    _revealed.clear()
    var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
    var raw: Array = run.get("fog_revealed", []) as Array
    for k in raw:
        var coord: Vector2i = _parse_coord(String(k))
        _revealed[coord] = true
    _push_to_tile_grid()


func _on_tile_colonized(coord: Vector2i, _owner_id: StringName) -> void:
    reveal_area(coord, REVEAL_RADIUS)


func reveal_area(center: Vector2i, radius: int) -> void:
    var newly_revealed: Array[Vector2i] = []
    for dy in range(-radius, radius + 1):
        for dx in range(-radius, radius + 1):
            var c: Vector2i = Vector2i(center.x + dx, center.y + dy)
            if not _is_in_bounds(c):
                continue
            if _revealed.has(c):
                continue
            _revealed[c] = true
            newly_revealed.append(c)
    if newly_revealed.is_empty():
        return
    _persist()
    if _tile_grid.has_method("reveal_tiles"):
        _tile_grid.reveal_tiles(newly_revealed)


func is_revealed(coord: Vector2i) -> bool:
    return _revealed.has(coord)


func get_revealed_count() -> int:
    return _revealed.size()


func _is_in_bounds(c: Vector2i) -> bool:
    return c.x >= 0 and c.y >= 0 and c.x < _tile_grid.GRID_WIDTH and c.y < _tile_grid.GRID_HEIGHT


func _persist() -> void:
    var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
    var arr: Array = []
    for c in _revealed.keys():
        arr.append("%d,%d" % [c.x, c.y])
    run["fog_revealed"] = arr


func _push_to_tile_grid() -> void:
    if not _tile_grid.has_method("set_fog_state"):
        return
    var arr: Array[Vector2i] = []
    for c in _revealed.keys():
        arr.append(c)
    _tile_grid.set_fog_state(arr)


func _parse_coord(s: String) -> Vector2i:
    var parts := s.split(",", false)
    if parts.size() != 2:
        return Vector2i.ZERO
    return Vector2i(int(parts[0]), int(parts[1]))
```

Register in `scenes/world/world.tscn` under `World/Systems/FogSystem`.

## TileGrid fog overlay

Add a single Node2D child of TileGrid that draws a dark rect for every UN-revealed tile. Use `_draw()` for one-pass rendering (same pattern as `_EdgesOverlay`).

```gdscript
# In tile_grid.gd:
const FOG_COLOR: Color = Color(0.04, 0.04, 0.06, 1.0)
const FOG_EDGE_COLOR: Color = Color(0.08, 0.08, 0.10, 1.0)
var _fog_overlay: _FogOverlay
var _revealed_set: Dictionary[Vector2i, bool] = {}


class _FogOverlay extends Node2D:
    var tile_grid
    func _draw() -> void:
        if tile_grid == null:
            return
        for y in range(tile_grid.GRID_HEIGHT):
            for x in range(tile_grid.GRID_WIDTH):
                var c := Vector2i(x, y)
                if tile_grid._revealed_set.has(c):
                    continue
                var origin: Vector2 = tile_grid.map_to_local(c) - Vector2(tile_grid.TILE_SIZE * 0.5, tile_grid.TILE_SIZE * 0.5)
                draw_rect(Rect2(origin, Vector2(tile_grid.TILE_SIZE, tile_grid.TILE_SIZE)), tile_grid.FOG_COLOR, true)


# In _ready, after _overlay_layer setup:
_fog_overlay = _FogOverlay.new()
_fog_overlay.name = "FogOverlay"
_fog_overlay.tile_grid = self
_fog_overlay.z_index = 4   # above everything else
_overlay_layer.add_child(_fog_overlay)


func set_fog_state(revealed: Array[Vector2i]) -> void:
    _revealed_set.clear()
    for c in revealed:
        _revealed_set[c] = true
    _fog_overlay.queue_redraw()


func reveal_tiles(coords: Array[Vector2i]) -> void:
    for c in coords:
        _revealed_set[c] = true
    _fog_overlay.queue_redraw()
```

## Placement rejection on hidden tiles

`ColonizationRulesRegistry` should reject placement on un-revealed tiles. Add a global pre-check at the top of `evaluate(coord, species)`:

```gdscript
var fog: Node = _get_fog_system()
if fog != null and fog.has_method("is_revealed") and not fog.is_revealed(coord):
    return _invalid()


func _get_fog_system() -> Node:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null:
        return null
    return tree.root.get_node_or_null("World/Systems/FogSystem")
```

## Initial reveal on run start

When a new run begins, the player has no tiles yet — the whole map is dark. **Reveal a small starting area** so the player has something to tap into. Add to `FogSystem._on_run_loaded` (after loading saved state):

```gdscript
# If nothing revealed yet (fresh run), reveal a central 5×5 starting zone.
if _revealed.is_empty():
    var cx: int = int(_tile_grid.GRID_WIDTH / 2)
    var cy: int = int(_tile_grid.GRID_HEIGHT / 2)
    reveal_area(Vector2i(cx, cy), 2)
```

Or pick the starting reveal location based on the ecosystem (e.g., near a non-obstacle tile). For v1, center is fine.

## Perf

- 32×48 = 1536 tiles. Drawing 1500 rects per repaint is borderline.
- `_fog_overlay.queue_redraw()` only triggers on reveal events (not every tick) → fine.
- If 1500 rects/frame is too slow, optimize to draw only unrevealed tiles within camera viewport, OR use a single Image as a dark texture and punch holes at revealed tiles (Phase 16+ polish).

## Acceptance criteria

- [ ] `FogSystem` mounted under World/Systems.
- [ ] Fresh run: only a 5×5 center area is visible; rest is dark.
- [ ] Colonizing a tile reveals it + 5×5 around it.
- [ ] Reveals persist across save/load within a run.
- [ ] Reveals reset on prestige.
- [ ] Placement on hidden tiles rejected by ColonizationRulesRegistry.
- [ ] Fog overlay renders without flickering.
- [ ] No perf drop on a fresh run (max fog rect count).

## Out of scope

- Animated reveal (snap reveal in v1).
- Per-species reveal radius (uniform radius 2 in v1).
- Reveal abilities (Scout ability, etc.) — Phase 16+.
- Mini-map showing fog state — future polish.
- Camera-clipping optimization (Phase 16+ if needed).
