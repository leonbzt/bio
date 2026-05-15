# Brief 01 — Save schema v2 → v3

**Suggested agent**: ChatGPT 5.2 via Copilot. **Route diff to Claude before merge** — touches save format.

Read first:
1. `docs/ARCHITECTURE.md` § 3 save schema, § 9 versioning ("migrations must cascade").
2. `scripts/autoloads/save_system.gd`.
3. `tests/test_save_system.gd`.

## Goal
Add the v3 schema fields and a cascading migration arm. No game logic changes — just schema and migration.

## Outputs (modify)
- `scripts/autoloads/save_system.gd` — bump version, add migration arm, update `_build_default_save`.
- `tests/test_save_system.gd` — add v2 → v3 test and a v0 → v3 cascade regression test.

## Changes

### `SAVE_VERSION`
```gdscript
const SAVE_VERSION: int = 3
```

### `migrate()` — add new `if` block

```gdscript
if from_version < 3:
    # v2 -> v3: meta-progression and per-run statistics scaffolding.
    if old.has("meta") and old["meta"] is Dictionary:
        var meta: Dictionary = old["meta"]

        var kingdoms_raw: Variant = meta.get("unlocked_kingdoms", [])
        var kingdoms: Array
        if kingdoms_raw is Array:
            kingdoms = kingdoms_raw
        else:
            kingdoms = []
            meta["unlocked_kingdoms"] = kingdoms
        if not kingdoms.has("plantae"):
            kingdoms.append("plantae")

        if not meta.has("statistics") or not (meta["statistics"] is Dictionary):
            meta["statistics"] = {}
        var meta_stats: Dictionary = meta["statistics"]
        if not meta_stats.has("prestige_count"):
            meta_stats["prestige_count"] = 0
        if not meta_stats.has("evolution_points_balance"):
            meta_stats["evolution_points_balance"] = 0
        if not meta_stats.has("total_biomass_lifetime"):
            meta_stats["total_biomass_lifetime"] = 0.0

    if old.has("run") and old["run"] is Dictionary:
        var run: Dictionary = old["run"]
        if not run.has("statistics") or not (run["statistics"] is Dictionary):
            run["statistics"] = {}
        var run_stats: Dictionary = run["statistics"]
        if not run_stats.has("total_biomass_earned"):
            run_stats["total_biomass_earned"] = 0.0
        if not run_stats.has("tiles_colonized"):
            run_stats["tiles_colonized"] = 0
        if not run_stats.has("waves_defeated"):
            run_stats["waves_defeated"] = 0
```

### `_build_default_save()`
- `meta.unlocked_kingdoms = ["plantae"]`
- `meta.statistics = {"prestige_count": 0, "evolution_points_balance": 0, "total_biomass_lifetime": 0.0}`
- `run.statistics = {"total_biomass_earned": 0.0, "tiles_colonized": 0, "waves_defeated": 0}`

## Tests

```gdscript
func test_migrate_v2_adds_prestige_scaffolding() -> void:
    var v2 := {
        "save_version": 2,
        "meta": {"unlocked_kingdoms": [], "evolution_tree": {}, "statistics": {}},
        "run": {"resources": {}, "biome_map": {}, "tiles": [], "organisms": [], "active_events": []}
    }
    var migrated := SaveSystem.migrate(v2, 2)
    assert_true(migrated["meta"]["unlocked_kingdoms"].has("plantae"))
    assert_eq(migrated["meta"]["statistics"]["evolution_points_balance"], 0)
    assert_true(migrated["run"]["statistics"].has("total_biomass_earned"))


func test_migrate_v0_cascades_to_v3() -> void:
    # Regression: a hypothetical ancient save passes through every migration.
    var v0 := {"save_version": 0, "meta": {}, "run": {"kingdom": "plantae"}}
    var migrated := SaveSystem.migrate(v0, 0)
    assert_true(migrated["run"].has("kingdom_id"))               # v0 -> v1
    assert_true(migrated["run"].has("biome_map"))                # v1 -> v2
    assert_true(migrated["meta"]["unlocked_kingdoms"].has("plantae"))  # v2 -> v3
```

## Acceptance criteria
- [ ] First launch on a clean device builds a v3 save with `unlocked_kingdoms: ["plantae"]`.
- [ ] Existing v2 saves get migrated cleanly to v3 (test in editor — your current device save should auto-upgrade).
- [ ] Both new tests pass.
- [ ] Older v0 cascade regression test still passes.

## Out of scope
- Using any of the new fields yet. Subsequent briefs read/write them.
