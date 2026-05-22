# Visual Direction — Bio

Locked 2026-05-21. Source: synthesis of `builds/screenshots/map.png` (atmosphere) and `builds/screenshots/final.png` (per-tile vocabulary + structures), plus the constraint that zoom + drag are already in place so on-screen tile count is decoupled from simulation grid.

This doc is the canonical brief to feed image AIs (Midjourney, ChatGPT/Sora image, Nano Banana, etc.) when generating sprites, tile art, structure art, or full-world mockups. See **How to prompt** at the bottom.

---

## The pitch (one paragraph)

A portrait-mobile incremental where you play **life itself** colonizing a tile world. The grid is a living habitat — moody, naturalist, dither-textured — not a chessboard. Every tile says something specific (what kingdom, what species, what biome, how old), and when tiles arrange into the right pattern, they **stop being individual tiles and visually fuse into a single structure** (a fairy ring becomes a *ring*, not 5 mushrooms with a circle drawn around them).

Tone: mythic-scientific. Carl Sagan, Annie Dillard. Not cute, not grimdark, not fantasy.

---

## Two takeaways (the synthesis)

1. **Atmosphere — from `map.png`.** Dither textures, low-key naturalist palette, soft ambient glow per kingdom, the world feels like a *habitat* viewed from above. The play surface is moody and inviting, not loud or arcadey.

2. **Readability — from `final.png`.** Each species reads as a recognizable silhouette (a mushroom IS a mushroom, a grass IS a tuft, a grazer IS a creature shape). Maturation stages are clearly different. Biome textures have personality (frost crystals on tundra, mineral flecks on vents, peat-mat on swamp).

Both at once: paint final.png's silhouettes *on top of* map.png's substrate.

---

## Tile rendering spec

**This section is superseded by the 2026-05-22 "Locked long-term canvas" below. Use that as the source of truth for tile size, species rendering, and layer order.** Summary of the current spec:

- **48 px tile, 48 px cluster sprite** (filling the tile)
- **Cluster-in-biome rendering** — biome substrate always visible, species appear as a few small organisms within
- **Single species per tile**, symbiosis as adjacency interaction (corner dots + edge highlight)
- **Ecological-stage clustering** — cluster density scales with same-kingdom neighbor count

---

## Structures as **fused meta-tiles** — the big idea

When the structure detector matches a pattern, the constituent tiles **stop rendering as individual tiles** and instead render as **one continuous structure object spanning the matched footprint**. The structure is the visual subject; the underlying tiles become its substrate.

### Three ways this can be achieved (pick per structure)

1. **Composite sprite (manual)** — author a multi-tile PNG for each structure (e.g., a 3×3 fairy ring sprite at 96×96 native). On promotion, hide the individual tile fills and stamp the composite. Cleanest but every structure needs custom art.

2. **Procedural overlay (programmatic)** — keep tile fills, but draw a structure-specific overlay on top via a `_draw()` call. Fairy ring = ring-shaped gradient; Old-Growth Stand = tall trunk silhouettes rising above the tile grid into the row above; Mycorrhizal Hub = root-web lines connecting tile centers.

3. **Shader fusion** — write a shader that reads the active-structure map and blends tile borders out, replacing them with one continuous biome-aware texture. Most flexible, hardest to author.

### What "fusion" should look like per structure (visual brief)

- **Fairy Ring** — 5 fungi tiles in a ring. Fused appearance: a faint circular ridge of mycelium arching across the 5 tiles with bare/darker center earth. Tile borders should be invisible inside the ring; the *ring* is the subject.
- **Old-Growth Stand** — 3×3 same-species plantae block. Fused appearance: 3–4 tall ancient trunk silhouettes rising *above* the 3×3 footprint (into the row above the block), with thick canopy shadow over the 9 tiles. Tile borders dissolve under the canopy.
- **Mycorrhizal Hub** — fungi center + plant neighbors. Fused appearance: visible root-web radiating from the central tile into adjacent plant tiles, glowing faintly. Individual tiles still visible but threaded together.
- **Decay Pit** — fungi cluster on rich-soil biome. Fused appearance: a depression in the substrate, dark stain, fungal fruiting bodies clustered at the rim. Tile grid fades into a continuous pit shape.

---

## Maturation visualization (steal from `final.png`)

