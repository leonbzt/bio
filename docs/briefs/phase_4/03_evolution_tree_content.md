# Brief 03 — Evolution tree content + EvolutionTreeIndex

**Suggested agent**: Kilo for the .tres files. ChatGPT for the index schema.

Read first:
1. `docs/ARCHITECTURE.md` § 4 — `EvolutionNodeData` schema and Content indices subsection.
2. `scripts/data/evolution_node_data.gd`.
3. `scripts/data/biome_index.gd` — pattern to mirror.
4. `data/traits/` — existing trait .tres files that some nodes will grant.

## Goal
Five EvolutionNodeData resources + the index. Nodes form a small branching tree the player progresses through across multiple prestiges.

## Outputs (create)

### Schema
`scripts/data/evolution_tree_index.gd`:
```gdscript
class_name EvolutionTreeIndex
extends Resource

@export var nodes: Array[EvolutionNodeData] = []
```

### Nodes — `data/evolution_tree/`

**`thrifty_growth.tres`** — entry node, no prereq
- `id = &"thrifty_growth"`
- `display_name = "Thrifty Growth"`
- `description = "Colonization costs 1 less biomass."`
- `prerequisites = []`
- `meta_cost = {"evolution_points": 3}`
- `grants_traits = []`
- `grants_kingdoms = []`

**`pioneer_resilience.tres`** — entry node
- `id = &"pioneer_resilience"`
- `display_name = "Pioneer Resilience"`
- `description = "Need 5 tiles owned before events can fire (was 3)."`
- `prerequisites = []`
- `meta_cost = {"evolution_points": 3}`

**`toxin_potency.tres`** — requires one entry node
- `id = &"toxin_potency"`
- `display_name = "Toxin Potency"`
- `description = "Toxin Bloom damage 3 → 5."`
- `prerequisites = [&"thrifty_growth"]`
- `meta_cost = {"evolution_points": 5}`

**`efficient_photosynthesis.tres`** — requires one entry node
- `id = &"efficient_photosynthesis"`
- `display_name = "Efficient Photosynthesis"`
- `description = "Plants gain +20% biomass yield."`
- `prerequisites = [&"pioneer_resilience"]`
- `meta_cost = {"evolution_points": 5}`

**`unlock_fungi.tres`** — the goal node
- `id = &"unlock_fungi"`
- `display_name = "Fungal Kinship"`
- `description = "Discover the fungi kingdom."`
- `prerequisites = [&"toxin_potency", &"efficient_photosynthesis"]`
- `meta_cost = {"evolution_points": 10}`
- `grants_kingdoms = [&"fungi"]`

### Index
`data/evolution_tree/_index.tres`:
```
[gd_resource type="Resource" script_class="EvolutionTreeIndex" load_steps=7 format=3]

[ext_resource type="Script" path="res://scripts/data/evolution_tree_index.gd" id="1"]
[ext_resource type="Resource" path="res://data/evolution_tree/thrifty_growth.tres" id="2"]
[ext_resource type="Resource" path="res://data/evolution_tree/pioneer_resilience.tres" id="3"]
[ext_resource type="Resource" path="res://data/evolution_tree/toxin_potency.tres" id="4"]
[ext_resource type="Resource" path="res://data/evolution_tree/efficient_photosynthesis.tres" id="5"]
[ext_resource type="Resource" path="res://data/evolution_tree/unlock_fungi.tres" id="6"]

[resource]
script = ExtResource("1")
nodes = Array[Resource]([ExtResource("2"), ExtResource("3"), ExtResource("4"), ExtResource("5"), ExtResource("6")])
```

## Tree visualization (for your reference, not part of file content)

```
      thrifty_growth (3)        pioneer_resilience (3)
              |                            |
       toxin_potency (5)         efficient_photosynthesis (5)
              \                            /
               \                          /
                +---- unlock_fungi (10) --+
```

Total cost to unlock fungi from scratch: 3 + 3 + 5 + 5 + 10 = 26 EP.

## Acceptance criteria
- [ ] All 5 nodes + index + schema land in the right paths.
- [ ] `load("res://data/evolution_tree/_index.tres") as EvolutionTreeIndex` returns 5 entries.
- [ ] Each node's `prerequisites` array correctly references other node ids.
- [ ] `unlock_fungi.grants_kingdoms` contains `&"fungi"`.

## Out of scope
- Visual icons (Phase 7 polish).
- Multiple levels per node (binary unlock for now).
- Reset/refund mechanics. Unlocks are permanent.
