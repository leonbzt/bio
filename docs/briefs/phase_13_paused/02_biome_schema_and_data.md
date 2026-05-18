# Brief 02 — BiomeData schema extension + 3 new biome files

**Suggested agent**: ChatGPT 5.2 for the schema edit. Kilo for authoring the three .tres files. Route diff to Claude for balance.

Read first:
1. `scripts/data/biome_data.gd` — current schema.
2. `data/biomes/grassland.tres`, `data/biomes/rich_soil.tres`, `data/biomes/forest_edge.tres` — existing values.
3. `data/biomes/_index.tres` — index pattern.
4. `scripts/systems/growth_system.gd._apply_yields` — fungi biomass branch (commit `5a23aca`) is the precedent for handling biomes that don't use sunlight.

## Goal

Extend `BiomeData` with a `chemosynthesis_per_tick: float` field, then author three new biome resources matched to Phase 12's authored ecosystems.

## Schema change

### `scripts/data/biome_data.gd`

```gdscript
class_name BiomeData
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var tile_texture: Texture2D
@export var sunlight_per_tick: float = 0.0
@export var nutrient_per_tick: float = 0.0
@export var decay_per_tick: float = 0.0

# Phase 13: biomes can supply biomass via chemosynthesis (volcanic vents,
# mineral substrate). Plantae get this at 0.5×; fungi at full. Always 0 for
# legacy biomes — no rebalance of existing content.
@export var chemosynthesis_per_tick: float = 0.0
```

The existing three biome files keep `chemosynthesis_per_tick = 0.0` by default — no .tres edit needed unless you want to be explicit.

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

**Balance rationale**: Tundra is sun-poor + nutrient-poor + decay-frozen. Plantae struggle here (0.3× the sunlight of grassland). Fungi struggle for decay substrate but can colonize. Pairs with `cryo_polar_ice` and `cryo_under_ice_sea` ecosystems. Forces the player to lean on **node bonuses** (cryotolerance from brief 07) or pick a different ecosystem.

### `data/biomes/mineral_vent.tres`

```
[gd_resource type="Resource" script_class="BiomeData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/biome_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"mineral_vent"
display_name = "Mineral Vent"
sunlight_per_tick = 0.0
nutrient_per_tick = 0.4
decay_per_tick = 0.1
chemosynthesis_per_tick = 0.6
```

**Balance rationale**: The chemosynthesis biome. Zero sunlight. Plantae get *some* growth via chemosynthesis (at 0.5× multiplier, see growth_system change below) — they were photosynthesizers, this is awkward for them. Fungi thrive — they're decomposers, the vent substrate suits them. Pairs with `cryo_volcanic_vent`. Designed so a fungi run feels naturally at home, a plantae run feels uphill (you needed a node investment to make this work).

### `data/biomes/swamp.tres`

```
[gd_resource type="Resource" script_class="BiomeData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/biome_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"swamp"
display_name = "Swamp"
sunlight_per_tick = 0.7
nutrient_per_tick = 0.4
decay_per_tick = 0.5
chemosynthesis_per_tick = 0.0
```

**Balance rationale**: High decay (rotting matter everywhere) + good nutrients (water + mineral runoff) but slightly muted sunlight (canopy + mist). Fungi run feels at home (decay-rich), plantae run is good but not best. Pairs with `dev_inland_swamp`. Parasite plantae *loves* this (rich neighbor biomass to steal).

## Update `data/biomes/_index.tres`

Add the three new biomes to the existing index file. Same pattern as Phase 12's ecosystem index:

```
[ext_resource type="Resource" path="res://data/biomes/tundra.tres" id="<next>"]
[ext_resource type="Resource" path="res://data/biomes/mineral_vent.tres" id="<next+1>"]
[ext_resource type="Resource" path="res://data/biomes/swamp.tres" id="<next+2>"]

# Append all three to the biomes array.
```

## Growth system integration

`scripts/systems/growth_system.gd._apply_yields` already has the fungi-biomass branch (commit `5a23aca`) that skips sunlight. Extend the biomass branch to handle chemosynthesis for **both** kingdoms:

```gdscript
if resource_key == &"biomass":
    var biome: BiomeData = _nutrients.get_biome_at(coord)
    if biome == null:
        continue
    if kingdom_id == &"fungi":
        # Fungi: decompose substrate. Skip sunlight. Add chemosynthesis if biome has it.
        per_tile *= (1.0 + float(trait_mods.get(&"biomass_per_tile", 0.0)))
        if biome.chemosynthesis_per_tick > 0.0:
            per_tile *= (1.0 + biome.chemosynthesis_per_tick)
        if _is_tile_mycorrhizal_bonded(coord):
            per_tile *= 1.20
    else:
        # Plantae: existing sunlight+biome path, plus 0.5× chemosynthesis benefit.
        var local_sun_mult := sun_mult
        if _is_tile_warmed(coord) and _ambient.has_method("get_event_multiplier"):
            var cool_mult: float = float(_ambient.get_event_multiplier(&"cool_spell", &"sunlight_multiplier"))
            if cool_mult > 0.0:
                local_sun_mult = sun_mult / cool_mult
        per_tile *= biome.sunlight_per_tick * local_sun_mult
        if biome.chemosynthesis_per_tick > 0.0:
            per_tile += base_yield * base_mult * biome.chemosynthesis_per_tick * 0.5
        per_tile *= _get_niche_yield_multiplier()
        per_tile *= (1.0 + float(trait_mods.get(&"biomass_per_tile", 0.0)))
        per_tile *= meta_mult
        if kingdom_id == &"plantae" and MetaModifiers.is_unlocked(&"soil_memory"):
            per_tile *= 1.15
        if _is_tile_mycorrhizal_bonded(coord):
            per_tile *= 1.20
```

Note the plantae chemosynthesis is *additive* (`per_tile += base * 0.5 * chemo`), so a plantae tile on mineral_vent still earns *something* even at 0 sunlight — just less than a fungi tile would. This is the "uphill but possible" balance.

## ARCHITECTURE.md updates

- §4 schema — add `chemosynthesis_per_tick` to `BiomeData`.
- New section in §6 (or `KINGDOMS.md`) on biome-kingdom interactions: matrix of which kingdom does well in which biome.

## Acceptance criteria

- [ ] `BiomeData.chemosynthesis_per_tick` field exists; default 0.0.
- [ ] `tundra.tres`, `mineral_vent.tres`, `swamp.tres` all load in inspector.
- [ ] All three are registered in `data/biomes/_index.tres`.
- [ ] Existing 3 biomes still load with no behavior change.
- [ ] Fungi on a `mineral_vent` tile gains biomass per tick despite zero sunlight (manual test via debug placement or wait for brief 03).
- [ ] Plantae on a `mineral_vent` tile gains a small biomass amount per tick (50% of chemosynthesis).
- [ ] No regression on grassland / rich_soil / forest_edge yields.

## Out of scope

- Per-ecosystem map generation using these biomes (brief 03).
- Per-era tile textures / palette tints (brief 08 — these biomes get flat placeholder textures there).
- New traits or nodes for chemosynthesis (brief 07's `chemosynthetic_pathway` node uses this field).
- Rebalancing the existing 3 biomes — explicitly not touching them.
