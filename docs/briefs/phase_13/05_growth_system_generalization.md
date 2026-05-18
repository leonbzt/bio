# Brief 05 — GrowthSystem generalization + tick_effects dispatcher

**Suggested agent**: ChatGPT 5.2. Route diff to **Claude** — yield math is balance-load-bearing.

Read first:
1. `scripts/systems/growth_system.gd` — current shape (single-kingdom tick, layered-species special case).
2. `scripts/systems/parasite_steal_system.gd` — behavior that folds into `tick_effects`.
3. `scripts/systems/parasite_decay_system.gd` — same.
4. `docs/SPECIES_MODEL.md` §Interactions and §Per-tile state.
5. Brief 04 — new TerritorySystem API.

## Goal

Generalize `GrowthSystem` to tick **every species the player has introduced this run**, not just one kingdom. Replace the layered-species special case with the recipe model (recipe species don't tick directly; their components do, automatically because they occupy slots independently). Fold `parasite_steal_system` + `parasite_decay_system` into a per-species `tick_effects` dispatcher.

## New tick flow

```gdscript
func _on_tick(_delta_seconds: float) -> void:
    if _all_species.is_empty():
        return
    var unlocked: Array = GameState.run_save.get("unlocked_species_in_run", []) as Array
    if unlocked.is_empty():
        return
    for species_id_str in unlocked:
        var species: SpeciesData = _all_species.get(StringName(species_id_str), null)
        if species == null:
            continue
        # Recipe species don't tick themselves; their components do.
        if species.placement_rule == &"recipe":
            continue
        var coords: Array[Vector2i] = _territory.get_species_occupied_coords(species.id)
        if coords.is_empty():
            continue
        _apply_yields(species, coords, 1.0)
        _apply_tick_effects(species, coords)
```

## `_apply_yields` refactor

The existing function is mostly correct — it takes a species + coords + kingdom + mult. Simplify the kingdom argument (read from `species.kingdom_id`), keep the symbiosis / mycorrhizal_bond / warmed / wood_wide_web / endophytic_bridge predicates, and pass through:

```gdscript
func _apply_yields(species: SpeciesData, coords: Array[Vector2i], base_mult: float) -> void:
    if species == null or coords.is_empty():
        return
    var kingdom_id: StringName = species.kingdom_id
    var trait_mods: Dictionary = _compute_trait_modifiers(species)
    var meta_mult: float = _get_meta_growth_multiplier() if kingdom_id == &"plantae" else 1.0
    var extra_biomass: float = 0.0
    if MetaModifiers.is_unlocked(&"endophytic_bridge"):
        for coord in coords:
            if _is_endophytic_partner(coord, kingdom_id):
                extra_biomass += 0.2

    for resource_id in species.tick_yield.keys():
        var resource_key: StringName = StringName(resource_id)
        var base_yield: float = float(species.tick_yield[resource_id])
        if base_yield == 0.0:
            continue
        var total: float = 0.0
        var sun_mult: float = 1.0
        if _ambient.has_method("get_multiplier"):
            sun_mult = float(_ambient.get_multiplier(&"sunlight_multiplier"))
        for coord in coords:
            var per_tile: float = base_yield * base_mult
            if resource_key == &"biomass":
                if kingdom_id == &"fungi":
                    per_tile *= (1.0 + float(trait_mods.get(&"biomass_per_tile", 0.0)))
                    if _is_tile_mycorrhizal_bonded(coord):
                        per_tile *= 1.20
                else:
                    var biome: BiomeData = _nutrients.get_biome_at(coord)
                    if biome == null:
                        continue
                    var local_sun_mult := sun_mult
                    if _is_tile_warmed(coord) and _ambient.has_method("get_event_multiplier"):
                        var cool_mult: float = float(_ambient.get_event_multiplier(&"cool_spell", &"sunlight_multiplier"))
                        if cool_mult > 0.0:
                            local_sun_mult = sun_mult / cool_mult
                    per_tile *= biome.sunlight_per_tick * local_sun_mult
                    per_tile *= (1.0 + float(trait_mods.get(&"biomass_per_tile", 0.0)))
                    per_tile *= meta_mult
                    if kingdom_id == &"plantae" and MetaModifiers.is_unlocked(&"soil_memory"):
                        per_tile *= 1.15
                    if _is_tile_mycorrhizal_bonded(coord):
                        per_tile *= 1.20
            elif resource_key == &"decay":
                per_tile *= (1.0 + float(trait_mods.get(&"decay_per_tile", 0.0)))
                if _is_tile_mycorrhizal_bonded(coord):
                    per_tile *= 1.20
            elif resource_key == &"spores":
                per_tile *= (1.0 + float(trait_mods.get(&"spore_per_tile", 0.0)))

            if _is_tile_symbiotic(coord):
                per_tile *= (1.0 + _get_symbiosis_bonus())
            elif MetaModifiers.is_unlocked(&"wood_wide_web") and _is_adjacent_to_symbiotic(coord):
                per_tile *= 1.15

            total += per_tile
        if total > 0.0:
            ResourceLedger.add(resource_key, total)
    if extra_biomass > 0.0:
        ResourceLedger.add(ResourceLedger.BIOMASS, extra_biomass)
```

Note `_is_tile_symbiotic` now reads occupants:

```gdscript
func _is_tile_symbiotic(coord: Vector2i) -> bool:
    var occ: Dictionary = _territory.get_occupants(coord)
    return occ.has(&"plantae") and occ.has(&"fungi")
```

`_is_adjacent_to_fungi` / `_is_adjacent_to_plantae` similarly query `get_occupants` instead of `get_subsurface_owner` / `get_surface_owner`.

## `tick_effects` dispatcher

```gdscript
const _TICK_EFFECT_HANDLERS: Dictionary = {
    &"parasite_steal": "_effect_parasite_steal",
    &"corpse_decay": "_effect_corpse_decay",
    &"mycorrhizal_bond_apply": "_effect_mycorrhizal_bond_apply",
}

func _apply_tick_effects(species: SpeciesData, coords: Array[Vector2i]) -> void:
    if species.tick_effects.is_empty():
        return
    for effect_id in species.tick_effects:
        var method_name: String = _TICK_EFFECT_HANDLERS.get(effect_id, "")
        if method_name == "" or not has_method(method_name):
            continue
        call(method_name, species, coords)


func _effect_parasite_steal(species: SpeciesData, coords: Array[Vector2i]) -> void:
    var targets: Array[StringName] = species.placement_targets
    if targets.is_empty():
        return
    var total_bonus: float = 0.0
    for coord in coords:
        var neighbor_count: int = 0
        for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
            var neighbor: Vector2i = coord + offset
            var occ: Dictionary = _territory.get_occupants(neighbor)
            for k in targets:
                if occ.has(k):
                    neighbor_count += 1
                    break
        if neighbor_count > 0:
            total_bonus += 0.2 * float(neighbor_count)
    if total_bonus > 0.0:
        ResourceLedger.add(ResourceLedger.BIOMASS, total_bonus)


func _effect_corpse_decay(species: SpeciesData, coords: Array[Vector2i]) -> void:
    # Currently a no-op stub — the corpse_system already handles decay rates
    # when fungi colonize corpse tiles. Hook reserved for future "decay-while-here"
    # behaviors (saprotrophic enrichment, etc.).
    pass


func _effect_mycorrhizal_bond_apply(species: SpeciesData, coords: Array[Vector2i]) -> void:
    # Stamp mycorrhizal_bond on tiles where this species' kingdom slot meets
    # a plantae slot — keeps the bond flag fresh as plants colonize after the
    # fungi placement.
    for coord in coords:
        var occ: Dictionary = _territory.get_occupants(coord)
        if occ.has(&"plantae") and not bool(_territory.get_tile_data(coord, "mycorrhizal_bond", false)):
            _territory.set_tile_data(coord, "mycorrhizal_bond", true)
```

## Delete `parasite_steal_system.gd` + `parasite_decay_system.gd`

Their behavior moves to `tick_effects` handlers. Steps:
1. Delete both files.
2. Remove the two autoload registrations from `project.godot` (they're system children of World, not autoloads — confirm in the scene tree).
3. The matching species (`bramble`, mycorrhizal_mycelium) get `tick_effects = [&"parasite_steal"]` and `[&"mycorrhizal_bond_apply"]` in their .tres files (brief 08).

## Resource ledger keys

No new keys. Existing `BIOMASS`, `DECAY`, `SPORES`, `NUTRIENTS`, `SUNLIGHT` cover everything.

## Acceptance criteria

- [ ] `GrowthSystem._on_tick` iterates `unlocked_species_in_run` and ticks each per its kingdom_id.
- [ ] Recipe species (e.g., `lichen_common`) are skipped at the top level; their components (`pioneer_grass`, `mycelium_thread`) tick normally because they occupy slots independently.
- [ ] A plantae-only run yields biomass identical to Phase 12 (within rounding) — no regression.
- [ ] A lichen run yields biomass+decay+spores at the same rates as Phase 12.
- [ ] A parasitic bramble run gains the parasite-steal bonus (via `tick_effects` dispatcher) at the same rate as Phase 12's `parasite_steal_system`.
- [ ] A mycorrhizal mycelium run: bond flag appears on tiles co-occupied with plantae; 1.20× yields apply.
- [ ] `parasite_steal_system.gd` + `parasite_decay_system.gd` deleted; no broken references in project.godot or scene files.
- [ ] No regression on symbiosis bonus, wood_wide_web bonus, endophytic_bridge bonus.

## Out of scope

- New tick effects beyond the 3 stubs above (Phase 14+).
- Per-biome chemosynthesis bonus on biomass (Phase 14 — `BiomeData.chemosynthesis_per_tick` ships then).
- Multi-species competition (a species' yield reduced by adjacent foreign species). Future tier.
- Trait scaling adjustments — that's a balance pass, not a refactor.
