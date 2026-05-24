# Commission Brief — Species Sprites (Placeholder Alpha Set)

**Status**: ⏸ **DEFERRED** (deferral confirmed 2026-05-22). Alpha uses 4 kingdom-level cluster density variants per kingdom, tinted by species color — see `docs/COMMISSION_KINGDOM_ICONS.md` for the alpha commission scope (8 PNGs instead of 14 per-species sprites).

When this brief is reactivated post-alpha, the spec changes to match the 2026-05-22 visual model: per-species art drops into the **48 × 48 px cluster slot** (not the 32-px focal-icon slot in the prior spec below). Each per-species commission would deliver 4 density variants (pioneer / establishing / established / mature) for a species-specific cluster — same density progression as kingdom-level art, but with per-species silhouette identity. That's **4 × 14 = 56 PNGs** for the full roster, so reactivation should follow validated need (per-species identity becoming a visible bottleneck) and budget availability.

Sections below are the **pre-2026-05-22** spec (32 px focal icons) and are retained as historical context. Treat as superseded.

**Original references**: `docs/VISUAL_DIRECTION.md`, `builds/screenshots/map.png`, `builds/screenshots/final.png`, `builds/screenshots/making_biomes_and_species_visible.png`.

**Deliverable**: 14 species sprites + 1 maturation reference sheet.

---

## Format spec

- **Native size**: 32×32 px PNG, transparent background.
- **Inner area**: silhouette occupies the inner ~24×24 px. Leave a ~4 px breathing room so the biome substrate frames the icon.
- **Style**: top-down pixel art, chunky pixel-art retro feel, naturalist mythic-scientific tone (Carl Sagan / Annie Dillard). NOT cute, NOT fantasy magic, NOT high-contrast neon.
- **Palette**: lock per-species hex codes below. Stick to the listed primary + 1–2 shade-darker variants for depth. Each species belongs to a kingdom palette family — see `docs/VISUAL_DIRECTION.md` for the kingdom hex anchors.
- **Anti-pattern**: no faces, no eyes, no anthropomorphism. A grazer is a shape with hint-of-motion, not a cartoon animal.
- **Maturation**: deliver MATURE stage only for v1 (single sprite per species). Code applies sprout/ancient via scale + accent. Per-stage silhouettes commissioned later.
- **Delivery**: one PNG per species, filename = `<species_id>.png` (e.g. `pioneer_grass.png`). Drop into `assets/art/species/`.
- **Test against**: each sprite must read as its species at 100% zoom on a 360×640 mobile screen. Hand the artist a test sheet of all 14 thumbnails on a neutral mid-tone background — viewer should be able to tell each one apart with no labels.

---

## Species list — Plantae (5)

Palette family: warm forest green spectrum. Backdrop dark earth.

| ID | Display name | Latin | Primary color | Silhouette direction |
|---|---|---|---|---|
| `pioneer_grass` | Pioneer Stem | *Cooksonia caledonica* | `#73c74d` | Low chunky upward stems, 3 vertical blades sprouting from a base point. Reads as "first thing on the ground." |
| `bramble` | Climbing Bramble | *Trimerophyton robustius* | `#8c802d` | Thorny tangled cluster, branching outward, slightly chaotic. Reads as parasite/clinger. |
| `tree_fern_stem` | Tree-Fern Stem | *Wattieza muschelae* | `#338c40` | Tall central trunk with a fanned frond crown. The ONLY tall plantae sprite — must read as vertical from above. |
| `creeping_vine` | Creeping Vine | *Vitis serpentina* | `#669933` | Serpentine line tracing diagonally across the tile, leaves at intervals. Reads as movement / spread. |
| `cyanobacterial_mat` | Cyanobacterial Mat | *Oscillatoria princeps* | `#33a68c` | Thin mossy skin spread evenly across most of the tile inner area. Reads as a "layer" not a "thing." Slightly teal-leaning vs other plantae. |

## Species list — Fungi (6)

Palette family: violet-purple, dusty mauve. Backdrop deep dark violet.

