# Brief 06 — Step 6: Per-cluster status indicators

You are working on the Bio-Fantasy RPG project. Before you write any code, read:
1. `docs/ARCHITECTURE.md`
2. `docs/V1_PROTOTYPE.md` § 6 (UI principles — cluster bars)
3. `docs/briefs/phase_16/00_phase_16_entry.md`

## Goal

Each species' clusters show a colored status indicator based on input availability. Lets players diagnose bottlenecks by looking at the canvas instead of reading a spreadsheet.

In v1 the throttle is **per-species global** (all Calamites tiles share one throttle value), not per-tile.

## Inputs (read-only)

- `scripts/systems/growth_system.gd` — `_compute_input_throttle` (added step 1)
- `scripts/entities/tile_grid.gd` — current tile renderer + occupancy data
- `scripts/autoloads/territory_system.gd`

## Outputs (create or modify)

| File | What |
|---|---|
| `scripts/systems/growth_system.gd` | Expose `get_species_throttle(species_id: StringName) -> float`. Cache the last computed throttle per species in a `Dictionary[StringName, float]` populated inside `_apply_yields`. Cleared on `EventBus.run_started`. |
| `scripts/entities/tile_grid.gd` | Add a `_StatusOverlay` child Node2D. Override `_draw`. Each occupied tile gets a 6×6 colored dot at its top-right, colored by the species' throttle (see color rules). Hero species (`calamites`) gets an 8×8 dot. Connect to `EventBus.tick`; call `queue_redraw()` at ~1 Hz (every 10 ticks, not every tick). |

## Status color rules

```gdscript
const COLOR_OK: Color = Color(0.53, 0.80, 0.40)      # green #88cc66
const COLOR_THROTTLED: Color = Color(0.87, 0.87, 0.40)  # yellow #dddd66
const COLOR_STARVING: Color = Color(0.80, 0.40, 0.40)   # red #cc6666

func _status_color(throttle: float) -> Color:
    if throttle >= 0.7: return COLOR_OK
    if throttle >= 0.3: return COLOR_THROTTLED
    return COLOR_STARVING
```

## Constraints

- No new autoloads.
- No new EventBus signals.
- Rendering via `_draw` on a Node2D overlay child of TileGrid.
- Throttle cache populated by `GrowthSystem._apply_yields`; cleared on `run_started`.
- Per-species (not per-tile) — Calamites with empty `consume_input` (impossible in v1 but defensively) gets throttle = 1.0 → green.
- Don't overdraw — `queue_redraw()` at most ~1 Hz.

## Acceptance criteria

- [ ] Place only Calamites; wait for nutrient depletion → Calamites cluster dots turn yellow then red.
- [ ] Place Mycorrhizal Network; Calamites dots return to green as nutrients flow.
- [ ] Place Arthropleura with empty B pool → Arthropleura dots red (starving) until biomass flows.
- [ ] Dots don't render on empty tiles.
- [ ] Pause stops the dot animation; resume on unpause.
- [ ] Hero species dot is visibly larger than supports (8 vs 6 px).
- [ ] Code runs in editor without errors.

## Out of scope

- Tooltip on hover (defer)
- Per-tile throttle (in v1 all clusters of a species share one throttle)
- Animated dot pulsing (defer)
- Status indicators on the species panel buttons (canvas only)

## Hand-back

Diff for 2 files to Leon for Claude review. The cache invalidation on `run_started` is the trickiest piece — verify a fresh run starts with no stale throttle values.
