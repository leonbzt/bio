# Commission Brief — Structure Composite Sprites

**Status**: updated 2026-05-22. Supersedes the 2026-05-21 dimensions (which were sized at 32 px per tile). Per the 2026-05-22 "Locked long-term canvas" in `docs/VISUAL_DIRECTION.md`, tile size is **48 px native**, and all structure PNG dimensions in this brief now reflect that. References `docs/VISUAL_DIRECTION.md` (canonical art direction, structure-fusion concept) and `builds/screenshots/swamp_biome_gpt.png` (visual style ref — see Old-Growth Stand and Mycorrhizal Hub in the mockup).

**Deliverable**: 4 multi-tile composite sprites + 1 explanation sheet for the fusion concept.

---

## The fusion principle (read first)

A structure is NOT a halo around tiles. When the game promotes a structure, the constituent tiles **stop rendering as individual tiles** and visually fuse into a single continuous structure object spanning the matched footprint.

- Tile borders are INVISIBLE inside the structure footprint.
- The underlying biome may show as a frame around the structure perimeter, but not inside.
- The structure is the visual subject; constituent tile fills are subordinate.
- The structure can extend slightly beyond its tile footprint (especially vertically, e.g. tall trees) to break the grid and convey real form.

Reference: `swamp_biome_gpt.png` Old-Growth Stand — note tall trunks rising up out of the canopy into the row above, and the lack of visible 3×3 tile grid inside the canopy mass. That's the look.

---

## Format spec

- **Native scale**: **48 px per tile**. Structure sprite dimensions = (tile_footprint × 48) plus optional vertical/horizontal overflow for things that break the grid.
- **Style**: pixel art, top-down, naturalist mythic-scientific. Matches the species-sprite style (`COMMISSION_SPECIES.md`).
- **Transparent edges** so the engine can stamp the composite onto the existing tile grid and biome shows around it.
- **Anti-pattern**: no magical glow, no fantasy runes, no neon. Subtle ambient glow (suggesting biological activity) is OK; arcane glow is not.
- **Delivery**: one PNG per structure, filename = `<structure_id>.png` (e.g. `fairy_ring.png`). Drop into `assets/art/structures/`.
- **Naming**: lowercase snake_case to match `data/structures/<id>.tres`.

---

## Structure 1 — Fairy Ring

| Spec | Value |
|---|---|
| Sprite ID | `fairy_ring` |
| Footprint | 3×3 tiles |
| PNG size | 144 × 144 px (no vertical overflow) |
| Pattern | Ring of 5 fungi tiles (8 outer cells of 3×3, but only 5 colonized in the actual game logic) |
| Halo color hint (current) | `#80cef2` cool blue |
| Palette | Fungi violet `#7f59b8` + dark substrate `#0e0a14` + bare-earth brown for center |

**Visual brief:**

A continuous mycelial ring arching across the 3×3 footprint. Constituent fungi tiles FUSE into one ring shape — no individual tile borders inside the footprint. The ring is the visual subject.

- **Ring itself**: a soft ridge of dense mycelium following the outer perimeter, varying in thickness organically (not a perfect circle outline). Small violet fruiting bodies emerge at irregular intervals along the ring (maybe 4-6 small caps).
- **Ring center**: bare/darker earth, mysteriously empty — this is the structure's defining feature. The center stays bare in the lore ("the center stays mysteriously bare"). NO mushrooms inside.
- **Outside the ring**: faded edges, transparent so the biome frame shows.
- **Ambient quality**: faint ring glow violet, low-intensity, suggesting slow biological activity. NOT magic-looking.
- **Substrate hint**: a hint of biome-neutral dark soil underneath. The artwork should look fine on top of any biome substrate (the engine handles biome rendering separately).

## Structure 2 — Old-Growth Stand

| Spec | Value |
|---|---|
| Sprite ID | `old_growth_stand` |
| Footprint | 3×3 tiles |
| PNG size | 144 × 192 px tall (48 px vertical overflow above the footprint) |
| Pattern | 3×3 same-species plantae block |
| Halo color hint (current) | `#66d94d` warm forest green |
| Palette | Plantae green `#73c74d` + deep saturated old-growth core `#226633` + dark trunk shadow |

**Visual brief:**

A dense canopy of ancient trees, with 3-4 tall trunks rising ABOVE the 3×3 footprint into the row above. This is the structure that most aggressively breaks the tile grid via vertical overflow.

