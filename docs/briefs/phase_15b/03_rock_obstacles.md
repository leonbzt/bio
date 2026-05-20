# Brief 03 — Rock obstacles (deterministic generation + render)

**Suggested agent**: ChatGPT 5.2. Route diff to Claude.

Read first:
1. `scripts/entities/tile_grid.gd._build_atlas_texture` — atlas tile drawing pattern.
2. `scripts/systems/territory_system.gd` — tile state.
3. `scripts/systems/colonization_rules_registry.gd.evaluate` — placement-rejection point.

## Goal

Generate ~5% of map tiles as impassable rock obstacles, deterministically from `run_seed`. Render as a distinct dark gray atlas tile. Block placement on rock tiles. Rocks regenerate per ecosystem (same as biome map).

## New system

`scripts/systems/obstacle_system.gd` (mounted under World/Systems):

```gdscript
extends Node

const OBSTACLE_RATE: float = 0.05    # ~5% of map
const GRID_W: int = 32
const GRID_H: int = 48

var _obstacles: Dictionary[Vector2i, bool] = {}

@onready var _tile_grid: Node = get_node("../../TileGrid")
@onready var _territory: Node = get_node("../TerritorySystem")


func _ready() -> void:
    EventBus.run_loaded.connect(_on_run_loaded)
    if not GameState.run_save.is_empty():
        _on_run_loaded(SaveSystem.SAVE_VERSION)


func _on_run_loaded(_v: int) -> void:
    _obstacles.clear()
    var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
    var raw: Array = run.get("obstacles", []) as Array
    if raw.is_empty():
        # Generate deterministically from run_seed.
        var generated: Array = _generate_obstacles(int(GameState.run_seed))
        for s in generated:
            _obstacles[_parse_coord(String(s))] = true
        run["obstacles"] = generated
        GameState.run_save = run
        SaveSystem.save_now()
    else:
        for s in raw:
            _obstacles[_parse_coord(String(s))] = true

    # Don't place rocks on tiles that are already owned (existing run carryover).
    if _territory.has_method("is_tile_occupied"):
        var purged: Array = []
        for c in _obstacles.keys():
            if _territory.is_tile_occupied(c):
                continue
            purged.append(c)
        _obstacles.clear()
        for c in purged:
            _obstacles[c] = true

    _push_to_tile_grid()


func is_obstacle(coord: Vector2i) -> bool:
    return _obstacles.has(coord)


static func _generate_obstacles(seed: int) -> Array:
    var rng := RandomNumberGenerator.new()
    rng.seed = seed
    var out: Array = []
    for y in range(GRID_H):
        for x in range(GRID_W):
            if rng.randf() < OBSTACLE_RATE:
                out.append("%d,%d" % [x, y])
    return out


func _push_to_tile_grid() -> void:
    if not _tile_grid.has_method("set_obstacles"):
        return
    var arr: Array[Vector2i] = []
    for c in _obstacles.keys():
        arr.append(c)
    _tile_grid.set_obstacles(arr)


func _parse_coord(s: String) -> Vector2i:
    var parts := s.split(",", false)
    if parts.size() != 2:
        return Vector2i.ZERO
    return Vector2i(int(parts[0]), int(parts[1]))
```

Register in `scenes/world/world.tscn` under `World/Systems/ObstacleSystem`. Mount **after** TerritorySystem (so `is_tile_occupied` works on load).

## Atlas tile for rock

Extend `tile_grid.gd._build_atlas_texture` to add a 7th tile (`ATLAS_BIOME_ROCK = Vector2i(7, 0)`):

```gdscript
const ATLAS_BIOME_ROCK: Vector2i = Vector2i(7, 0)

# In _build_tileset:
atlas.create_tile(ATLAS_BIOME_ROCK)

# Extend atlas width to TILE_SIZE * 7 in _build_atlas_texture.
# Add a draw call for the rock:
_draw_biome_tile(
    atlas_image,
    Vector2i(TILE_SIZE * 7, 0),
    Color8(0x55, 0x55, 0x55),    # mid-gray body
    Color8(0x2a, 0x2a, 0x2c),    # near-black border
    era_tint,
    0.05,                          # less era-tinted (rocks are rocks)
    false
)
```

Don't forget to update atlas width: `+ TILE_SIZE * 7` instead of `* 6`.

## TileGrid renders obstacles

```gdscript
var _obstacle_set: Dictionary[Vector2i, bool] = {}


func set_obstacles(coords: Array[Vector2i]) -> void:
    _obstacle_set.clear()
    for c in coords:
        _obstacle_set[c] = true
    _populate_base_from_biomes()    # repaint base layer


# Modify _atlas_for_coord to check obstacles first:
func _atlas_for_coord(coord: Vector2i) -> Vector2i:
    if _obstacle_set.has(coord):
        return ATLAS_BIOME_ROCK
    var nutrients: Node = _get_nutrient_system()
    if nutrients == null or not nutrients.has_method("get_biome_at"):
        return ATLAS_BASE
    var biome: BiomeData = nutrients.get_biome_at(coord)
    if biome == null:
        return ATLAS_BASE
    return BIOME_ATLAS_BY_ID.get(biome.id, ATLAS_BASE)
```

## Reject placement on obstacles

Add to `ColonizationRulesRegistry.evaluate` (same global pre-check spot as fog):

```gdscript
var obstacles: Node = _get_obstacle_system()
if obstacles != null and obstacles.has_method("is_obstacle") and obstacles.is_obstacle(coord):
    return _invalid()


func _get_obstacle_system() -> Node:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null:
        return null
    return tree.root.get_node_or_null("World/Systems/ObstacleSystem")
```

## Don't generate obstacles inside the starting reveal area

If the rock generator hits the central starting reveal area, the player can't expand. Two options:

(a) Filter rocks within radius 3 of map center.
(b) Reroll until the central 5×5 is clear.

Recommend (a): cheaper, deterministic.

```gdscript
# In _generate_obstacles, skip if in starting clear zone:
var cx: int = int(GRID_W / 2)
var cy: int = int(GRID_H / 2)
const START_CLEAR_RADIUS: int = 3

for y in range(GRID_H):
    for x in range(GRID_W):
        if abs(x - cx) <= START_CLEAR_RADIUS and abs(y - cy) <= START_CLEAR_RADIUS:
            continue
        if rng.randf() < OBSTACLE_RATE:
            out.append("%d,%d" % [x, y])
```

## Acceptance criteria

- [ ] `ObstacleSystem` mounted under World/Systems.
- [ ] On run start, ~5% of map tiles (excluding 7×7 central zone) become rocks.
- [ ] Same `run_seed` produces identical rock layout.
- [ ] Rocks render in dark gray, distinct from any biome.
- [ ] Placement on rock rejected (`ColonizationRulesRegistry.evaluate` returns invalid).
- [ ] Existing owned tiles are NOT overwritten by rocks (rock generator skips them).
- [ ] Rocks persist across save/load within a run.
- [ ] Rocks regenerate (different layout) on a new run with new seed.

## Out of scope

- Rocks visually clustered (organic-feeling). Current uniform-random distribution is OK for v1.
- Conditional obstacles (water, ice) — Phase 16+.
- Destructible obstacles — Phase 16+.
- Rocks affecting cluster connectivity for structures (Brief 05 doesn't bridge over rocks — that's fine).
- Special rock variants per biome.
