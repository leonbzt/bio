# Brief 05 — GrowthSystem

**Suggested agent**: ChatGPT 5.2 via Copilot.

Read first:
1. `docs/ARCHITECTURE.md` — sections 3 (`ResourceLedger`), 5 (`GrowthSystem` subscribes to `tick`).
2. `scripts/systems/territory_system.gd` — for `get_owned_coords()`.
3. `scripts/systems/nutrient_system.gd` — for `get_biome_at(coord)`.
4. `data/species/pioneer_grass.tres` — the "active" species for Phase 2.
5. `scripts/data/species_data.gd` and `trait_data.gd`.

## Goal
A `GrowthSystem` that, on every tick, credits biomass per owned tile based on:
- the active species' `tick_yield["biomass"]` (base value)
- the biome's `sunlight_per_tick` (acts as a 0.0–1.0+ multiplier on biomass)
- summed trait modifiers (`biomass_per_tile` additive multiplier, e.g. +0.15 → ×1.15)

Formula per tile per tick:
```
biomass = species.tick_yield["biomass"]
        * biome.sunlight_per_tick
        * (1.0 + sum_of_trait_modifiers["biomass_per_tile"])
```

Total biomass credited per tick = sum across all owned tiles.

## Outputs (create)
- `scripts/systems/growth_system.gd`
- Modification to `scenes/world/world.tscn` — add `GrowthSystem` under `Systems`, after `NutrientSystem`.

## Implementation notes
- `Node`. Load the active species in `_ready()`:
  - `const ACTIVE_SPECIES_PATH := "res://data/species/pioneer_grass.tres"`
  - Hardcoded for Phase 2; will read from `GameState.current_kingdom_id` + species selection in Phase 4.
  - Add `# TODO Phase 4: species selection`.
- Cache the trait sum on load: `_biomass_per_tile_modifier: float`. Compute once from `species.base_traits[*].modifiers["biomass_per_tile"]` summed.
- Connect `EventBus.tick.connect(_on_tick)`.
- `_on_tick(_delta)`:
  - `var total: float = 0.0`
  - For each `coord in TerritorySystem.get_owned_coords()`:
    - `biome = NutrientSystem.get_biome_at(coord)`
    - `if biome == null: continue`
    - `total += species.tick_yield.get("biomass", 0.0) * biome.sunlight_per_tick * (1.0 + _biomass_per_tile_modifier)`
  - `if total > 0.0: ResourceLedger.add(ResourceLedger.BIOMASS, total)`

## Acceptance criteria
- [ ] With zero owned tiles: biomass does not change.
- [ ] After colonizing 1 tile (cost = 5 biomass): biomass starts climbing. With `pioneer_grass` (yield 0.5) + `fast_growth` (+0.15) + grassland (sunlight 1.0), per-tick add ≈ `0.5 * 1.0 * 1.15 = 0.575`.
- [ ] With multiple owned tiles, the total scales linearly.
- [ ] Killing and reopening the app: biomass resumes accumulating from saved value.
- [ ] No reference to `_smoke_growth` remains anywhere.

## Out of scope
- Nutrients/sunlight as consumed *inputs* (only as multipliers for now). Brief 03 already credits them separately so resources show movement.
- Cap on growth, decay over time, population pressure — all later phases.
- Trait stacking interactions (multiplicative vs additive). Stick to additive for `biomass_per_tile`.
