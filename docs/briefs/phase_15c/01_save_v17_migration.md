# Brief 01 — Save v16 → v17 migration

**Suggested agent**: ChatGPT 5.2. Route diff to Claude.

Read first:
1. `scripts/autoloads/save_system.gd` — migration chain.

## Goal

Bump save schema to v17. Add `run.adaptation` (current pool) and `run.species_levels` (per-species mid-run level).

## Outputs

### `scripts/autoloads/save_system.gd`

Bump `SAVE_VERSION = 17`.

```gdscript
func _migrate_v16_to_v17(save: Dictionary) -> void:
    var run: Dictionary = save.get("run", {}) as Dictionary
    if not run.has("adaptation"):
        run["adaptation"] = 0.0
    if not run.has("species_levels"):
        run["species_levels"] = {}    # species_id (String) -> level (int, default 1)
    save["run"] = run
```

Wire into chain.

### Defensive `_repair_species_unlocked` extension

Add the new run fields so saves loaded outside migration still have them:

```gdscript
if not run.has("adaptation"):
    run["adaptation"] = 0.0
if not run.has("species_levels"):
    run["species_levels"] = {}
```

### Reset on prestige

`PrestigeSystem._reset_run_state` already builds a fresh run dict. Add the two new fields to the template:

```gdscript
var fresh_run := {
    # ... existing fields ...
    "adaptation": 0.0,
    "species_levels": {}
}
```

## ARCHITECTURE.md updates

§9 save schema — append v16 → v17 row.

## Acceptance criteria

- [ ] `SAVE_VERSION = 17`.
- [ ] `_migrate_v16_to_v17` runs once on a v16 save.
- [ ] `run.adaptation = 0.0`, `run.species_levels = {}` after migration.
- [ ] Fresh v17 save loads as no-op.
- [ ] Prestige resets both fields.
- [ ] v11→…→v17 chain runs on old saves without error.

## Out of scope

- Earning / spending logic (brief 02 / 03).
- UI display (brief 02 / 03).
- New placement rules (brief 04).
