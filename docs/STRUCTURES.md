# Structures — emergent multi-tile organisms

> **Status**: parked design (no phase committed). Sketched 2026-05-17. See `ROADMAP.md` § Parked ideas.

## Purpose

The current tilemap feels static once a tile is placed — every cell is independently owned, independently yielding, visually identical to its neighbors. The **structures** concept makes the tilemap *transform* as the player builds: when a specific pattern of tiles + layers comes together, the engine **promotes** those tiles into a single multi-cell entity with its own visual, its own status, and its own yield.

This delivers the "tilemap feels alive and changing" experience the user flagged 2026-05-17. It substantiates "place certain combinations and it becomes something larger."

## Why this matters for the vision

| Vision pillar | How structures support it |
|---|---|
| Ecology over fantasy | Real ecosystems are full of emergent multi-organism structures: termite mounds, coral reefs, fairy rings, old-growth canopies. Mechanically modeling this is a strong ecology-flavor win. |
| Complexity through interactions | Structures only form when *combinations* across kingdoms align. A coral reef needs animal + algae + symbiont in a specific pattern — the structure rewards cross-kingdom mastery. |
| Distinct kingdom playstyles | Each kingdom has signature structures (plantae → groves; fungi → rings; animals → mounds; layered packs → reefs). Reinforces playstyle identity. |
| Prestige as evolution | Capstone evolution nodes unlock the *ability* to form a structure. "Lichen Heritage" unlocks the Lichen species; "Old Growth" unlocks the ability to form a Tree structure. |
| Mobile-friendly tempo | Structures are a long-term build goal inside an idle session — you can leave the game, come back, and have new tiles that combine into a structure on the next visit. |

## How a structure forms

1. **Player places tiles normally** (one cell at a time, owner = current kingdom/niche).
2. **After each colonization**, `StructureRegistry` scans the neighborhood of the new tile for matching patterns from the registered `StructureData` set.
3. **A match promotes the involved tiles to a Structure**. The tiles' individual `surface_owner` / `subsurface_owner` are preserved (so saves remain consistent), but new metadata `tile.data.structure_id` references the structure entity.
4. **The structure becomes a single entity** for:
   - **Yield**: instead of N small ticks from N tiles, one consolidated yield from the structure.
   - **Status**: structure has its own HP, decay timer, level, etc. Events that "damage tiles" damage the structure as a unit.
   - **Visual**: the underlying tile sprites are suppressed; a single larger sprite spans the cells.
   - **Events**: events can target structures specifically ("a herd attacks your Tree"; "your Coral Polyp Cluster reaches reef status").
5. **Structures persist** in the run save under `run.structures`. On prestige they're cleared with the rest of run state.

## Examples (sketch)

| Structure | Pattern (relative cells) | Owner requirement | Effect |
|---|---|---|---|
| **Mycorrhizal Hub** | 2×2 cluster | 3× fungi subsurface + 1× plantae surface on center | +50% biomass yield from all 4 tiles, drawn as a glowing root-knot sprite |
| **Old-Growth Tree** | 3-tile vertical line | 3× plantae surface, all `pioneer_resilience` unlocked | +1 sunlight/tick, immune to herbivore wave, drawn as a tall canopy |
| **Fairy Ring** | 8 tiles in a ring (~radius 2) | 8× fungi subsurface | sporadic spore burst event (every 60 ticks, +5 spores in 3-tile AOE) |
| **Coral Polyp Cluster** | 3+ animal tiles touching (any shape) | 3× animal (Coral species) | reef-building progress bar; at 10 tiles, becomes a Reef capable of solving reef ecosystems |
| **Termite Mound** | 5 tiles in pyramid (1 + 2 + 2 staggered) | 5× animal (Termite species), requires_kingdom_played fungi | passive shelter bonus for adjacent tiles; produces Chitin |

The exact patterns + balance are content design. The engine support is generic.

## Schema

### `scripts/data/structure_data.gd`
```gdscript
class_name StructureData
extends Resource

@export var id: StringName
@export var display_name: String
@export var description: String

# Pattern as an array of {offset: Vector2i, owner_layer: StringName, owner_kingdom: StringName}.
# offset is relative to a "pattern anchor" cell. The registry tries each owned tile as the
# anchor and checks whether the pattern matches.
@export var pattern: Array[Dictionary]

# Bounding-box size when promoted, for visual placement.
@export var promoted_size: Vector2i

# Visual sprite (single texture covering the bounding box).
@export var sprite: Texture2D

# Yield emitted per tick by the structure as a whole (replaces per-tile yields of cells in pattern).
@export var tick_yield: Dictionary

# Optional: an evolution node that gates ability to form this structure.
@export var unlock_node_id: StringName

# Optional: a discovery entry triggered on first formation.
@export var discovery_entry_id: StringName

# Optional: HP. Structures with hp > 0 can be damaged by events.
@export var hp: float = 0.0
```

