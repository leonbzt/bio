# Brief 03 — Tile history rendering + soil_memory tile-local refactor

**Suggested agent**: ChatGPT 5.2 via Copilot. Route diff to Claude — balance/visual layer.

Read first:
1. `docs/briefs/phase_11/02_tile_history_persistence.md` (must land first).
2. `scripts/entities/tile_grid.gd` — current tile rendering.
3. `scripts/systems/growth_system.gd:111` — current `soil_memory` per-run yield bonus.
4. `data/evolution_tree/soil_memory.tres` — the node whose semantics change.

## Goal
Two related changes:
1. **Visual**: draw a faint pre-existing tint on tiles with non-empty history. Color is the wing color of the *most-recent* historical kingdom; alpha ~0.15. Drawn under the active-tile overlay so it doesn't fight current state.
2. **Balance**: `soil_memory` evolution node's 15% biomass bonus becomes **per-tile**, applying only when that tile's history includes `&"fungi"`. Drops the Phase 9 global-multiplier balance leak.

## Part 1 — Render history tint

### `scripts/entities/tile_grid.gd`

Find the tile-render path. Add a `_history_overlay_color` per-tile compute that returns the wing-color of the most-recent history entry, or transparent if no history.

```gdscript
const WING_COLORS: Dictionary = {
    &"plantae": Color(0.35, 0.78, 0.42, 1.0),
    &"fungi":   Color(0.62, 0.42, 0.85, 1.0),
    &"animals": Color(0.88, 0.68, 0.32, 1.0),
}
const HISTORY_TINT_ALPHA: float = 0.15

@onready var _territory: Node = get_node("../Systems/TerritorySystem")


func get_history_overlay_color(coord: Vector2i) -> Color:
    var history: Array[StringName] = _territory.get_tile_history(coord)
    if history.is_empty():
        return Color(0, 0, 0, 0)
    var most_recent: StringName = history[history.size() - 1]
    var base: Color = WING_COLORS.get(most_recent, Color(0.5, 0.5, 0.5, 1.0))
    return Color(base.r, base.g, base.b, HISTORY_TINT_ALPHA)
```

### Where to apply the tint

If `TileGrid` uses a TileMapLayer / TileMap with atlas variants, the tint is best applied as a per-tile modulate via `set_cell` with a TileSet that supports modulate or via a separate Sprite2D overlay node per tile.

If the project uses custom drawn tiles (Control._draw), call `draw_rect(tile_rect, get_history_overlay_color(coord))` after the base tile draw and before the owner-color overlay.

**The right integration point depends on the current tile-render implementation** — pick the path that matches what's there. The brief constraint is: history tint sits *under* the active-owner color visually (active owner alpha 1.0 always wins over history alpha 0.15).

### Refresh trigger

Tiles should re-tint when:
- The run is loaded (cold-load).
- A tile is colonized (a fresh history entry appears).

Connect to `EventBus.tile_colonized` and `EventBus.run_loaded` in `tile_grid.gd`. On these signals, redraw the affected tile (or the full grid for run_loaded).

## Part 2 — soil_memory tile-local refactor

### `scripts/systems/growth_system.gd`

Current (line ~111):
```gdscript
if kingdom_id == &"plantae" and MetaModifiers.is_unlocked(&"soil_memory"):
    per_tile *= 1.15
```

Replace with:
```gdscript
if kingdom_id == &"plantae" and MetaModifiers.is_unlocked(&"soil_memory"):
    if _territory.tile_has_history(coord, &"fungi"):
        per_tile *= 1.15
```

(`_territory` already injected in `growth_system.gd`.)

### Update node description

`data/evolution_tree/soil_memory.tres`:
- Current: `"Biomes that hosted past fungal runs yield 15% more biomass on plant colonization."`
- New: `"Plant tiles colonized on substrate that has previously hosted fungi yield 15% more biomass."`

### Update brief 03 cross-references

`docs/briefs/phase_9/04_author_cross_kingdom_nodes.md` — the `soil_memory` row's description should be updated to match. Find-replace, no semantic change to the brief.

### Tests

Append to `tests/test_growth_system.gd` (create if absent):

```gdscript
func test_soil_memory_tile_local() -> void:
    GameState.meta_save = {
        "evolution_tree": {"soil_memory": true},
        "tile_history": {
            "0,0": ["plantae"],
            "1,0": ["fungi", "plantae"]
        }
    }
    # ... arrange a single-tile run at each coord, run one tick, assert biomass yield ...
    # Tile (0,0): no fungi history → no bonus (baseline yield).
    # Tile (1,0): fungi in history → 15% bonus.
```

## Acceptance criteria

### Rendering
- [ ] After playing a plantae run that colonized tiles (1,1) and (2,2), prestiging, and starting a fungi run, those tiles show a faint green pre-existing tint.
- [ ] Same tile re-colonized in the new kingdom: tint stays faint-green underneath active fungi color.
- [ ] Empty tiles with no history: no tint.
- [ ] Performance: at full 32×48 grid with history on every tile, no measurable frame drop on Android target device. (Sanity-check via dev profiler.)

### Balance
- [ ] `soil_memory` purchased + plantae run on a tile with no fungi history → no bonus.
- [ ] `soil_memory` purchased + plantae run on a tile with fungi history → 1.15× biomass on that tile only.
- [ ] `soil_memory` NOT purchased: bonus never applies, regardless of history.
- [ ] Hover/long-press a tile (post-Phase-12 if no tooltip exists today) reveals history — *not blocking for Phase 11*.

## Out of scope
- Tile-history tooltip ("This tile was once fungi, then plantae"). Defer to Phase 12 polish.
- Multi-kingdom-blend tint (showing both fungi-green-faded *and* plantae-green-faded). v1 just uses most-recent.
- Animating the tint when a new history entry appears.
- Soil-memory for non-plantae kingdoms (could imagine fungi getting boosts on plant-history tiles; defer).
