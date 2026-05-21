# Bio — itch.io page copy

Copy/paste these into the matching fields on the itch.io project page.

---

## Short description (one-liner)

A pocket-sized incremental about evolving life — place species, form structures, prestige across eras.

---

## Full description (main body)

**Bio** is a portrait-mobile incremental about growing an ecosystem from a single tile out. Pick a starting species, tap to colonize a biome, and let resources accumulate. Place more species across plant / fungi / lichen niches to form clusters and unlock structures. When you hit your run goal, prestige to convert the work into Evolution Points and start a new generation with permanent upgrades.

This is an early **alpha** — the core loop runs end-to-end, but content is still thin and balance is rough. I'm posting it for feedback on feel, pacing, and clarity. Bugs and rough edges expected.

### Why this exists

Most incrementals reward bigger numbers; **Bio** rewards arrangement. Where you place a species matters as much as how many you have — biomes have affinities, neighbors form structures, and clusters generate the floating income that drives the loop.

### What's in alpha

- 3 kingdoms (plantae, fungi, lichen) and ~15 species across the early eras
- Per-tile structure discovery (find the patterns; the Field Guide remembers them)
- Three currency layers: resources → adaptation → evolution points
- Fog of war, rock obstacles, era-gated content
- One-tap onboarding the first time you play

### What's coming

- Animal kingdom (predators / herbivores / decomposers as placeable actors)
- Carboniferous era and beyond
- Visual overhaul (dither textures, sprite art)

### Known issues

- Late game can hitch on slower machines — perf pass is in progress
- Some Unicode glyphs may render as boxes depending on your browser's font fallback
- Saves are stored in browser local storage; clearing site data will reset progress

If anything feels off — confusing onboarding, pacing dead spots, layout breaking on your screen — please open an issue or comment. That's the whole point of the alpha.

---

## How to play (guide section)

### The core loop

1. **Tap a tile** to colonize it with your current species. Resources start ticking up.
2. **Pick a species** from the buttons at the bottom of the screen. Tap once to select; tap again on an already-selected species to evolve it (costs Adaptation).
3. **Open the Avail toggle** to introduce a new species from your unlocked roster.
4. **Form structures** by arranging tiles into specific patterns (rings, blocks, kingdom-adjacent shapes). Each discovered structure shows up in the Field Guide.
5. **Hit the run goal** shown in the left panel. When it's met, tap Menu → Prestige to convert your run into Evolution Points.
6. **Spend EP** in the evolution tree to unlock permanent buffs and new species for future runs.

### Reading the HUD

- **Left column**: live resources (Biomass, Nutrients, Sunlight, Decay, Spores, and unlockables). Below that: your adaptation pool, the biomes present on the current map, and your run goal.
- **Bottom strip**: species selection. Tap to pick a placement target; long-press or tap-active-again to evolve.
- **Top-right Guide button**: the Field Guide — three tabs (Species / Structures / Biomes). Structures appear as `???` silhouettes until you discover them.
- **Top-right pause button**: settings, prestige, save management.

### Tips

- Biomes have **affinities** — a species placed on its preferred biome yields more. Hover/tap a tile to see biome info, or check the Biomes tab of the Field Guide.
- **Clusters of the same species** drift a floating income label every few seconds. Bigger clusters = bigger floats.
- **Tile maturation**: tiles age into Sprouting → Mature → Ancient stages over time and pay better as they get older. Don't churn through them.
- **Don't prestige too early** — the EP curve favors longer runs, but a stuck run is worth converting and resetting.
- **The Field Guide** is your reference for structure patterns. Once you've formed one in a run, the formula stays unlocked across runs.

### Controls

- **Tap** — colonize tile / select species / press button
- **Tap-active species** or **right-click** — open evolve modal
- **Tap outside a modal** — close it
- The game is portrait-only; rotate your phone or resize the browser window vertically for the intended layout.

---

## Tags (suggested)

`incremental`, `idle`, `biology`, `ecology`, `pixel-art`, `mobile-friendly`, `portrait`, `tile-based`, `prestige`, `alpha`
