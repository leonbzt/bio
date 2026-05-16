# Brief 01 — Save schema v5 → v6 (and a follow-on v6 → v7 for niche-id rename)

> **Note (2026-05-16, post-impl)**: brief 07 review surfaced an internal id inconsistency
> — the parasite plantae niche shipped in v6 with id `&"parasite_plantae"` but the
> colonization-rule key and unlock-node id already used `&"parasitic_plantae"`. The
> canonical id was retroactively unified to `&"parasitic_plantae"`. A v6 → v7
> micro-migration (also implemented in `save_system.gd`) rewrites
> `run.niche_id` and any `meta.niches_played` entries from `parasite_plantae` to
> `parasitic_plantae`. Save version is now 7.


**Suggested agent**: ChatGPT 5.2 via Copilot. **Route diff to Claude** — save format change.

Read first:
1. `docs/ARCHITECTURE.md` § 3 save schema, § 9 cascading migrations.
2. `scripts/autoloads/save_system.gd`.
3. `tests/test_save_system.gd`.
4. `docs/briefs/phase_9/00_phase_8_recap.md` for the rationale of each new field.

## Goal
Add three fields supporting the progression web + discovery log:
- `meta.discovery_log: Dictionary` — entry_id → bool, tracks which discovery entries the player has unlocked.
- `meta.kingdoms_played: Array[String]` — kingdom_ids the player has completed (prestiged out of) at least once. Used by `requires_kingdom_played` enforcement.
- `run.event_first_fires_seen: Array[String]` — event_ids that have already triggered a discovery within the current run. Per-run dedup so e.g. drought firing five times doesn't fire five discovery entries.

## Changes

### `SAVE_VERSION`
```gdscript
const SAVE_VERSION: int = 6
```

### `migrate()` — new arm

```gdscript
if from_version < 6:
    # v5 -> v6: add discovery_log + kingdoms_played to meta, event_first_fires_seen to run.
    if old.has("meta") and old["meta"] is Dictionary:
        var meta: Dictionary = old["meta"]
        if not meta.has("discovery_log"):
            meta["discovery_log"] = {}
        if not meta.has("kingdoms_played"):
            # Conservative default: empty list. The player will earn entries from now on.
            # Note: we deliberately do NOT backfill from unlocked_kingdoms — having a kingdom
            # unlocked is not the same as having played a run as that kingdom, and the
            # requires_kingdom_played gate is about play experience.
            meta["kingdoms_played"] = []
    if old.has("run") and old["run"] is Dictionary:
        var run: Dictionary = old["run"]
        if not run.has("event_first_fires_seen"):
            run["event_first_fires_seen"] = []
```

### `_build_default_save()`
Under `meta`:
```gdscript
"discovery_log": {},
"kingdoms_played": [],
```
Under `run`:
```gdscript
"event_first_fires_seen": [],
```

### `_reset_run_state()` in `prestige_system.gd`
Add `"event_first_fires_seen": [],` to the fresh_run dict so prestige clears the per-run dedup.

## Tests

Append to `tests/test_save_system.gd`:

```gdscript
func test_migrate_v5_adds_discovery_fields() -> void:
    var v5 := {
        "save_version": 5,
        "meta": {"unlocked_kingdoms": ["plantae", "fungi"], "evolution_tree": {}, "statistics": {}},
        "run": {
            "kingdom_id": "plantae", "niche_id": "photosynthesizer",
            "tiles": [], "resources": {}, "biome_map": {}, "organisms": [], "active_events": [],
            "statistics": {"total_biomass_earned": 0.0, "tiles_colonized": 0, "waves_defeated": 0}
        }
    }
    var migrated := SaveSystem.migrate(v5, 5)
    assert_true(migrated["meta"].has("discovery_log"))
    assert_true(migrated["meta"].has("kingdoms_played"))
    assert_eq(migrated["meta"]["discovery_log"], {})
    assert_eq(migrated["meta"]["kingdoms_played"], [])
    assert_true(migrated["run"].has("event_first_fires_seen"))
    assert_eq(migrated["run"]["event_first_fires_seen"], [])


func test_migrate_v5_does_not_backfill_kingdoms_played() -> void:
    # Having a kingdom unlocked != having played it. Don't conflate.
    var v5 := {
        "save_version": 5,
        "meta": {"unlocked_kingdoms": ["plantae", "fungi", "symbiosis"]},
        "run": {}
    }
    var migrated := SaveSystem.migrate(v5, 5)
    assert_eq(migrated["meta"]["kingdoms_played"], [])


func test_migrate_v0_cascades_to_v6() -> void:
    var v0 := {"save_version": 0, "meta": {}, "run": {"kingdom": "plantae"}}
    var migrated := SaveSystem.migrate(v0, 0)
    assert_true(migrated["meta"].has("discovery_log"))
    assert_true(migrated["meta"].has("kingdoms_played"))
    assert_true(migrated["run"].has("event_first_fires_seen"))
    assert_eq(migrated["run"]["niche_id"], "photosynthesizer")  # v5 carryover
```

## Acceptance criteria
- [ ] `SAVE_VERSION == 6`.
- [ ] Existing v5 saves migrate cleanly: `discovery_log == {}`, `kingdoms_played == []`, `event_first_fires_seen == []`.
- [ ] Cascade test (v0 → v6) passes — all intervening fields populated.
- [ ] First launch on a clean device writes a v6 save with the three new fields present and empty.
- [ ] `kingdoms_played` is NOT backfilled from `unlocked_kingdoms` (verify with the test above).

## Out of scope
- Writing to the new fields (briefs 03 + 06 do that).
- Discovery entries themselves (brief 07).
- UI for the discovery log (brief 08).
- Backfilling `kingdoms_played` for existing players from any historical signal — deliberately not done. Forward-looking only.
