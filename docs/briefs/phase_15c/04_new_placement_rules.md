# Brief 04 — 3 new placement rules + variant species

**Suggested agent**: ChatGPT 5.2 (rules) + Kilo (species data). Route diff to Claude.

Read first:
1. `scripts/systems/colonization_rules_registry.gd` — existing rules + dispatcher.
2. `scripts/data/species_data.gd` — `placement_rule`, `placement_targets`, `tags` fields.
3. `docs/SPECIES_ROSTER.md` for naming/voice conventions.

## Goal

Add 3 new placement rules to `ColonizationRulesRegistry` and 3 variant species using them:

| Rule | Behavior | Species |
|---|---|---|
| `diagonal_only` | Places only on 4-diagonal of existing same-kingdom tiles | Creeping Vine (plantae variant of bramble) |
| `gap_jumper` | Places up to 4 tiles away in cardinal line-of-sight (with no obstacles between) | Spore Drift (fungi, wind-dispersed) |
| `corpse_only` | Places exclusively on corpse tiles | Scavenger Swarm (animals, eats corpses) |

## Rule implementations

In `scripts/systems/colonization_rules_registry.gd.evaluate(coord, species)`, extend the match:

```gdscript
match species.placement_rule:
    # ... existing rules ...
    &"diagonal_only":
        return _rule_diagonal_only(coord, species)
    &"gap_jumper":
        return _rule_gap_jumper(coord, species)
    &"corpse_only":
        return _rule_corpse_only(coord, species)
```

### `diagonal_only`

```gdscript
func _rule_diagonal_only(coord: Vector2i, species: SpeciesData) -> Dictionary:
    var territory: Node = _get_territory()
    if territory == null: return _invalid()
    var kingdom_id: StringName = species.kingdom_id
    # Slot must be empty.
    if territory.get_occupant(coord, kingdom_id) != &"":
        return _invalid()
    var owned: Array[Vector2i] = territory.get_kingdom_occupied_coords(kingdom_id)
    if owned.is_empty():
        # First tile placement: allow anywhere (same first-free pattern as adjacent_empty).
        return _single(coord, species, {}, {})
    # Check if any of the 4 diagonals has an owned tile of the same kingdom.
    var diagonals: Array[Vector2i] = [
        Vector2i(coord.x - 1, coord.y - 1),
        Vector2i(coord.x + 1, coord.y - 1),
        Vector2i(coord.x - 1, coord.y + 1),
        Vector2i(coord.x + 1, coord.y + 1)
    ]
    var has_diag: bool = false
    for d in diagonals:
        if territory.get_occupant(d, kingdom_id) != &"":
            has_diag = true
            break
    if not has_diag:
        return _invalid()
    var cost: Dictionary = _scaled_cost(species)
    if MetaModifiers.is_unlocked(&"thrifty_growth"):
        for k in cost.keys():
            cost[k] = maxf(0.0, float(cost[k]) - 1.0)
    return _single(coord, species, cost, {})
```

### `gap_jumper`

```gdscript
const GAP_JUMPER_MAX_RANGE: int = 4

func _rule_gap_jumper(coord: Vector2i, species: SpeciesData) -> Dictionary:
    var territory: Node = _get_territory()
    if territory == null: return _invalid()
    var kingdom_id: StringName = species.kingdom_id
    if territory.get_occupant(coord, kingdom_id) != &"":
        return _invalid()
    var owned: Array[Vector2i] = territory.get_kingdom_occupied_coords(kingdom_id)
    if owned.is_empty():
        return _single(coord, species, {}, {})
    # Check cardinal line-of-sight up to GAP_JUMPER_MAX_RANGE tiles away.
    # LOS = no obstacle (rock) in between.
    var obstacles: Node = _get_obstacle_system()
    var found: bool = false
    for dir in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
        for dist in range(1, GAP_JUMPER_MAX_RANGE + 1):
            var n: Vector2i = coord + dir * dist
            # If this far cell is owned by this kingdom, LOS established.
            if territory.get_occupant(n, kingdom_id) != &"":
                # Verify no obstacle on the path between coord and n (exclusive).
                var blocked: bool = false
                for inter_dist in range(1, dist):
                    var inter: Vector2i = coord + dir * inter_dist
                    if obstacles != null and obstacles.has_method("is_obstacle") and obstacles.is_obstacle(inter):
                        blocked = true
                        break
                if not blocked:
                    found = true
                    break
        if found: break
    if not found:
        return _invalid()
    var cost: Dictionary = _scaled_cost(species)
    return _single(coord, species, cost, {})


func _get_obstacle_system() -> Node:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null: return null
    return tree.root.get_node_or_null("World/Systems/ObstacleSystem")
```

### `corpse_only`

```gdscript
func _rule_corpse_only(coord: Vector2i, species: SpeciesData) -> Dictionary:
    var territory: Node = _get_territory()
    if territory == null: return _invalid()
    var kingdom_id: StringName = species.kingdom_id
    if territory.get_occupant(coord, kingdom_id) != &"":
        return _invalid()
    var corpses: Node = _get_corpses()
    if corpses == null or not corpses.has_method("is_corpse_at"):
        return _invalid()
    if not corpses.is_corpse_at(coord):
        return _invalid()
    var cost: Dictionary = _scaled_cost(species)
    return _single(coord, species, cost, {})
```

## Variant species

### `data/species/creeping_vine.tres`

