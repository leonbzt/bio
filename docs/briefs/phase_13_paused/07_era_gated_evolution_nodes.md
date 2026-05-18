# Brief 07 — Era-gated evolution nodes (schema + 5 new nodes)

**Suggested agent**: ChatGPT 5.2 for the schema + PrestigeSystem edits. Kilo for the 5 .tres files. Claude reviews balance + gating.

Read first:
1. `scripts/data/evolution_node_data.gd` — current schema.
2. `data/evolution_tree/unlock_fungi.tres`, `data/evolution_tree/wood_wide_web.tres` — existing node shape.
3. `scripts/systems/prestige_system.gd` — where node availability is filtered (and where to add the era gate).
4. `scripts/ui/evolution_tree_screen.gd` (or similar) — UI surface; era-gated nodes display greyed-out with a tooltip.

## Goal

Add a `requires_era: StringName` field to `EvolutionNodeData`. Author 5 new nodes that exercise the gating mechanic. Update the tree UI to grey-out era-locked nodes with a clear "Requires X era" tooltip.

## Schema change

### `scripts/data/evolution_node_data.gd`

```gdscript
class_name EvolutionNodeData
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var prerequisites: Array[StringName] = []
@export var meta_cost: Dictionary = {}
@export var grants_traits: Array[TraitData] = []
@export var grants_kingdoms: Array[StringName] = []

@export var wing: StringName = &""
@export var tier: int = 1
@export var requires_kingdom_played: Array[StringName] = []

# Phase 13: era gate. Empty = always purchasable.
# When set, the node may only be PURCHASED while playing in this era.
# Already-purchased nodes stay purchased forever, regardless of era.
@export var requires_era: StringName = &""
```

## PrestigeSystem integration

Add a node-availability filter that respects the era gate:

```gdscript
func is_node_purchasable(node: EvolutionNodeData) -> bool:
    if node.requires_era == &"":
        return true
    var current_era := StringName(GameState.meta_save.get("current_era_id", ""))
    return current_era == node.requires_era
```

Whatever path currently invokes "can purchase" (UI guard, purchase API, etc.) defers to this method. Already-unlocked nodes (in `meta.unlocked_nodes`) are not re-checked — they're permanent.

## UI integration

In the tree screen, when rendering each node:
- If `requires_era` is set AND `current_era_id != requires_era` AND node is not already unlocked: render greyed-out with a small badge ("CRYO" / "DEVO") and tooltip "Requires Cryogenian era — play any ecosystem there to unlock this purchase."
- If already unlocked: render normally regardless of era.

The tooltip pattern matches the existing `requires_kingdom_played` greying logic. Reuse that styling.

## New evolution nodes

### `data/evolution_tree/cryotolerance.tres`

```
[gd_resource type="Resource" script_class="EvolutionNodeData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/evolution_node_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"cryotolerance"
display_name = "Cryotolerance"
description = "Your lineage shrugs off the chill. Cold Snap and Cool Spell hit at 0.85× strength."
prerequisites = Array[StringName]([&"pioneer_resilience"])
meta_cost = {"evolution_points": 4}
grants_traits = Array[Resource]([])
grants_kingdoms = Array[StringName]([])
wing = &"defense"
tier = 2
requires_kingdom_played = Array[StringName]([])
requires_era = &"cryogenian"
```

