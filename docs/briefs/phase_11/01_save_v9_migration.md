# Brief 01 — Save schema v8 → v9

**Suggested agent**: ChatGPT 5.2 via Copilot. **Route diff to Claude** — save format change.

Read first:
1. `docs/ARCHITECTURE.md` § 3 save schema, § 9 cascading migrations.
2. `scripts/autoloads/save_system.gd`.
3. `tests/test_save_system.gd`.
4. `docs/briefs/phase_11/00_phase_11_entry.md` for the rationale of each new field.

## Goal
Add three soft-goal fields to the run block:
- `run.goal_id: String` — id of the soft prestige goal active for the current run. Empty string = no goal (legacy or pre-goal run).
- `run.goal_progress: Dictionary` — free-form per-goal-type progress. Each goal type defines its own key set.
- `run.goal_met: bool` — whether the active goal has been satisfied at any point this run.

(Tile history was dropped from Phase 11 — see brief 00. No `meta.tile_history` field is added.)

## Changes

### `SAVE_VERSION`
```gdscript
const SAVE_VERSION: int = 9
```

### `migrate()` — new arm

```gdscript
if from_version < 9:
    # v8 -> v9: soft prestige goal state.
    if old.has("run") and old["run"] is Dictionary:
        var run: Dictionary = old["run"]
        if not run.has("goal_id"):
            run["goal_id"] = ""
        if not run.has("goal_progress"):
            run["goal_progress"] = {}
        if not run.has("goal_met"):
            run["goal_met"] = false
```

### `_build_default_save()`
Under `run`:
```gdscript
"goal_id": "",
"goal_progress": {},
"goal_met": false,
```

### `_reset_run_state()` in `prestige_system.gd`
Add to the fresh_run dict (alphabetical with existing keys):
```gdscript
"goal_id": "",
"goal_progress": {},
"goal_met": false,
```

## Tests

Append to `tests/test_save_system.gd`:

```gdscript
func test_migrate_v8_adds_goal_fields() -> void:
    var v8 := {
        "save_version": 8,
        "meta": {"unlocked_kingdoms": ["plantae"], "evolution_tree": {}, "statistics": {}, "discovery_log": {}, "kingdoms_played": [], "niches_played": []},
        "run": {
            "kingdom_id": "plantae", "niche_id": "photosynthesizer",
            "tiles": [], "resources": {}, "biome_map": {}, "organisms": [], "active_events": [],
            "event_first_fires_seen": [],
            "statistics": {"total_biomass_earned": 0.0, "tiles_colonized": 0, "waves_defeated": 0}
        }
    }
    var migrated := SaveSystem.migrate(v8, 8)
    assert_true(migrated["run"].has("goal_id"))
    assert_eq(migrated["run"]["goal_id"], "")
    assert_true(migrated["run"].has("goal_progress"))
    assert_eq(migrated["run"]["goal_progress"], {})
    assert_true(migrated["run"].has("goal_met"))
    assert_false(migrated["run"]["goal_met"])


func test_migrate_v0_cascades_to_v9() -> void:
    var v0 := {"save_version": 0, "meta": {}, "run": {"kingdom": "plantae"}}
    var migrated := SaveSystem.migrate(v0, 0)
    assert_true(migrated["run"].has("goal_id"))
    # Sanity: earlier-version fields still populated.
    assert_eq(migrated["run"]["niche_id"], "photosynthesizer")
    assert_true(migrated["run"].has("event_first_fires_seen"))
```

## Acceptance criteria
- [ ] `SAVE_VERSION == 9`.
- [ ] Existing v8 saves migrate cleanly: `goal_id == ""`, `goal_progress == {}`, `goal_met == false`.
- [ ] Cascade test (v0 → v9) passes — all intervening fields populated.
- [ ] First launch on a clean device writes a v9 save with the three new fields present.
- [ ] `_reset_run_state` clears `goal_id`/`goal_progress`/`goal_met`.

## Out of scope
- Authoring goal data (brief 04).
- Goal-tracking logic (brief 04).
- Banner UI (brief 05).
- Title-screen counter (brief 06).
- Tile history (dropped from Phase 11 entirely).
