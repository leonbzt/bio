# Brief 01 — Save v12 → v13 migration

**Suggested agent**: ChatGPT 5.2. Route diff to Claude.

Read first:
1. `scripts/autoloads/save_system.gd` — `SAVE_VERSION = 12`, `_migrate_v11_to_v12`.
2. `docs/SPECIES_MODEL.md` §Save shape (v11 → v12) — pattern reference.

## Goal

Bump save schema to v13. Add `meta.lineages_played: Array[String]` for the lineage milestone tracker. Backfill from existing `meta.species_played` by mapping each species id to its lineage_id.

## Outputs

### `scripts/autoloads/save_system.gd`

Bump `SAVE_VERSION = 13`.

```gdscript
# Species id -> lineage id, sourced from SPECIES_ROSTER.md and species .tres files.
# Hardcoded here so migration runs without needing to load species data (saves
# can migrate before content is loaded).
const _SPECIES_TO_LINEAGE: Dictionary[StringName, StringName] = {
    &"pioneer_grass": &"pioneer_stem",
    &"cyanobacterial_mat": &"pioneer_stem",
    &"mycelium_thread": &"mycorrhizal",
    &"mycelium_thread_mycorrhizal": &"mycorrhizal",
    &"bramble": &"parasitic_climber",
    &"lichen_common": &"lichen",
    &"cryo_lichen": &"lichen",
    &"vent_archaeon": &"extremophile",
    &"tree_fern_stem": &"arborescent",
    &"wood_rot_bracket": &"saprotroph",
    &"common_grazer": &"tetrapod_browser",
    &"common_predator": &"tetrapod_predator"
}

func _migrate_v12_to_v13(save: Dictionary) -> void:
    var meta: Dictionary = save.get("meta", {}) as Dictionary
    if not meta.has("lineages_played"):
        meta["lineages_played"] = []
    var lineages: Array = meta.get("lineages_played", []) as Array
    var species_played: Array = meta.get("species_played", []) as Array
    for sp_id in species_played:
        var lineage: StringName = _SPECIES_TO_LINEAGE.get(StringName(sp_id), &"")
        if lineage != &"" and not lineages.has(String(lineage)):
            lineages.append(String(lineage))
    meta["lineages_played"] = lineages
    save["meta"] = meta
```

Wire into the migration chain alongside `_migrate_v11_to_v12`.

### Defensive load repair extension

In `_apply_loaded._repair_species_unlocked`, after the existing species_unlocked seeding, also ensure `lineages_played` exists:

```gdscript
if not meta.has("lineages_played"):
    meta["lineages_played"] = []
```

(Keeps Phase 14a's discovery-log lineage milestones robust against any save weirdness from earlier testing.)

## Tests / verification

Manual: load a v12 save (Phase 13 ship state); confirm:
- Save file `version` becomes `13` on first load.
- `meta.lineages_played` exists.
- If `meta.species_played` had entries (e.g., `"pioneer_grass"`), `lineages_played` contains the matching lineage (`"pioneer_stem"`).
- Loading a fresh v13 save is a no-op.
- v11 → v12 chain still runs for older saves.

## ARCHITECTURE.md updates

§9 save schema — append v12 → v13 row with `meta.lineages_played`.

## Acceptance criteria

- [ ] `SAVE_VERSION = 13`.
- [ ] `_migrate_v12_to_v13` runs once, sets `meta.lineages_played`.
- [ ] Lineage list correctly derived from species_played.
- [ ] No regression in v10/v11/v12 migration chain.
- [ ] Defensive `_repair` ensures `lineages_played` exists on every load.

## Out of scope

- Lineage milestone unlock logic (brief 07).
- New species data (briefs 03 + 04).
- Schema additions on SpeciesData itself (brief 02).