```
[gd_resource type="Resource" script_class="SpeciesData" load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/data/species_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"creeping_vine"
display_name = "Creeping Vine"
description = "A plant that grows on its own shadow — corner to corner, never straight."
kingdom_id = &"plantae"
sprite = null
base_traits = Array[Resource]([])
colonize_cost = {"biomass": 4.0}
tick_yield = {"biomass": 0.35}
introduce_cost = {"biomass": 60.0}
placement_rule = &"diagonal_only"
placement_targets = Array[StringName]([])
tags = Array[StringName]([&"plantae", &"climber"])
tick_effects = Array[StringName]([])
unlock_ep_cost = 5
unlock_prerequisites = Array[StringName]([&"pioneer_grass"])
era_requires = &""
recipe_components = Array[StringName]([])
tile_marker_color = Color(0.40, 0.60, 0.20, 1.0)
tile_marker_shape = &"cross"
latin_name = "Vitis serpentina (modeled, all eras)"
lineage_id = &"climber"
biome_affinity = {
&"forest_edge": 1.3,
&"swamp": 1.2,
&"rich_soil": 1.0,
&"grassland": 0.9,
&"tundra": 0.5,
&"mineral_vent": 0.4
}
```

### `data/species/spore_drift.tres`

```
[resource]
id = &"spore_drift"
display_name = "Spore Drift"
description = "Spores that catch the wind. They land where the wind decides — far from where they began."
kingdom_id = &"fungi"
sprite = null
base_traits = Array[Resource]([])
colonize_cost = {"spores": 4.0}
tick_yield = {"biomass": 0.25, "spores": 0.20}
introduce_cost = {"spores": 70.0, "biomass": 30.0}
placement_rule = &"gap_jumper"
placement_targets = Array[StringName]([])
tags = Array[StringName]([&"fungi", &"wind_dispersed"])
tick_effects = Array[StringName]([])
unlock_ep_cost = 5
unlock_prerequisites = Array[StringName]([&"mycelium_thread"])
era_requires = &""
recipe_components = Array[StringName]([])
tile_marker_color = Color(0.60, 0.45, 0.80, 1.0)
tile_marker_shape = &"spore"
latin_name = "Aspergillus aerios (modeled, all eras)"
lineage_id = &"wind_disperser"
biome_affinity = {
&"forest_edge": 1.1,
&"grassland": 1.2,
&"swamp": 1.0,
&"tundra": 0.7,
&"rich_soil": 1.0,
&"mineral_vent": 0.5
}
```

### `data/species/scavenger_swarm.tres`

```
[resource]
id = &"scavenger_swarm"
display_name = "Scavenger Swarm"
description = "Many small mouths that arrive only where something has died."
kingdom_id = &"animals"
sprite = null
base_traits = Array[Resource]([])
colonize_cost = {"biomass": 5.0}
tick_yield = {"biomass": 0.30}
introduce_cost = {"biomass": 70.0, "protein": 20.0}
placement_rule = &"corpse_only"
placement_targets = Array[StringName]([])
tags = Array[StringName]([&"animals", &"scavenger"])
tick_effects = Array[StringName]([])
unlock_ep_cost = 5
unlock_prerequisites = Array[StringName]([&"common_grazer"])
era_requires = &""
recipe_components = Array[StringName]([])
tile_marker_color = Color(0.55, 0.35, 0.25, 1.0)
tile_marker_shape = &"border"
latin_name = "Necrophagus convocatus (modeled)"
lineage_id = &"scavenger"
biome_affinity = {
&"swamp": 1.3,
&"forest_edge": 1.2,
&"rich_soil": 1.1,
&"grassland": 1.0,
&"tundra": 0.6,
&"mineral_vent": 0.5
}
```

### Update `data/species/_index.tres`

Append all 3 new species.

### Auto-unlock for testing

For Phase 15c playtest convenience, add to `save_system.gd._PHASE_14A_AUTO_UNLOCK` (or rename to `_PHASE_15C_AUTO_UNLOCK`):

```gdscript
const _PHASE_14A_AUTO_UNLOCK: Array[String] = [
    # ... existing ...
    "creeping_vine",
    "spore_drift",
    "scavenger_swarm"
]
```

(Until proper unlock-tree integration, these are auto-unlocked. Same stopgap as before.)

## Discovery entries (optional but recommended)

Author 3 species discovery entries (`disc_species_creeping_vine.tres`, `disc_species_spore_drift.tres`, `disc_species_scavenger_swarm.tres`) following existing voice. Register in `_index.tres`. Skip if scope-tight.

## Acceptance criteria

- [ ] All 3 new placement rules implemented + dispatched in `evaluate()`.
- [ ] 3 variant species `.tres` files load + appear in species picker (after auto-unlock).
- [ ] Creeping Vine can only place diagonally adjacent to its own tiles (cardinal placements rejected).
- [ ] Spore Drift can place up to 4 tiles away in a cardinal direction along clear line-of-sight (blocked by rocks).
- [ ] Scavenger Swarm can only place on corpse tiles.
- [ ] First-tile-free behavior preserved for all 3 rules.
- [ ] Cost scaling (Phase 15a brief 06) applies to all 3.
- [ ] All 3 species auto-unlocked via defensive repair for testing.

## Out of scope

- Discovery entries (optional; can land later).
- Proper EP-unlock tree integration (uses auto-unlock stopgap).
- Per-rule variant abilities (e.g., spore_drift gains spore range bonus from a node).
- Visual indicator on valid placement targets (Phase 16+ polish).
