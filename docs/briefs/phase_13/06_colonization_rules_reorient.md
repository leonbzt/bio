# Brief 06 — ColonizationRulesRegistry reorientation + recipe rule

**Suggested agent**: ChatGPT 5.2. Route diff to Claude.

Read first:
1. `scripts/systems/colonization_rules_registry.gd` — current rules dispatcher (reads `NicheData`).
2. `scripts/systems/plant_colonization.gd`, `fungi_colonization.gd`, `animal_colonization.gd` — callers.
3. `scripts/systems/tile_input_router.gd` — entry point for tap → colonize flow.
4. `docs/SPECIES_MODEL.md` §Placement rules and §Coinhabitation rules.

## Goal

Reorient `ColonizationRulesRegistry` to read **species directly** (no `NicheData` parameter). Add the `recipe` rule for atomic multi-component placement. Update callers to pass species. Implement coinhabitation policy (one species per kingdom per tile; recipe must validate all components).

## New API

```gdscript
# Returns {"valid": bool, "cost": Dictionary, "data": Dictionary,
#          "placements": Array[Dictionary]}.
# placements lists every (coord, kingdom_id, species_id, tile_data) tuple to apply.
# Most rules return one placement; recipe returns N.
func evaluate(coord: Vector2i, species: SpeciesData) -> Dictionary:
    var rule: StringName = species.placement_rule
    match rule:
        &"adjacent_empty":
            return _rule_adjacent_empty(coord, species)
        &"fungi_substrate":
            return _rule_fungi_substrate(coord, species)
        &"parasitic_plantae":
            return _rule_parasitic_plantae(coord, species)
        &"mycorrhizal_fungi":
            return _rule_mycorrhizal_fungi(coord, species)
        &"animal_anchor":
            return _rule_animal_anchor(coord, species)
        &"recipe":
            return _rule_recipe(coord, species)
        _:
            push_warning("ColonizationRulesRegistry: unknown rule %s" % String(rule))
            return _invalid()


func _invalid() -> Dictionary:
    return {"valid": false, "cost": {}, "data": {}, "placements": []}
```

## Per-rule updates

Each existing rule loses the `niche` parameter; reads `species` for cost + placement_targets. The rule logic itself is unchanged. Example:

```gdscript
func _rule_adjacent_empty(coord: Vector2i, species: SpeciesData) -> Dictionary:
    var territory: Node = _get_territory()
    if territory == null:
        return _invalid()
    var kingdom_id: StringName = species.kingdom_id
    # Slot must be empty.
    if territory.get_occupant(coord, kingdom_id) != &"":
        return _invalid()
    # Adjacency check (relax for first tile).
    var owned: Array[Vector2i] = territory.get_kingdom_occupied_coords(kingdom_id)
    if owned.size() > 0:
        var owned_set: Dictionary = {}
        for c in owned: owned_set[c] = true
        var has_neighbor: bool = false
        for n in neighbors(coord):
            if owned_set.has(n):
                has_neighbor = true
                break
        if not has_neighbor:
            return _invalid()
    # Cost.
    var cost: Dictionary = species.colonize_cost.duplicate()
    if MetaModifiers.is_unlocked(&"thrifty_growth"):
        for k in cost.keys():
            cost[k] = maxf(0.0, float(cost[k]) - 1.0)
    if owned.is_empty():
        cost = {}  # first tile free.
    return {
        "valid": true,
        "cost": cost,
        "data": {},
        "placements": [{
            "coord": coord,
            "kingdom_id": kingdom_id,
            "species_id": species.id,
            "data": {}
        }]
    }
```

Apply the same pattern to all 5 existing rules (`fungi_substrate`, `parasitic_plantae`, `mycorrhizal_fungi`, `animal_anchor`). Drop the `niche` parameter from every signature. `placement_targets` reads from `species.placement_targets` (was `niche.parasitic_targets`).

Each rule returns exactly **one** placement.

## Recipe rule

```gdscript
func _rule_recipe(coord: Vector2i, species: SpeciesData) -> Dictionary:
    if species.recipe_components.is_empty():
        push_warning("Recipe species %s has no components" % String(species.id))
        return _invalid()
    var territory: Node = _get_territory()
    if territory == null:
        return _invalid()

    var combined_placements: Array = []
    var combined_cost: Dictionary = species.colonize_cost.duplicate()  # recipe's own cost
    var data_carry: Dictionary = {}

    for component_id in species.recipe_components:
        var component: SpeciesData = _species_lookup(component_id)
        if component == null:
            return _invalid()
        # Each component must validate against its own rule + slot.
        var sub: Dictionary = evaluate(coord, component)
        if not sub.get("valid", false):
            return _invalid()
        # Slot must be empty (recipe never overwrites).
        if territory.get_occupant(coord, component.kingdom_id) != &"":
            return _invalid()
        # Sum costs.
        for k in sub["cost"].keys():
            combined_cost[k] = float(combined_cost.get(k, 0.0)) + float(sub["cost"][k])
        # Merge data (e.g., mycorrhizal_bond from a recipe-included mycorrhizal mycelium).
        for k in sub["data"].keys():
            data_carry[k] = sub["data"][k]
        for placement in sub["placements"]:
            combined_placements.append(placement)

    return {
        "valid": true,
        "cost": combined_cost,
        "data": data_carry,
        "placements": combined_placements
    }


func _species_lookup(species_id: StringName) -> SpeciesData:
    var index: SpeciesIndex = load("res://data/species/_index.tres") as SpeciesIndex
    if index == null:
        return null
    for sp in index.species:
        if sp.id == species_id:
            return sp
    return null
```

