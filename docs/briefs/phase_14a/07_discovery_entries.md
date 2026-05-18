# Brief 07 — Discovery entries (5 species + 3 lineage milestones)

**Suggested agent**: Claude writes voice text directly.

Read first:
1. `data/discovery/disc_kingdom_plantae.tres` + voice reference entries.
2. `docs/STORY_AND_TONE.md` (if exists) — voice rules.
3. `docs/SPECIES_ROSTER.md` — lineage definitions.

## Goal

Author 8 new discovery entries:
- 5 species entries (one per new species from brief 04).
- 3 lineage-milestone entries (pioneer_stem reaches 2 eras; mycorrhizal reaches 2 eras; lichen reaches 2 eras).

Wire `DiscoveryLog._on_species_introduced` to also check lineage milestones.

## New entry files

### 1. `disc_species_cyanobacterial_mat.tres`

```
title = "The First Skin"
body = "A green film across the ice. It learns to breathe with a sun that barely reaches.
Every breath you take, every plant you walk past, every cell you are made of — they all came from this. Don't be fooled by how thin it looks."
category = &"species"
trigger_id = &"cyanobacterial_mat"
```

### 2. `disc_species_vent_archaeon.tres`

```
title = "The Wait at the Crack"
body = "Single cells the size of nothing, gathered where the deep world breathes heat into the cold.
They don't know they are first. They aren't first. They are simply still there, and that is the same thing."
category = &"species"
trigger_id = &"vent_archaeon"
```

### 3. `disc_species_cryo_lichen.tres`

```
title = "Two Cold Bodies, One Survival"
body = "Cyanobacteria woven into fungal thread. The bacteria photograph the light; the fungus holds them above the ice.
Together they survive what neither could alone. The blueprint is older than most of what calls itself alive."
category = &"species"
trigger_id = &"cryo_lichen"
```

### 4. `disc_species_tree_fern_stem.tres`

```
title = "Standing Up"
body = "Conducting tissue. Lignin. Height. The first thing on land that grew above the height of a thumb and stayed.
You raise your leaves into a sky that has never had anything in it but cloud and weather. From now on, there are also you."
category = &"species"
trigger_id = &"tree_fern_stem"
```

### 5. `disc_species_wood_rot_bracket.tres`

```
title = "The First Decomposer of Wood"
body = "Lignin is a molecule the world had not known what to do with. For sixty million years, dead trees did not decay — they accumulated, fell over, and became coal.
Then a fungus learned the trick. The carbon began to move again. Without this, nothing recycles."
category = &"species"
trigger_id = &"wood_rot_bracket"
```

### 6. `disc_lineage_pioneer_stem.tres`

```
title = "The Lineage of Beginnings"
body = "From bacterial mat to vascular stem, the same impulse: be first, hold light, ask nothing of the soil that the soil cannot give.
You have carried this lineage forward across more than one age. The same project, two implementations."
category = &"milestone"
trigger_id = &"lineage_pioneer_stem"
```

### 7. `disc_lineage_mycorrhizal.tres`

```
title = "The Network Beneath"
body = "Threads in the soil have looked the same for half a billion years. They reach what roots cannot reach, and what they reach, the roots receive.
You have grown them under two different worlds. The pattern remembers itself."
category = &"milestone"
trigger_id = &"lineage_mycorrhizal"
```

### 8. `disc_lineage_lichen.tres`

```
title = "The Partnership That Outlasts"
body = "Two organisms agreeing to be one organism. Cyanobacteria with fungus. Algae with fungus. The contract is always different and always works.
You have made this partnership in more than one age. The form survives the era that named it."
category = &"milestone"
trigger_id = &"lineage_lichen"
```

## Update `data/discovery/_index.tres`

Append all 8 new entries. Increment `load_steps`.

## DiscoveryLog wiring

Extend `scripts/autoloads/discovery_log.gd._on_species_introduced` to also track lineage milestones:

```gdscript
func _on_species_introduced(species_id: StringName) -> void:
    if species_id == &"":
        return
    var entry := find_entry_for_trigger(&"species", species_id)
    if entry != &"":
        unlock(entry)

    # Phase 14a: lineage tracking.
    var species: SpeciesData = _lookup_species(species_id)
    if species == null:
        return
    var lineage: StringName = species.lineage_id
    if lineage == &"":
        return
    var played: Array = GameState.meta_save.get("lineages_played", []) as Array
    var ecosystem_id: StringName = StringName(GameState.meta_save.get("current_ecosystem_id", ""))
    var lineage_key: String = "%s@%s" % [String(lineage), String(ecosystem_id)]
    var seen: Array = GameState.meta_save.get("lineage_ecosystems_seen", []) as Array
    if not seen.has(lineage_key):
        seen.append(lineage_key)
        GameState.meta_save["lineage_ecosystems_seen"] = seen
    # Count distinct ERAS this lineage has been played in.
    var eras_for_lineage: Dictionary = {}
    var era_system := _get_era_system()
    if era_system != null:
        for key in seen:
            var parts: PackedStringArray = String(key).split("@")
            if parts.size() == 2 and parts[0] == String(lineage):
                var eco_id: StringName = StringName(parts[1])
                var eco = era_system.get_ecosystem(eco_id)
                if eco != null:
                    eras_for_lineage[String(eco.era_id)] = true
    if eras_for_lineage.size() >= 2:
        # Lineage spans 2+ eras — unlock milestone.
        var milestone := find_entry_for_trigger(&"milestone", StringName("lineage_" + String(lineage)))
        if milestone != &"":
            unlock(milestone)


func _lookup_species(species_id: StringName) -> SpeciesData:
    if not has_node("/root/SpeciesIndex"):
        return _load_species_for_lookup(species_id)
    return _load_species_for_lookup(species_id)


func _load_species_for_lookup(species_id: StringName) -> SpeciesData:
    var index: SpeciesIndex = load("res://data/species/_index.tres") as SpeciesIndex
    if index == null:
        return null
    for sp in index.species:
        if sp.id == species_id:
            return sp
    return null


func _get_era_system() -> Node:
    if has_node("/root/EraSystem"):
        return get_node("/root/EraSystem")
    return null
```

Note: this uses `lineage_ecosystems_seen` as a stored set ("lineage@ecosystem" composite keys). Phase 14b's save migration can add this field to the schema; for Phase 14a, the dict-as-default-empty pattern just works (existing `.get(key, [])` returns empty on first run).

## Acceptance criteria

- [ ] All 8 new discovery entries load in inspector.
- [ ] All 8 registered in `_index.tres`.
- [ ] Introducing a new species (or starting a run with one) unlocks the matching `disc_species_*` entry.
- [ ] Cultivating Cyanobacterial Mat in Cryogenian + Pioneer Stem in Devonian unlocks `disc_lineage_pioneer_stem`.
- [ ] Cultivating Mycelium Thread in 2 different ecosystems across 2 eras unlocks `disc_lineage_mycorrhizal`.
- [ ] Cultivating Cryo-Lichen + Devonian Lichen unlocks `disc_lineage_lichen`.
- [ ] Entry count denominator updates by +8.

## Out of scope

- Discovery entries for `extremophile`, `arborescent`, `saprotroph`, `tetrapod_browser`, `tetrapod_predator`, `parasitic_climber` lineage milestones (Phase 15+ when more eras exist for them to span).
- New biome discovery entries (Phase 14b — for tundra/mineral_vent/swamp).
- Tooltip integration of lineage info.
- Lineage tree visualization UI.