**Mechanic** (wired in AmbientModifierSystem or growth_system): when `cryotolerance` is unlocked, multiply the *severity* of cold_snap and cool_spell modifiers by 0.85 instead of 1.0. (The simplest implementation: when stacking the event's `sunlight_multiplier` debuff into the ambient multiplier, blend it toward 1.0 by `(1.0 - 0.85) = 0.15`.)

Doesn't grant a trait — applied via MetaModifiers check in the modifier path.

### `data/evolution_tree/chemosynthetic_pathway.tres`

```
[gd_resource type="Resource" script_class="EvolutionNodeData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/evolution_node_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"chemosynthetic_pathway"
display_name = "Chemosynthetic Pathway"
description = "Convert mineral substrate to biomass without sunlight. Fungi on chemosynthesis-rich biomes gain +50% biomass."
prerequisites = Array[StringName]([&"unlock_fungi"])
meta_cost = {"evolution_points": 6}
grants_traits = Array[Resource]([])
grants_kingdoms = Array[StringName]([])
wing = &"fungi"
tier = 3
requires_kingdom_played = Array[StringName]([&"fungi"])
requires_era = &"cryogenian"
```

**Mechanic** (wired in growth_system fungi-biomass branch): when this node is unlocked AND tile's biome has `chemosynthesis_per_tick > 0`, multiply per_tile biomass by 1.5. Stacks with the base chemosynthesis bonus from brief 02.

### `data/evolution_tree/vascular_network.tres`

```
[gd_resource type="Resource" script_class="EvolutionNodeData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/evolution_node_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"vascular_network"
display_name = "Vascular Network"
description = "Plant tiles with 4+ owned neighbors gain +25% biomass. The forest carries its own."
prerequisites = Array[StringName]([&"efficient_photosynthesis"])
meta_cost = {"evolution_points": 8}
grants_traits = Array[Resource]([])
grants_kingdoms = Array[StringName]([])
wing = &"plantae"
tier = 3
requires_kingdom_played = Array[StringName]([&"plantae"])
requires_era = &"devonian"
```

**Mechanic** (in growth_system plantae path): when this node is unlocked, for each plantae tile count owned neighbors via `_territory.get_surface_owner`. If ≥4, multiply per_tile biomass by 1.25. Reward for dense board states.

### `data/evolution_tree/mass_fruiting.tres`

```
[gd_resource type="Resource" script_class="EvolutionNodeData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/evolution_node_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"mass_fruiting"
display_name = "Mass Fruiting"
description = "Unlocks the Sporulate tap-action: burst spores from a fungal cluster, granting +10 spores per adjacent owned tile."
prerequisites = Array[StringName]([&"spore_distribution"])
meta_cost = {"evolution_points": 7}
grants_traits = Array[Resource]([])
grants_kingdoms = Array[StringName]([])
wing = &"fungi"
tier = 3
requires_kingdom_played = Array[StringName]([&"fungi"])
requires_era = &"devonian"
```

**Mechanic**: registers a new ability id `&"sporulate"` in AbilitySystem (cooldown ~45s, costs 0 — opt-in flavor burst). When used on a fungal tile, count adjacent owned tiles and add `10 * count` spores to the ledger. Same active-intervention pattern as Phase 11's `bundle` (cold-spell counter) and `irrigate`.

If wiring the tap-action is heavy, ship the node ungranted-ability for v1 and defer Sporulate to a Phase 14 follow-on brief. Flagged graceful degrade.

### `data/evolution_tree/extinction_survivor.tres`

```
[gd_resource type="Resource" script_class="EvolutionNodeData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/evolution_node_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"extinction_survivor"
display_name = "Extinction Survivor"
description = "Memory of catastrophe sharpens what comes after. All yields +10%."
prerequisites = Array[StringName]([])
meta_cost = {"evolution_points": 10}
grants_traits = Array[Resource]([])
grants_kingdoms = Array[StringName]([])
wing = &"meta"
tier = 4
requires_kingdom_played = Array[StringName]([])
requires_era = &""
```

**Special**: Cross-era node, **but** purchasable only after the first era transition has happened (i.e., `meta.first_run_in_era_completed` is non-empty). Implement this as a second predicate in `is_node_purchasable`:

```gdscript
func is_node_purchasable(node: EvolutionNodeData) -> bool:
    if node.id == &"extinction_survivor":
        var completed: Array = GameState.meta_save.get("first_run_in_era_completed", []) as Array
        if completed.is_empty():
            return false
    if node.requires_era == &"":
        return true
    var current_era := StringName(GameState.meta_save.get("current_era_id", ""))
    return current_era == node.requires_era
```

Alternative cleaner approach (preferred if scope budget allows): add `requires_milestone: StringName = &""` field to `EvolutionNodeData` and check it generically. But for Phase 13 the hard-coded special case is acceptable — there's only one such node.

**Mechanic** (in growth_system + animal_system biomass paths): when unlocked, multiply all biomass yields by 1.1. Implemented via existing MetaModifiers check pattern.

## Update `data/evolution_tree/_index.tres`

Append all 5 new nodes.

## ARCHITECTURE.md updates

- §4 schema — add `requires_era` to `EvolutionNodeData`.
- §6 systems — note PrestigeSystem's era-gate check on purchase.

## Acceptance criteria

- [ ] `EvolutionNodeData.requires_era` field exists; default `&""`.
- [ ] All 5 new nodes load in inspector.
- [ ] All 5 registered in evolution tree index.
- [ ] `PrestigeSystem.is_node_purchasable` returns false for an era-gated node when current era doesn't match.
- [ ] Tree UI shows era-gated nodes greyed out with era badge when wrong era.
- [ ] `extinction_survivor` is locked until the player has completed at least one era transition.
- [ ] Buying `cryotolerance` during a Cryogenian run reduces Cold Snap and Cool Spell severity to ~0.85× the debuff impact.
- [ ] Buying `chemosynthetic_pathway` boosts fungi biomass on `mineral_vent` and `cryo_volcanic_vent` tiles by an extra 50%.
- [ ] Buying `vascular_network` boosts plantae tiles with ≥4 neighbors by +25%.
- [ ] Buying `extinction_survivor` applies +10% biomass to all subsequent runs across all eras.
- [ ] Mass Fruiting either ships the Sporulate tap-action OR ships the node grey-flagged "ability coming Phase 14" — document the choice in the implementation PR.

## Out of scope

- Generic `requires_milestone` field on `EvolutionNodeData` (defer if scope tight).
- Refunds / respec for era-gated nodes purchased in the wrong era (not possible — gate is on purchase).
- Per-era visualization in the tree (column highlighting by era). Polish.
- Multi-era nodes (a node that requires either Cryogenian OR Devonian). Out of scope until a third era exists.
- Cross-era nodes that *require* multiple era transitions (no second-tier extinction_survivor variant in Phase 13).
