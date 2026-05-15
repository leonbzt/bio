# Brief 01 — Save schema v3 → v4 (dual-layer tile ownership)

**Suggested agent**: ChatGPT 5.2 via Copilot. **Route diff to Claude** — save format change.

Read first:
1. `docs/ARCHITECTURE.md` § 3 save schema (note the updated `run.tiles[i]` shape), § 9 cascading migrations.
2. `scripts/autoloads/save_system.gd`.
3. `tests/test_save_system.gd`.

## Goal
Migrate every tile entry from `{coord, owner_id, data}` to `{coord, surface_owner, subsurface_owner, data}`. All historical tiles are plantae, so map `owner_id` → `surface_owner`.

## Changes

### `SAVE_VERSION`
```gdscript
const SAVE_VERSION: int = 4
```

### `migrate()` — new arm

```gdscript
if from_version < 4:
    # v3 -> v4: split tile ownership into surface/subsurface layers.
    # Historically every tile is plantae, so owner_id -> surface_owner.
    if old.has("run") and old["run"] is Dictionary:
        var run: Dictionary = old["run"]
        var tiles_raw: Variant = run.get("tiles", [])
        if tiles_raw is Array:
            for tile in tiles_raw:
                if not (tile is Dictionary):
                    continue
                var t: Dictionary = tile
                if t.has("owner_id") and not t.has("surface_owner"):
                    t["surface_owner"] = t["owner_id"]
                    t.erase("owner_id")
                if not t.has("surface_owner"):
                    t["surface_owner"] = ""
                if not t.has("subsurface_owner"):
                    t["subsurface_owner"] = ""
```

### `_build_default_save()`
No change needed — `tiles: []` is the default, and an empty array has no entries to migrate.

## Tests

```gdscript
func test_migrate_v3_splits_tile_ownership() -> void:
    var v3 := {
        "save_version": 3,
        "meta": {"unlocked_kingdoms": ["plantae"], "evolution_tree": {}, "statistics": {}},
        "run": {
            "tiles": [
                {"coord": [5, 7], "owner_id": "plantae", "data": {}},
                {"coord": [6, 7], "owner_id": "plantae", "data": {"trait": "thick"}},
            ],
            "resources": {}, "biome_map": {}, "organisms": [], "active_events": [],
            "statistics": {"total_biomass_earned": 0.0, "tiles_colonized": 0, "waves_defeated": 0}
        }
    }
    var migrated := SaveSystem.migrate(v3, 3)
    var tiles: Array = migrated["run"]["tiles"]
    assert_eq(tiles.size(), 2)
    for tile in tiles:
        assert_false(tile.has("owner_id"))
        assert_eq(tile["surface_owner"], "plantae")
        assert_eq(tile["subsurface_owner"], "")
    assert_eq(tiles[1]["data"]["trait"], "thick")


func test_migrate_v0_cascades_to_v4() -> void:
    # Append to existing v0 cascade test, OR replace it. v0 -> v4 must work.
    var v0 := {"save_version": 0, "meta": {}, "run": {"kingdom": "plantae"}}
    var migrated := SaveSystem.migrate(v0, 0)
    assert_true(migrated["run"].has("kingdom_id"))
    assert_true(migrated["run"].has("biome_map"))
    assert_true(migrated["meta"]["unlocked_kingdoms"].has("plantae"))
    assert_true(migrated["run"].has("statistics"))
    # v3 -> v4 had no tiles to migrate, but the arm should still run cleanly.
```

## Acceptance criteria
- [ ] `SAVE_VERSION == 4`.
- [ ] On-device save (currently v3 with plantae tiles) migrates cleanly on first launch of the new build.
- [ ] Tile entries in `save.json` after migration use the new keys; no `owner_id` remains anywhere.
- [ ] Both new and existing migration tests pass.

## Out of scope
- TerritorySystem refactor (brief 02 — must wait until this migration ships so loaders read the new format).
- New default fields. Add later if Phase 5 requires them; for now the migration is purely transformative.