Three stages with **distinct silhouettes**, not just color/alpha tweaks:

- **Sprouting** — small, tentative silhouette taking ~30% of tile inner area. Reads as "just placed."
- **Mature** — full silhouette filling the tile. Default state.
- **Ancient** — larger silhouette overflowing the tile slightly, with subtle accent (a glow rim, a tendril, a deeper saturated core). Reads as "settled, weighty."

---

## Per-kingdom silhouette vocabulary

- **Plantae** — vertical, tufted, branching. Grasses (low tufts), Brambles (thorny), Tree-ferns (tall fronds), Vines (creeping). Greens and yellow-greens.
- **Fungi** — round caps on stems, mottled, mycelial. Mycelium Thread (sprawl-mat), Wood-rot Bracket (shelf shapes), Cryo-Lichen (crusty patches). Violets, mauves, dusty pinks.
- **Animals** — creature silhouettes with hint of motion. Grazers (round-bellied browsers), Predators (lower, sharper outline), Scavengers (small, scattered). Bronzes, ambers, warm earth tones.
- **Hybrid / Symbiotic** — composite forms that read as "both at once." Lichen = crusty patch with embedded green dots. Coral = layered branching. Teal/turquoise accent.

---

## Anti-patterns — what to avoid

- Anthropomorphic faces, mascots, cute creatures with eyes
- Fantasy magic (glowing runes, arcane circles, "mystic ancient primordial" filler)
- Body-horror decay — decay should feel **patient**, not gross
- High-contrast neon or saturated brights — palette stays moody and naturalist
- Generic incremental-game UI candy (exclamation badges, celebration confetti, chunky cartoon buttons)
- Per-tile detail that competes with the species silhouette (no fancy footprints, no debris-on-every-tile)

---

## How to prompt an image AI

**Send three things every time:**

