# Brief 03 — Fungi content (species + traits)

**Suggested agent**: Kilo Code free model for the .tres files. ChatGPT if Kilo struggles with format.

Read first:
1. `docs/ARCHITECTURE.md` § 4 (`SpeciesData`, `TraitData` schemas).
2. `data/species/pioneer_grass.tres` and `data/traits/fast_growth.tres` — pattern to mirror.
3. `scripts/data/species_data.gd` — note `tick_yield` is `Dictionary` keyed by resource id.

## Goal
One fungi species and two fungi-specific traits. The fungi species generates decay + spores per tick (instead of biomass like plantae).

## Outputs (create)

### Traits — `data/traits/`

**`mycorrhizal_network.tres`** — fungi-only trait
- `id = &"mycorrhizal_network"`
- `display_name = "Mycorrhizal Network"`
- `description = "Adjacent fungi tiles share nutrient absorption."`
- `modifiers = {"nutrient_multiplier": 1.15, "spore_per_tile": 0.05}`
- `tradeoff_summary = "+15% nutrients shared / +5% spore yield"`

**`saprophytic_efficiency.tres`** — fungi-only trait
- `id = &"saprophytic_efficiency"`
- `display_name = "Saprophytic Efficiency"`
- `description = "Better at extracting nutrients from decay."`
- `modifiers = {"decay_per_tile": 0.2, "colonize_cost": -0.1}`
- `tradeoff_summary = "+20% decay yield / -10% colonize cost"`

### Species — `data/species/`

**`mycelium_thread.tres`** — starter fungus
- `id = &"mycelium_thread"`
- `display_name = "Mycelium Thread"`
- `kingdom_id = &"fungi"`
- `sprite = null` (Phase 7 polish)
- `base_traits = [load("res://data/traits/mycorrhizal_network.tres")]`
- `colonize_cost = {"spores": 3.0}`
- `tick_yield = {"decay": 0.4, "spores": 0.15}`

## .tres format
Use the existing `.tres` template from `data/species/pioneer_grass.tres` and biome/trait files. Critical bits:
- Species: `load_steps` = 2 + number of base traits (one ExtResource per trait).
- Trait: `load_steps = 2`.

## Update `data/species/_index.tres`
You may not have a species index yet; if not, create it now (mirrors `BiomeIndex` / `EvolutionTreeIndex` pattern). This is required so GrowthSystem (brief 04) can route from `kingdom_id` to species without DirAccess.

Schema `scripts/data/species_index.gd`:
```gdscript
class_name SpeciesIndex
extends Resource

@export var species: Array[SpeciesData] = []
```

Index file `data/species/_index.tres`:
```
[gd_resource type="Resource" script_class="SpeciesIndex" load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/data/species_index.gd" id="1"]
[ext_resource type="Resource" path="res://data/species/pioneer_grass.tres" id="2"]
[ext_resource type="Resource" path="res://data/species/bramble.tres" id="3"]
[ext_resource type="Resource" path="res://data/species/mycelium_thread.tres" id="4"]

[resource]
script = ExtResource("1")
species = Array[Resource]([ExtResource("2"), ExtResource("3"), ExtResource("4")])
```

## Update `data/traits/_index.tres` (if you have one)
If you don't yet — create it now with all 5 traits (the 3 plantae ones plus the 2 new fungi ones). Schema:

```gdscript
class_name TraitIndex
extends Resource

@export var traits: Array[TraitData] = []
```

The exporter only includes traits referenced from the trait index (or from species `base_traits`, which already happens). The index is mostly for future systems to enumerate.

## Acceptance criteria
- [ ] Files load in Godot without errors.
- [ ] Species index returns 3 entries.
- [ ] `mycelium_thread.kingdom_id == &"fungi"`, `tick_yield` has decay + spores (no biomass).
- [ ] `colonize_cost` uses spores, not biomass.

## Out of scope
- Multiple fungi species. One species is enough for Phase 5.
- Adding more plantae species. Existing two are fine.
- Visual sprites for fungi. Phase 7.
