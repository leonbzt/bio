# Brief 04 — Five new species files

**Suggested agent**: Kilo for the .tres scaffolding. **Claude writes the `description` voice text directly.**

Read first:
1. `docs/SPECIES_ROSTER.md` — full roster table.
2. `data/species/mycelium_thread_mycorrhizal.tres` — most recent species file for format reference.
3. `data/species/_index.tres` — register new species here.

## Goal

Author 5 new species files and register them in the species index. Includes:
- Cryogenian: **Cyanobacterial Mat**, **Vent Archaeon**, **Cryo-Lichen** (recipe)
- Devonian: **Tree-Fern Stem**, **Wood-Rot Bracket**

Each species needs every field including the Phase 14a additions (latin_name, lineage_id, biome_affinity).

## Per-species .tres content

### `data/species/cyanobacterial_mat.tres`

```
[gd_resource type="Resource" script_class="SpeciesData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/species_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"cyanobacterial_mat"
display_name = "Cyanobacterial Mat"
description = "A thin green skin across the ice and rock. The first to make oxygen worth breathing."
kingdom_id = &"plantae"
sprite = null
base_traits = Array[Resource]([])
colonize_cost = {
"biomass": 2.0
}
tick_yield = {
"biomass": 0.2,
"nutrients": 0.1
}
introduce_cost = {}
placement_rule = &"adjacent_empty"
placement_targets = Array[StringName]([])
tags = Array[StringName]([&"plantae", &"pioneer", &"nitrogen_fixer"])
tick_effects = Array[StringName]([])
unlock_ep_cost = 0
unlock_prerequisites = Array[StringName]([])
era_requires = &"cryogenian"
recipe_components = Array[StringName]([])
tile_marker_color = Color(0.35, 0.65, 0.50, 1.0)
tile_marker_shape = &"square"
latin_name = "Oscillatoria princeps (Proterozoic-Cambrian)"
lineage_id = &"pioneer_stem"
biome_affinity = {
&"rich_soil": 1.1,
&"forest_edge": 0.9,
&"grassland": 1.0
}
```

Note: `era_requires = &"cryogenian"` makes this species visible only in Cryogenian ecosystems. Phase 14b's tundra/polar_ice biomes will get the proper 1.2-1.3 affinity boosts there. For now (legacy biomes), it sits at neutral.

### `data/species/vent_archaeon.tres`

```
[gd_resource type="Resource" script_class="SpeciesData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/species_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"vent_archaeon"
display_name = "Vent Archaeon"
description = "Heat-eaters. They wait at the cracks where the deep world breathes."
kingdom_id = &"fungi"
sprite = null
base_traits = Array[Resource]([])
colonize_cost = {
"spores": 3.0
}
tick_yield = {
"biomass": 0.25,
"decay": 0.15
}
introduce_cost = {
"biomass": 60.0
}
placement_rule = &"fungi_substrate"
placement_targets = Array[StringName]([])
tags = Array[StringName]([&"fungi", &"pioneer", &"extremophile"])
tick_effects = Array[StringName]([])
unlock_ep_cost = 4
unlock_prerequisites = Array[StringName]([&"mycelium_thread"])
era_requires = &"cryogenian"
recipe_components = Array[StringName]([])
tile_marker_color = Color(0.30, 0.25, 0.40, 1.0)
tile_marker_shape = &"spore"
latin_name = "Pyrolobus fumarii (extremophile, all eras)"
lineage_id = &"extremophile"
biome_affinity = {
&"rich_soil": 0.5,
&"forest_edge": 0.4,
&"grassland": 0.3
}
```

The 1.8× volcanic_vent affinity referenced in SPECIES_ROSTER.md applies once the `mineral_vent` biome ships in Phase 14b. Until then, all biomes are sub-1.0 (Vent Archaeon is hostile-environment-only by design).

### `data/species/cryo_lichen.tres` (recipe species)

```
[gd_resource type="Resource" script_class="SpeciesData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/species_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"cryo_lichen"
display_name = "Cryo-Lichen"
description = "Cyanobacteria woven into mycelium. The two of them survive what neither could alone."
kingdom_id = &"fungi"
sprite = null
base_traits = Array[Resource]([])
colonize_cost = {}
tick_yield = {}
introduce_cost = {
"biomass": 100.0,
"spores": 40.0
}
placement_rule = &"recipe"
placement_targets = Array[StringName]([])
tags = Array[StringName]([])
tick_effects = Array[StringName]([])
unlock_ep_cost = 5
unlock_prerequisites = Array[StringName]([&"cyanobacterial_mat", &"mycelium_thread"])
era_requires = &"cryogenian"
recipe_components = Array[StringName]([&"cyanobacterial_mat", &"mycelium_thread"])
tile_marker_color = Color(0.6, 0.7, 0.55, 1.0)
tile_marker_shape = &"square"
latin_name = "Lecidea atrobrunnea (Proterozoic-now)"
lineage_id = &"lichen"
biome_affinity = {
&"rich_soil": 1.2,
&"forest_edge": 1.0
}
```

Recipe species have empty `tick_yield` (components yield independently per the kingdom-slot model).

