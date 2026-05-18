# Brief 03 — Per-ecosystem biome generation

**Suggested agent**: ChatGPT 5.2. Route diff to Claude for determinism check.

Read first:
1. `scripts/systems/nutrient_system.gd` — `_generate_biome_map()` is what we're rewriting.
2. `scripts/data/ecosystem_data.gd` — `biome_preference` field already exists (Phase 12).
3. `scripts/autoloads/era_system.gd` — `get_current_ecosystem()` is the lookup.
4. `data/ecosystems/*.tres` — currently set `biome_preference` to legacy ids (`grassland`, etc.); brief 03 also fixes these.

## Goal

Make `EcosystemData.biome_preference` actually shape the generated map. Currently `_generate_biome_map()` picks uniformly across all biomes — including biomes that don't belong to the current era. Phase 12 stamped the field but ignored it; Phase 13 honors it with a 70/30 weighted mix.

## Design

When generating the biome map at run start:

1. Look up current ecosystem via `EraSystem.get_current_ecosystem()`.
2. If `ecosystem == null` or `ecosystem.biome_preference == &""`: fall through to legacy uniform-random behavior (preserves Phase 12 saves where ecosystems haven't been re-authored).
3. Otherwise:
   - Resolve the era's **natural mix** = list of biomes "appropriate" for this era (see era → biome mapping below).
   - For each tile: with probability `0.7`, pick `biome_preference`; with probability `0.3`, pick uniformly from the natural mix.
   - All rolls use a deterministic RNG seeded from `GameState.run_seed`.

The natural mix per era is a static dictionary in `NutrientSystem` for now (Phase 13 doesn't add a field to `EraData` — kept lean). Phase 14+ can promote this to `EraData.natural_biomes` if more eras land.

## Outputs

### `scripts/systems/nutrient_system.gd`

Add the static mapping near the top:

```gdscript
# Era -> biome ids that may appear in that era's natural mix (30% slice).
# The preferred biome (70% slice) is set per-ecosystem on EcosystemData.biome_preference.
const ERA_NATURAL_BIOMES: Dictionary = {
    &"cryogenian": [&"tundra", &"mineral_vent", &"rich_soil"],
    &"devonian": [&"grassland", &"forest_edge", &"rich_soil", &"swamp"],
}
const PREFERRED_BIOME_WEIGHT: float = 0.7
```

Rewrite `_generate_biome_map()`:

```gdscript
func _generate_biome_map() -> Dictionary:
    var rng := RandomNumberGenerator.new()
    rng.seed = GameState.run_seed

    var width: int = int(_tile_grid.GRID_WIDTH)
    var height: int = int(_tile_grid.GRID_HEIGHT)
    var map: Dictionary = {}

    var preferred: BiomeData = null
    var natural_pool: Array[BiomeData] = []
    var era_system := _resolve_era_system()
    if era_system != null:
        var eco: EcosystemData = era_system.get_current_ecosystem()
        if eco != null and eco.biome_preference != &"":
            preferred = _find_biome(eco.biome_preference)
            var era_id: StringName = eco.era_id
            var ids: Array = ERA_NATURAL_BIOMES.get(era_id, [])
            for bid in ids:
                var b: BiomeData = _find_biome(StringName(bid))
                if b != null:
                    natural_pool.append(b)

    var fallback_pool: Array[BiomeData] = _biomes  # legacy uniform-random

    for y in range(height):
        for x in range(width):
            var biome: BiomeData
            if preferred != null and not natural_pool.is_empty():
                if rng.randf() < PREFERRED_BIOME_WEIGHT:
                    biome = preferred
                else:
                    biome = natural_pool[rng.randi_range(0, natural_pool.size() - 1)]
            else:
                biome = fallback_pool[rng.randi_range(0, fallback_pool.size() - 1)]
            map["%d,%d" % [x, y]] = String(biome.id)
    return map


func _resolve_era_system() -> Node:
    # EraSystem is an autoload; access via the engine singleton if available.
    if Engine.has_singleton("EraSystem"):
        return Engine.get_singleton("EraSystem")
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null:
        return null
    return tree.root.get_node_or_null("EraSystem")
```

### Update `data/ecosystems/*.tres`

Phase 12 likely left `biome_preference` empty or pointed at legacy ids. Update each ecosystem to point at the appropriate biome:

| Ecosystem id | `biome_preference` |
|---|---|
| `cryo_polar_ice` | `&"tundra"` |
| `cryo_volcanic_vent` | `&"mineral_vent"` |
| `cryo_under_ice_sea` | `&"tundra"` |
| `dev_tidal_pool` | `&"rich_soil"` (no aquatic biome yet — keep authored Phase-12 value if already set) |
| `dev_forest_edge` | `&"forest_edge"` |
| `dev_inland_swamp` | `&"swamp"` |

If a Phase 12 ecosystem already has a sensible preference, leave it alone. Document each change in the commit message.

### Determinism guarantee

The same `run_seed` must produce the same map regardless of how many times `_generate_biome_map` is called. Verify by:
- Logging the first 5 generated coords + their biomes on run start.
- Reloading the save (which re-reads the saved `run.biome_map`, not regenerating).
- Starting a fresh run with the same seed (via debug menu if available); the first 5 coords match.

The 70/30 logic uses the same RNG instance per tile, so this is automatic — but call it out so the reviewer checks.

## Acceptance criteria

- [ ] Starting a `cryo_volcanic_vent` run produces a map dominated by `mineral_vent` (~70% of tiles).
- [ ] Starting a `dev_inland_swamp` run produces a map dominated by `swamp` (~70% of tiles).
- [ ] Starting a `cryo_polar_ice` run is mostly `tundra`, with `mineral_vent` and `rich_soil` sprinkled in (Cryogenian natural mix).
- [ ] An ecosystem with empty `biome_preference` falls back to current uniform-random behavior (Phase 12 saves don't break).
- [ ] Same `run_seed` produces the same map (reload → identical layout).
- [ ] No errors when `EraSystem` returns `null` (e.g., very early in app lifecycle).
- [ ] Fungi run on `cryo_volcanic_vent` actually earns biomass tick-over-tick (mineral_vent's chemosynthesis kicks in via brief 02's growth_system edit).

## Out of scope

- Adding `natural_biomes` to `EraData` (statically scoped in NutrientSystem for Phase 13; promote in Phase 14 if a third era lands).
- Aquatic biome type (parked for Phase 14 alongside `dev_tidal_pool`).
- Tile-level biome editing tools / debug overlay.
- Cross-ecosystem biome blending (each run is one ecosystem, one map).
- Biome regeneration mid-run.
