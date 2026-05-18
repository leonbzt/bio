# Brief 06 — EvolutionNodeData.requires_era + 5 new era-gated nodes

**Suggested agent**: ChatGPT 5.2 + Kilo. Route diff to Claude.

Read first:
1. `scripts/data/evolution_node_data.gd` — current schema.
2. `scripts/systems/prestige_system.gd.purchase_node` + `_prerequisites_met`.
3. `docs/briefs/phase_13_paused/07_era_gated_evolution_nodes.md` — direct source material.

## Goal

Add `requires_era: StringName` field to `EvolutionNodeData`. Author 5 new era-gated nodes. PrestigeSystem checks the era gate on purchase + tree UI surfaces lock status.

## Schema

### `scripts/data/evolution_node_data.gd`

Append:

```gdscript
# Phase 14b: era gate. Empty = always purchasable.
# When set, the node may only be PURCHASED while playing in this era.
# Already-purchased nodes stay unlocked forever, regardless of era.
@export var requires_era: StringName = &""
```

### PrestigeSystem

Add to `purchase_node` or as a guard:

```gdscript
func is_node_purchasable(node: EvolutionNodeData) -> bool:
    # Extinction Survivor: requires first era transition completed.
    if node.id == &"extinction_survivor":
        var completed: Array = GameState.meta_save.get("first_run_in_era_completed", []) as Array
        if completed.is_empty():
            return false
    if node.requires_era == &"":
        return true
    var current_era := StringName(GameState.meta_save.get("current_era_id", ""))
    return current_era == node.requires_era


# Modify purchase_node to call is_node_purchasable:
func purchase_node(node_id: StringName) -> bool:
    var node := _find_node(node_id)
    if node == null:
        return false
    if is_node_unlocked(node_id):
        return false
    if not _prerequisites_met(node):
        return false
    if not _kingdoms_played_satisfied(node):
        return false
    if not is_node_purchasable(node):
        return false
    # ... rest unchanged ...
```

## 5 new era-gated node files

### `data/evolution_tree/cryotolerance.tres`

```
[resource]
id = &"cryotolerance"
display_name = "Cryotolerance"
description = "Your lineage shrugs off the chill. Cold Snap and Cool Spell hit at 0.85× strength."
prerequisites = Array[StringName]([&"pioneer_resilience"])
meta_cost = {"evolution_points": 4}
grants_traits = Array[Resource]([])
grants_kingdoms = Array[StringName]([])
grants_species = Array[StringName]([])
wing = &"defense"
tier = 2
requires_kingdom_played = Array[StringName]([])
requires_era = &"cryogenian"
```

**Wiring**: when `MetaModifiers.is_unlocked(&"cryotolerance")`, multiply the *severity* of cold_snap / cool_spell modifiers by 0.85. Implementation hint: in `AmbientModifierSystem.get_event_multiplier`, if the modifier comes from `cold_snap` or `cool_spell` AND `cryotolerance` is unlocked, blend the multiplier toward 1.0:

```gdscript
func get_event_multiplier(event_id: StringName, key: StringName) -> float:
    var raw := _raw_event_multiplier(event_id, key)
    if (event_id == &"cold_snap" or event_id == &"cool_spell") and MetaModifiers.is_unlocked(&"cryotolerance"):
        # Blend toward 1.0: severity × 0.85.
        return 1.0 + (raw - 1.0) * 0.85
    return raw
```

### `data/evolution_tree/chemosynthetic_pathway.tres`

```
[resource]
id = &"chemosynthetic_pathway"
display_name = "Chemosynthetic Pathway"
description = "Convert mineral substrate to biomass without sunlight. Fungi on chemosynthesis-rich biomes gain +50% biomass."
prerequisites = Array[StringName]([&"unlock_fungi"])
meta_cost = {"evolution_points": 6}
wing = &"fungi"
tier = 3
requires_kingdom_played = Array[StringName]([&"fungi"])
requires_era = &"cryogenian"
```

