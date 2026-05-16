# Kingdom Definitions

See also: `NICHES.md` (playstyles within a kingdom) and `GAME_VISION.md` (how kingdoms fit into the larger structure).

## Plantae

### Identity
Surface-layer kingdom. Light-driven. Slow but compounding. Vulnerable to mobile threats.

### Core Resources
- Biomass (primary output)
- Sunlight (biome-driven multiplier)
- Nutrients (passive, from biome)
- Protein (only with Carnivore niche)

### Niches *(see NICHES.md)*
- **Photosynthesizer** *(current, default)*
- **Carnivore** — attracts and eats herbivores
- **Parasite** — colonizes on other plants
- **Pollinator-host** — synergizes with insect agents

### Active gameplay
- Toxin blooms (Photosynthesizer)
- Snare events (Carnivore)
- Spread to neighbor's biomass (Parasite)
- Insect bloom buffs (Pollinator)

### Identity statement
*"You stay where you are and turn light into more of yourself."*

---

## Fungi

### Identity
Subsurface-layer kingdom. Decay-driven. Spreads through networks. Quietly map-wide.

### Core Resources
- Decay (primary, from corpses + tick)
- Spores (colonize cost + infection)
- Lifeforce (only with Parasite niche)

### Niches *(see NICHES.md)*
- **Decomposer** *(current, default)*
- **Parasite** — colonizes on living organisms; cordyceps
- **Mycorrhizal** — pairs with plantae for shared yields

### Active gameplay
- Spore infection event (Decomposer)
- Host takeover progress bar (Parasite)
- Network shimmer when plantae yields boost (Mycorrhizal)

### Identity statement
*"You arrive after. You are what comes next."*

---

## Animals *(planned, Tier 1 phase 10 onward)*

### Identity
Mobile-layer kingdom. Range-based (not tile-based). Defined by what they eat.

### Core Resources
- Protein (primary)
- Lifeforce (predator niche)
- Pollination (pollinator niche, an agent class)

### Niches *(see NICHES.md)*
- **Herbivore** — consumes plant tiles
- **Predator** — hunts other animals
- **Scavenger** — consumes corpses
- **Pollinator** — passive agent; available as autonomous agent in plant runs before being playable

### Active gameplay
- Range expansion via passive movement
- Predator culling reduces ecological pressure on plant runs
- Migration events when biomes shift

### Identity statement
*"You move on your own now. Hunger is your direction."*

---

## Layered lifeforms *(replaces "Symbiosis as kingdom" — see `GAME_VISION.md`)*

In the MVP, symbiosis was treated as a third kingdom. **Post-MVP, symbiosis is the long progression axis of the game** — the player gradually unlocks the ability to play more and more lifeforms at the same time, with each tier giving access to richer interactions and harder specialized environments.

### Layer ladder

Layered lifeforms are **pre-authored curated species packs** — not free combinatorial assembly. Each pack has a fixed layer count and a fixed roster of species per layer (single species per layer at v1; later, species may be swappable within a layer).

| Tier | Layers | Species pack examples | Unlock |
|---|---|---|---|
| 1 | 1 | Pioneer Grass, Mycelium Thread, Herbivore | Default per kingdom unlock |
| 2 | 2 | **Lichen** (plantae × fungi), **Mycorrhizal Forest** (plantae × fungi at network scale) | `lichen_heritage` capstone (Phase 9 scaffolded) |
| 3 | 3 | **Coral** (animal × algae × symbiont), **Termite Mound** (animal × fungi × bacteria) | Tier-2 capstone (Phases 13–14) |
| 4+ | 4+ | Whole-ecosystem composites for specialized environments | Tier 3 (far horizon) |

### Implementation

- `SpeciesData` gains `layer_count: int` (1 = single, 2 = dual-layer, 3+ = stack), `layer_species: Array[SpeciesData]` (the per-layer roster — populated for layered species, empty for single-layer).
- A layered species like **Lichen** has `layer_count = 2`, `layer_species = [pioneer_grass, mycelium_thread]`, and its own `kingdom_id = &"plantae"` for indexing purposes.
- Run setup detects `layer_count > 1` and enters multi-layer placement mode automatically. The existing dual-layer placement engine (Phase 5–6) generalizes to N layers.
- The `&"symbiosis"` kingdom id is retired in Phase 10. Layered species are accessed via species selection inside their primary kingdom.

### Why pre-authored packs (not free combination)

Treating each layered lifeform as a curated tuple lets each pack have:
- Its own colonization rules (Coral cannot grow on dry rock; Lichen can).
- Its own resource economy (Lichen barely needs nutrients; Coral generates and consumes calcium).
- Its own discovery entry (the voice text in `STORY_AND_TONE.md` framing).
- Its own art and tile variant.

A combinatorial system would force a generic "merged" identity again, which is the problem we're solving by retiring symbiosis-as-kingdom.

### Future packs (sketched, not committed)

- **Lichen** (plantae × fungi) — Phase 10. Existing dual-layer experience, reframed.
- **Mycorrhizal Forest** (plantae × fungi at network scale) — Phase 10–11. Granted by `photosynthetic_network` (already in tree).
- **Coral** (animal × algae × symbiont) — Phase 13–14. Requires animal kingdom + algae as a microbial-like sub-species.
- **Termite Mound** (animal × fungi × bacteria) — Phase 14+. 3-layer model demo.
- **Endosymbiont** (any × microbial) — only if scale ascension ever happens.

### Identity statement

For tier-2 packs: *"You are two. The boundary between you is a fiction the world tolerates."*

For tier-3+ packs: *"You are an arrangement. The world does not recognize you as one thing because you are not one thing — and you are nevertheless succeeding."*
