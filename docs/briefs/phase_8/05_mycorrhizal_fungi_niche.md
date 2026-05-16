# Brief 05 — Mycorrhizal fungi niche

**Suggested agent**: ChatGPT 5.2 via Copilot.

Read first:
1. `docs/NICHES.md`.
2. `data/species/mycelium_thread.tres` — note the existing `mycorrhizal_network` trait.
3. `scripts/systems/growth_system.gd` — applies trait modifiers per tile.
4. `scripts/systems/colonization_rules_registry.gd` (post brief 03).

## Goal
Add **Mycorrhizal** as a fungi niche. Design intent: a "support" niche that's mediocre alone but powerful when paired with plantae tiles. Sets up Phase 10's symbiosis reframe (Lichen species will require this niche to be unlocked).

## Design summary

| Property | Mycorrhizal fungi | Default (Decomposer) fungi |
|---|---|---|
| Colonization | Must be adjacent to plantae tile OR adjacent to mycorrhizal fungi | Plant tile / corpse / adjacent fungi |
| Cost | 2 spores | 3 spores |
| Yield (self) | 0.2 decay/tick, 0.05 spores/tick | 0.4 decay/tick, 0.15 spores/tick |
| Bonus | Each mycorrhizal-fungi-under-plantae tile gives **+30% biomass** to the plant tile above | None |
| Visual | Teal subsurface overlay (vs violet) | Violet |

In a pure-fungi run, mycorrhizal yields are weak — it's intentionally a support niche.

## Outputs

### `data/niches/mycorrhizal_fungi.tres`
```
[gd_resource type="Resource" script_class="NicheData" load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/data/niche_data.gd" id="1"]
[ext_resource type="Resource" path="res://data/species/mycelium_thread.tres" id="2"]

[resource]
script = ExtResource("1")
id = &"mycorrhizal_fungi"
display_name = "Mycorrhizal"
description = "Bind to roots. Trade nutrients for sugar. Shine when paired."
kingdom_id = &"fungi"
species_options = Array[Resource]([ExtResource("2")])
colonization_rule = &"mycorrhizal_fungi"
cost_override = {"spores": 2.0}
unlock_node_id = &"unlock_mycorrhizal_fungi"
```

Add to `data/niches/_index.tres`.

### `data/evolution_tree/unlock_mycorrhizal_fungi.tres`
```
[gd_resource type="Resource" script_class="EvolutionNodeData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/evolution_node_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"unlock_mycorrhizal_fungi"
display_name = "Root Whisperer"
description = "Learn the language of root and hypha."
prerequisites = [&"unlock_fungi"]
meta_cost = {"evolution_points": 8}
grants_traits = []
grants_kingdoms = []
```

Append to `data/evolution_tree/_index.tres`.

### `ColonizationRulesRegistry._rule_mycorrhizal_fungi`

```gdscript
func _rule_mycorrhizal_fungi(coord, kingdom_id, species, niche) -> Dictionary:
    var territory: Node = _get_territory()
    if territory.get_subsurface_owner(coord) != &"":
        return {"valid": false, "cost": {}, "data": {}}

    var owned: Array[Vector2i] = territory.get_subsurface_owned_coords(kingdom_id)

    # Bootstrap: first tile must be adjacent to (or under) a plant tile.
    var plant_at_or_adjacent: bool = territory.get_surface_owner(coord) == &"plantae"
    if not plant_at_or_adjacent:
        for n in neighbors(coord):
            if territory.get_surface_owner(n) == &"plantae":
                plant_at_or_adjacent = true
                break

    if owned.is_empty():
        if not plant_at_or_adjacent:
            return {"valid": false, "cost": {}, "data": {}}    # nowhere to root yet
        return {"valid": true, "cost": {}, "data": {}}    # first mycorrhizal tile is free

    # Subsequent: adjacent to plant tile OR adjacent to existing mycorrhizal tile.
    var owned_set: Dictionary = {}
    for c in owned: owned_set[c] = true
    var has_neighbor: bool = plant_at_or_adjacent
    if not has_neighbor:
        for n in neighbors(coord):
            if owned_set.has(n):
                has_neighbor = true
                break
    if not has_neighbor:
        return {"valid": false, "cost": {}, "data": {}}

    var cost: Dictionary = niche.cost_override.duplicate() if not niche.cost_override.is_empty() else species.colonize_cost.duplicate()
    return {"valid": true, "cost": cost, "data": {}}
```

### `GrowthSystem` patch — apply the mycorrhizal yield modifier

When the active niche is `mycorrhizal_fungi` AND a plant surface tile sits on a mycorrhizal subsurface tile, the plant yield gets +30%.

Currently in `_apply_yields`, the symbiosis bonus only fires in symbiosis runs. Extend that with a mycorrhizal check that fires regardless of run mode:

```gdscript
func _is_tile_mycorrhizal_boosted(coord: Vector2i) -> bool:
    if GameState.current_niche_id != &"mycorrhizal_fungi":
        return false
    return _territory.get_surface_owner(coord) == &"plantae" \
        and _territory.get_subsurface_owner(coord) == &"fungi"
```

Inside the per-coord loop in `_apply_yields`, for `resource_key == &"biomass"`:
```gdscript
if _is_tile_mycorrhizal_boosted(coord):
    per_tile *= 1.30
```

### Visual: mycorrhizal teal
`tile_grid.gd` adds atlas tile 5 (teal `#5fa888`) at `Vector2i(4, 0)`. New constant `ATLAS_MYCORRHIZAL_FUNGI`. `set_subsurface_owner` accepts a variant:

```gdscript
func set_subsurface_owner(coord: Vector2i, kingdom_id: StringName, variant: StringName = &"") -> void:
    if String(kingdom_id) == "":
        erase_cell(LAYER_SUBSURFACE, coord)
    elif kingdom_id == &"fungi":
        var atlas: Vector2i = ATLAS_MYCORRHIZAL_FUNGI if variant == &"mycorrhizal" else ATLAS_FUNGI
        set_cell(LAYER_SUBSURFACE, coord, SOURCE_ID, atlas)
```

`TerritorySystem.add_subsurface` accepts the optional variant argument and passes it. FungiColonization, when in mycorrhizal niche, calls `add_subsurface(coord, KINGDOM_ID, &"mycorrhizal")`.

### NicheData expansion (small follow-up if you want it tidier)
Optional: add `@export var tile_variant: StringName = &""` to NicheData. The colonization caller passes `niche.tile_variant` as the visual variant. This removes the niche-id string check from the visual layer. Recommended.

## Acceptance criteria
- [ ] Mycorrhizal niche unlocks after buying `unlock_mycorrhizal_fungi` (8 EP).
- [ ] In pure-fungi mycorrhizal run: cannot bootstrap on empty grid. Must place adjacent to (or on) a plant tile. Fungi-only runs without plants thus get stuck — that's the design.
- [ ] In a run that *already* has plant tiles (e.g. via Phase 10's symbiosis or a future cross-kingdom feature), mycorrhizal tiles can spread.
- [ ] Mycorrhizal subsurface under plant surface: plant tile yields +30% biomass.
- [ ] Visual: teal subsurface vs violet decomposer.
- [ ] No regression in decomposer fungi.

## Out of scope
- Symbiotic Lichen species (Phase 10 will use this niche as its fungi half).
- Cordyceps parasite fungi (Phase 10).
- Cross-kingdom resource sharing beyond the yield bonus (Phase 9 progression web).
