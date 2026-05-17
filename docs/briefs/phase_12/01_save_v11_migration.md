# Brief 01 — Save schema v10 → v11

**Suggested agent**: ChatGPT 5.2. **Route diff to Claude** — save format change.

Read first:
1. `docs/ARCHITECTURE.md` § 3 + § 9.
2. `scripts/autoloads/save_system.gd`.
3. `tests/test_save_system.gd`.

## Goal
Add four era/ecosystem fields to `meta`. On migrate from v10, default new players to era `&"cryogenian"`, ecosystem `&"cryo_polar_ice"`, no completions, only Cryogenian unlocked.

## Changes

### `SAVE_VERSION`
```gdscript
const SAVE_VERSION: int = 11
```

### `migrate()` — new arm

```gdscript
if from_version < 11:
    # v10 -> v11: era + ecosystem state.
    if old.has("meta") and old["meta"] is Dictionary:
        var meta: Dictionary = old["meta"]
        if not meta.has("current_era_id"):
            meta["current_era_id"] = "cryogenian"
        if not meta.has("current_ecosystem_id"):
            meta["current_ecosystem_id"] = "cryo_polar_ice"
        if not meta.has("ecosystem_completions"):
            meta["ecosystem_completions"] = {}
        if not meta.has("eras_unlocked"):
            meta["eras_unlocked"] = ["cryogenian"]
```

### `_build_default_save()`
Under `meta`:
```gdscript
"current_era_id": "cryogenian",
"current_ecosystem_id": "cryo_polar_ice",
"ecosystem_completions": {},
"eras_unlocked": ["cryogenian"],
```

### Cascading note
Existing players who have unlocked plantae will find they're now in Cryogenian (fungi-only). They'll see "Plantae locked in this era" in the kingdom selector. This is intentional — the era system reframes earlier progress. To smooth the surprise, brief 09 authors a discovery entry that fires on first launch of v11: "You arrived before the warm. The plants you will become have not yet learned to be."

For dev sanity, the smoke test recommends starting on a fresh save to feel the new flow without cognitive baggage.

## Tests

```gdscript
func test_migrate_v10_adds_era_fields() -> void:
    var v10 := {
        "save_version": 10,
        "meta": {"unlocked_kingdoms": ["plantae", "fungi"], "kingdoms_played": ["plantae"], "evolution_tree": {}, "statistics": {}, "discovery_log": {}, "niches_played": []},
        "run": {"kingdom_id": "", "niche_id": "", "resources": {}, "tiles": [], "biome_map": {}, "organisms": [], "active_events": [], "event_first_fires_seen": [], "goal_id": "", "goal_progress": {}, "goal_met": false, "statistics": {}}
    }
    var migrated := SaveSystem.migrate(v10, 10)
    assert_eq(migrated["meta"]["current_era_id"], "cryogenian")
    assert_eq(migrated["meta"]["current_ecosystem_id"], "cryo_polar_ice")
    assert_eq(migrated["meta"]["ecosystem_completions"], {})
    assert_eq(migrated["meta"]["eras_unlocked"], ["cryogenian"])


func test_migrate_v0_cascades_to_v11() -> void:
    var v0 := {"save_version": 0, "meta": {}, "run": {"kingdom": "plantae"}}
    var migrated := SaveSystem.migrate(v0, 0)
    assert_eq(migrated["meta"]["current_era_id"], "cryogenian")
    assert_true(migrated["meta"]["eras_unlocked"].has("cryogenian"))
```

## Acceptance criteria
- [ ] `SAVE_VERSION == 11`.
- [ ] v10 saves migrate with era fields populated to Cryogenian defaults.
- [ ] Fresh saves start in Cryogenian.
- [ ] Cascade test passes.

## Out of scope
- Reading/writing these fields from gameplay code (brief 04 + 05).
- World map UI (brief 05).
- Era-locked kingdom filtering (brief 07).
