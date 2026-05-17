# Brief 01 — Save schema v9 → v10

**Suggested agent**: ChatGPT 5.2 via Copilot. **Route diff to Claude** — save format change + content migration.

Read first:
1. `docs/ARCHITECTURE.md` § 3 save schema, § 9 cascading migrations.
2. `scripts/autoloads/save_system.gd`.
3. `tests/test_save_system.gd`.
4. `docs/briefs/phase_10/00_phase_10_entry.md` for the rationale.

## Goal

Retire the `&"symbiosis"` kingdom from save state. Two concrete migrations:

1. **`meta.unlocked_kingdoms`**: remove the string `"symbiosis"` if present.
2. **In-flight `run.kingdom_id == "symbiosis"`**: rewrite to `"fungi"` with `run.niche_id = "lichen"` (player's symbiosis run becomes a fungi-Lichen run).

Plus a forward-looking touch:

3. **6 stub resource IDs in `run.resources`**: ensure they exist with value `0.0`. This is defensive — `ResourceLedger` will tolerate missing keys but having them present makes save inspection nicer and aligns the schema.

## Changes

### `SAVE_VERSION`
```gdscript
const SAVE_VERSION: int = 10
```

### `migrate()` — new arm

```gdscript
if from_version < 10:
    # v9 -> v10: retire symbiosis kingdom; add stub resource IDs.
    if old.has("meta") and old["meta"] is Dictionary:
        var meta: Dictionary = old["meta"]
        var unlocked: Array = meta.get("unlocked_kingdoms", []) as Array
        var filtered: Array = []
        for k in unlocked:
            if String(k) != "symbiosis":
                filtered.append(k)
        meta["unlocked_kingdoms"] = filtered
        # Strip "symbiosis" from kingdoms_played too — the new model doesn't have it.
        var played: Array = meta.get("kingdoms_played", []) as Array
        var played_filtered: Array = []
        for k in played:
            if String(k) != "symbiosis":
                played_filtered.append(k)
        meta["kingdoms_played"] = played_filtered
    if old.has("run") and old["run"] is Dictionary:
        var run: Dictionary = old["run"]
        if String(run.get("kingdom_id", "")) == "symbiosis":
            run["kingdom_id"] = "fungi"
            run["niche_id"] = "lichen"
        # Stub resources.
        var resources: Dictionary = run.get("resources", {}) as Dictionary
        for rid in ["protein", "cellulose", "chitin", "phosphate", "lifeforce", "pollination"]:
            if not resources.has(rid):
                resources[rid] = 0.0
        run["resources"] = resources
```

### `_build_default_save()`
Add the 6 stub resources to `run.resources`:
```gdscript
"resources": {
    "protein": 0.0,
    "cellulose": 0.0,
    "chitin": 0.0,
    "phosphate": 0.0,
    "lifeforce": 0.0,
    "pollination": 0.0
},
```

### `_reset_run_state()` in `prestige_system.gd`
Add the 6 stub resources to the fresh_run `resources` dict.

## Tests

Append to `tests/test_save_system.gd`:

```gdscript
func test_migrate_v9_strips_symbiosis_from_unlocked_kingdoms() -> void:
    var v9 := {
        "save_version": 9,
        "meta": {"unlocked_kingdoms": ["plantae", "fungi", "symbiosis"], "kingdoms_played": ["plantae", "symbiosis"], "evolution_tree": {}, "statistics": {}, "discovery_log": {}, "niches_played": []},
        "run": {"kingdom_id": "plantae", "niche_id": "photosynthesizer", "resources": {}, "tiles": [], "biome_map": {}, "organisms": [], "active_events": [], "event_first_fires_seen": [], "goal_id": "", "goal_progress": {}, "goal_met": false, "statistics": {}}
    }
    var migrated := SaveSystem.migrate(v9, 9)
    assert_false(migrated["meta"]["unlocked_kingdoms"].has("symbiosis"))
    assert_true(migrated["meta"]["unlocked_kingdoms"].has("plantae"))
    assert_true(migrated["meta"]["unlocked_kingdoms"].has("fungi"))
    assert_false(migrated["meta"]["kingdoms_played"].has("symbiosis"))
    assert_true(migrated["meta"]["kingdoms_played"].has("plantae"))


func test_migrate_v9_rewrites_in_flight_symbiosis_run() -> void:
    var v9 := {
        "save_version": 9,
        "meta": {"unlocked_kingdoms": ["plantae", "fungi"], "kingdoms_played": [], "evolution_tree": {}, "statistics": {}, "discovery_log": {}, "niches_played": []},
        "run": {"kingdom_id": "symbiosis", "niche_id": "", "resources": {}, "tiles": [], "biome_map": {}, "organisms": [], "active_events": [], "event_first_fires_seen": [], "goal_id": "", "goal_progress": {}, "goal_met": false, "statistics": {}}
    }
    var migrated := SaveSystem.migrate(v9, 9)
    assert_eq(migrated["run"]["kingdom_id"], "fungi")
    assert_eq(migrated["run"]["niche_id"], "lichen")


func test_migrate_v9_adds_stub_resources() -> void:
    var v9 := {
        "save_version": 9,
        "meta": {"unlocked_kingdoms": ["plantae"], "kingdoms_played": [], "evolution_tree": {}, "statistics": {}, "discovery_log": {}, "niches_played": []},
        "run": {"kingdom_id": "plantae", "niche_id": "photosynthesizer", "resources": {"biomass": 10.0}, "tiles": [], "biome_map": {}, "organisms": [], "active_events": [], "event_first_fires_seen": [], "goal_id": "", "goal_progress": {}, "goal_met": false, "statistics": {}}
    }
    var migrated := SaveSystem.migrate(v9, 9)
    var resources: Dictionary = migrated["run"]["resources"]
    assert_true(resources.has("protein"))
    assert_true(resources.has("cellulose"))
    assert_true(resources.has("chitin"))
    assert_true(resources.has("phosphate"))
    assert_true(resources.has("lifeforce"))
    assert_true(resources.has("pollination"))
    # Existing biomass preserved.
    assert_eq(resources["biomass"], 10.0)


func test_migrate_v0_cascades_to_v10() -> void:
    var v0 := {"save_version": 0, "meta": {}, "run": {"kingdom": "plantae"}}
    var migrated := SaveSystem.migrate(v0, 0)
    # Verify the new symbiosis filter and stub resources land.
    assert_false(migrated["meta"]["unlocked_kingdoms"].has("symbiosis"))
    assert_true(migrated["run"]["resources"].has("protein"))
```

## Acceptance criteria
- [ ] `SAVE_VERSION == 10`.
- [ ] Existing v9 saves with `"symbiosis"` in `unlocked_kingdoms` migrate to drop it.
- [ ] In-flight v9 symbiosis runs rewrite cleanly to fungi + lichen.
- [ ] All 6 stub resources present in migrated runs and in fresh default saves.
- [ ] Cascade test (v0 → v10) passes.

## Out of scope
- Removing symbiosis from CODE — brief 03 does that.
- Lichen niche data file — brief 05.
- Stub resource HUD display — brief 10.
- Resource wiring beyond the IDs — Phase 14.
