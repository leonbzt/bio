# Brief 01 — Save v11 → v12 migration

**Suggested agent**: ChatGPT 5.2. Route diff to Claude — save format.

Read first:
1. `scripts/autoloads/save_system.gd` — `SAVE_VERSION`, migration chain, `_migrate_*` functions.
2. `docs/briefs/phase_12/01_save_v11_migration.md` for the established migration pattern.

## Goal

Bump save schema to v12. Add the meta fields Phase 13 needs:

- `meta.post_extinction: Dictionary` — active recovery state. Default `{}`. When set, contains `{"to_era_id": String, "debuff_ticks_remaining": int}`. Cleared when the post-extinction run prestiges.
- `meta.first_run_in_era_completed: Array[String]` — era ids for which the extinction-survivor EP bonus has already been awarded. Prevents double-grant.
- `meta.first_era_seen: String` — records the era id the player first played in (so re-entering the Cryogenian baseline doesn't trigger a phantom "extinction" debuff). Default = `meta.current_era_id` if set, else `""`.

Also: backfill `scope = "world"` onto any active event payloads carried over from a v11 save (very rare — only matters if a player saves mid-event during the upgrade). The data-file `EventData` resources get their `scope` field set in brief 04; this migration is just for run-state event entries.

## Outputs

### `scripts/autoloads/save_system.gd`

Bump `SAVE_VERSION = 12`.

Add `_migrate_v11_to_v12(save: Dictionary)`:

```gdscript
func _migrate_v11_to_v12(save: Dictionary) -> void:
    var meta: Dictionary = save.get("meta", {}) as Dictionary
    if not meta.has("post_extinction"):
        meta["post_extinction"] = {}
    if not meta.has("first_run_in_era_completed"):
        meta["first_run_in_era_completed"] = []
    if not meta.has("first_era_seen"):
        meta["first_era_seen"] = String(meta.get("current_era_id", ""))
    save["meta"] = meta

    # Backfill scope on any in-flight active events from a v11 save.
    # The data-file events get scope set in brief 04 — this is just runtime state.
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

Wire into the migration chain alongside the existing `_migrate_v10_to_v11` call. Same pattern: bump version, log a one-liner.

### Tests / verification

Manual: load a v11 save (Phase 12 ship state); confirm:
- Save file `version` becomes `12` on first load.
- `meta.post_extinction` exists and equals `{}`.
- `meta.first_run_in_era_completed` exists and equals `[]`.
- `meta.first_era_seen` matches `meta.current_era_id` (likely `"cryogenian"` for fresh-ish saves).
- No gameplay disruption — load straight into world map, run starts cleanly.

## ARCHITECTURE.md updates

- §9 save schema — append v11 → v12 row with the three new meta fields + the in-flight event scope backfill.

## Acceptance criteria

- [ ] `SAVE_VERSION = 12`.
- [ ] Loading a v11 save runs the migration once, then writes v12 back.
- [ ] All three new meta fields exist after migration.
- [ ] Active-event payloads in `run.active_events` carry a `scope` key after migration.
- [ ] Loading a fresh v12 save (no migration needed) is a no-op.
- [ ] No regressions in v10 → v11 chain (the Phase 12 migration still runs for older saves).

## Out of scope

- Reading the new meta fields (briefs 06 + 04 do that).
- Authoring new event content with scope (brief 05).
- Schema changes on `BiomeData`, `EventData`, `EvolutionNodeData` (briefs 02, 04, 07).