**Wiring**: in `GrowthSystem._apply_yields` fungi branch, when `MetaModifiers.is_unlocked(&"chemosynthetic_pathway")` AND `biome.chemosynthesis_per_tick > 0.0`, multiply per_tile by 1.5 (stacks with base chemosynthesis).

### `data/evolution_tree/vascular_network.tres`

```
[resource]
id = &"vascular_network"
display_name = "Vascular Network"
description = "Plant tiles with 4+ owned neighbors gain +25% biomass. The forest carries its own."
prerequisites = Array[StringName]([&"efficient_photosynthesis"])
meta_cost = {"evolution_points": 8}
wing = &"plantae"
tier = 3
requires_kingdom_played = Array[StringName]([&"plantae"])
requires_era = &"devonian"
```

**Wiring**: in plantae biomass branch, if `MetaModifiers.is_unlocked(&"vascular_network")`, count owned neighbors via `_territory.get_kingdom_occupied_coords`. If ≥4 plantae neighbors, multiply per_tile by 1.25.

### `data/evolution_tree/mass_fruiting.tres`

```
[resource]
id = &"mass_fruiting"
display_name = "Mass Fruiting"
description = "Unlocks the Sporulate tap-action: burst spores from a fungal cluster, granting +10 spores per adjacent owned tile."
prerequisites = Array[StringName]([&"spore_distribution"])
meta_cost = {"evolution_points": 7}
wing = &"fungi"
tier = 3
requires_kingdom_played = Array[StringName]([&"fungi"])
requires_era = &"devonian"
```

**Wiring**: register `&"sporulate"` ability in `AbilitySystem`. Cooldown ~45s, cost 0. On use over a fungal tile, count adjacent owned tiles and add `10 * count` spores to ledger.

If sporulate ability wiring is heavier than expected, ship the node greyed with tooltip "(coming Phase 15)". Document graceful degrade.

### `data/evolution_tree/extinction_survivor.tres`

```
[resource]
id = &"extinction_survivor"
display_name = "Extinction Survivor"
description = "Memory of catastrophe sharpens what comes after. All yields +10%."
prerequisites = Array[StringName]([])
meta_cost = {"evolution_points": 10}
wing = &"meta"
tier = 4
requires_kingdom_played = Array[StringName]([])
requires_era = &""
```

**Special**: cross-era node, purchase locked behind first era transition (handled in `is_node_purchasable` above). When unlocked, multiply all biomass yields by 1.10 (`MetaModifiers.is_unlocked(&"extinction_survivor")`).

## Update `data/evolution_tree/_index.tres`

Append all 5 new nodes.

## Evolution tree UI surfacing

In the tree screen rendering, when drawing each node:
- If `requires_era` set AND `current_era_id != requires_era` AND node not unlocked: grey out + badge ("CRYO" / "DEVO") + tooltip "Requires {Era} era".
- Extinction Survivor: if `first_run_in_era_completed.is_empty()`: grey + tooltip "Requires first era transition".

Reuse existing `requires_kingdom_played` greying styling.

## Acceptance criteria

- [ ] `EvolutionNodeData.requires_era` field exists; default `&""`.
- [ ] All 5 new nodes load + registered.
- [ ] `is_node_purchasable` returns false for era-locked nodes when current era doesn't match.
- [ ] Tree UI surfaces era badges for locked nodes.
- [ ] `extinction_survivor` locked until at least one era transition is completed.
- [ ] Cryotolerance reduces cold_snap / cool_spell severity to ~0.85× when active.
- [ ] Chemosynthetic Pathway adds +50% to fungi biomass on mineral_vent.
- [ ] Vascular Network adds +25% to plantae tiles with 4+ neighbors.
- [ ] Mass Fruiting either ships Sporulate ability OR ships greyed with deferred tooltip.
- [ ] Extinction Survivor adds +10% biomass to all subsequent runs.

## Out of scope

- Generic `requires_milestone` field on EvolutionNodeData.
- Refunds / respec.
- Multi-era nodes (require either era).
- Cross-era node variants requiring multiple transitions.
- Per-era tree column highlighting (polish).