### `data/species/tree_fern_stem.tres`

```
[gd_resource type="Resource" script_class="SpeciesData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/species_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"tree_fern_stem"
display_name = "Tree-Fern Stem"
description = "Vascular tissue at last. The first tall thing in a world that had been low."
kingdom_id = &"plantae"
sprite = null
base_traits = Array[Resource]([])
colonize_cost = {
"biomass": 5.0
}
tick_yield = {
"biomass": 0.5,
"nutrients": 0.2
}
introduce_cost = {
"biomass": 80.0
}
placement_rule = &"adjacent_empty"
placement_targets = Array[StringName]([])
tags = Array[StringName]([&"plantae", &"successor", &"arborescent"])
tick_effects = Array[StringName]([])
unlock_ep_cost = 6
unlock_prerequisites = Array[StringName]([&"pioneer_grass"])
era_requires = &"devonian"
recipe_components = Array[StringName]([])
tile_marker_color = Color(0.30, 0.55, 0.25, 1.0)
tile_marker_shape = &"leaf"
latin_name = "Wattieza muschelae (Middle Devonian)"
lineage_id = &"arborescent"
biome_affinity = {
&"forest_edge": 1.3,
&"rich_soil": 1.2,
&"grassland": 0.9
}
```

### `data/species/wood_rot_bracket.tres`

```
[gd_resource type="Resource" script_class="SpeciesData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/species_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"wood_rot_bracket"
display_name = "Wood-Rot Bracket"
description = "A fungus that learned to eat wood. The first organism in 400 million years that did. Everything else burned. This one rotted."
kingdom_id = &"fungi"
sprite = null
base_traits = Array[Resource]([])
colonize_cost = {
"spores": 3.0
}
tick_yield = {
"biomass": 0.3,
"decay": 0.6,
"spores": 0.1
}
introduce_cost = {
"spores": 60.0,
"biomass": 30.0
}
placement_rule = &"fungi_substrate"
placement_targets = Array[StringName]([])
tags = Array[StringName]([&"fungi", &"saprotroph"])
tick_effects = Array[StringName]([&"corpse_decay"])
unlock_ep_cost = 5
unlock_prerequisites = Array[StringName]([&"mycelium_thread"])
era_requires = &"devonian"
recipe_components = Array[StringName]([])
tile_marker_color = Color(0.55, 0.35, 0.20, 1.0)
tile_marker_shape = &"root"
latin_name = "Prototaxites loganii (Silurian-Devonian, gigantic)"
lineage_id = &"saprotroph"
biome_affinity = {
&"forest_edge": 1.2,
&"rich_soil": 1.1
}
```

## Update `data/species/_index.tres`

Append the 5 new species to the index. Increment `load_steps` accordingly.

## Update `data/ecosystems/*.tres` `starting_species_filter`

Expand filters to include the new species where appropriate (per SPECIES_ROSTER.md guidance):

| Ecosystem | New filter additions |
|---|---|
| `cryo_polar_ice` | + `&"cyanobacterial_mat"`, `&"cryo_lichen"` |
| `cryo_volcanic_vent` | + `&"vent_archaeon"` |
| `cryo_under_ice_sea` | + `&"cyanobacterial_mat"` |
| `dev_tidal_pool` | unchanged |
| `dev_forest_edge` | empty (any unlocked, so all new species eligible if era matches) |
| `dev_inland_swamp` | + `&"tree_fern_stem"`, `&"wood_rot_bracket"` |

## Species panel + picker UI update

Light touch — when rendering a species card or row, show `latin_name` as a smaller secondary text or tooltip on hover:

```gdscript
# In species_panel.gd._build_introduced_row and _build_available_row,
# also in starting_species_picker.gd._build_card:
if species.latin_name != "":
    var lat := Label.new()
    lat.text = species.latin_name
    lat.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
    lat.add_theme_font_size_override("font_size", 10)
    # Append to the same vbox / row container.
```

## Acceptance criteria

- [ ] All 5 new species files load in inspector.
- [ ] All 5 registered in `data/species/_index.tres`.
- [ ] Each species has all Phase 14a fields populated.
- [ ] Ecosystem filters updated; new species appear in their eligible Cryogenian/Devonian pickers.
- [ ] Cryo-Lichen recipe placement works (places cyanobacterial_mat + mycelium_thread atomically).
- [ ] Vent Archaeon, Wood-Rot Bracket follow fungi placement rule + tick effects.
- [ ] Tree-Fern Stem has `successor` tag (predicate handler is Phase 14a brief 06's pioneer wiring — successor stays as a no-op tag for v1).
- [ ] Latin names visible in the picker/panel UI.

## Out of scope

- Tundra/mineral_vent/swamp biome-specific affinity values (Phase 14b once those biomes ship).
- Successor predicate enforcement (Phase 15 — tag is authored, not yet wired).
- Pollinator/allelopath/nitrogen_fixer predicates (Phase 15 — Cyanobacterial Mat has `nitrogen_fixer` tag but no behavior yet).
- Species pricing balance (smoke test pass; adjust after Phase 14a ships).
