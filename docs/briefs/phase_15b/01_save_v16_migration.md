# Brief 01 — Save v15 → v16 migration

**Suggested agent**: ChatGPT 5.2. Route diff to Claude.

Read first:
1. `scripts/autoloads/save_system.gd` — current migration chain.

## Goal

Bump save schema to v16. Add fields for fog of war, rock obstacles, and active structures.

## Outputs

### `scripts/autoloads/save_system.gd`

Bump `SAVE_VERSION = 16`.

```gdscript
func _migrate_v15_to_v16(save: Dictionary) -> void:
    var run: Dictionary = save.get("run", {}) as Dictionary

    if not run.has("fog_revealed"):
        # For an existing run that started before fog was a thing, reveal
        # every coord that's currently owned (and the 4×4 neighborhood) so
        # players don't suddenly lose visibility of their existing world.
        var revealed: Array = []
        var tiles: Array = run.get("tiles", []) as Array
        var seen: Dictionary = {}
        for entry in tiles:
            if not (entry is Dictionary):
                continue
            var coord: Variant = entry.get("coord", null)
            if coord is Array and coord.size() == 2:
                _flood_reveal(int(coord[0]), int(coord[1]), 2, seen)
        for k in seen.keys():
            revealed.append(k)
        run["fog_revealed"] = revealed

    if not run.has("obstacles"):
        # Generate obstacles deterministically from run_seed.
        # If no run is active, leave empty — generated when run starts.
        if run.has("run_seed") and int(run.get("run_seed", 0)) != 0:
            run["obstacles"] = _generate_obstacles(int(run["run_seed"]))
        else:
            run["obstacles"] = []

    if not run.has("active_structures"):
        run["active_structures"] = []

    save["run"] = run

    var meta: Dictionary = save.get("meta", {}) as Dictionary
    if not meta.has("structures_discovered"):
        meta["structures_discovered"] = []
    save["meta"] = meta


# Helper to flood 4×4 reveal around a coord (radius 2 in each direction).
static func _flood_reveal(cx: int, cy: int, radius: int, into: Dictionary) -> void:
    for dy in range(-radius, radius + 1):
        for dx in range(-radius, radius + 1):
            into["%d,%d" % [cx + dx, cy + dy]] = true


# Same deterministic algorithm used by ObstacleSystem (brief 03).
# Duplicated here so migration doesn't depend on World autoloads.
static func _generate_obstacles(seed: int) -> Array:
    var rng := RandomNumberGenerator.new()
    rng.seed = seed
    const GRID_W: int = 32
    const GRID_H: int = 48
    const RATE: float = 0.05
    var out: Array = []
    for y in range(GRID_H):
        for x in range(GRID_W):
            if rng.randf() < RATE:
                out.append("%d,%d" % [x, y])
    return out
```

Wire into the migration chain alongside `_migrate_v14_to_v15`.

## Notes

- Existing tiles **stay placeable** even if the obstacle generator picks the same coord — the obstacle list ignores already-owned tiles at runtime.
- Fog backfill ensures players reloading mid-run don't lose visibility of what they built.

## ARCHITECTURE.md updates

§9 save schema — append v15 → v16 row.

## Acceptance criteria

- [ ] `SAVE_VERSION = 16`.
- [ ] `_migrate_v15_to_v16` runs once on a v15 save.
- [ ] `run.fog_revealed` populated with reveal around existing owned tiles.
- [ ] `run.obstacles` deterministically generated from `run_seed`.
- [ ] `run.active_structures` exists as empty array.
- [ ] `meta.structures_discovered` exists as empty array.
- [ ] Fresh v16 save loads as no-op.
- [ ] v11→…→v16 chain runs on old saves without error.

## Out of scope

- Reading fog/obstacles/structures (briefs 02-07 do that).
- Validating consistency (don't drop tiles that happen to be obstacles).
