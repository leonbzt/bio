# Brief 08 — Niche deletion + species content folding

**Suggested agent**: Kilo for the .tres edits. Claude reviews each fold for content fidelity.

Read first:
1. `data/niches/*.tres` — all 7 files (decomposer, herbivore, lichen, mycorrhizal_fungi, parasitic_plantae, photosynthesizer, predator).
2. `data/species/*.tres` — existing 7 species.
3. `docs/SPECIES_MODEL.md` §Species + §Locked Decision 12 (Lichen as recipe).

## Goal

Fold each niche's authored content into its corresponding species (the first in `species_options`). Create new species where niches imply variants that don't exist yet. Delete the entire `data/niches/` folder, `NicheData` + `NicheIndex` scripts, and the autoload `NicheIndex` registration (if any).

## Niche → species fold table

| Niche | Target species | Fields folded |
|---|---|---|
| `photosynthesizer` | `pioneer_grass` (existing) | placement_rule = adjacent_empty (already implicit); no other carry. |
| `decomposer` | `mycelium_thread` (existing) | placement_rule = fungi_substrate; no other carry. |
| `parasitic_plantae` | `bramble` (existing) | placement_rule = parasitic_plantae; placement_targets = [&"plantae", &"fungi"]; tick_effects = [&"parasite_steal"]; tags = [&"parasite"]; introduce_cost = {biomass: 80}; cost_override copied to bramble.colonize_cost. |
| `mycorrhizal_fungi` | `mycelium_thread_mycorrhizal` (**NEW species**) | placement_rule = mycorrhizal_fungi; tick_effects = [&"mycorrhizal_bond_apply"]; tags = []; introduce_cost = {spores: 50, biomass: 30}; cost_override copied. |
| `lichen` | `lichen_common` (existing, restructured) | placement_rule = recipe; recipe_components = [&"pioneer_grass", &"mycelium_thread"]; tags = []; introduce_cost = {biomass: 120, spores: 50}; layer_count + layer_species fields removed. |
| `herbivore` | `common_grazer` (existing) | placement_rule = animal_anchor; tags = [&"herbivore"]; introduce_cost = {} (free starter for animals kingdom). |
| `predator` | `common_predator` (existing) | placement_rule = animal_anchor; tags = [&"predator"]; introduce_cost = {biomass: 100, protein: 30}. |

## New species: `mycelium_thread_mycorrhizal`

Create `data/species/mycelium_thread_mycorrhizal.tres`:

```
[gd_resource type="Resource" script_class="SpeciesData" load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/data/species_data.gd" id="1"]
[ext_resource type="Resource" path="res://data/traits/mycorrhizal_network.tres" id="2"]

[resource]
script = ExtResource("1")
id = &"mycelium_thread_mycorrhizal"
display_name = "Mycorrhizal Mycelium"
description = "A network-leaning mycelium that thrives bound to roots."
kingdom_id = &"fungi"
sprite = null
base_traits = Array[Resource]([ExtResource("2")])
colonize_cost = {
"spores": 4.0
}
tick_yield = {
"biomass": 0.3,
"decay": 0.4,
"spores": 0.15
}
placement_rule = &"mycorrhizal_fungi"
placement_targets = Array[StringName]([])
tags = Array[StringName]([])
tick_effects = Array[StringName]([&"mycorrhizal_bond_apply"])
introduce_cost = {
"spores": 50.0,
"biomass": 30.0
}
unlock_ep_cost = 4
unlock_prerequisites = Array[StringName]([&"mycelium_thread"])
era_requires = &""
recipe_components = Array[StringName]([])
tile_marker_color = Color(0.6, 0.4, 0.7, 1.0)
tile_marker_shape = &"root"
```

Add to `data/species/_index.tres`.

## Updated species files (examples — full edits in implementation)

### `data/species/pioneer_grass.tres` add fields

```
placement_rule = &"adjacent_empty"
placement_targets = Array[StringName]([])
tags = Array[StringName]([&"plantae"])
tick_effects = Array[StringName]([])
introduce_cost = {}
unlock_ep_cost = 0
unlock_prerequisites = Array[StringName]([])
era_requires = &""
recipe_components = Array[StringName]([])
tile_marker_color = Color(0.45, 0.75, 0.35, 1.0)
tile_marker_shape = &"leaf"
```

### `data/species/mycelium_thread.tres` add fields

```
placement_rule = &"fungi_substrate"
placement_targets = Array[StringName]([])
tags = Array[StringName]([&"fungi"])
tick_effects = Array[StringName]([])
introduce_cost = {}
unlock_ep_cost = 0
unlock_prerequisites = Array[StringName]([])
era_requires = &""
recipe_components = Array[StringName]([])
tile_marker_color = Color(0.55, 0.40, 0.70, 1.0)
tile_marker_shape = &"spore"
```

### `data/species/bramble.tres` add fields

```
placement_rule = &"parasitic_plantae"
placement_targets = Array[StringName]([&"plantae", &"fungi"])
tags = Array[StringName]([&"parasite", &"plantae"])
tick_effects = Array[StringName]([&"parasite_steal"])
introduce_cost = {"biomass": 80.0}
unlock_ep_cost = 3
unlock_prerequisites = Array[StringName]([&"pioneer_grass"])
era_requires = &""
recipe_components = Array[StringName]([])
tile_marker_color = Color(0.4, 0.35, 0.2, 1.0)
tile_marker_shape = &"cross"
```

