# Brief 05 — Tile maturation (life stages)

**Suggested agent**: ChatGPT 5.2. Route diff to **Claude** — yield math + visual.

Read first:
1. `scripts/systems/territory_system.gd._ensure_entry` — tile data dict.
2. `scripts/systems/growth_system.gd._apply_yields` — per-tile yield multiplier site.
3. `scripts/entities/tile_grid.gd._paint_fill` — color/saturation visual.
4. `docs/briefs/phase_15a/01_save_v15_migration.md` — `run.tile_ages` field.

## Goal

Tiles age in real time (ticks since placement). Three stages with different yield multipliers + a visual saturation that grows with age:

| Stage | Age (ticks) | Yield multiplier | Visual | Extra |
|---|---|---|---|---|
| Sprouting | 0-14 | ×0.5 | -30% saturation, slight transparency 0.85 | none |
| Mature | 15-59 | ×1.0 | full saturation | none |
| Ancient | 60+ | ×1.3 | full saturation + subtle inner glow | Fertilizer aura: +5% biomass to 4-neighbor tiles |

Ages reset on prestige; persist across save/load mid-run.

## TerritorySystem changes

Stamp the placed tick on every new occupant:

```gdscript
func add_occupant(coord: Vector2i, kingdom_id: StringName, species_id: StringName) -> bool:
    # ... existing checks ...
    var entry: Dictionary = _ensure_entry(coord)
    var occupants: Dictionary = entry.get("occupants", {}) as Dictionary
    if occupants.has(kingdom_id):
        return false
    occupants[kingdom_id] = species_id
    entry["occupants"] = occupants
    _tiles[coord] = entry
    _set_tile_age(coord, _current_tick())  # NEW
    # ... existing tile-grid + signal emission ...


func _set_tile_age(coord: Vector2i, tick: int) -> void:
    var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
    var ages: Dictionary = run.get("tile_ages", {}) as Dictionary
    ages["%d,%d" % [coord.x, coord.y]] = tick
    run["tile_ages"] = ages


func get_tile_placed_tick(coord: Vector2i) -> int:
    var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
    var ages: Dictionary = run.get("tile_ages", {}) as Dictionary
    return int(ages.get("%d,%d" % [coord.x, coord.y], _current_tick()))


func _current_tick() -> int:
    var stats: Dictionary = GameState.run_save.get("statistics", {}) as Dictionary
    return int(stats.get("tick_count", 0))
```

(If `tick_count` is tracked elsewhere, route accordingly — TickClock might own it.)

## GrowthSystem maturation multiplier

In `_apply_yields`, after biome + trait multipliers, before the resource-multiplier registry from brief 02:

```gdscript
# Phase 15a: tile maturation multiplier.
var age_ticks: int = _current_tick() - _territory.get_tile_placed_tick(coord)
var maturation_mult: float = _maturation_yield_multiplier(age_ticks)
per_tile *= maturation_mult
```

Helper:

```gdscript
const SPROUTING_DURATION: int = 15
const MATURE_DURATION: int = 45     # mature lasts 45 ticks (15-59 total = 60 ticks before Ancient)

func _maturation_yield_multiplier(age_ticks: int) -> float:
    if age_ticks < SPROUTING_DURATION:
        return 0.5
    if age_ticks < SPROUTING_DURATION + MATURE_DURATION:
        return 1.0
    return 1.3
```

## Ancient fertilizer aura

In `_apply_yields`, after `maturation_mult`, if any neighbor is ancient AND of the same species/kingdom, bump biomass by +5%:

```gdscript
if resource_key == &"biomass" and _has_ancient_neighbor_of_same_kingdom(coord, kingdom_id):
    per_tile *= 1.05
```

Helper:

```gdscript
func _has_ancient_neighbor_of_same_kingdom(coord: Vector2i, kingdom_id: StringName) -> bool:
    for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
        var neighbor: Vector2i = coord + offset
        var occ: Dictionary = _territory.get_occupants(neighbor)
        if not occ.has(kingdom_id):
            continue
        var neighbor_age: int = _current_tick() - _territory.get_tile_placed_tick(neighbor)
        if neighbor_age >= SPROUTING_DURATION + MATURE_DURATION:
            return true
    return false
```

## TileGrid visual

In `_paint_fill`, after computing `fill_color`, modulate by age:

```gdscript
# Phase 15a: maturation visual. Sprouting tiles are dim + slightly transparent.
var age_ticks: int = _current_tick() - _territory.get_tile_placed_tick(coord)
var saturation: float = 0.7 if age_ticks < SPROUTING_DURATION else 1.0
var alpha: float = 0.85 if age_ticks < SPROUTING_DURATION else 1.0
fill_color.s *= saturation   # HSV-ish blend; use .lerp(Color.WHITE, 0.3) if .s direct mutation is awkward
fill_color.a = alpha
```

For Ancient tiles add a subtle inner glow (small inset ColorRect at 30% alpha lightened color), or skip for v1 if scope-tight.

To keep the visual current as tiles age, hook into `EventBus.tick` and trigger `queue_redraw()` or per-tile `_repaint_tile` periodically. Cheaper: just repaint when crossing a stage boundary. Brief notes: every ~5 ticks, sample owned tiles and repaint if their stage changed.

```gdscript
func _on_tick_age_refresh(_delta: float) -> void:
    var current_tick: int = _current_tick()
    if current_tick % 5 != 0:
        return
    for coord in _tile_occupants.keys():
        _repaint_tile(coord)
```

(Performance: O(N) every 5 ticks; with 200 tiles → 40 ops/sec. Negligible.)

## Acceptance criteria

- [ ] New tiles placed at tick T get `tile_ages["x,y"] = T`.
- [ ] Tiles aged < 15 ticks yield ×0.5 of base.
- [ ] Tiles aged 15-59 ticks yield ×1.0.
- [ ] Tiles aged 60+ yield ×1.3.
- [ ] Ancient tiles boost adjacent same-kingdom tiles' biomass by +5%.
- [ ] Sprouting tiles render dimmer + slightly transparent.
- [ ] Mature/Ancient tiles render at full saturation; Ancient ideally gets a subtle glow.
- [ ] Stage transitions visually update within ~5 ticks of crossing the boundary.
- [ ] Save round-trip preserves tile ages.
- [ ] No regression in tick perf on a 200-tile run.

## Out of scope

- Ancient bonus extending diagonally (only 4-neighbor for v1).
- Per-species maturation curves (uniform across all species in v1).
- Maturation events (e.g., "your first Ancient tile" milestone — parked for tier-up banners later).
- Smooth color tween between stages (snap-on-stage-change is fine for v1).