### `scripts/autoloads/structure_registry.gd`

```gdscript
extends Node

const STRUCTURE_INDEX_PATH := "res://data/structures/_index.tres"
var _all_structures: Array[StructureData]

func _ready() -> void:
    EventBus.tile_colonized.connect(_on_tile_colonized)
    _load_structures()

func _on_tile_colonized(coord: Vector2i, _owner: StringName) -> void:
    for structure in _all_structures:
        if structure.unlock_node_id != &"" and not MetaModifiers.is_unlocked(structure.unlock_node_id):
            continue
        var match: Array = _try_match(structure, coord)
        if not match.is_empty():
            _promote(structure, match)
            return    # one promotion per colonization is fine
```

### `run.structures` save shape

```json
"structures": [
  {
    "id": "mycorrhizal_hub",
    "cells": [[12,30],[13,30],[12,31],[13,31]],
    "hp": 10.0,
    "data": {}
  }
]
```

### `TerritorySystem` extensions

- `get_structure_at(coord: Vector2i) -> StructureData` — returns the structure containing this cell, or null.
- `is_part_of_structure(coord: Vector2i) -> bool`.
- `remove_structure(structure_id_or_anchor)` — for events that destroy structures.

When `GrowthSystem._apply_yields` iterates owned tiles, it should skip cells where `is_part_of_structure(coord)` is true and instead yield the structure's `tick_yield` once.

## Interactions with other systems

| System | Interaction |
|---|---|
| Niches | A niche can have a `forms_structures: Array[StringName]` field, restricting which structures it can build (e.g., parasite plantae can't form Old-Growth Tree). |
| Layered lifeforms | A layered species' structure is its capstone payoff. Lichen → Crustose Patch structure. Coral → Reef structure. Termite Mound is the layered Termite pack's structure. |
| Niche signatures | Parasite plantae's signature could be *converting* structures (capturing them into infected versions) rather than building them. |
| Events | Per-axis events can target structures: "A heatwave damages your Old-Growth Tree." Mass extinctions destroy all structures. |
| Discovery log | First-formed of each structure type unlocks an entry. Voice text: "You learned that bodies arranged in a particular way are no longer just bodies — they are a *thing*." |
| Ecosystem completion (Phase 12) | Some ecosystems require a specific structure to "complete": "Build a Coral Reef in this tidal pool" instead of generic tile/biomass thresholds. |
| Tile history | When a structure is destroyed, leaves a *ruin* footprint in tile history that persists longer or carries more weight than ordinary tile history. (See ROADMAP § Parked ideas — tile history is also parked; the combination is a Tier 2+ possibility.) |

## Open design questions

1. **Pattern matching cost**: 32×48 grid × N structures × per-colonization scan could get expensive. Mitigate by indexing structures by their anchor-cell owner requirement, scanning only matching candidates.
2. **Multi-layer structures**: a Tree includes both root (subsurface) and canopy (surface). Does the structure occupy both layers as a single entity, or are they separate? Lean: single entity, the pattern spec just references both layers per cell.
3. **Player anticipation**: how does the player see "I'm one tile away from a structure"? Options: ghost preview overlay on potential anchor cells; a "structures available" panel listing what they could build with their current tile layout; no preview (let the player learn patterns from discovery log).
4. **Structure persistence vs. prestige**: do structures reset on prestige or persist? Lean: reset (it's run state). Long-arc memory comes from tile history (parked) and discovery log (existing), not structures.
5. **Movability**: can a structure be moved/relocated, or only built/destroyed? Lean: only built/destroyed. Movement adds huge complexity.
6. **Stacking**: can multiple structures share cells? Lean: no, mutually exclusive — one cell, one structure.
7. **Player-driven destruction**: should the player be able to *intentionally* dismantle a structure to free its cells? Lean: yes, via a "Dismantle" ability that returns part of the resource cost. Otherwise structures become permanent commitments.

## Implementation phasing

Not phased yet. Probably Phase 13 or 14 (Tier 2 polish) if the user prioritizes. Dependencies:
- Layered-lifeform foundation (Phase 10) — for the layered structure examples (Reef, Termite Mound).
- Per-niche signature mechanics (Phase 10) — for niches that interact with structures specifically.
- Save schema bump (one phase to add `run.structures`).
- Sprite assets (one art pass per structure).

Minimum viable phase: 2-3 starter structures (Mycorrhizal Hub, Old-Growth Tree, Fairy Ring), engine support, discovery entries. Iterate from there.
