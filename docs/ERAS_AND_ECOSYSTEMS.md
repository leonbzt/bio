# Eras and Ecosystems

## Purpose
Eras are the **macro time-axis** of the game. Within each era, **ecosystems** are individual challenges with different baseline conditions. Both must be completed to advance. This adds a "route" layer above the run loop — you're not just playing runs, you're choosing which ecosystem to tackle next and how to attack it.

## Era progression

The player starts in the **Cryogenian** (or equivalent early era) with the fewest options. Advancing eras unlocks:
- New kingdoms (animals don't exist until the Cambrian-equivalent era).
- New niches (carnivory unlocks alongside herbivory).
- New biomes (tundra, swamp, jungle as the world warms).
- New ecological events (mass extinctions, atmospheric shifts).
- New evolution tree nodes.

Era examples (final list TBD):

| Era | Available kingdoms | New mechanics introduced |
|---|---|---|
| **Cryogenian** | Fungi only (extremophiles) | Bare grid; cold biomes; resource scarcity |
| **Devonian** | Plantae, Fungi | First plants; full current MVP mechanics |
| **Carboniferous** | Plantae, Fungi | High decay rates; spore infection common; mass extinction events |
| **Mesozoic** | Plantae, Fungi, Animals (herbivore/predator) | Animal kingdom debuts |
| **Cenozoic** | All kingdoms, all niches | Climate volatility; invasive species |
| **Anthropocene** | All + civilization layer (much later) | Reserved for far horizon |

## Ecosystems within an era

Each era contains **3–5 ecosystems** that must all be completed. An ecosystem is a small "scenario" with:
- A specific biome composition (the grid is seeded differently).
- Specific challenges (events, herbivore types, environmental pressures).
- A clear completion condition (e.g., "sustain a population for 500 ticks", "defeat the apex pressure", "establish symbiosis").

The player chooses:
- **Which ecosystem to attempt next** (any unlocked, in any order within the era).
- **How to attempt it** (kingdom × niche × species combination they think will work).

Example Devonian era ecosystems:
- **Tidal Pool**: heavily aquatic. Plants struggle; fungi adapted to salinity dominate.
- **Bare Mineral Plain**: no organic substrate. Pioneer plants and decomposer fungi only.
- **Sheltered Valley**: rich biome variety. Best for testing symbiotic species combos.

Completion criteria are *niche-flexible*: "establish 30+ owned tiles AND survive 3 ecological events" can be hit by photosynthetic plants, parasitic fungi, or a symbiotic Lichen run. Player chooses the path.

Once all era ecosystems are completed, an era-transition event fires (mass extinction, climate shift, era-end discovery) and the next era unlocks.

## How ecosystems map to existing systems

- The current 32×48 grid stays.
- Ecosystem = an `EcosystemData` resource with: biome distribution weights, starting events, completion conditions, era it belongs to.
- `NutrientSystem`'s `_generate_biome_map` already accepts a `run_seed`; it just needs to use the ecosystem's biome weights instead of uniform random.
- A new `EcosystemTracker` system watches the run for completion criteria and emits `ecosystem_completed(ecosystem_id)`.
- Meta-save tracks `meta.ecosystems_completed: Array[StringName]`; era advancement is a derived check.

## Cross-era persistence (lightweight succession)

Within a single world (we start with one), some state survives across runs:
- **World memory**: `meta.world_memory` dict tracking cumulative cross-run state (total decomposed corpses, extinct species, symbiosis breakthroughs).
- **Visited ecosystems**: which ones you've completed and with which strategies.
- **Era progress**: cleared eras remain cleared even if you return for completion-rate achievements.

This delivers "your past lives shape this one" without simulating full ecological succession.

## UI flow

```
[Main map: era + ecosystem select]
  Current Era: Devonian
  Ecosystems:
    ✓ Tidal Pool                 (cleared as Decomposer Fungi)
    ⚠ Bare Mineral Plain         (in progress, last attempt failed at tick 400)
    ⊙ Sheltered Valley           (untouched)

[Tap an ecosystem → run setup]
  Choose kingdom: Plantae / Fungi / [Lichen symbiotic]
  Choose niche: Photosynthesizer / Carnivore
  Choose species: Pioneer Grass / Bramble
  Begin

[Era transition (all 5 cleared)]
  "The atmosphere thickens. Oxygen accumulates. Something is changing.
   The Carboniferous opens before you."
  Unlocks: 1 new evolution node, herbivore precursor agents, swamp biome.
```

## Open design questions

1. **Can you replay completed ecosystems?** Yes for variety / better-score; doesn't grant additional EP (anti-grind).
2. **Era retreat?** Probably no — once advanced, you stay there. But the player can attempt later-era ecosystems with earlier-era kingdoms for challenge-runs.
3. **How long is one era's play time?** Target: 4–8 hours of active play per era. Five eras = 20–40 hours to MVP-final-content. Reasonable for a portfolio/indie game.
4. **Era-specific evolution nodes?** Yes — some nodes are tied to era unlocks (e.g., the predator-awakening node only appears once you reach the Mesozoic equivalent).
