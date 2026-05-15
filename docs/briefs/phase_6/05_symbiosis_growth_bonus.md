# Brief 05 — Symbiosis bonus in GrowthSystem

**Suggested agent**: ChatGPT 5.2 via Copilot.

Read first:
1. `scripts/systems/growth_system.gd` — current `_on_tick`, kingdom routing.
2. `scripts/systems/territory_system.gd` — `get_surface_owner`, `get_subsurface_owner`.

## Goal
Make GrowthSystem aware of co-occupied tiles. In symbiosis runs, GrowthSystem must process **both** layers (surface plantae yields biomass, subsurface fungi yields decay+spores). Tiles with both layers occupied get a configurable bonus multiplier on both yields.

This is the **exit criterion** for Phase 6 ("measurably stronger ecosystem with symbiosis"): in a symbiosis run, the SAME number of tiles produces more resources than equivalent split plant + fungi runs.

## Outputs (modify)
- `scripts/systems/growth_system.gd`

## Patch shape

Restructure `_on_tick` to iterate based on current kingdom:

```gdscript
const SYMBIOSIS_BONUS: float = 0.30   # +30% to each layer's yield when symbiotic

func _on_tick(_delta_seconds: float) -> void:
    if _all_species.is_empty():
        return
    var kingdom_id: StringName = GameState.current_kingdom_id
    if kingdom_id == &"plantae" or kingdom_id == &"fungi":
        _tick_single_kingdom(kingdom_id)
    elif kingdom_id == &"symbiosis":
        _tick_symbiosis()


func _tick_single_kingdom(kingdom_id: StringName) -> void:
    # existing behavior — call into the per-resource logic for the active species
    var species: SpeciesData = _all_species.get(STARTER_SPECIES_BY_KINGDOM.get(kingdom_id), null)
    if species == null:
        return
    var coords: Array[Vector2i]
    if kingdom_id == &"fungi":
        coords = _territory.get_subsurface_owned_coords(&"fungi")
    else:
        coords = _territory.get_surface_owned_coords(&"plantae")
    _apply_yields(species, coords, kingdom_id, 1.0)


func _tick_symbiosis() -> void:
    var plant_species: SpeciesData = _all_species.get(&"pioneer_grass", null)
    var fungi_species: SpeciesData = _all_species.get(&"mycelium_thread", null)
    if plant_species == null and fungi_species == null:
        return
    var surface_coords: Array[Vector2i] = _territory.get_surface_owned_coords(&"plantae") if plant_species else []
    var sub_coords: Array[Vector2i] = _territory.get_subsurface_owned_coords(&"fungi") if fungi_species else []

    if plant_species != null:
        _apply_yields(plant_species, surface_coords, &"plantae", 1.0, true)
    if fungi_species != null:
        _apply_yields(fungi_species, sub_coords, &"fungi", 1.0, true)


func _apply_yields(
    species: SpeciesData,
    coords: Array[Vector2i],
    kingdom_id: StringName,
    base_mult: float,
    apply_symbiosis_bonus: bool = false
) -> void:
    if species == null or coords.is_empty():
        return
    # Recompute trait modifier sum for this species (cache later if perf becomes an issue).
    var trait_mods: Dictionary = _compute_trait_modifiers(species)
    var meta_mult: float = _get_meta_growth_multiplier() if kingdom_id == &"plantae" else 1.0

    for resource_id in species.tick_yield.keys():
        var resource_key: StringName = StringName(resource_id)
        var base_yield: float = float(species.tick_yield[resource_id])
        if base_yield == 0.0:
            continue
        var total: float = 0.0
        for coord in coords:
            var per_tile: float = base_yield * base_mult
            # Per-resource modifier wiring (mirror existing logic).
            if resource_key == &"biomass":
                var biome: BiomeData = _nutrients.get_biome_at(coord)
                if biome == null:
                    continue
                per_tile *= biome.sunlight_per_tick
                per_tile *= (1.0 + float(trait_mods.get(&"biomass_per_tile", 0.0)))
                per_tile *= meta_mult
            elif resource_key == &"decay":
                per_tile *= (1.0 + float(trait_mods.get(&"decay_per_tile", 0.0)))
            elif resource_key == &"spores":
                per_tile *= (1.0 + float(trait_mods.get(&"spore_per_tile", 0.0)))

            # Symbiosis bonus: applies only in symbiosis runs, only on co-occupied tiles.
            if apply_symbiosis_bonus and _is_tile_symbiotic(coord):
                per_tile *= (1.0 + SYMBIOSIS_BONUS)

            total += per_tile

        if total > 0.0:
            ResourceLedger.add(resource_key, total)


func _is_tile_symbiotic(coord: Vector2i) -> bool:
    return _territory.get_surface_owner(coord) == &"plantae" and _territory.get_subsurface_owner(coord) == &"fungi"


func _compute_trait_modifiers(species: SpeciesData) -> Dictionary:
    var mods: Dictionary = {}
    for trait_item: TraitData in species.base_traits:
        if trait_item == null:
            continue
        for key in trait_item.modifiers.keys():
            var key_name: StringName = StringName(key)
            mods[key_name] = mods.get(key_name, 0.0) + float(trait_item.modifiers.get(key, 0.0))
    return mods
```

Note: this refactor replaces the previous `_active_species` + `_trait_modifier_sum` cached state with per-tick recomputation. That's fine — the species list is small (3 entries) and the modifier sum is tiny. If profiling shows hot-spot, add a cache keyed by species id later.

## Acceptance criteria
- [ ] Plantae run: biomass yield is unchanged from Phase 5 (regression).
- [ ] Fungi run: decay + spore yields are unchanged from Phase 5 (regression).
- [ ] Symbiosis run, plant-only tile: yields ONLY biomass (no decay/spores from that tile).
- [ ] Symbiosis run, fungi-only tile: yields ONLY decay+spores (no biomass).
- [ ] Symbiosis run, **co-occupied tile**: yields biomass +30% AND decay+spores +30%.
- [ ] Sustainable feedback loop: in a symbiosis run with N co-occupied tiles, both biomass and spores climb without external intervention.

## Out of scope
- Adjacency-based symbiosis bonuses (mutualism node — brief 06).
- Per-tile or per-species symbiosis-bonus tuning (everyone gets +30%).
