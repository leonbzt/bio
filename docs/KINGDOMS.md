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

## Symbiosis *(not a kingdom — see below)*

In the MVP, symbiosis was treated as a third kingdom. **Post-MVP, this is reframed.**

Symbiosis is now an **emergent property of paired species** rather than a separate playable kingdom. Specific species in different kingdoms can be designated as **symbiotic partners**. Choosing a symbiotic species at run start enters a dual-layer play mode where both partner kingdoms are placeable.

The existing dual-layer placement engine (Phase 5–6) is retained — it just gets reframed in UI and content.

### Implementation
- `SpeciesData` gains `symbiotic_partner_kingdom: StringName` and `symbiotic_partner_species: StringName` fields.
- A symbiotic species like **Lichen** has `kingdom_id = &"plantae"`, `symbiotic_partner_kingdom = &"fungi"`, `symbiotic_partner_species = &"mycelium_thread"`.
- Run setup detects symbiotic species and enters dual-layer mode automatically.
- The `&"symbiosis"` kingdom id stays as an internal mode tag (the engine already routes on it); but it disappears from the player-facing kingdom-selection UI.

### Future symbiotic species
- **Lichen** (plantae × fungi) — the existing dual-layer experience, reframed.
- **Coral** (animals × algae) — when animal kingdom lands.
- **Mycorrhizal forest** (plantae × fungi at scale) — a tier-3 species, granted by capstone evolution node.
- **Endosymbiont** (any × microbial) — only relevant if scale ascension ever happens.

### Why reframe
Treating symbiosis as a kingdom forces a *generic* "merged" identity. Treating it as paired species lets each pair have its own flavor — lichen is not coral is not mycorrhizal forest. More variety, less abstract.

### Identity statement (for any symbiotic species)
*"You are two. The boundary between you is a fiction the world tolerates."*