| ID | Display name | Latin | Primary color | Silhouette direction |
|---|---|---|---|---|
| `mycelium_thread` | Mycelium Thread | *Glomeromycota basalis* | `#7f59b8` | Sprawling network of fine thread-lines radiating outward from tile center, no cap. Reads as "below ground network." |
| `mycelium_thread_mycorrhizal` | Mycorrhizal Mycelium | *Glomus intraradices* | `#a566c0` | Like `mycelium_thread` but threads have small bulb-nodules where they intersect, and faint connection-glow at endpoints. Slightly brighter purple. |
| `wood_rot_bracket` | Wood-Rot Bracket | *Prototaxites loganii* | `#8c4d73` | Shelf-fungus shape — 2-3 stacked horizontal brackets emerging from one side of the tile. Reads as "eating something dead." Dusty rose-violet. |
| `cryo_lichen` | Cryo-Lichen | *Lecidea atrobrunnea* | `#d9d98c` | Crusty mottled patch of dim olive-yellow on the substrate, lichen-like. NOT a mushroom shape — flat and crusty. (NB: tile_marker_color is dim yellow, NOT typical fungi violet — this species sits in the fungi kingdom but visually reads as a hybrid.) |
| `vent_archaeon` | Vent Archaeon | *Pyrolobus fumarii* | `#4d338c` | Dark deep-violet cluster of tiny cap-shapes clustered tightly. Faint orange/red glow inside the cluster (suggesting thermophilic life). Extremophile vibe. |
| `spore_drift` | Spore Drift | *Aspergillus aerios* | `#9966cc` | Drifting wispy cluster of small spore-cap shapes spread evenly across the tile, all leaning the same direction (wind cue). Light violet, airy. |

## Species list — Animals (3)

Palette family: bronze, amber, warm earth. Backdrop dark warm earth. Render small at tile center — animals are inset markers, not full-tile fills.

| ID | Display name | Latin | Primary color | Silhouette direction |
|---|---|---|---|---|
| `common_grazer` | Lobe-Finned Browser | *Eusthenopteron foordi* | `#eba033` | Small round-bellied creature outline (~10 px across), top-down view. Lobe-fin Devonian aesthetic — pre-tetrapod, fish-with-legs. Reads as "browsing herbivore." |
| `common_predator` | Apex Stalker | *Hyneria lindae* | `#c7332e` | Smaller-but-leaner shape than grazer (~9 px across), lower silhouette, hints of teeth or jaw. Reads as "hunter." Deep red-orange. |
| `scavenger_swarm` | Scavenger Swarm | *Necrophagus convocatus* | `#8c5940` | Cluster of 4-6 tiny dots/specks (~3 px each) scattered across the tile, not centered. Reads as "many small mouths." |

## Species list — Hybrid / Symbiotic (1)

Palette family: teal/turquoise accent. This species occupies the fungi kingdom slot but represents a fused organism.

| ID | Display name | Latin | Primary color | Silhouette direction |
|---|---|---|---|---|
| `lichen_common` | Devonian Lichen | *Pertusariales devonica* | `#c7bf73` | A crusty patch combining lichen-yellow base with embedded green dots and faint violet threading. Composite silhouette reads as "two organisms fused into one." |

---

## Maturation reference sheet (1 deliverable)

Deliver a single horizontal reference sheet showing `pioneer_grass` at three growth stages side by side (32×32 each, 8 px gap), demonstrating the maturation convention engineers will replicate programmatically for v1:

| Stage | Treatment |
|---|---|
| Sprouting | Same silhouette as mature, but ~50% scale, centered, dim alpha (0.55). Reads as "tentative." |
| Mature | Full silhouette, full opacity. Default state. |
| Ancient | Full silhouette + slight upward bleed beyond tile bounds + accent glow rim. Reads as "settled, weighty." |

This sheet anchors the maturation system. Once approved, the same convention applies to all species via code (scale + alpha + accent), so we don't need per-species per-stage sprites for the alpha. Long-term we'll commission unique silhouettes per stage.

---

## Reference attachments

Hand the artist (or paste into the AI prompt):

1. `docs/VISUAL_DIRECTION.md` — canonical art direction (atmosphere, palette anchors, anti-patterns)
2. `builds/screenshots/map.png` — atmosphere reference (dither texture, moody substrate, ambient glow)
3. `builds/screenshots/final.png` — silhouette specificity reference (per-species recognizability at small size)
4. `builds/screenshots/making_biomes_and_species_visible.png` — explicit layered rendering model: biome substrate + species icon overlay
5. `builds/screenshots/swamp_biome_gpt.png` — best in-game synthesis mockup; this is the target feel