(Note: `bramble.colonize_cost` should match the previous niche's `cost_override = {biomass: 3.0}`.)

### `data/species/lichen_common.tres` rewrite

Delete `layer_count`, `layer_species`. Add:

```
placement_rule = &"recipe"
placement_targets = Array[StringName]([])
tags = Array[StringName]([])
tick_effects = Array[StringName]([])
introduce_cost = {"biomass": 120.0, "spores": 50.0}
unlock_ep_cost = 5
unlock_prerequisites = Array[StringName]([&"pioneer_grass", &"mycelium_thread"])
era_requires = &""
recipe_components = Array[StringName]([&"pioneer_grass", &"mycelium_thread"])
tile_marker_color = Color(0.7, 0.7, 0.4, 1.0)
tile_marker_shape = &"square"
colonize_cost = {}  # recipe pays component costs; recipe's own cost = 0
```

### `data/species/common_grazer.tres` add fields

```
placement_rule = &"animal_anchor"
placement_targets = Array[StringName]([])
tags = Array[StringName]([&"herbivore", &"animals"])
tick_effects = Array[StringName]([])
introduce_cost = {}
unlock_ep_cost = 0
unlock_prerequisites = Array[StringName]([])
era_requires = &""
recipe_components = Array[StringName]([])
tile_marker_color = Color(0.9, 0.65, 0.25, 1.0)
tile_marker_shape = &"border"
```

### `data/species/common_predator.tres` add fields

```
placement_rule = &"animal_anchor"
placement_targets = Array[StringName]([])
tags = Array[StringName]([&"predator", &"animals"])
tick_effects = Array[StringName]([])
introduce_cost = {"biomass": 100.0, "protein": 30.0}
unlock_ep_cost = 4
unlock_prerequisites = Array[StringName]([&"common_grazer"])
era_requires = &""
recipe_components = Array[StringName]([])
tile_marker_color = Color(0.6, 0.2, 0.2, 1.0)
tile_marker_shape = &"border"
```

## Deletions

Delete all of the following:

```
data/niches/decomposer.tres
data/niches/herbivore.tres
data/niches/lichen.tres
data/niches/mycorrhizal_fungi.tres
data/niches/parasitic_plantae.tres
data/niches/photosynthesizer.tres
data/niches/predator.tres
data/niches/_index.tres
data/niches/                              (the empty folder itself)
scripts/data/niche_data.gd
scripts/data/niche_data.gd.uid
scripts/data/niche_index.gd
scripts/data/niche_index.gd.uid
```

After deletion, grep the codebase for any remaining references to `NicheData`, `NicheIndex`, `NICHE_INDEX_PATH`, `current_niche_id`, `niche_id`. Expected remaining references after briefs 04 + 05 + 06 + 07 land:
- `growth_system.gd` — should be zero after brief 05.
- `colonization_rules_registry.gd` — should be zero after brief 06.
- `multi_layer_placement.gd` — file deleted in brief 06.
- `parasite_steal_system.gd` — file deleted in brief 05.
- `discovery_log.gd` — `niche_changed` signal handler — delete the function and the signal connection.
- `event_bus.gd` — `niche_changed` signal — delete.
- `prestige_system.gd` — niche-related code in start_run — already updated in brief 07.

If any references remain, fix in this brief.

## Evolution tree updates

The two niche-unlock nodes redirect:

### `data/evolution_tree/unlock_parasitic_plantae.tres`
```
grants_kingdoms = Array[StringName]([])    # cleared
grants_species = Array[StringName]([&"bramble"])
```
(`grants_species` is a new field on `EvolutionNodeData` — schema add lands in brief 02's adjacent scope, or directly in this brief. Confirm the field exists; if not, add it.)

### `data/evolution_tree/unlock_mycorrhizal_fungi.tres`
```
grants_kingdoms = Array[StringName]([])
grants_species = Array[StringName]([&"mycelium_thread_mycorrhizal"])
```

### `data/evolution_tree/unlock_symbiosis.tres` (currently redirected to lichen)
```
grants_kingdoms = Array[StringName]([])
grants_species = Array[StringName]([&"lichen_common"])
```

### `data/evolution_tree/unlock_fungi.tres`
```
grants_kingdoms = Array[StringName]([&"fungi"])    # kept — auto-unlocks default starter
grants_species = Array[StringName]([&"mycelium_thread"])
```

### `data/evolution_tree/unlock_animals.tres`
```
grants_kingdoms = Array[StringName]([&"animals"])
grants_species = Array[StringName]([&"common_grazer"])
```

## EvolutionNodeData schema add

Add to `scripts/data/evolution_node_data.gd`:

```gdscript
@export var grants_species: Array[StringName] = []
```

PrestigeSystem's purchase handler reads both `grants_kingdoms` (kept for back-compat) and `grants_species` (new). When a node with `grants_species` is purchased, append each species id to `meta.species_unlocked`.

## Acceptance criteria

- [ ] `data/niches/` folder gone.
- [ ] `scripts/data/niche_data.gd` + `niche_index.gd` gone.
- [ ] All 7 existing species files updated with the new species fields populated per the tables.
- [ ] `mycelium_thread_mycorrhizal` species exists and loads.
- [ ] `lichen_common` no longer has `layer_count` or `layer_species`; has `recipe_components` set.
- [ ] 5 evolution unlock nodes have `grants_species` set; PrestigeSystem applies them on purchase.
- [ ] Grep for `current_niche_id`, `niche_id`, `NicheData`, `NicheIndex` returns zero hits.
- [ ] Save migration (brief 01) tested again — still works (this brief shouldn't break it; the migration maps niche → species without reading niche .tres files).

## Out of scope

- New species beyond the mycorrhizal mycelium (Phase 14 — cordyceps, mycoheterotroph, scavenger).
- Trait additions to existing species (Phase 14).
- Re-balance of tick_yield values (Phase 14 balance pass).
- Niche-discovery-entry re-categorization (brief 10).
