# Brief 01 — Save v14 → v15 migration

**Suggested agent**: ChatGPT 5.2. Route diff to Claude.

Read first:
1. `scripts/autoloads/save_system.gd` — `SAVE_VERSION = 14`, `_migrate_v13_to_v14`, `_repair_species_unlocked`.

## Goal

Bump save schema to v15. Add three fields needed by the multiplier system, tile maturation, and per-species cost scaling.

## Outputs

### `scripts/autoloads/save_system.gd`

Bump `SAVE_VERSION = 15`.

```gdscript
func _migrate_v14_to_v15(save: Dictionary) -> void:
    var run: Dictionary = save.get("run", {}) as Dictionary
    if not run.has("tile_ages"):
        run["tile_ages"] = {}
    if not run.has("species_tile_counts"):
        # Recompute from current tiles[].occupants — keeps existing runs accurate.
        var counts: Dictionary = {}
        var tiles: Array = run.get("tiles", []) as Array
        for entry in tiles:
            if not (entry is Dictionary):
                continue
            var occupants: Dictionary = entry.get("occupants", {}) as Dictionary
            for kingdom_id in occupants.keys():
                var sp_id: String = String(occupants[kingdom_id])
                counts[sp_id] = int(counts.get(sp_id, 0)) + 1
        run["species_tile_counts"] = counts
    save["run"] = run

    var meta: Dictionary = save.get("meta", {}) as Dictionary
    if not meta.has("lifetime_counters"):
        meta["lifetime_counters"] = {
            "tiles_placed_lifetime": 0,
            "clusters_formed_lifetime": 0
        }
    save["meta"] = meta
```

Wire into migration chain alongside `_migrate_v13_to_v14`.

### Defensive `_repair_species_unlocked` extension

Add the new run fields to the defensive backfill so saves loaded outside migration still have them:

```gdscript
# In _repair_species_unlocked (or equivalent on-load helper).
var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
if not run.has("tile_ages"):
    run["tile_ages"] = {}
if not run.has("species_tile_counts"):
    run["species_tile_counts"] = {}
```

## Notes

- `tile_ages` keyed by `"x,y"` string (same coord-key convention as `biome_map`).
- `species_tile_counts` is denormalized — TerritorySystem must keep it in sync on add/remove. Brief 06 wires the increment/decrement.
- `lifetime_counters` is meta-side; only Phase 15c reads it for Adaptation. Init empty here so the dict exists.

## ARCHITECTURE.md updates

§9 save schema — append v14 → v15 row listing the three new fields.

## Acceptance criteria

- [ ] `SAVE_VERSION = 15`.
- [ ] `_migrate_v14_to_v15` runs once on a v14 save.
- [ ] `run.tile_ages` exists as empty dict (existing tiles get age 0 implicitly — they'll mature on next tick).
- [ ] `run.species_tile_counts` populated from existing `run.tiles[].occupants`.
- [ ] `meta.lifetime_counters` exists with the two seed keys.
- [ ] Fresh v15 save (no migration) loads as no-op.
- [ ] v11→v12→v13→v14→v15 chain still runs on old saves.

## Out of scope

- Reading or applying the new fields (briefs 02, 05, 06 do that).
- New resource-multiplier-source storage (lives in-memory via ResourceLedger; not persisted in v15).
- Lifetime counter values populated (brief 03 increments on cluster form, etc.).
