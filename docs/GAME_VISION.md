# Game Vision

> **An idle/roguelike where you play life itself across kingdoms, niches, and eras — each run unlocks the next role you can inhabit, and the choices you made as plants come back to shape your run as fungi.**

## What this game is

A mobile life-based idle/incremental game with RPG and roguelike features. You don't play a character; you play **life as a category**. Each run is a new attempt at colonizing a world as some niche of some kingdom — a photosynthetic plant, a parasitic fungus, a herbivorous animal, eventually a sentient species. You prestige out of runs to bank meta-progress, then re-enter as a different role in the same or different world.

What makes it different from other idle/roguelikes:
1. **Ecology is the magic system.** Magic is biological, not arcane. Mechanics are grounded in real biology, then stylized.
2. **Niches are the playstyles.** Not "warrior / mage / rogue" but "decomposer / predator / pollinator / parasite / colony organism / symbiotic hybrid".
3. **The web of life is the meta progression.** Your evolution tree isn't per-kingdom; it's interconnected. Mastering a fungi run unlocks plant abilities. Mastering a predator unlocks new prey niches.
4. **The world remembers.** Across runs in the same world, the substrate carries traces of past life — decomposed corpses, fossilized networks, extinct species.

## The three axes of complexity

Each run sits at the intersection of three orthogonal choices:

| Axis | Determines | Count | Choice frequency |
|---|---|---|---|
| **Kingdom** | Macro playstyle: which resources, which layer of the world | 4–6 lifetime: plantae, fungi, animals, … | Pick at start of run |
| **Niche** | Role within that kingdom: photosynthesizer vs carnivore vs parasite | 3–4 per kingdom | Pick at start, after kingdom |
| **Species** | Specific stat / trait template within a niche | 2–3 per niche | Pick at start, can evolve during run |

This is the source of replay variety. 5 kingdoms × 3 niches × 2 species = 30 distinct run configurations.

## How symbiosis works — layered-lifeform progression

**Symbiosis is not a kingdom. It is the long progression axis of the game.**

Most idle/roguelikes have one progression dimension (numbers go up, or new content unlocks). This game has a *third* dimension that compounds with the others: **the number of lifeforms you can play simultaneously**. You start as a single-kingdom organism. By late-game you are playing a three- or four-layer composite organism, where each layer pulls from a different kingdom and their interaction is the gameplay.

### The layer ladder

| Tier | Layer count | Examples | Unlock gate |
|---|---|---|---|
| 1 | **Single** | Photosynthesizer plantae, Decomposer fungi | Default |
| 2 | **Dual** (symbiotic pair) | Lichen (plantae × fungi), Mycorrhizal partnership | `lichen_heritage` capstone node |
| 3 | **Triple** | Coral (animal × algae × symbiont), Termite mound (animal × fungi × bacteria) | Tier-2 capstone in Tier 2 of roadmap |
| 4+ | **Stack** | Whole-ecosystem composites that solve specialized environments | Tier 3, far horizon |

### How layers are picked

Species packs are **pre-authored curated tuples**, not free combinatorial assembly. *Lichen* always means plantae × fungi with specific partner species. *Coral* always means animal × algae × symbiont. This keeps each layered lifeform readable, distinct, and individually flavored — Coral is not just "another 3-layer pack," it has its own colonization rules and its own discovery entry.

Players unlock a layered species via an evolution-tree node and gain the whole stack at once. Future systems may allow swapping species within a layer of a pack, but the layer count itself is fixed per species.

### Why layered lifeforms is *the* progression axis

- **It substantiates "you play life itself."** A single organism feels like a character; a layered organism feels like an *arrangement* — closer to what life actually is.
- **It compounds with niches and the web.** A 3-layer Coral run is mechanically different from any single-kingdom run, *and* different from any 2-layer Lichen run.
- **It gives specialized environments a real solution.** Late-game ecosystems can require specific layer stacks ("this is a coral reef; only an animal × algae × symbiont stack will thrive here"), which gives the ecosystem selector real bite without locking out player choice elsewhere.
- **It absorbs cross-kingdom strategy.** The web-of-life evolution tree feeds into which layered species you can unlock; the layers determine which niches matter on which runs.

## The web of life — interconnected meta progression

The evolution tree is a **directed graph across kingdoms**, not a per-kingdom unlock list.

