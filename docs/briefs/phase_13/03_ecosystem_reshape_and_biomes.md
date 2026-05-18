# Brief 03 — EcosystemData reshape + biome recipe data

**Suggested agent**: ChatGPT 5.2 for the schema edit. Kilo for the .tres updates. Claude reviews.

Read first:
1. `scripts/data/ecosystem_data.gd` — current schema (Phase 12).
2. `data/ecosystems/*.tres` — 6 ecosystem files.
3. `docs/SPECIES_MODEL.md` §World & Ecosystem — target schema.

## Goal

Reshape `EcosystemData` for the species-first model:
- `biome_preference` (single biome) → `biome_recipe` (weighted dict) + `biome_cluster_size`.
- `completion_required_niche` / `completion_required_kingdom` → `completion_required_species` / `completion_required_biome`.
- Add `starting_species_filter` for the species-picker constraint.

Update all 6 existing ecosystem files to the new shape, preserving Phase 12 intent.

## Schema change

### `scripts/data/ecosystem_data.gd`

```gdscript
class_name EcosystemData
extends Resource
##
## A biome region within an era. Has its own completion criterion and
## constrains the starting-species picker.
##

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var era_id: StringName = &""

# Biome recipe — weighted mix the procedural map generator samples.
# Format: {biome_id: weight_float}. Empty = use legacy uniform-random
# behavior (current Phase 12 generation).
@export var biome_recipe: Dictionary = {}

# Cluster size for biome generation. 1.0 = scattered (per-tile independent).
# Higher values (3.0, 5.0) produce patchier maps with contiguous regions.
@export var biome_cluster_size: float = 1.0

# Completion criterion (Phase 12 fields preserved).
@export var completion_criterion: StringName = &""
@export var completion_target: float = 0.0

# Species/biome completion gates (Phase 13 replacement for niche/kingdom gates).
@export var completion_required_species: StringName = &""
@export var completion_required_biome: StringName = &""

# Starting-species picker constraint. Player picks from this list ∩
# meta.species_unlocked. Empty = all unlocked species eligible.
@export var starting_species_filter: Array[StringName] = []

@export var unlock_text: String = ""
@export var complete_text: String = ""
```

### Removed fields

- `biome_preference` — deleted. Replaced by `biome_recipe`.
- `completion_required_niche` — deleted.
- `completion_required_kingdom` — deleted.

### Save migration impact

The v11 → v12 save migration (brief 01) does **not** touch `EcosystemData` fields (those live in .tres files, not save data). Ecosystem completion state in `meta.ecosystem_completions` keys by ecosystem id — unchanged.

## Updated ecosystem files

Each of the 6 ecosystems gets edited. Keep `id`, `display_name`, `description`, `era_id`, `completion_*` fields' values where they map cleanly.

### `data/ecosystems/cryo_polar_ice.tres`

```
[resource]
script = ExtResource("1")
id = &"cryo_polar_ice"
display_name = "Polar Ice"
era_id = &"cryogenian"
description = "Frozen flats. What grows here, grows slowly."
biome_recipe = {
    &"grassland": 0.2,
    &"rich_soil": 0.3,
    &"forest_edge": 0.5
}
biome_cluster_size = 2.0
completion_criterion = &"tiles_colonized"
completion_target = 30.0
completion_required_species = &""
completion_required_biome = &""
starting_species_filter = [&"mycelium_thread"]
unlock_text = "The first cold. Few species can begin here."
complete_text = "A presence holds in the cold. Patience proved enough."
```

(Note: until Phase 14 ships tundra/mineral_vent biomes, the recipe references existing biomes weighted to feel sparse. Phase 14 swaps in proper cold-biome ids.)

### `data/ecosystems/cryo_volcanic_vent.tres`

```
biome_recipe = {
    &"rich_soil": 0.4,
    &"forest_edge": 0.4,
    &"grassland": 0.2
}
biome_cluster_size = 3.0
completion_criterion = &"biomass_earned"
completion_target = 400.0
completion_required_species = &""
completion_required_biome = &""
starting_species_filter = [&"mycelium_thread"]
```

### `data/ecosystems/cryo_under_ice_sea.tres`

```
biome_recipe = {
    &"rich_soil": 0.6,
    &"grassland": 0.4
}
biome_cluster_size = 4.0
completion_criterion = &"events_survived"
completion_target = 3.0
completion_required_species = &""
completion_required_biome = &""
starting_species_filter = [&"mycelium_thread"]
```

### `data/ecosystems/dev_tidal_pool.tres`

```
biome_recipe = {
    &"rich_soil": 0.6,
    &"forest_edge": 0.4
}
biome_cluster_size = 2.0
completion_criterion = &"tiles_colonized"
completion_target = 40.0
completion_required_species = &""
completion_required_biome = &""
starting_species_filter = [&"pioneer_grass", &"mycelium_thread", &"common_grazer"]
```

### `data/ecosystems/dev_forest_edge.tres`

