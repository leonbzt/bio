# Progression Web — interconnected evolution tree

## Purpose
The current evolution tree is a flat per-kingdom unlock graph (8 nodes, mostly numeric bonuses). The post-MVP vision is a **directed graph across kingdoms**, where mastering one kingdom opens doors in another. This is what makes the meta-progression feel alive across dozens of runs.

## Mechanical foundation
**The existing `EvolutionNodeData.prerequisites: Array[StringName]` field already references node ids freely**, so cross-kingdom prerequisites are a *content* design problem, not an engine one. We just need to:
1. Author a richer set of nodes.
2. Render them in a tree visualization that *shows* the web (right now the UI doesn't visualize relationships).
3. Tag nodes with `wing` metadata so the UI can group them.

Schema addition:
```gdscript
class_name EvolutionNodeData
extends Resource

@export var id: StringName
# ... existing fields ...
@export var wing: StringName        # &"plantae", &"fungi", &"animals", &"hybrid"
@export var tier: int = 1           # for layout: 1 = entry, 2 = mid, 3 = capstone
@export var requires_kingdom_played: Array[StringName] = []   # soft prereq: must have played a run as this
```

`requires_kingdom_played` is the cross-kingdom hook. A node can require "must have completed a fungi run" without requiring a specific other node. Encourages exploration.

## Wing structure

| Wing | Theme | Color in UI |
|---|---|---|
| **Plantae** | Surface, light, growth | Green |
| **Fungi** | Underground, decay, network | Violet |
| **Animals** | Mobility, predation, behavior | Amber |
| **Hybrid** | Cross-kingdom: symbiosis, mutualism, parasitism | Teal |

Each wing has roughly **8–12 nodes** across three tiers. Total target: ~40 nodes by Tier 2 of the roadmap.

## Sample cross-kingdom chains

### Chain A: From decomposer to plantae regrowth
```
[Fungi] Decomposer Mastery (tier 1)
   ↓
[Fungi] Saprophytic Efficiency II (tier 2)
   ↓ AND requires_kingdom_played includes &"plantae"
[Plantae] Soil Memory (tier 2) — biomes that hosted past plant runs yield more biomass.
```
Pure plantae players never see "Soil Memory" — it's a reward for cross-kingdom exploration.

### Chain B: Predator-prey unlocks
```
[Plantae] Insectivory (tier 1) — carnivore niche grants
   ↓
[Fungi] Cordyceps Mastery (tier 2) — parasite niche grants
   ↓ AND requires_kingdom_played includes both plantae and fungi
[Animals] Predator Awakening (tier 3) — animal kingdom unlocks; predator niche grants
```
The animal kingdom is *earned* by mastering predation across two other kingdoms first. Players feel they evolved into it.

### Chain C: Symbiosis as emergent
```
[Plantae] Photosynthetic Generosity (tier 2)
   AND
[Fungi] Mycorrhizal Network (tier 2)
   ↓
[Hybrid] Lichen Heritage (tier 3) — unlocks Lichen species, which enables dual-layer play.
```
Symbiosis stops being a kingdom and becomes a node-unlocked species. (See `GAME_VISION.md` → "How symbiosis works".)

## Visualization

The tree UI should:
- **Group nodes by wing horizontally** (Plantae left, Fungi center-left, Hybrid center, Animals right).
- **Stack by tier vertically** (entry nodes top, capstones bottom).
- **Draw prereq lines across wings** so the player sees the crossings.
- **Color the line by destination wing** so crossings are visually loud.
- Greyed/locked nodes still display so players see future potential. Tooltip explains "Requires: X, Y, played run as Z".

This is intentionally visually busy — the busyness is the point. The player should look at the tree and think "wow there's a lot to explore."

## Migration from current tree

The 8 nodes currently in `data/evolution_tree/` map cleanly into wings:
- `thrifty_growth`, `pioneer_resilience`, `efficient_photosynthesis` → plantae wing, tier 1
- `toxin_potency` → plantae wing, tier 2
- `unlock_fungi` → hybrid wing, tier 1 (the "discovery" node)
- `unlock_symbiosis`, `mutualism`, `wood_wide_web` → hybrid wing, tier 2/3

Phase 9 will add the `wing` and `tier` metadata to existing nodes, then add ~10 new cross-kingdom nodes to populate the connections.

## Open design questions

1. **Refunds and respec?** Once you buy a node, is it forever? Lean YES for v1 (refunds are a UX safety net that often makes balance harder — and they're not very ecology-themed).
2. **Visual on mobile**: a sprawling DAG on a 360×640 screen is hard. Probably need vertical scroll + horizontal pan. Or: each wing is a separate tab + a "Crossings" view that shows only cross-wing connections.
3. **How many cross-wing nodes are too many?** If every fungi node has a plantae prereq, the game becomes a tour-checklist instead of a tree. Aim for **~30% of mid-tier-or-higher nodes** to have cross-wing prereqs. The rest stay wing-local.
