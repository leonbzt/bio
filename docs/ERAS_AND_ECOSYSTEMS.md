# Eras and Ecosystems

> **For alpha-scope starter content (eras, biomes, maps, species, interactions), see `docs/ALPHA_LOCK.md`.** This doc covers the general architecture — how eras and ecosystems work as systems — independent of the specific content shipping in alpha.

## Purpose
Eras are the **macro time-axis** of the game. Within each era, **ecosystems** are individual challenges with different baseline conditions. Both must be completed to advance. This adds a "route" layer above the run loop — you're not just playing runs, you're choosing which ecosystem to tackle next and how to attack it.

## Era progression

The player starts in one of the **two alpha-locked starter eras** (Carboniferous or Pleistocene; see `ALPHA_LOCK.md`). Advancing eras unlocks:
- New biomes (era-signature biomes carry the era's visual identity).
- New species (some carry over via `lineage_id`, some are era-locked).
- New ecological events (mass extinctions, atmospheric shifts).
- New evolution tree nodes (era-gated nodes).

### Alpha-locked era pair

| Era | Player-facing name | Available kingdoms | Signature biome |
|---|---|---|---|
| **Carboniferous** | Coal Forests | Plants, Fungi, Animals (Meganeura, Arthropleura) | `lush_canopy` |
| **Pleistocene** | Ice Age | Plants, Fungi, Animals (Mammoth, Saber-Tooth) | `tundra` |

Both share `wetland` and `open_ground` as cross-era biomes (era-specific visual variants).

### Aspirational era pipeline (post-alpha)

Directional only — not in alpha scope:

| Era | Notes |
|---|---|
| **Cryogenian** | Deferred "deep time" unlock; microbial-only with fungi extremophiles. |
| **Devonian** | Bridge era; species absorbed into Carboniferous where biologically appropriate. |
| **Mesozoic / Cretaceous** | Dinosaurs as charismatic megafauna; gymnosperms + early angiosperms. |
| **Cenozoic** | Climate volatility, invasive species. |
| **Anthropocene** | Reserved for far horizon. |

## Ecosystems within an era

Each era contains **3 ecosystems** in alpha (was 3–5; tightened for alpha simplicity). An ecosystem is a small "scenario" with:
- A specific biome composition (the grid is seeded differently).
- Specific challenges (events, animal pressures, environmental pressures).
- A clear completion condition (e.g., "fill the coal gauge to 50", "establish a self-sustaining steppe with mammoth grazing").

The player chooses:
- **Which ecosystem to attempt next** (any unlocked, in any order within the era).
- **How to attempt it** (which species composition they think will work).

### Alpha ecosystems

**Carboniferous (Coal Forests)**:
- **Coal Swamp** *(first ship)* — `wetland` + `open_ground`. Drowned forest; biomass piles into coal.
- **Fern Glade** — `open_ground` dominant + `lush_canopy` edges. Dappled understory between fires.
- **Riverside Cathedral** — `lush_canopy` + `wetland`. The mature climax forest.

**Pleistocene (Ice Age)**:
- **Glacier's Edge** — `open_ground` (scree) + sparse `tundra`. Pioneer life on retreating ice.
- **Mammoth Steppe** — `tundra` dominant + `open_ground`. Lost grassland, mammoth-engineered.
- **Taiga Border** — `wetland` (peat) + `tundra`. Where forest creeps north.

Completion criteria are **species-flexible**: each ecosystem has a target gauge or condition that can be hit with different valid species combinations. The Coal Swamp coal gauge fills from any plant dying on `wetland`, so the player can use any plant they have access to.

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
  Current Era: Coal Forests (Carboniferous)
  Ecosystems:
    ✓ Coal Swamp                 (cleared with Calamites + Mycorrhizal Network)
    ⚠ Fern Glade                 (in progress, last attempt failed at tick 400)
    ⊙ Riverside Cathedral        (untouched)

[Tap an ecosystem → run setup]
  Choose starting species: Calamites / Tree Fern / Mycorrhizal Network
  Begin

[Era transition (all 3 cleared)]
  "The forests fall. The world cools. Ice creeps south.
   The Ice Age opens before you."
  Unlocks: Pleistocene era, tundra biome, megafauna species pool.
```

## Open design questions

1. **Can you replay completed ecosystems?** Yes for variety / better-score; doesn't grant additional EP (anti-grind).
2. **Era retreat?** Probably no — once advanced, you stay there. But the player can attempt later-era ecosystems with earlier-era species for challenge-runs.
3. **How long is one era's play time?** Target with alpha's 3 maps per era: ~1–2 hours of active play per era for completion; replay value extends this.
4. **Era-specific evolution nodes?** Yes — some nodes are tied to era unlocks (e.g., apex predation tutorial only triggers in Pleistocene where Saber-Tooth lives).