- **Trunks** (3-4 of them): pixel-art tall trunks emerging from the canopy mass, ~48 px tall each, irregularly spaced across the top of the 3×3 footprint. Trunks taper. Top of trunks shows hint of canopy leaves (broad pixel-cluster).
- **Canopy mass below the trunks**: a continuous green-shaded cover blanketing the 3×3 footprint. Hint of dappled shadow, mossy undergrowth, fallen leaf litter. NO visible tile borders inside the canopy.
- **Periphery**: canopy edges feather slightly into transparent at the 3×3 perimeter so neighboring biome shows.
- **Quality**: weighty, patient, settled. Long-lived. NOT spooky-dark-forest.
- **Mood**: like looking down through a small clearing into an ancient grove. Light filters from above.

## Structure 3 — Mycorrhizal Hub

| Spec | Value |
|---|---|
| Sprite ID | `mycorrhizal_hub` |
| Footprint | 5-tile cross (center + 4 cardinal neighbors) |
| PNG size | 144 × 144 px (3×3 bounding box; the 5-tile cross occupies center + 4 cardinal cells, leaving transparent corners) |
| Pattern | Fungi center + 4+ adjacent plantae |
| Halo color hint (current) | `#bf80e6` light violet |
| Palette | Fungi violet `#7f59b8` + plantae green `#73c74d` + hybrid teal `#5acab0` for connection glow |

**Visual brief:**

Visible root-web threading from a central fungi tile out to the 4 adjacent plant tiles. Constituent tiles DO still show their species sprites, but the borders between them dissolve into the connecting web. This structure is about connection, not occlusion.

- **Central tile**: a denser fungi mass than a normal fungi tile, suggesting a hub/nexus.
- **Connection lines**: fine branching root-thread lines emanating from the center, reaching into each of the 4 adjacent plant tiles. Lines glow faintly teal where fungi meets plant — visible nutrient exchange.
- **Adjacent plant tiles**: show plantae sprites still visible but with tendrils of root-thread merging into their bases.
- **Tile borders inside the cross**: dissolve into the web. Borders OUTSIDE the cross (the 4 corner tiles of the 5×5 bounding box) remain crisp — they're not part of the structure.
- **Substrate**: the artwork should look fine on top of any biome (rich_soil and forest_edge most likely).
- **Mood**: alive, exchanging. The visual equivalent of trade.

## Structure 4 — Decay Pit

| Spec | Value |
|---|---|
| Sprite ID | `decay_pit` |
| Footprint | 2×2 tiles |
| PNG size | 96 × 96 px (no vertical overflow) |
| Pattern | 2×2 fungi block on rich-soil with adjacent corpse |
| Halo color hint (current) | `#cc8080` warm rose |
| Palette | Fungi violet `#7f59b8` + dark stain `#1a1218` + rich-soil substrate brown |

**Visual brief:**

A slight ground depression — the earth sinks here. 2×2 fungi tiles fuse into a continuous pit shape. Around the rim, a dense cluster of fungal fruiting bodies.

- **Pit substrate**: the 2×2 footprint shows substrate that darkens toward the center, conveying a depression. Pixel-shading to imply concavity (lighter on outer ring, darker toward center).
- **Pit center**: dark stain of decomposing matter. A hint of bone or chitin texture (an arc, a curve, a fragmentary shape) — but NOT explicit gore. Decay should feel patient and slow.
- **Rim cluster**: dense ring of fungal fruiting bodies (violet caps on pale stems) crowding the rim of the depression. Reads as "many small organisms working."
- **Aura**: a soft darkening that extends faintly beyond the 2×2 into adjacent tiles (the bonus aura). Render as a transparent fade, not a sharp edge.
- **Substrate**: artwork should look fine on rich_soil biome (its required biome). The dark stain reads as decay-on-earth.
- **Mood**: weighty, slow, patient. Decay as a process, not a horror.

---

## What you get if all 4 are done well

When a structure promotes in-game, it stops being a "halo around tiles" and becomes its own visual object on the playfield — recognizable from across the screen, distinct from every other structure, and unmistakably part of the same visual language as the species sprites.

Reference: `swamp_biome_gpt.png` shows Old-Growth Stand and Mycorrhizal Hub in-engine. That's the target.

---

## Reference attachments

Hand the artist (or paste into the AI prompt):

1. `docs/VISUAL_DIRECTION.md` — canonical art direction
2. `docs/COMMISSION_SPECIES.md` — sister brief, same style
3. `builds/screenshots/swamp_biome_gpt.png` — best in-engine reference for fused structures
4. `builds/screenshots/final.png` — explicit structure formation diagrams (Fairy Ring, Old-Growth, Mycorrhizal Hub explained visually)
