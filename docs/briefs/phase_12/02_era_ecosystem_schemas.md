# Brief 02 — EraData + EcosystemData resources + indexes

**Suggested agent**: ChatGPT 5.2. Route diff to Claude — contracts.

Read first:
1. `scripts/data/niche_data.gd`, `discovery_entry.gd` for the resource + content-index pattern.
2. `scripts/data/per_run_goal_data.gd` — the `tracker` taxonomy is reused here.

## Goal
Lay the schema for era/ecosystem content. No content yet (brief 03 authors). No system logic (brief 04 wires).

## Outputs

### `scripts/data/era_data.gd`

```gdscript
class_name EraData
extends Resource
##
## A geological era. Defines which kingdoms are playable and contains
## the ecosystems the player completes to advance to the next era.
## Instances live in data/eras/<id>.tres.
##

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""

# Which kingdoms can be played in this era. Players who unlocked a kingdom
# via the evolution tree still can't play it if the era forbids it.
# Empty = all unlocked kingdoms allowed (default for permissive eras).
@export var available_kingdoms: Array[StringName] = []

# The ecosystems contained in this era. Player must complete all to advance.
@export var ecosystems: Array[EcosystemData] = []

# UI tint for the world-map background per Phase 12 decision 3.
# Phase 13's graphics pass adds richer per-era visuals.
@export var tint_color: Color = Color(1.0, 1.0, 1.0, 0.1)

# 4-8 sentence mythic-scientific passage shown during transition INTO this era.
# Empty for the first era (Cryogenian).
@export var transition_narrative: String = ""

# id of the era that must be fully complete for this era to unlock.
# Empty = always unlocked (default era).
@export var unlock_requires_prev_era: StringName = &""
```

### `scripts/data/ecosystem_data.gd`

```gdscript
class_name EcosystemData
extends Resource
##
## A biome region within an era. Has its own completion criterion.
## Instances live in data/ecosystems/<id>.tres.
##

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""

# Back-reference. Could derive from EraData.ecosystems but explicit is cleaner
# for systems that look up an ecosystem and need its era.
@export var era_id: StringName = &""

# Completion criterion uses the same taxonomy as PerRunGoalData.tracker.
# Recognized values: &"tiles_colonized", &"biomass_earned", &"events_survived",
# &"herbivores_defeated", &"node_purchased".
@export var completion_criterion: StringName = &""
@export var completion_target: float = 0.0

# Optional niche gate: completion only counts if the player ran the criterion
# during a run of this specific niche. Empty = any niche.
@export var completion_required_niche: StringName = &""

# Optional kingdom gate (more permissive than niche). Empty = any kingdom in
# the era's available_kingdoms.
@export var completion_required_kingdom: StringName = &""

# 1-3 sentence flavor shown on the world-map ecosystem tile + on completion.
@export var unlock_text: String = ""
@export var complete_text: String = ""

# Biome preference: a biome_id (from data/biomes/) that should dominate this
# ecosystem's generated map. Phase 13 wires this; Phase 12 stores but ignores.
@export var biome_preference: StringName = &""
```

### `scripts/data/era_index.gd`

```gdscript
class_name EraIndex
extends Resource

@export var eras: Array[EraData] = []
```

### `scripts/data/ecosystem_index.gd`

```gdscript
class_name EcosystemIndex
extends Resource

@export var ecosystems: Array[EcosystemData] = []
```

### Create directories

- `data/eras/` (for `<era_id>.tres` files; brief 03 authors)
- `data/ecosystems/` (for `<ecosystem_id>.tres` files; brief 03 authors)

### Placeholder `data/eras/_index.tres` and `data/ecosystems/_index.tres`

Empty stubs to verify schema loads:

```
[gd_resource type="Resource" script_class="EraIndex" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/era_index.gd" id="1"]

[resource]
script = ExtResource("1")
eras = Array[Resource]([])
```

(Same shape for ecosystem index.)

## ARCHITECTURE.md updates

- §4 schema — add EraData + EcosystemData.
- §9 save schema — append v10 → v11 row.

## Acceptance criteria
- [ ] EraData + EcosystemData load in inspector.
- [ ] Empty `_index.tres` files load without error.
- [ ] No gameplay impact.

## Out of scope
- Era + ecosystem content (brief 03).
- EraSystem autoload (brief 04).
- World map UI (brief 05).
