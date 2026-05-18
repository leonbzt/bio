# Brief 01 — Save v11 → v12 migration (species-first model)

**Suggested agent**: ChatGPT 5.2. Route diff to **Claude** — lossless tile transform is the high-risk surface.

Read first:
1. `scripts/autoloads/save_system.gd` — `SAVE_VERSION`, migration chain, `_migrate_*` functions.
2. `docs/briefs/phase_12/01_save_v11_migration.md` for the established migration pattern.
3. `docs/SPECIES_MODEL.md` §"Save shape (v11 → v12)" — schema target.

## Goal

Bump save schema to v12. Transform v11 saves into the species-first shape **losslessly for normal Phase 12 runs**. Lossy only for niche-specific tile variant data (e.g., a parasitic plantae tile loses its niche flavor and becomes a generic plantae tile with `bramble` as the run's starter species — the visible plantae stays put; the niche metadata is gone).

Brief 02 lands the new `SpeciesData` schema; Brief 03 lands the new `EcosystemData` schema. **This brief assumes both have already landed in the codebase** — order in brief 00 routing puts them before this one.

## Outputs

### `scripts/autoloads/save_system.gd`

Bump `SAVE_VERSION = 12`.

```gdscript
const _KINGDOM_DEFAULT_STARTERS: Dictionary[StringName, StringName] = {
    &"plantae": &"pioneer_grass",
    &"fungi": &"mycelium_thread",
    &"animals": &"common_grazer"
}

# Niche id -> the species that absorbs its run-state when migrating
# (the starter the player would have been playing under that niche).
const _NICHE_TO_STARTER_SPECIES: Dictionary[StringName, StringName] = {
    &"photosynthesizer": &"pioneer_grass",
    &"parasitic_plantae": &"bramble",
    &"decomposer": &"mycelium_thread",
    &"mycorrhizal_fungi": &"mycelium_thread_mycorrhizal",
    &"lichen": &"lichen_common",
    &"herbivore": &"common_grazer",
    &"predator": &"common_predator"
}

func _migrate_v11_to_v12(save: Dictionary) -> void:
    var meta: Dictionary = save.get("meta", {}) as Dictionary

    # Meta: species_unlocked seeded from kingdoms_played.
    var kingdoms_played: Array = meta.get("kingdoms_played", []) as Array
    var species_unlocked: Array = meta.get("species_unlocked", []) as Array
    for k in kingdoms_played:
        var starter: StringName = _KINGDOM_DEFAULT_STARTERS.get(StringName(k), &"")
        if starter != &"" and not species_unlocked.has(String(starter)):
            species_unlocked.append(String(starter))
    # Always include the default plantae starter (always-unlocked baseline).
    if not species_unlocked.has("pioneer_grass"):
        species_unlocked.append("pioneer_grass")
    meta["species_unlocked"] = species_unlocked

    # Meta: species_played — empty array, builds from future prestiges.
    if not meta.has("species_played"):
        meta["species_played"] = []

    # Meta: niches_played — DELETED.
    meta.erase("niches_played")

    save["meta"] = meta

    # Run: starter species + unlocked-in-run.
    var run: Dictionary = save.get("run", {}) as Dictionary
    var kingdom_id: String = String(run.get("kingdom_id", ""))
    var niche_id: String = String(run.get("niche_id", ""))

    var starter_species: StringName = &""
    if niche_id != "":
        starter_species = _NICHE_TO_STARTER_SPECIES.get(StringName(niche_id), &"")
    if starter_species == &"" and kingdom_id != "":
        starter_species = _KINGDOM_DEFAULT_STARTERS.get(StringName(kingdom_id), &"")

    if starter_species != &"":
        run["starting_species_id"] = String(starter_species)
        var in_run: Array = [String(starter_species)]
        # Lichen run was effectively two species at once — seed both in unlocked_in_run.
        if niche_id == "lichen":
            if not in_run.has("pioneer_grass"):
                in_run.append("pioneer_grass")
            if not in_run.has("mycelium_thread"):
                in_run.append("mycelium_thread")
        run["unlocked_species_in_run"] = in_run
        run["starting_species_kingdom_id"] = kingdom_id

    # Run: niche_id DELETED. kingdom_id retained as read-only mirror for now
    # (Phase 14 deletes it). Both starting_species_kingdom_id and kingdom_id
    # carry the same value during the transition.
    run.erase("niche_id")

    # Run: tiles transform — surface_owner / subsurface_owner → occupants dict.
    var tiles: Array = run.get("tiles", []) as Array
    var migrated_tiles: Array = []
    for entry in tiles:
        if not (entry is Dictionary):
            continue
        var coord: Variant = entry.get("coord", null)
        if coord == null:
            continue
        var data: Dictionary = entry.get("data", {}) as Dictionary
        var surface_owner: String = String(entry.get("surface_owner", ""))
        var subsurface_owner: String = String(entry.get("subsurface_owner", ""))

        var occupants: Dictionary = {}

        if surface_owner == "plantae":
            occupants["plantae"] = String(_pick_species_for_kingdom(starter_species, &"plantae", niche_id))
        elif surface_owner == "animals":
            occupants["animals"] = String(_pick_species_for_kingdom(starter_species, &"animals", niche_id))

        if subsurface_owner == "fungi":
            occupants["fungi"] = String(_pick_species_for_kingdom(starter_species, &"fungi", niche_id))

        if occupants.is_empty():
            continue   # tile had no owners — skip.
        migrated_tiles.append({
            "coord": coord,
            "occupants": occupants,
            "data": data
        })
    run["tiles"] = migrated_tiles
    save["run"] = run


func _pick_species_for_kingdom(starter_species: StringName, kingdom_id: StringName, niche_id: String) -> StringName:
    # If the run's starter belongs to this kingdom, use it.
    # Else fall back to the kingdom default starter.
    # Special case: lichen run uses pioneer_grass for plantae, mycelium_thread for fungi.
    if niche_id == "lichen":
        if kingdom_id == &"plantae":
            return &"pioneer_grass"
        if kingdom_id == &"fungi":
            return &"mycelium_thread"
    var species_index: SpeciesIndex = load("res://data/species/_index.tres") as SpeciesIndex
    if species_index != null:
        for sp in species_index.species:
            if sp.id == starter_species and sp.kingdom_id == kingdom_id:
                return starter_species
    return _KINGDOM_DEFAULT_STARTERS.get(kingdom_id, &"")
```

Wire into the migration chain alongside `_migrate_v10_to_v11`.

### Edge cases

- **Empty v11 save** (no run yet): migration sets `meta.species_unlocked = ["pioneer_grass"]`, `meta.species_played = []`, no run state touched. Harmless.
- **Run mid-flight** (`run.kingdom_id` set, has tiles): full transform as above. Lichen run gets its three-species seed (lichen_common + components).
- **In-flight active_events**: untouched (events don't reference niches or layered species; brief 04 of paused-phase-13 already covered `payload.scope` backfill — we keep that hint here for consistency).

```gdscript
# Backfill scope onto any in-flight active events.
var active: Array = run.get("active_events", []) as Array
for entry in active:
    if entry is Dictionary:
        var payload: Dictionary = entry.get("payload", {}) as Dictionary
        if not payload.has("scope"):
            payload["scope"] = "world"
        entry["payload"] = payload
run["active_events"] = active
```

### Discovery log entry handling

Discovery entries with `category: &"niche"` (currently 4 of them — photosynthesizer, decomposer, parasitic_plantae, mycorrhizal_fungi) **stay in the index unchanged**. Brief 10 re-categorizes them (to `&"species"` or `&"interaction"`) — not this brief.

A v11 save's `meta.discovery_log` dict keys reference entry ids (e.g., `"disc_niche_photosynthesizer"`). Those keys stay valid; the entry ids don't change in brief 10, only their categories do.

## Tests / verification

Manual: load a v11 save (Phase 12 ship state); confirm:
- Save file `version` becomes `12` on first load.
- `meta.species_unlocked` includes `"pioneer_grass"` plus starters for any played kingdoms.
- `meta.species_played` exists (empty if fresh).
- `meta.niches_played` does not exist.
- `run.starting_species_id` matches niche → species mapping (or kingdom default if no niche).
- `run.unlocked_species_in_run` contains starter (+ lichen components for lichen run).
- `run.niche_id` does not exist.
- `run.tiles[*].occupants` dict populated per surface/subsurface owner mapping.
- No gameplay disruption — load straight into world map; if a run was in flight, it resumes with tiles intact.

Edge-case manual:
- Lichen run save: `unlocked_species_in_run = ["lichen_common", "pioneer_grass", "mycelium_thread"]`. Tiles show plantae+fungi occupants per the v11 surface/subsurface.
- Parasitic plantae run save: `starting_species_id = "bramble"`. Tiles show plantae occupants = `"bramble"`.
- Mycorrhizal fungi run save: `starting_species_id = "mycelium_thread_mycorrhizal"` (a new species created in brief 08).

## ARCHITECTURE.md updates

- §9 save schema — append v11 → v12 row with all the field changes (species_unlocked, species_played, starting_species_id, unlocked_species_in_run, tiles.occupants, niches_played deletion, niche_id deletion).

## Acceptance criteria

- [ ] `SAVE_VERSION = 12`.
- [ ] Loading a v11 save runs the migration once, then writes v12 back.
- [ ] All new meta + run fields populated correctly per niche → species mapping.
- [ ] Deleted fields (`niches_played`, `niche_id`) absent in the v12 save.
- [ ] Lichen run save migrates with three species in `unlocked_species_in_run`.
- [ ] Active-event payloads carry `scope` after migration.
- [ ] Loading a fresh v12 save (no migration needed) is a no-op.
- [ ] v10 → v11 chain still runs for older saves.

## Out of scope

- Reading the new fields (briefs 04 + 05 + 07 do that).
- Creating new species `.tres` files (brief 08).
- UI changes (brief 07).
- Schema changes on `SpeciesData` / `EcosystemData` themselves (briefs 02, 03).