**Atomic placement guarantee** (Locked Decision 16): if ANY component fails to validate, the entire recipe returns invalid. No partial application.

## Caller updates

### `tile_input_router.gd`

Resolve the species to colonize from the current run state, not from niche selection:

```gdscript
func _on_tile_tap(coord: Vector2i) -> void:
    var species: SpeciesData = _resolve_active_placement_species()
    if species == null:
        return
    var result: Dictionary = _rules.evaluate(coord, species)
    if not result.get("valid", false):
        # UI feedback for invalid placement.
        return
    var cost: Dictionary = result.get("cost", {})
    if not ResourceLedger.can_afford(cost):
        return
    ResourceLedger.spend(cost)
    for placement in result.get("placements", []):
        _territory.add_occupant(placement["coord"], placement["kingdom_id"], placement["species_id"])
        # Apply per-placement tile data (mycorrhizal_bond, parasite_decay_ticks, etc.)
        for k in placement.get("data", {}).keys():
            _territory.set_tile_data(placement["coord"], k, placement["data"][k])
    # Recipe-level shared data (e.g., bond flag stamped once).
    for k in result.get("data", {}).keys():
        _territory.set_tile_data(coord, k, result["data"][k])


func _resolve_active_placement_species() -> SpeciesData:
    var species_id: StringName = StringName(GameState.placement_target_species_id)
    if species_id == &"":
        return null
    return _species_lookup(species_id)
```

`GameState.placement_target` (kingdom-id) is replaced by `GameState.placement_target_species_id` (a species id, set by the species panel UI in brief 07). Default at run start = `starting_species_id`.

### Delete `plant_colonization.gd`, `fungi_colonization.gd`, `animal_colonization.gd`

These currently wrap kingdom-specific colonization paths. Their logic now lives entirely in the rule handlers + tile_input_router. Delete them and remove their scene references (they live as children of `World/Systems/`).

If any of them subscribe to additional signals or hold state beyond colonization, fold that into the appropriate single point (probably `tile_input_router` or a small `species_panel.gd` UI controller in brief 07).

## Multi-layer placement removal

`scripts/autoloads/multi_layer_placement.gd` is deleted. Its responsibilities:

- **Layered-mode toggle**: gone — recipe rule replaces it; recipe taps place all components in one input, no toggle needed.
- **`GameState.placement_target` rotation**: gone — replaced by per-species-id selection.

Remove the autoload from `project.godot`.

The recipe placement is a single tap that pays the combined cost and stamps both components — no "tap once for layer A, tap again for layer B" UX. This is **simpler than the current Lichen** flow. If players need to place only one component, they place the underlying species directly (e.g., place `pioneer_grass` instead of `lichen_common`).

## Acceptance criteria

- [ ] `ColonizationRulesRegistry.evaluate` takes only `(coord, species)`.
- [ ] All 5 legacy rules updated and pass behavior tests (place a plantae tile, a fungi tile, a parasite tile, a mycorrhizal tile, an animal tile — each succeeds where it did before).
- [ ] Recipe rule: placing Lichen on an empty tile succeeds, places `pioneer_grass` + `mycelium_thread` atomically, pays combined cost.
- [ ] Recipe rule: placing Lichen on a tile already holding `pioneer_grass` fails entirely (no partial fungi placement).
- [ ] `plant_colonization.gd`, `fungi_colonization.gd`, `animal_colonization.gd`, `multi_layer_placement.gd` all deleted; project.godot updated; no broken references.
- [ ] First-tile-free behavior preserved for `adjacent_empty` rule.
- [ ] Mycorrhizal placement still stamps `mycorrhizal_bond` data.
- [ ] Parasite placement still records `parasite_decay_ticks`.
- [ ] No regression on tile input: tapping a valid tile still places, invalid tile still rejects.

## Out of scope

- Same-kingdom coinhabitation exceptions (future tier).
- Player-facing recipe failure feedback ("Lichen failed: fungi slot occupied"). Polish.
- Recipe placement preview (tile highlight showing what will be placed). Polish.
- New rules beyond `recipe` (Phase 14+).
- Cost discount stacking across recipe components. Recipe cost = sum of components' costs + species own cost; current implementation is correct.
