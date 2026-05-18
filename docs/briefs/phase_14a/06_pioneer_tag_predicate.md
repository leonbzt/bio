# Brief 06 — Pioneer tag predicate in ColonizationRulesRegistry

**Suggested agent**: ChatGPT 5.2. Route diff to Claude.

Read first:
1. `scripts/systems/colonization_rules_registry.gd` — current `_rule_adjacent_empty`.
2. `docs/SPECIES_ROSTER.md` §Tags reference — `pioneer` semantics.

## Goal

Species tagged `pioneer` can colonize bare tiles **without** the normal adjacency requirement. The species starts placing where it wants on the map, not just next to itself.

Affects: **Cyanobacterial Mat**, **Vent Archaeon**. Other pioneer-tagged species (future) get the behavior for free.

## Implementation

### `scripts/systems/colonization_rules_registry.gd._rule_adjacent_empty`

Insert a `pioneer` check before the adjacency block:

```gdscript
func _rule_adjacent_empty(coord: Vector2i, species: SpeciesData) -> Dictionary:
    var territory: Node = _get_territory()
    if territory == null:
        return _invalid()
    var kingdom_id: StringName = species.kingdom_id
    # Slot must be empty.
    if territory.get_occupant(coord, kingdom_id) != &"":
        return _invalid()
    # Phase 14a: pioneer tag skips adjacency.
    if species.tags.has(&"pioneer"):
        var cost_pioneer: Dictionary = species.colonize_cost.duplicate()
        if MetaModifiers.is_unlocked(&"thrifty_growth"):
            for k in cost_pioneer.keys():
                cost_pioneer[k] = maxf(0.0, float(cost_pioneer[k]) - 1.0)
        var owned_pioneer: Array[Vector2i] = territory.get_kingdom_occupied_coords(kingdom_id)
        if owned_pioneer.is_empty():
            cost_pioneer = {}   # first tile free
        return {
            "valid": true,
            "cost": cost_pioneer,
            "data": {},
            "placements": [{
                "coord": coord,
                "kingdom_id": kingdom_id,
                "species_id": species.id,
                "data": {}
            }]
        }
    # Standard adjacency check.
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
        cost = {}
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

### Extend to `fungi_substrate` rule

Vent Archaeon uses `fungi_substrate` rule. Apply the same pioneer-skip:

```gdscript
func _rule_fungi_substrate(coord: Vector2i, species: SpeciesData) -> Dictionary:
    var territory: Node = _get_territory()
    if territory == null:
        return _invalid()
    var kingdom_id: StringName = species.kingdom_id
    if territory.get_occupant(coord, kingdom_id) != &"":
        return _invalid()

    # Phase 14a: pioneer tag skips the substrate requirement too — vent
    # archaeons colonize raw rock, not pre-existing tiles.
    if species.tags.has(&"pioneer"):
        var cost: Dictionary = _apply_trait_cost_modifiers(_resolve_cost(species), species)
        var owned_p: Array[Vector2i] = territory.get_kingdom_occupied_coords(kingdom_id)
        if owned_p.is_empty():
            cost = {}
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

    # Standard substrate logic (existing) — unchanged.
    var owned: Array[Vector2i] = territory.get_kingdom_occupied_coords(kingdom_id)
    if owned.is_empty():
        return _valid_with_cost(species, coord, {})
    if territory.get_occupant(coord, &"plantae") != &"":
        return _valid_with_cost(species, coord, {})
    if _is_corpse_at(coord):
        return _valid_with_cost(species, coord, {})
    var owned_set: Dictionary = {}
    for c in owned: owned_set[c] = true
    for offset in neighbors(coord):
        if owned_set.has(offset):
            return _valid_with_cost(species, coord, {})
    if MetaModifiers.is_unlocked(&"spore_distribution"):
        var charges: int = _get_spore_distribution_charges()
        if charges > 0 and _has_line_of_sight(coord, owned):
            _set_spore_distribution_charges(charges - 1)
            return _valid_with_cost(species, coord, {})
    return _invalid()
```

(Use a small `_valid_with_cost` helper to factor the repeated return shape — purely refactor, no behavior change.)

### Successor tag (no-op stub for Phase 14a)

`successor`-tagged species (Tree-Fern Stem) should require prior-occupation history on the tile. **Phase 14a ships the tag without the predicate** — Tree-Fern places via the standard adjacent_empty rule. Phase 15 wires the predicate when tile-history scaffolding lands. Document this in the brief — the tag's authored, the predicate is deferred.

## Acceptance criteria

- [ ] `pioneer`-tagged species placed via `adjacent_empty` skip the adjacency check.
- [ ] `pioneer`-tagged species placed via `fungi_substrate` skip the substrate requirement.
- [ ] First-tile-free behavior preserved for both rule paths.
- [ ] Non-pioneer species behave identically to Phase 13 (no regression on Pioneer Stem / Mycelium Thread).
- [ ] Cyanobacterial Mat can be placed on any bare tile in Cryogenian.
- [ ] Vent Archaeon can be placed on any bare tile (after introduction).
- [ ] `successor` tag documented as no-op stub for Phase 14a.

## Out of scope

- Successor predicate (Phase 15, with tile-history work).
- Pioneer cost discount (currently flat; may want to make pioneer placements cheap as a rule — leave for balance pass).
- New pioneer species beyond the two in Phase 14a.
- Visual tile feedback for pioneer-eligible placements (Phase 15+ polish).
