# Brief 04 — Species + Trait content (.tres)

**Suggested agent**: Kilo Code free model for the writing, ChatGPT if Kilo struggles with file format.

Read first:
1. `docs/ARCHITECTURE.md` section 4 — `SpeciesData` and `TraitData` schemas.
2. `scripts/data/species_data.gd` and `scripts/data/trait_data.gd`.
3. `data/biomes/*.tres` for the biome ids your species will reference.

## Goal
Two plant `SpeciesData` resources and three `TraitData` resources. These let GrowthSystem (brief 05) produce varying biomass output per tile.

For Phase 2, the player automatically uses the "starter" species when colonizing — species choice UI lands in Phase 4.

## Outputs (create)

### Traits — `data/traits/`

**`thick_cuticle.tres`** — +defense at growth-speed cost
- `id = &"thick_cuticle"`
- `display_name = "Thick Cuticle"`
- `description = "Waxy outer layer slows water loss but limits expansion."`
- `modifiers = {"defense": 2.0, "biomass_per_tile": -0.05}`
- `tradeoff_summary = "+2 defense / −5% biomass yield"`

**`deep_roots.tres`** — better nutrient uptake, slower colonize
- `id = &"deep_roots"`
- `display_name = "Deep Roots"`
- `description = "Taproots reach mineral layers below the topsoil."`
- `modifiers = {"nutrient_multiplier": 1.25, "colonize_cost": 2.0}`
- `tradeoff_summary = "+25% nutrients / +2 biomass per colonize"`

**`fast_growth.tres`** — bonus biomass, fragile
- `id = &"fast_growth"`
- `display_name = "Fast Growth"`
- `description = "Soft tissues expand rapidly but tear under stress."`
- `modifiers = {"biomass_per_tile": 0.15, "defense": -1.0}`
- `tradeoff_summary = "+15% biomass / −1 defense"`

### Species — `data/species/`

**`pioneer_grass.tres`** — starter, balanced
- `id = &"pioneer_grass"`
- `display_name = "Pioneer Grass"`
- `kingdom_id = &"plantae"`
- `sprite` — omit (null) for Phase 2
- `base_traits = [load("res://data/traits/fast_growth.tres")]`
- `colonize_cost = {"biomass": 5.0}`
- `tick_yield = {"biomass": 0.5}` (base biomass per owned tile per tick, before biome/trait multipliers)

**`bramble.tres`** — defensive, slower
- `id = &"bramble"`
- `display_name = "Bramble"`
- `kingdom_id = &"plantae"`
- `base_traits = [load("res://data/traits/thick_cuticle.tres")]`
- `colonize_cost = {"biomass": 8.0}`
- `tick_yield = {"biomass": 0.3}`

## .tres file format
Species traits array using `ExtResource`:

```
[gd_resource type="Resource" script_class="SpeciesData" load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/data/species_data.gd" id="1"]
[ext_resource type="Resource" path="res://data/traits/fast_growth.tres" id="2"]

[resource]
script = ExtResource("1")
id = &"pioneer_grass"
display_name = "Pioneer Grass"
kingdom_id = &"plantae"
base_traits = Array[Resource]([ExtResource("2")])
colonize_cost = {
"biomass": 5.0
}
tick_yield = {
"biomass": 0.5
}
```

Trait file template (no ExtResource children):

```
[gd_resource type="Resource" script_class="TraitData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/trait_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"fast_growth"
display_name = "Fast Growth"
description = "Soft tissues expand rapidly but tear under stress."
modifiers = {
"biomass_per_tile": 0.15,
"defense": -1.0
}
tradeoff_summary = "+15% biomass / −1 defense"
```

## Acceptance criteria
- [ ] All 5 files load in Godot without errors.
- [ ] Inspector shows correct values; `base_traits` array on each species shows the linked TraitData.
- [ ] Modifier keys are consistent across traits — no typos. The canonical keys for Phase 2 are: `biomass_per_tile`, `nutrient_multiplier`, `defense`, `colonize_cost`. Any new key needs a `TODO` in the brief and a Claude check.

## Out of scope
- Sprites (Phase 7).
- Trait stacking rules — for now, modifiers from multiple traits sum (GrowthSystem will handle).
- More species. Two is enough to verify the system; we'll add more across phases.
