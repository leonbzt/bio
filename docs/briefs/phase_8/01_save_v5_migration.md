# Brief 01 — Save schema v4 → v5

**Suggested agent**: ChatGPT 5.2 via Copilot. **Route diff to Claude** — save format change.

Read first:
1. `docs/ARCHITECTURE.md` § 3 save schema, § 9 cascading migrations.
2. `scripts/autoloads/save_system.gd`.
3. `tests/test_save_system.gd`.

## Goal
Add `run.niche_id` (which niche the current run is being played as) and an optional `data.parasite_decay_ticks` field on tile entries (used by the Parasite plantae niche to track how long until a parasite tile withers without network support).

## Changes

### `SAVE_VERSION`
```gdscript
const SAVE_VERSION: int = 5
```

### `migrate()` — new arm

```gdscript
if from_version < 5:
    # v4 -> v5: add niche_id to run; tile.data may now carry parasite_decay_ticks.
    # Existing tiles default to the kingdom's default niche.
    if old.has("run") and old["run"] is Dictionary:
        var run: Dictionary = old["run"]
        if not run.has("niche_id"):
            # Map historical kingdoms to their default niches.
            var kingdom_id: String = String(run.get("kingdom_id", ""))
            match kingdom_id:
                "plantae":   run["niche_id"] = "photosynthesizer"
                "fungi":     run["niche_id"] = "decomposer"
                _:           run["niche_id"] = ""    # symbiosis runs or no active run
        # No tile-level migration needed; parasite_decay_ticks is optional in data{} per tile.
```

### `_build_default_save()`
Add `"niche_id": ""` to the `run` block. Empty string means "no active run".

## Tests

Append to `tests/test_save_system.gd`:

```gdscript
func test_migrate_v4_adds_niche_id() -> void:
    var v4 := {
        "save_version": 4,
        "meta": {"unlocked_kingdoms": ["plantae"], "evolution_tree": {}, "statistics": {}},
        "run": {
            "kingdom_id": "plantae",
            "tiles": [{"coord": [1, 1], "surface_owner": "plantae", "subsurface_owner": "", "data": {}}],
            "resources": {}, "biome_map": {}, "organisms": [], "active_events": [],
            "statistics": {"total_biomass_earned": 0.0, "tiles_colonized": 0, "waves_defeated": 0}
        }
    }
    var migrated := SaveSystem.migrate(v4, 4)
    assert_eq(migrated["run"]["niche_id"], "photosynthesizer")


func test_migrate_v4_fungi_default_niche() -> void:
    var v4_fungi := {
        "save_version": 4,
        "meta": {},
        "run": {"kingdom_id": "fungi"}
    }
    var migrated := SaveSystem.migrate(v4_fungi, 4)
    assert_eq(migrated["run"]["niche_id"], "decomposer")


func test_migrate_v0_cascades_to_v5() -> void:
    var v0 := {"save_version": 0, "meta": {}, "run": {"kingdom": "plantae"}}
    var migrated := SaveSystem.migrate(v0, 0)
    assert_true(migrated["run"].has("kingdom_id"))
    assert_true(migrated["run"].has("biome_map"))
    assert_true(migrated["meta"]["unlocked_kingdoms"].has("plantae"))
    assert_true(migrated["run"].has("statistics"))
    assert_eq(migrated["run"]["niche_id"], "photosynthesizer")
```

## Acceptance criteria
- [ ] `SAVE_VERSION == 5`.
- [ ] Existing v4 saves migrate to v5 with `niche_id` populated based on `kingdom_id`.
- [ ] Cascade test (v0 → v5) passes.
- [ ] First launch on a clean device writes a v5 save with empty `niche_id`.

## Out of scope
- Using `niche_id` to alter gameplay (brief 03+ does that).
- Niche-specific tile data fields (parasite_decay_ticks lives in tile `data` dict and is loader-tolerant).