1. **The relevant section of this doc** (don't paste the whole thing — pick the section that matches your subject).
2. **`builds/screenshots/map.png`** as a style reference for *atmosphere*.
3. **`builds/screenshots/final.png`** as a style reference for *silhouette specificity + structure visualization*.

**Frame your subject in terms of game verbs**, not just nouns:

> "Pixel-art top-down tile, 32×32 px native, showing a **sprouting Pioneer Grass** on a **rich-soil biome**. Plantae palette (warm forest green on dark earth). Dither texture substrate, 3-px biome frame, tentative silhouette taking ~30% of the inner tile area. Reference style: attached map.png for atmosphere, final.png for silhouette readability. No anthropomorphism, no fantasy glow."

**For structures, prompt the fused appearance, not the tile grid:**

> "Pixel-art top-down view of a **Fairy Ring structure** spanning a 3×3 tile area at 32-px-per-tile native (96×96 total). The 5 fungi tiles in a ring formation **fuse into one continuous ring of mycelium**, tile borders invisible inside the ring, bare earth at center. Fungi palette violet on dark substrate. Reference: final.png structure section."

**For full-world mockups:**

> "Portrait-mobile (360×640) top-down view of a colonized tile world, 14×24 tiles visible (at 32-px tile size with the rest off-screen via zoom/drag). Mix of plantae clusters, fungi sprawl, and 2 visible structures (one Fairy Ring, one Old-Growth Stand) rendered as fused meta-tiles. Era tint: Cryogenian cool ice-blue wash. Reference: map.png for atmosphere, final.png for structure visualization."

---

## Locked long-term canvas (2026-05-22 — current lock)

Supersedes the 2026-05-21 lock (96 px tile + 32 px focal sprite + multi-occupant symbiosis). The prior lock is preserved as historical context below. Reason for change: strategy-game density goals, AI-gen budget, simpler symbiosis model, and biome-continuity all pointed toward smaller tiles with one species per tile rendered as a cluster of organisms in biome.

### Visual model: cluster-in-biome with ecological stages

Each species tile renders as **a few small organisms scattered within the biome** — not a single silhouette filling the tile, and not a small focal icon on top. The biome substrate is always visible *around and between* the organisms. The tile boundary is rendered as a subtle 1-2 px darker biome-shade line for grid clarity without hard edges.

**"Growing together" emerges from clustering, not from auto-tile geometry.** As more same-kingdom tiles are placed adjacent, each tile's cluster density steps up — isolated tiles show a sparse pioneer cluster; tiles surrounded by same-kingdom neighbors show dense established groves. Players see their placement decisions develop the world visually.

### Canvas constants

| Layer | Native size | Notes |
|---|---|---|
| **Tile** | **48 × 48 px** | Grid is 32×48 cells, total world 1536 × 2304 px |
| **Species cluster sprite** | **48 × 48 px** (= tile) | 4 density variants per kingdom: pioneer / establishing / established / mature. White-on-transparent, code-tinted by species color. Sprite contents are sparse organisms with biome showing through gaps. |
| **Tile-edge tint** | 1-2 px on tile boundary | Procedural, slightly darker biome shade. Grid clarity without hard borders. |
| **Animal marker** | 16 × 16 px procedural | Inset diamond at tile center for now. Per-species sprites deferred. |
| **Symbiosis marker** | Corner dot + edge highlight | 4×4 px gold dot in tile corner facing each adjacent partner; tile-edge line tinted gold on the shared boundary. Procedural. |
| **Hybrid-pair fusion sprite** (Lichen, Coral) | Special render for adjacency-pair tiles | Both tiles in a true-cohabitation pair render with a hybrid sprite variant. Triggered only for designated hybrid species pairs. |
| **Structure composite** | 48 × tile-count | Fairy Ring 144² (3×3), Old-Growth 144×192 (3×3 with vertical overflow), Mycorrhizal Hub 240² (5-tile cross), Decay Pit 96² (2×2) |
| **Biome substrate** | 48 × 48 px per biome | Procedural now; commissioned PNGs later drop into same slot |
| **Resource icon** | 16 × 16 (chip), 32 × 32 (tooltip) | HUD only, unchanged |
| **Maturation accent** | procedural (1 px rim, ancient stage) | Code-drawn, no asset |

### Single species per tile

Each tile holds at most ONE species occupant. Symbiosis (mycorrhiza, pollination, lichen-style cohabitation) is a relationship between *adjacent* tiles, not stacking within one tile. This:
- Makes spatial planning the core strategic loop ("which tile holds what, who's next to whom")
- Prevents the "put everything everywhere" failure mode of multi-occupancy
- Eliminates visual stacking ambiguity at small tile sizes
- Maps better to real ecology (habitats are spatially differentiated)
- Allows true-cohabitant species (Lichen, Coral) to render a fused hybrid sprite across the adjacency pair as a special case, preserving their thematic charm

### Ecological-stage clustering

Cluster density per tile scales with the count of same-kingdom 4-neighbors. The variant rendered on a given tile is determined by neighbor count at render time:

| Same-kingdom 4-neighbors | Stage | Visual character |
|---|---|---|
| 0 (isolated) | Pioneer | 1-2 small organisms, lots of biome visible. "Just placed." |
| 1-2 | Establishing | 3-4 organisms, moderate cover. "Taking hold." |
| 3-4 (clustered) | Established | 5-6 organisms, dense cluster. "Settled colony." |
| All 4 neighbors same | Mature | Larger-scale feature in tile (small grove pattern, herd, field). "Defining feature of the area." |

Players see their placement decisions develop the world. No 16-variant auto-tile geometry required — only 4 density variants per kingdom.

### Layer order in a single tile (z, low to high)

1. Biome substrate (full tile, Sprite2D)
2. Tile-edge tint (1-2 px boundary, procedural)
3. Species cluster sprite (48 × 48, density variant chosen by neighbor count, tinted by species color)
4. Adjacency-symbiosis edge highlight (procedural, gold tint on shared edges)
5. Adjacency-symbiosis corner dots (procedural, 4 × 4 px per partnered direction)
6. Hybrid-pair fusion sprite (overrides 3, only for designated hybrid species)
7. Maturation accent rim (procedural, ancient stage only)
8. Animal marker (16 × 16 centered, procedural)
9. Structure fusion overlay (multi-tile, replaces cluster sprite within footprint)
10. Fog overlay (full-tile dark mask, when unrevealed)
11. Hover / tap highlight (future)

### Camera + zoom

- **Default zoom**: 1.0 (native 1:1, phone shows ~7.5 × 13 tiles — strategy overview is the default state)
- **Snap zoom levels**: 0.5 (world map, ~15 × 26 tiles visible), 1.0 (play), 2.0 (inspect, 3.75 × 6.7 tiles)
- **Pinch snaps** to these three levels; non-integer scales are blocked to prevent pixel shimmer
- **World dimensions**: 1536 × 2304 px (32×48 grid at 48 px tile)

### Asset commission spec at a glance

| Asset class | Per-kingdom count | Native size |
|---|---|---|
| Cluster density variants | 4 (pioneer/establishing/established/mature) | 48 × 48 |
| Biome substrate | 1 per biome (7 biomes total) | 48 × 48 |
| Structure composite | 1 per structure (4 structures) | 48 × tile-count |
| Hybrid-pair fusion | 1 per hybrid species (currently only Lichen) | 48 × 48 (renders on each paired tile) |

For 2 alpha kingdoms (plantae, fungi) the species commission is **8 PNGs total** (4 density × 2 kingdoms) — dramatically lower than the prior 16-tile-auto-tile spec (32 PNGs) and lower still than the original 14 per-species spec.

### Why these numbers

- **48 px tile**: AI-gen sweet spot. At 32 px the cluster organisms become hard to keep consistent across density variants; at 64 px world becomes large and on-screen tile count drops. 48 balances density of strategy view with detail clarity per tile.
- **Cluster matching tile size (no inset)**: every authored pixel contributes. The "biome visible through" goal is met by the cluster being *sparse organisms*, not by leaving margin around a focal silhouette.
- **4 density variants vs 16 auto-tile**: 4× fewer commissions, 4× faster iteration cycles, easier to keep silhouette consistent across the set. The "tiles growing together" feel emerges from clustering visually, not from edge-matching geometry.
- **Single species per tile**: covered above — strategic depth + visual clarity + simpler engine.

### What's preserved and what's abandoned vs prior lock

**Preserved**:
- Top-down naturalist pixel-art tone (per `map.png` + `final.png` synthesis)
- 32×48 grid (game logic unchanged)
- Structure fusion overlay pattern (multi-tile composite rendering)
- Per-species color tinting in code
- Biome continuity as a visual goal

**Abandoned (relative to 2026-05-21 lock)**:
- 96 px tile size → 48 px
- Sprite-floats-in-biome model → cluster-fills-tile
- Multi-occupant symbiosis (dual icons + gold ring) → single species + adjacency markers
- Auto-tile 16-variant approach (considered as α) → 4-variant ecological-stage clustering

### β path (not planned — confirmed 2026-05-22)

The cellular-automata growth overlay (β) is **not on the roadmap** and the engine will NOT preserve hooks or scaffolding for it. Cluster-in-biome is the committed direction. If, post-alpha, cluster-in-biome proves visually insufficient and β becomes worth revisiting, it will be designed fresh against the codebase as it stands — not bolted onto preserved hooks. Current code should be as simple as the cluster-in-biome spec allows.

### When this lock would change

- Switching to hex grid (multi-week engine refactor, deferred)
- Switching to a fundamentally different style (field-guide schematic, vector flat) — current direction holds
- Validated user-testing signal that 48 px is wrong (then evaluate 32 vs 64; not before)

---

## Prior locked decisions (further superseded by the 2026-05-22 lock)

1. **2026-05-21 96 px canvas lock** — replaced by the 48 px cluster-in-biome lock above.
2. **Structures: composite sprite first.** Direction holds, sizes change (48 px per tile, not 32 — see commission spec).
3. **Maturation: single base × programmatic modifier.** Folded into the ecological-stage clustering — maturation now reads as cluster density + ancient accent rim.
4. **Kingdom icons stand in for per-species sprites.** Replaced by cluster density variants. The per-species sprite slot may still arrive post-alpha but drops into the same 48 × 48 cluster slot.

---

## Prompt library

Paste-ready templates. Replace `{{...}}` placeholders. Every prompt assumes you attach `map.png` (atmosphere ref) and `final.png` (silhouette + structure ref) as image references in the AI tool.

### Shared header (paste at top of every prompt)

```
Top-down pixel-art, naturalist mythic-scientific tone. Reference images:
map.png for atmosphere (dither textures, moody low-key palette, ambient
glow), final.png for silhouette specificity and structure visualization.
No anthropomorphic faces, no fantasy magic, no neon, no UI candy. Tone:
Carl Sagan / Annie Dillard — biology IS the magic system.
```

### 1. Single-tile prompts (32×32 native)

**Template — empty biome tile:**
```
A single 32×32 top-down pixel-art tile of a {{biome}} biome, unoccupied.
Dithered substrate texture true to the biome (frost crystals for tundra,
mineral flecks for mineral_vent, peat mat for swamp, fine grass for
grassland, dark turned earth for rich_soil, mossy ground for forest_edge,
cracked stone for rock). 3-px border framing the inner 26×26 area as the
biome reads through. Transparent edges allow seamless tiling.
```

**Template — colonized species tile (mature stage):**
```
A single 32×32 top-down pixel-art tile, {{species_display_name}}
({{kingdom}}) growing on a {{biome}} biome. Inner 26×26 area shows the
species silhouette in {{kingdom}} palette ({{palette_hint}}). 3-px biome
frame visible around the silhouette. Mature stage: silhouette fills the
tile fully, full saturation. Dithered substrate beneath the sprite.
```

**Concrete examples to seed the run:**

- *Pioneer Grass on grassland (mature):* `... Pioneer Grass (plantae) growing on a grassland biome. Inner area shows a tuft of low chunky pixel grass blades in warm forest-green (#5a9a3a accent on #14100a dark earth). 3-px grassland biome frame visible. Mature: tuft fills the tile. Dithered grass substrate.`

- *Mycelium Thread on mineral_vent (sprouting):* `... Mycelium Thread (fungi) on a mineral_vent biome, SPROUTING stage. Inner area shows a small tentative violet mycelial patch taking ~30% of the tile, dim alpha, suggesting "just placed." Mineral-vent substrate: dark stone with orange mineral flecks. Fungi palette violet (#7a4a9a) on dark substrate (#0e0a14).`

- *Wood-rot Bracket on forest_edge (ancient):* `... Wood-rot Bracket (fungi) on a forest_edge biome, ANCIENT stage. Shelf-fungi silhouette overflowing the tile slightly with a faint accent glow rim. Forest-edge biome substrate: dark loamy soil with leaf litter. Fungi violet palette.`

- *Common Grazer on grassland (mature):* `... Common Grazer (animals) on a grassland biome. Render the grazer as a small bronze creature silhouette at tile center, inset diamond marker style, on top of any underlying biome fill. Animals palette: bronze/amber (#ba8a4a on #12100a). Hint of motion in the silhouette.`

- *Lichen Common on tundra (mature, symbiosis):* `... Lichen Common (hybrid: plantae + fungi) on a tundra biome. Symbiosis tile: warm-gold fill (#d8b840) overrides the per-kingdom color, with hints of green + violet bleeding through at 30%. Crusty mottled lichen silhouette. Frost-crystal dither beneath.`

**Maturation row prompt (for asset reference sheets):**
```
A horizontal 3-tile reference sheet: same species ({{species_display_name}}
on {{biome}} biome) shown at 32×32 in three growth stages side by side —
SPROUTING (small silhouette, ~30% of tile, dim alpha, tentative),
MATURE (full silhouette fills the tile, full saturation),
ANCIENT (silhouette slightly overflows tile, accent glow rim, deeper
saturated core, reads as "settled and weighty").
The silhouette is the same shape; only scale and accent change.
```

### 2. Structure prompts (composite sprites)

Every structure ships as ONE multi-tile PNG at structure-native resolution. Tile borders are INVISIBLE inside the structure — the structure is the visual subject.

**Template — composite structure sprite:**
```
A composite top-down pixel-art sprite of a {{structure_name}} structure
covering a {{rows}}×{{cols}} tile area at 32-px-per-tile native
(total {{width}}×{{height}} px). The {{tile_count}} constituent tiles
FUSE into one continuous structure — tile borders are invisible inside
the structure footprint. The structure is the visual subject; underlying
biome shows only as a frame around the structure perimeter. {{specific_description}}
Pixel-art top-down, moody naturalist palette, no anthropomorphism.
```

**Concrete examples — all 4 active structures:**

- **Fairy Ring** (5 fungi tiles in a ring, ring_radius_1):
```
Composite top-down pixel-art sprite of a FAIRY RING structure covering a
3×3 tile area at 32-px-per-tile native (96×96 px total). The 5 fungi
tiles arranged in a ring pattern FUSE into ONE continuous mycelial ring
arching across the footprint. Inside the ring: bare darker earth, no
mushrooms — the center is mysteriously empty (this is the structure's
defining feature). On the ring itself: a faint ridge of violet mycelium
with small fruiting bodies emerging at intervals. Tile borders are
INVISIBLE inside the 3×3 area. Outer perimeter shows the biome frame
(authored for rich_soil; biome can be re-tinted per use). Fungi palette
violet (#7a4a9a) on dark substrate (#0e0a14). Faint ambient glow on
the ring suggests slow biological activity.
```

- **Old-Growth Stand** (3×3 same-species plantae block):
```
Composite top-down pixel-art sprite of an OLD-GROWTH STAND structure
covering a 3×3 tile area at 32-px-per-tile native (96×96 px total). The
9 plantae tiles FUSE into a dense canopy. Render 3–4 tall ancient trunk
silhouettes rising ABOVE the 3×3 footprint (extending up into the row
above, breaking the tile-grid silhouette to convey verticality and age).
Below the trunks: thick canopy shadow blanketing the 9-tile area, with
glimpses of moss-textured ground at gaps. Tile borders are INVISIBLE
under the canopy. Plantae palette warm forest-green (#5a9a3a on #14100a),
with deep-saturated old-growth core. No magical glow — just weight
and patience.
```

- **Mycorrhizal Hub** (fungi center with 4 adjacent plantae tiles):
```
Composite top-down pixel-art sprite of a MYCORRHIZAL HUB structure
covering a 5-tile cross pattern at 32-px-per-tile native (160×160 px
bounding box, structure occupies the cross). Central fungi tile + 4
adjacent plantae tiles FUSE via a visible root-web threading from the
central tile out to each plant. Render the root threads as fine
branching lines glowing faintly violet→green where fungi meets plant
(the symbiotic exchange visible). Tiles retain their individual species
sprites BUT the boundaries between them dissolve into the connecting
web. Hybrid teal palette accents (#3a8a7a) on the connection lines.
The hub feels alive and exchanging.
```

- **Decay Pit** (fungi cluster on rich_soil with adjacent corpse):
```
Composite top-down pixel-art sprite of a DECAY PIT structure covering a
2×2 tile area at 32-px-per-tile native (64×64 px total). The 4 fungi
tiles on rich-soil FUSE into a slight ground DEPRESSION — substrate
darkens toward the center, conveying "the earth sinks here." Around the
rim: a dense cluster of fungal fruiting bodies (violet caps on pale
stems). Center: dark stain of decomposing matter, possibly a hint of
bone or chitin texture. Aura extends faintly beyond the 2×2 into adjacent
tiles (this is the bonus aura — render as a soft darkening, not a sharp
edge). Tile borders INVISIBLE inside the pit. Decay should feel patient
and slow, not gross.
```

### 3. Full-world mockup prompts

For evaluating overall feel, marketing screenshots, design exploration. Render at portrait phone resolution.

**Template — playfield viewport (zoomed-out, multi-cluster):**
```
Portrait-mobile (360×640) top-down view of a Bio playfield mid-run,
showing approximately {{visible_tiles}} tiles at 32-px native (the rest
of the 32×48 sim grid is off-screen via zoom/drag). Era: {{era_name}}
({{era_tint}} wash over everything). Biome mix per ecosystem recipe:
{{biome_mix}}. Show {{cluster_count}} colonized clusters with visible
maturation variety (sprouting at the edges, mature in the body, ancient
at the centers). {{structure_count}} structures visible as fused
meta-tiles. Atmosphere from map.png, silhouette readability from
final.png. HUD overlays NOT shown — just the play surface.
```

**Concrete examples:**

- *Cryogenian Volcanic Vent mid-run mockup:*
```
Portrait-mobile (360×640) top-down view of a Bio playfield mid-run.
Era: Cryogenian (cool ice-blue wash, #d8eaff at low opacity over the
whole image). Ecosystem: Volcanic Vent — biome mix is 70% mineral_vent
(dark stone with orange flecks), 20% tundra (pale frost crystals), 10%
rich_soil. Show ~11×20 tiles visible at 32-px native. Two fungi clusters
(Mycelium Thread, Vent Archaeon) sprawling outward from a central
mineral-vent patch — sprouting at the edges, ancient at the cores.
ONE Fairy Ring structure visible as a fused meta-tile in the upper-right
quadrant. ONE small Decay Pit forming bottom-left. Fungi palette violet
dominates; mineral-vent orange flecks punctuate. No characters, no UI.
The world reads as a habitat being slowly colonized by patient life.
```

- *Devonian Inland Swamp late-run mockup with symbiosis:*
```
Portrait-mobile (360×640) top-down view of a late-run Devonian playfield.
Era: Devonian (warm pale-amber wash, #fff8e0). Ecosystem: Inland Swamp —
biome mix is 70% swamp (peat mat, dark wet ground), 20% forest_edge
(loamy with leaf litter), 10% rich_soil. ~11×20 tiles visible at 32-px
native. Show a dense established colony: plantae clusters (Tree-fern Stem,
Bramble), fungi clusters (Mycelium Thread, Wood-rot Bracket), and
significant symbiosis — many tiles render with the warm-gold symbiosis
override where plants and fungi share territory. ONE Old-Growth Stand
structure (3×3 fused canopy, tall trunks rising above its footprint) in
the middle. ONE Mycorrhizal Hub (5-tile cross with visible root-web)
nearby. Maturation full range visible — sprouting borders, mature body,
ancient cores. Atmosphere damp, weighty, settled.
```

- *Era transition / mass-extinction moment:*
```
Portrait-mobile (360×640) top-down view of a Bio playfield at the moment
of era transition from Cryogenian to Devonian. Mid-flash: cool ice-blue
wash being overtaken by warm amber wash across the image, top-down
gradient. Most tiles show a darkening/dimming cascade — the world is
losing what was built. A few resilient tiles (Lichen Common, Cryo-Lichen)
remain at full saturation in the upper portion, suggesting "patience
survives." Atmosphere: catastrophic but not gory — the world goes on
without most of it. Soft, almost reverent quality. No text, no UI.
```

### 4. Reference-sheet prompts (for asset planning)

**Biome swatch sheet:**
```
A 7-column reference sheet of 32×32 pixel-art biome tiles, no occupants:
grassland, rich_soil, forest_edge, swamp, tundra, mineral_vent, rock.
Each tile shows the biome's distinctive dither texture and color band as
described in the canonical palette. Laid out left-to-right with 8-px
gaps. Pure substrate, no species silhouettes.
```

**Species silhouette sheet (per kingdom):**
```
A reference sheet of all {{kingdom}} species silhouettes at 32×32 pixel
native, mature stage, arrayed in a grid. Each silhouette on a neutral
mid-tone background (no biome). Species: {{species_list}}. Each one
must read as a distinct creature/plant/fungus by silhouette alone — a
viewer should be able to tell them apart with no text labels.
```

  - Plantae list: pioneer_grass, bramble, tree_fern_stem, creeping_vine, cyanobacterial_mat
  - Fungi list: mycelium_thread, mycelium_thread_mycorrhizal, wood_rot_bracket, cryo_lichen, vent_archaeon, spore_drift
  - Animals list: common_grazer, common_predator, scavenger_swarm
  - Hybrid list: lichen_common

---

## Phase D — HUD restyle (PENDING RE-SCOPE 2026-05-22)

> **DO NOT EXECUTE D1-D7 AS WRITTEN.** The plan below was scoped against the pre-Hero-design HUD. `docs/GAMEPLAY_DESIGN.md` (2026-05-22) adds Hero portrait + stat radar, Pressure banner, action bar with up to 8 support species, mutation/event prompt modals, Tier List view, Tree of Life view, and Planet view. The existing resources strip + biome legend + goal banner + ability bar pattern is being substantially rebuilt, not restyled. Phase D must be re-scoped against the new HUD requirements before any D1-D7 work is done.
>
> **What still applies**: the visual language (dither backgrounds, glow accents, kingdom-tinted palette) carries forward to whatever the new HUD becomes. Steps D1 (dither micro-background helper) and D2 (glow-line accents) are reusable primitives. The biome legend chip restyle (D4) and the structure banner restyle (D5) are still in scope if those elements survive the redesign — but they are no longer the centerpiece of HUD polish.

### Original D1-D7 plan (pre-2026-05-22, retained for reference)

The HUD layout from `swamp_biome_gpt.png` is essentially the current layout — resources strip top, left column with biome legend + goal banner, kingdom-tab indicators on the right. Phase D is **restyling**, not rebuilding. The pilot (resource glyph chips + dropped name prefix) is already in `scripts/ui/hud.gd` as of 2026-05-21. The remaining steps:

### D1 — Dither micro-background for panels

Create `scripts/ui/dither_panel.gd` — a `Control` (or `Node2D` overlay) that paints a 2-color dot dither pattern as its background via `_draw()`. Drop behind:
- `Bar` PanelContainer (resources)
- `IdentityStrip`
- `GoalBanner`
- `SpeciesPanel`

Two colors per dither = surface_dim + surface_mid from the active kingdom palette (`KingdomTheme.kingdom_palette(kingdom_id)`). On `run_started` re-tint to match starter species' kingdom.

Alternative: write `assets/ui/shaders/dither.gdshader` taking a `pattern` enum (1-8 from the JSX identity system) + a 2-color uniform. Apply as `material` on a `ColorRect` background. Slightly more setup, much more flexible.

Recommendation: start with the GDScript `_draw()` approach (no shader pipeline needed); migrate to shader only if performance falters or if more variety per pattern is wanted.

### D2 — Glow-line accents

Per UI_POLISH.md `GlowLine` spec: a 2-px gradient at the top of buttons/toasts/panel headers. Polygon2D with vertex_colors interpolating transparent → kingdom-glow → transparent. Apply to:
- Bar panel top edge
- Selected ability button when active
- Event toast (warmer for negative events, cooler for positive)
- GoalBanner top

Single helper: `scripts/ui/glow_line.gd` reusable Node2D.

### D3 — Real PNG resource icons swap

When `assets/art/resources/<id>.png` files arrive (per `COMMISSION_RESOURCE_ICONS.md`), replace the ASCII glyph in `RESOURCE_GLYPHS` with `TextureRect` children of each resource label slot. Code change is minimal: swap `Label.text = "%s %s" % [glyph, amt]` for an `HBoxContainer` with `[TextureRect, Label]`. Tooltips already configured.

### D4 — Biome legend chip restyle

`scripts/ui/biome_legend.gd` currently renders ColorRect swatches. Replace with the actual procedurally-generated biome textures from `tile_grid.gd._biome_textures` so the legend matches the playfield 1:1. Source: `_get_tile_grid_biome_texture(biome_id)` helper added to tile_grid.

### D5 — Structure banner restyle

`scripts/ui/structure_banner.tscn` is a generic toast right now. When structure PNG sprites land (per `COMMISSION_STRUCTURES.md`), the banner should preview the composite structure thumbnail beside the announcement. ~25 lines of script.

### D6 — Evolve modal restyle

`scripts/ui/evolve_modal.gd` is a Control with VBoxes of buttons. Apply the dither background + glow line. Stretch goal: per-kingdom-tinted button hover state.

### D7 — Onboarding overlay polish

`scripts/ui/onboarding_overlay.gd` already works. Apply the same dither + glow language so the first-run flow doesn't break atmosphere.

### Order to execute

D1 → D2 → D3 (after icons arrive) → D4 → D5 (after structure art arrives) → D6 → D7. D1+D2 are pure code and ~half-day's work; the rest depends on art deliveries.

---

## Iteration tips

- **First-pass is rarely right.** Use the first generation to identify what's off (silhouette wrong shape, palette too saturated, structure-fusion failing) and re-prompt with that critique appended: *"Same as before but the fairy ring center must be fully empty bare earth, no mushrooms inside the ring."*
- **Ask for variants.** Most image AIs let you request 4 variants per prompt. Generate 4, pick the closest, then re-prompt against that one as a reference.
- **Compare against map.png + final.png after every generation.** If the output doesn't share atmosphere with map.png OR silhouette specificity with final.png, the prompt is off — don't accept a "pretty" output that breaks the visual language.
- **Lock palette via hex codes in the prompt.** AIs interpret "violet" loosely; `#7a4a9a` is unambiguous.
- **Tile and structure assets must be transparent-edged PNG** if you intend to drop them into Godot. Always include "transparent edges" or "transparent background" in the prompt.
