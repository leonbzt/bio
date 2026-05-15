# Brief 02 — Biome content (.tres)

**Suggested agent**: Kilo Code free model. ChatGPT works too if Kilo struggles with .tres syntax.

Read first:
1. `docs/ARCHITECTURE.md` section 4 — `BiomeData` schema.
2. `scripts/data/biome_data.gd` — fields.
3. `data/README.md` — naming convention.
4. `data/traits/test_photosynthesis.tres` (deleted in brief 00, but check git history for `.tres` format) — or:
5. Look at any existing Godot `.tres` resource file with `[resource]` block.

## Goal
Three `BiomeData` resource files for Phase 2 tiles. These define what each tile yields per tick when colonized.

## Outputs (create)

Three files in `data/biomes/`:

### `data/biomes/grassland.tres`
- `id = &"grassland"`
- `display_name = "Grassland"`
- `sunlight_per_tick = 1.0`
- `nutrient_per_tick = 0.3`
- `decay_per_tick = 0.0`
- `tile_texture` — leave `null` for now (Phase 7 polish replaces the uniform overlay).

### `data/biomes/forest_edge.tres`
- `id = &"forest_edge"`
- `display_name = "Forest Edge"`
- `sunlight_per_tick = 0.7`
- `nutrient_per_tick = 0.7`
- `decay_per_tick = 0.1`

### `data/biomes/rich_soil.tres`
- `id = &"rich_soil"`
- `display_name = "Rich Soil"`
- `sunlight_per_tick = 0.4`
- `nutrient_per_tick = 1.2`
- `decay_per_tick = 0.3`

## .tres file format
Use this template, replacing values:

```
[gd_resource type="Resource" script_class="BiomeData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/biome_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"grassland"
display_name = "Grassland"
sunlight_per_tick = 1.0
nutrient_per_tick = 0.3
decay_per_tick = 0.0
```

Leave `tile_texture` line out entirely if null.

## ALSO: create `data/biomes/_index.tres`

Per `docs/ARCHITECTURE.md` (Content indices), do NOT rely on `DirAccess` to find these — Android exports break that pattern. Build an explicit index resource:

1. Create `scripts/data/biome_index.gd`:
   ```gdscript
   class_name BiomeIndex
   extends Resource

   @export var biomes: Array[BiomeData] = []
   ```
2. Create `data/biomes/_index.tres`:
   ```
   [gd_resource type="Resource" script_class="BiomeIndex" load_steps=5 format=3]

   [ext_resource type="Script" path="res://scripts/data/biome_index.gd" id="1"]
   [ext_resource type="Resource" path="res://data/biomes/grassland.tres" id="2"]
   [ext_resource type="Resource" path="res://data/biomes/forest_edge.tres" id="3"]
   [ext_resource type="Resource" path="res://data/biomes/rich_soil.tres" id="4"]

   [resource]
   script = ExtResource("1")
   biomes = Array[Resource]([ExtResource("2"), ExtResource("3"), ExtResource("4")])
   ```

## Acceptance criteria
- [ ] All three files load in Godot without errors (open one in the editor; the inspector should show all fields).
- [ ] `BiomeData.new()` can be retrieved via `load("res://data/biomes/grassland.tres")` in a test script.
- [ ] `data/biomes/_index.tres` exists and shows all three biomes in the inspector array.
- [ ] Yields differentiate the biomes: grassland = sun-heavy, forest_edge = balanced, rich_soil = nutrient-heavy.

## Rationale (one line each, for designer reference)
- Grassland — open exposure, light soil. Default plant biome.
- Forest edge — partial canopy + leaf litter mixing into soil.
- Rich soil — humic floodplain. Best long-term but slow start.