```
biome_recipe = {
    &"forest_edge": 0.6,
    &"grassland": 0.3,
    &"rich_soil": 0.1
}
biome_cluster_size = 3.0
completion_criterion = &"biomass_earned"
completion_target = 500.0
completion_required_species = &""
completion_required_biome = &""
starting_species_filter = []  # any unlocked species
```

### `data/ecosystems/dev_inland_swamp.tres`

```
biome_recipe = {
    &"rich_soil": 0.5,
    &"forest_edge": 0.3,
    &"grassland": 0.2
}
biome_cluster_size = 2.5
completion_criterion = &"events_survived"
completion_target = 4.0
completion_required_species = &""
completion_required_biome = &""
starting_species_filter = [&"pioneer_grass", &"mycelium_thread", &"bramble"]
```

## NutrientSystem update

`scripts/systems/nutrient_system.gd._generate_biome_map` needs to honor the recipe. Rewrite:

```gdscript
func _generate_biome_map() -> Dictionary:
    var rng := RandomNumberGenerator.new()
    rng.seed = GameState.run_seed

    var width: int = int(_tile_grid.GRID_WIDTH)
    var height: int = int(_tile_grid.GRID_HEIGHT)

    var era_system := _get_era_system()
    var eco: EcosystemData = null
    if era_system != null:
        eco = era_system.get_current_ecosystem()

    var map: Dictionary = {}

    if eco == null or eco.biome_recipe.is_empty():
        # Legacy uniform-random fallback.
        for y in range(height):
            for x in range(width):
                var biome: BiomeData = _biomes[rng.randi_range(0, _biomes.size() - 1)]
                map["%d,%d" % [x, y]] = String(biome.id)
        return map

    # Weighted recipe + cluster bias.
    var cluster_threshold: float = 1.0 - (1.0 / maxf(eco.biome_cluster_size, 1.0))
    for y in range(height):
        for x in range(width):
            var biome_id: StringName = &""
            if rng.randf() < cluster_threshold and (x > 0 or y > 0):
                # Copy from a random already-placed neighbor.
                var src_key: String = ""
                if x > 0 and rng.randf() < 0.5:
                    src_key = "%d,%d" % [x - 1, y]
                elif y > 0:
                    src_key = "%d,%d" % [x, y - 1]
                if src_key in map:
                    biome_id = StringName(map[src_key])
            if biome_id == &"":
                biome_id = _weighted_pick(eco.biome_recipe, rng)
            map["%d,%d" % [x, y]] = String(biome_id)
    return map


func _weighted_pick(recipe: Dictionary, rng: RandomNumberGenerator) -> StringName:
    var total: float = 0.0
    for w in recipe.values():
        total += float(w)
    if total <= 0.0:
        return _biomes[0].id
    var roll: float = rng.randf_range(0.0, total)
    for biome_id in recipe.keys():
        roll -= float(recipe[biome_id])
        if roll <= 0.0:
            return StringName(biome_id)
    return _biomes[0].id


func _get_era_system() -> Node:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null:
        return null
    return tree.root.get_node_or_null("EraSystem")
```

## EraSystem update

`EraSystem._on_prestige_triggered` checks `completion_required_niche` and `completion_required_kingdom`. Update to check the new fields:

```gdscript
# Replace the niche / kingdom gate block:
if eco.completion_required_species != &"":
    var starter: StringName = StringName(GameState.run_save.get("starting_species_id", ""))
    if starter != eco.completion_required_species:
        return
if eco.completion_required_biome != &"":
    # Count tiles colonized on the required biome.
    var biome_tiles: int = _count_owned_tiles_on_biome(eco.completion_required_biome)
    if biome_tiles < int(eco.completion_target):
        return  # criterion already checked, this is the biome-specific narrow.
```

Helper `_count_owned_tiles_on_biome` queries `TerritorySystem.get_all_owned_coords()` (a new method, see brief 04) and looks up each tile's biome via `NutrientSystem.get_biome_at`.

## ARCHITECTURE.md updates

- §4 schema — replace `EcosystemData` entry with the new shape.
- §6 systems — update NutrientSystem generation paragraph (weighted recipe + cluster).

## Acceptance criteria

- [ ] `EcosystemData` schema matches target.
- [ ] All 6 ecosystem .tres files load with the new fields populated per the table above.
- [ ] `NutrientSystem._generate_biome_map` produces deterministic maps per `run_seed`.
- [ ] An ecosystem with empty `biome_recipe` falls back to legacy uniform-random (zero behavior change for that path).
- [ ] An ecosystem with a recipe shows visible biome clustering at `biome_cluster_size >= 2.0`.
- [ ] EraSystem completion check uses `completion_required_species` / `completion_required_biome` instead of niche/kingdom fields.

## Out of scope

- New biome types (Phase 14 — `tundra`, `mineral_vent`, `swamp`).
- Visual era tinting (Phase 14).
- Species picker UI (brief 07).
- New ecosystems beyond the existing 6.
