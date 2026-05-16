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

## How symbiosis works (reframed)

**Symbiosis is not a kingdom.** It's an emergent property that arises when certain species from different kingdoms occupy the same tile.

Mechanically: some species are **symbiotic** — they carry a `partner_kingdom` and `partner_species` reference. Picking a symbiotic species at run start enters a dual-layer play mode where both kingdoms can be placed. The bonus yield applies only when the two specific partners occupy the same tile.

Future symbiotic pairs we might add:
- **Lichen** (plantae × fungi) — the existing symbiosis, reframed as a species pair.
- **Coral** (animals × algae) — once the animal kingdom lands.
- **Mycorrhizal forest** (plantae × fungi at network scale) — a more advanced symbiosis.

The point: symbiosis becomes *something you unlock and assemble* rather than *a third kingdom*. More flavors. Cleaner conceptually.

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
- **Event flavor text**: each ecological event carries 1–3 sentences of voice.
- **Discovery log**: every prestige, niche unlock, kingdom unlock, and rare event milestone adds a short entry to a browsable log.
- **Discoveries: 12/57** counter pulls players who care about lore.

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

## Deferred / aspirational

The following ideas are flagged as worth pursuing IF the game proves itself, but are not on the near-term roadmap:

- **Scale ascension**: viruses → cells → organisms → populations → ecosystems → planets → civilizations. Each scale would be effectively a different game mode. The current game is the "ecosystem" tier. Reference future scales in discovery-log text now; build them only post-Tier-2 success.
- **Multiple worlds**: alien planets with non-Earth chemistry. Start with one world across eras; add other worlds only when the era system is mature.
- **Sentient kingdom**: technosphere, civilizations as a player role. Far horizon.
- **Cloud sync / multiplayer**: no plans.

## Audience and ambition

Between a polished portfolio piece and a serious indie release. Targeting **Android first** (Play Console internal beta → public). Mobile-first. 30-minute focused sessions PLUS 2-minute check-ins. Free with optional cosmetics, OR paid one-time — decide closer to release.

Solo developer with multi-model AI workflow (see `HANDOFF_GUIDE.md`).
