# Brief 01 — Save v13 → v14 migration

**Suggested agent**: ChatGPT 5.2. Route diff to **Claude** — lifecycle state.

Read first:
1. `scripts/autoloads/save_system.gd` — `SAVE_VERSION = 13`, `_migrate_v12_to_v13`.
2. `docs/briefs/phase_13_paused/01_save_v12_migration.md` (the original paused brief had the same field set — translates directly).

## Goal

Bump save schema to v14. Add three `meta` fields needed by mass extinction lifecycle (brief 05).

## Outputs

### `scripts/autoloads/save_system.gd`

Bump `SAVE_VERSION = 14`.

```gdscript
func _migrate_v13_to_v14(save: Dictionary) -> void:
    var meta: Dictionary = save.get("meta", {}) as Dictionary
    if not meta.has("post_extinction"):
        meta["post_extinction"] = {}
    if not meta.has("first_run_in_era_completed"):
        meta["first_run_in_era_completed"] = []
    if not meta.has("first_era_seen"):
        meta["first_era_seen"] = String(meta.get("current_era_id", ""))
    save["meta"] = meta

    # Backfill scope on any in-flight active events (legacy events stored mid-run).
    var run: Dictionary = save.get("run", {}) as Dictionary
    var active: Array = run.get("active_events", []) as Array
    for entry in active:
        if entry is Dictionary:
            var payload: Dictionary = entry.get("payload", {}) as Dictionary
            if not payload.has("scope"):
                payload["scope"] = "world"
            entry["payload"] = payload
    run["active_events"] = active
    save["run"] = run
```

Wire into the migration chain alongside `_migrate_v12_to_v13`.

### Defensive load repair extension

In `_repair_species_unlocked`, also ensure the three new fields exist (guards against v14 saves created without going through migration):

```gdscript
if not meta.has("post_extinction"):
    meta["post_extinction"] = {}
if not meta.has("first_run_in_era_completed"):
    meta["first_run_in_era_completed"] = []
if not meta.has("first_era_seen"):
    meta["first_era_seen"] = String(meta.get("current_era_id", ""))
```

## ARCHITECTURE.md updates

§9 save schema — append v13 → v14 row.

## Acceptance criteria

- [ ] `SAVE_VERSION = 14`.
- [ ] `_migrate_v13_to_v14` runs once.
- [ ] `meta.post_extinction = {}`, `meta.first_run_in_era_completed = []`, `meta.first_era_seen` set correctly.
- [ ] Active events get `scope = "world"` backfill if missing.
- [ ] v11 → v12 → v13 → v14 chain runs cleanly on old saves.
- [ ] Loading a fresh v14 save is a no-op.

## Out of scope

- Reading the new fields (brief 05 does that).
- Schema changes on `BiomeData`, `EventData`, `EvolutionNodeData` (briefs 02, 04, 06).