Example chain:
1. Play a **Carnivore plantae** run → discover the protein resource.
2. Buy *Insectivory* in the plantae wing → +30% yield from prey.
3. *Insectivory* is a prerequisite for *Cordyceps Mastery* in the **fungi** wing.
4. *Cordyceps Mastery* unlocks a **Parasite niche** for fungi.
5. Playing fungi parasitically generates lifeforce that unlocks **Predator** niches for animals.

Each kingdom advances the others. Total progression unfolds over dozens of runs across all kingdoms.

## Story through events and discoveries

The game has no dialogue or characters. Story emerges through:
- **Event flavor text**: each ecological event carries 1–3 sentences of voice. Events span four scopes — world (drought, climate shift), kingdom (oxygenation event for plantae), niche (host immune response for parasites), species (specific to a pack like Lichen's "the alga starves first"). Each scope has its own event pool; an active run rolls from the union of pools its scopes belong to.
- **Discovery log**: every prestige, niche unlock, kingdom unlock, and rare event milestone adds a short entry to a browsable log.
- **Discoveries: 12/57** counter pulls players who care about lore.
- **Generations counter**: the title screen shows total prestiges as a single number with an evolving descriptor that changes by threshold — "Pioneers" (1–5) → "Settled Colonies" (6–20) → "Networked Life" (21–100) → "The Anthropocene Watches" (101+). Cheap to implement; sells the long-arc identity.

Tone: **mythic + scientific**. Like Carl Sagan writing for poets. Grounded in real biology, but observed at a scale and through a voice that makes it feel weighty.

```
After first prestige:
  "The biomass cycles back. The substrate remembers everything you grew.
   In this world, death is just a different shape of life."

After unlocking fungi:
  "The decomposers were already here, waiting.
   They wait for everything."

After Carnivore plantae run:
  "Some plants learned to eat. The line was never as solid as you thought."
```

## World structure: eras, ecosystems, future planets

**One world to start, advancing across geological eras.** Each era opens new kingdoms, species, and challenges.

Era examples:
- **Cryogenian** → only microbial life, fungi limited to extremophiles, no plants yet.
- **Devonian** → first plants, first fungi, no animals on land.
- **Carboniferous** → giant ferns, abundant decomposers, atmospheric oxygen shifts.
- **Mesozoic** → giant reptilian herbivores, predators, gymnosperms.
- **Anthropocene** → climate volatility, invasive species, every kingdom available.
- **Speculative / alien** → eventually, parallel worlds with non-Earth biospheres.

Within each era, **multiple ecosystems** to complete (shallow sea, exposed rock, swamp, etc.). Player picks **which ecosystem to tackle next** and **how to tackle it** (which kingdom × niche × species combination). All ecosystems in an era must be completed before advancing to the next era — but the order and strategy are the player's.

This gives the run loop a **route layer** above the run itself: not just "play another run" but "I need to clear the Devonian's tidal-pool ecosystem; let me try it as parasitic fungi this time."

## Emergent structures (parked design)

Tiles can combine into larger multi-cell **structures** when the player places specific patterns. A 2×2 fungi cluster with a plantae center becomes a Mycorrhizal Hub. Three plantae tiles in a vertical line become an Old-Growth Tree. Animal tiles in the right shape become a Termite Mound. The structure replaces the underlying tiles visually and acts as a single entity for yield, status, and events. This makes the tilemap *visibly transform* as gameplay progresses rather than staying a flat owner-grid.

See `docs/STRUCTURES.md` for the full design sketch. Not phased yet; revisit alongside layered-lifeform packs and the ecosystem system.

## Deferred / aspirational

The following ideas are flagged as worth pursuing IF the game proves itself, but are not on the near-term roadmap:

- **Scale ascension**: viruses → cells → organisms → populations → ecosystems → planets → civilizations. Each scale would be effectively a different game mode. The current game is the "ecosystem" tier. Reference future scales in discovery-log text now; build them only post-Tier-2 success.
- **Multiple worlds**: alien planets with non-Earth chemistry. Start with one world across eras; add other worlds only when the era system is mature.
- **Sentient kingdom**: technosphere, civilizations as a player role. Far horizon.
- **Cloud sync / multiplayer**: no plans.

## Audience and ambition

Between a polished portfolio piece and a serious indie release. Targeting **Android first** (Play Console internal beta → public). Mobile-first. 30-minute focused sessions PLUS 2-minute check-ins. Free with optional cosmetics, OR paid one-time — decide closer to release.

Solo developer with multi-model AI workflow (see `HANDOFF_GUIDE.md`).
