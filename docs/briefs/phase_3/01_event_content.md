# Brief 01 — Event content + EventIndex

**Suggested agent**: Kilo Code free model for the .tres files. ChatGPT for the index schema.

Read first:
1. `docs/ARCHITECTURE.md` § 4 (`EventData` schema) and the **Content indices** subsection.
2. `scripts/data/event_data.gd`.
3. `scripts/data/biome_index.gd` and `data/biomes/_index.tres` — pattern to mirror.

## Goal
Define the one Phase 3 event (`HerbivoreWave`) as a `.tres` and create the event index so EcologicalPressure can enumerate events without using DirAccess. Set up two more lighter events as placeholders for variety scheduling, even though only HerbivoreWave is actively handled this phase.

## Outputs (create)

### Schema
`scripts/data/event_index.gd`:
```gdscript
class_name EventIndex
extends Resource

@export var events: Array[EventData] = []
```

### Content
`data/events/herbivore_wave.tres`:
- `id = &"herbivore_wave"`
- `display_name = "Herbivore Wave"`
- `description = "A herd has wandered into your territory."`
- `trigger_weight = 1.0`
- `duration_ticks = 60`
- `payload = {"spawn_count": 3, "chew_ticks": 4, "speed_ticks": 2, "hp": 2.0}`
  - `spawn_count`: how many herbivores spawn at the start.
  - `chew_ticks`: how many ticks a herbivore takes to eat one tile.
  - `speed_ticks`: how many ticks it takes a herbivore to move one tile.
  - `hp`: starting HP per herbivore.

`data/events/drought.tres` — placeholder, no handler this phase:
- `id = &"drought"`
- `display_name = "Drought"`
- `description = "Sunlight bakes the topsoil; nutrient generation halves."`
- `trigger_weight = 0.5`
- `duration_ticks = 90`
- `payload = {"nutrient_multiplier": 0.5}`

`data/events/cool_spell.tres` — placeholder, no handler this phase:
- `id = &"cool_spell"`
- `display_name = "Cool Spell"`
- `description = "Cloud cover dims sunlight."`
- `trigger_weight = 0.5`
- `duration_ticks = 60`
- `payload = {"sunlight_multiplier": 0.5}`

### Index
`data/events/_index.tres`:
```
[gd_resource type="Resource" script_class="EventIndex" load_steps=5 format=3]

[ext_resource type="Script" path="res://scripts/data/event_index.gd" id="1"]
[ext_resource type="Resource" path="res://data/events/herbivore_wave.tres" id="2"]
[ext_resource type="Resource" path="res://data/events/drought.tres" id="3"]
[ext_resource type="Resource" path="res://data/events/cool_spell.tres" id="4"]

[resource]
script = ExtResource("1")
events = Array[Resource]([ExtResource("2"), ExtResource("3"), ExtResource("4")])
```

## .tres template
EventData files follow the same template you used for biomes (`script_class="EventData"`, `[ext_resource type="Script" path="res://scripts/data/event_data.gd" id="1"]`, then the resource block with the typed fields).

## Acceptance criteria
- [ ] All 3 event .tres + 1 index .tres + 1 schema .gd land in the right paths.
- [ ] `load("res://data/events/_index.tres") as EventIndex` returns a non-null index containing 3 entries in the editor.
- [ ] No system *handles* drought/cool_spell yet (they're scheduling-only placeholders).

## Out of scope
- Drought/cool_spell handlers — Phase 5+.
- Visual styling for events. Brief 06 in this phase covers a simple toast.
