# Brief 04 — Tile pulse on production tick

**Suggested agent**: ChatGPT 5.2. Route diff to Claude.

Read first:
1. `scripts/entities/tile_grid.gd._paint_fill` — current ColorRect overlay pattern.
2. `scripts/systems/growth_system.gd` — emits no per-tile production signal; will need a hook.

## Goal

When a tile produces yields on a tick, briefly pulse its fill (slight brightness bump for ~150ms). Throttle to ~10% of ticks per tile so the effect reads as "life happening" rather than constant flicker. Pure visual; no gameplay impact.

## Approach

Option A (cheap): random sampling — for each owned tile, on each tick, 10% chance to pulse.

Option B (driven by yield): hook into GrowthSystem after applying yields, sample the cluster, pulse a random tile within it.

Both work. **Recommend A** for simplicity — no system coupling, just a visual layer on TileGrid that listens to ticks.

## Implementation

### `scripts/entities/tile_grid.gd`

```gdscript
const PULSE_CHANCE: float = 0.10        # 10% of owned tiles pulse per tick
const PULSE_DURATION: float = 0.15      # seconds
const PULSE_BRIGHTNESS_BUMP: float = 0.35
var _pulse_rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
    # ... existing setup ...
    _pulse_rng.randomize()
    EventBus.tick.connect(_on_tick_pulse)


func _on_tick_pulse(_delta: float) -> void:
    # Sample a fraction of owned tiles to pulse this tick.
    for coord in _fill_nodes.keys():
        if _pulse_rng.randf() > PULSE_CHANCE:
            continue
        _pulse_tile(coord)


func _pulse_tile(coord: Vector2i) -> void:
    var fill: ColorRect = _fill_nodes.get(coord, null)
    if fill == null:
        return
    var base_color: Color = fill.color
    var bright_color: Color = base_color.lightened(PULSE_BRIGHTNESS_BUMP)
    var tween := create_tween()
    fill.color = bright_color
    tween.tween_property(fill, "color", base_color, PULSE_DURATION)
```

## Perf consideration

Creating a Tween per pulse, throttled to ~10% of owned tiles per tick:
- 200 owned tiles × 10% = 20 tweens / tick
- 1Hz tick rate → 20 tweens/sec
- Each tween is short-lived (~150ms) → up to ~3 concurrent
- Negligible cost

If profiling shows it's heavy, fall back to `set_color` immediately + start a Timer that flips back, or use a single shared shader with per-cell pulse state.

## Acceptance criteria

- [ ] On each tick, a random ~10% of owned tiles briefly brighten then return to base color.
- [ ] No flicker on empty tiles (only `_fill_nodes` are touched).
- [ ] Visual pulse takes ~150ms — short enough to feel like a heartbeat, long enough to register.
- [ ] No regression in tick TPS on a 200-tile run.

## Out of scope

- Pulse intensity reflecting yield rate (Phase 16+).
- Pulse color reflecting resource produced (Phase 16+ if useful).
- Hardware-accelerated shader pulse (only if perf issues observed).
- Pulse on animal markers / cluster outlines (just the fill for now).
