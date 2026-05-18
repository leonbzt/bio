# Brief 02 — New biome data + chemosynthesis_per_tick

**Suggested agent**: ChatGPT 5.2 for schema, Kilo for .tres files.

Read first:
1. `scripts/data/biome_data.gd` — current schema.
2. `docs/briefs/phase_13_paused/02_biome_schema_and_data.md` — source material.
3. `docs/SPECIES_ROSTER.md` — biome affinities reference these biomes.

## Goal

Add three new biomes (tundra, mineral_vent, swamp). Add `chemosynthesis_per_tick` field to `BiomeData`. Update growth_system fungi-biomass branch to read the new field. Update biome index. Update Cryogenian / Devonian ecosystem `biome_recipe` dicts to reference the new biomes.

## Schema

### `scripts/data/biome_data.gd`

Append:

```gdscript
# Phase 14b: biomes can supply biomass via chemosynthesis (volcanic vents,
# mineral substrate). Plantae get this at 0.5×; fungi at full.
@export var chemosynthesis_per_tick: float = 0.0
```

## New biome files

### `data/biomes/tundra.tres`

```
[gd_resource type="Resource" script_class="BiomeData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/biome_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"tundra"
display_name = "Tundra"
sunlight_per_tick = 0.3
nutrient_per_tick = 0.1
decay_per_tick = 0.0
chemosynthesis_per_tick = 0.0
```

### `data/biomes/mineral_vent.tres`

```
[resource]
script = ExtResource("1")
id = &"mineral_vent"
display_name = "Mineral Vent"
sunlight_per_tick = 0.0
nutrient_per_tick = 0.4
decay_per_tick = 0.1
chemosynthesis_per_tick = 0.6
```

### `data/biomes/swamp.tres`

```
[resource]
script = ExtResource("1")
id = &"swamp"
display_name = "Swamp"
sunlight_per_tick = 0.7
nutrient_per_tick = 0.4
decay_per_tick = 0.5
chemosynthesis_per_tick = 0.0
```

## Update `data/biomes/_index.tres`

Append all three.

## GrowthSystem integration

`scripts/systems/growth_system.gd._apply_yields` — biomass branch. Extend the fungi path and plantae path to add chemosynthesis bonus:

```gdscript
if resource_key == &"biomass":
    var biome: BiomeData = _nutrients.get_biome_at(coord)
    if biome == null:
        continue
    if kingdom_id == &"fungi":
        per_tile *= (1.0 + float(trait_mods.get(&"biomass_per_tile", 0.0)))
        if biome.chemosynthesis_per_tick > 0.0:
            per_tile *= (1.0 + biome.chemosynthesis_per_tick)
        if _is_tile_mycorrhizal_bonded(coord):
            per_tile *= 1.20
    else:
        var local_sun_mult := sun_mult
        if _is_tile_warmed(coord) and _ambient.has_method("get_event_multiplier"):
            var cool_mult: float = float(_ambient.get_event_multiplier(&"cool_spell", &"sunlight_multiplier"))
            if cool_mult > 0.0:
                local_sun_mult = sun_mult / cool_mult
        per_tile *= biome.sunlight_per_tick * local_sun_mult
        if biome.chemosynthesis_per_tick > 0.0:
            # Plantae: chemosynthesis is awkward — added (not multiplied) at half rate.
            per_tile += base_yield * base_mult * biome.chemosynthesis_per_tick * 0.5
        per_tile *= (1.0 + float(trait_mods.get(&"biomass_per_tile", 0.0)))
        per_tile *= meta_mult
        if kingdom_id == &"plantae" and MetaModifiers.is_unlocked(&"soil_memory"):
            per_tile *= 1.15
        if _is_tile_mycorrhizal_bonded(coord):
            per_tile *= 1.20
    per_tile *= float(species.biome_affinity.get(biome.id, 1.0))   # Phase 14a affinity (preserved)
```

The Phase 14a affinity line stays — chemosynthesis stacks with affinity. A Vent Archaeon on mineral_vent: 1.0 base × (1 + 0.6 chemo) × 1.8 affinity ≈ 2.88× yield.

## Update ecosystem `biome_recipe` dicts

`data/ecosystems/*.tres` — reshape recipes to include new biomes:

| Ecosystem | New biome_recipe |
|---|---|
| `cryo_polar_ice` | `{&"tundra": 0.7, &"rich_soil": 0.2, &"forest_edge": 0.1}` |
| `cryo_volcanic_vent` | `{&"mineral_vent": 0.7, &"tundra": 0.2, &"rich_soil": 0.1}` |
| `cryo_under_ice_sea` | `{&"tundra": 0.7, &"rich_soil": 0.3}` |
| `dev_tidal_pool` | `{&"rich_soil": 0.6, &"forest_edge": 0.4}` (unchanged) |
| `dev_forest_edge` | `{&"forest_edge": 0.6, &"grassland": 0.3, &"rich_soil": 0.1}` (unchanged) |
| `dev_inland_swamp` | `{&"swamp": 0.7, &"forest_edge": 0.2, &"rich_soil": 0.1}` |

`biome_cluster_size` values can stay (~2.0-3.0) for visible regionality.

## Acceptance criteria

- [ ] `BiomeData.chemosynthesis_per_tick` field exists; default 0.0.
- [ ] `tundra.tres`, `mineral_vent.tres`, `swamp.tres` load.
- [ ] All three registered in `data/biomes/_index.tres`.
- [ ] Existing 3 biomes still load with `chemosynthesis_per_tick = 0.0`.
- [ ] Fungi on `mineral_vent` gains biomass per tick despite zero sunlight (chemosynthesis × affinity).
- [ ] Plantae on `mineral_vent` gains small biomass per tick (chemosynthesis × 0.5 × affinity).
- [ ] Cryogenian polar_ice run shows mostly tundra tiles.
- [ ] Devonian inland_swamp run shows mostly swamp tiles.

## Out of scope

- Brief 03: species `biome_affinity` table populated with these new biomes.
- Brief 07: distinct biome tile textures.
- New biome types beyond these three.
