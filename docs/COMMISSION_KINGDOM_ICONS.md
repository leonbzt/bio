# Commission Brief — Kingdom Icons (Alpha Set)

**Status**: ready to send 2026-05-21. Replaces the deferred per-species commission (`docs/COMMISSION_SPECIES.md`) with a much smaller alpha-targeted set.

**Why this exists**: per-species sprites (14 commissions) were too much scope for the alpha. Instead, ship kingdom-level icons. Each species in a kingdom uses the same icon shape, tinted by its `tile_marker_color`. Per-species visual identity comes from tooltips + the side species panel + the tile inspector. This trades visual specificity at the tile for ship speed and scope discipline.

**Key architectural choice (locked 2026-05-21)**: the icon size is **32×32 px native** — identical to the future per-species sprite size. When per-species art lands, those PNGs slot into the same Sprite2D positions with zero engine change. The kingdom icon becomes the "generic fallback" for unauthored species. No layout migration ever needed. See `docs/VISUAL_DIRECTION.md` "Locked long-term canvas".

**Deliverable**: **2 PNGs for the alpha** (plantae + fungi). Animals and hybrid keep their procedural placeholders (diamond + crusty patch) until the alpha proves out — then commission as a second wave.

---

## Format spec

- **Native size**: **32×32 px PNG, square**, transparent background.
- **Shape**: silhouette or filled-emblem within the 32×32 frame. May extend close to the edges but should leave at least 1 px transparent border on each side so the biome substrate frames the icon visually. Think Loop Hero / Stardew NPC silhouette style — top-down naturalist creature, not a Civ logo.
- **Tile placement**: engine draws the icon at fixed 32×32 size at tile center on a 96×96 tile (mono-occupant) or offset diagonally by 16 px from center (symbiosis dual). No resize ever. See `docs/VISUAL_DIRECTION.md` "Locked long-term canvas" for the placement diagram.
- **Style**: top-down pixel art, chunky retro, naturalist mythic-scientific. Matches `docs/VISUAL_DIRECTION.md`. No anthropomorphism, no fantasy magic, no neon, no UI candy.
- **Color**: deliver each icon **monochrome white-on-transparent** (or with a single base color). The engine multiplies the icon texture by `species.tile_marker_color` at draw time — so the artist authors VALUE/SHAPE only; color tinting happens in code. This is what makes 1 PNG cover N species.
- **Anti-aliasing OFF**: hard pixel edges only. 32×32 is enough canvas for real character — use it.
- **Delivery**: one PNG per kingdom, filename = `<kingdom_id>.png`. Drop into `assets/art/kingdoms/`.

---

## Icon list — alpha (commission now)

| ID | Kingdom | Direction | Constraint at 32×32 |
|---|---|---|---|
| `plantae` | Plant | Top-down silhouette of a rooted, upward-growing organism. Possible motifs: a tuft of 3-5 chunky leaves/blades, a single bold sprout with stem + cap leaves, a low fern frond. Convey verticality even from above. Reads as "rooted, photosynthesizing, growing." | Recognizable as plant at 32×32 against any biome substrate. Distinguishable from fungi by vertical/branching silhouette + tapering tips. |
| `fungi` | Fungus | Top-down silhouette evoking decomposer life. Possible motifs: a chunky cap-on-stem mushroom seen from above (round cap dominant, stem peeking), a mycelial radial pattern, a shelf-fungus bracket. Reads as "decomposing, patient, networked." | Recognizable as fungus at 32×32. Distinguishable from plantae by rounded/cap-based silhouette + no upward taper. |

**Dual-icon symbiosis note**: when plant + fungi share a tile, BOTH icons render at full 32×32 (no resize) — placed diagonally inside the 96 px tile (plant lower-left, fungi upper-right), with 16 px gap each side of center. A gold ring (radius 44) traces around them. The icons need to read clearly in both contexts (alone, and paired). Test deliverable: render at 32×32 on (a) a swamp biome substrate alone, (b) paired with the fungi icon diagonally on swamp biome with the gold symbiosis ring.

**Future species sprite drop-in**: when per-species sprites are commissioned later (e.g. Pioneer Stem, Mycelium Thread, Wood-Rot Bracket — see `COMMISSION_SPECIES.md`), they will be authored at the **same 32×32 native size** and dropped into the same Sprite2D slot. The kingdom icon becomes the unauthored-species fallback. No layout change ever needed.

## Icon list — second wave (defer)

| ID | Kingdom | Silhouette direction |
|---|---|---|
| `animals` | Animal | Inset diamond marker. Currently rendered procedurally. Commission once Devonian content is the focus. |
| `hybrid` | Hybrid / Symbiotic | Crusty lichen patch with embedded contrast dots. Currently procedural. Commission alongside lichen content. |

---

## Reference: in-engine procedural placeholder

The engine currently draws these shapes via GDScript `_draw()` in `scripts/entities/tile_grid.gd::_SpeciesIcon`. Compare your delivery against the procedural output — your version should be the same SHAPE but with proper pixel-art craft (anti-aliased curves removed, weighting consistent, hand-tuned). The procedural version is the placeholder; your version is the alpha-ship art.

---

## Tinting test

After delivery, every PNG will be tinted by 14 different `tile_marker_color` values in-game:

- Plantae icon tinted with: `#73c74d` Pioneer Stem, `#8c802d` Bramble, `#338c40` Tree-Fern, `#669933` Vine, `#33a68c` Cyanobacteria
- Fungi icon tinted with: `#7f59b8` Mycelium, `#a566c0` Mycorrhizal, `#8c4d73` Wood-Rot, `#d9d98c` Cryo-Lichen, `#4d338c` Vent Archaeon, `#9966cc` Spore Drift
- Animals icon tinted with: `#eba033` Lobe-Finned Browser, `#c7332e` Apex Stalker, `#8c5940` Scavenger Swarm
- Hybrid icon tinted with: `#c7bf73` Devonian Lichen

The shape needs to read clearly under all these tints. Test: render the white silhouette over each tint color and confirm the silhouette still reads at 32 px — no detail should be lost when tinted dark, no detail should blow out when tinted bright.

---

## Reference attachments

Hand the artist (or paste into the AI prompt):

1. `docs/VISUAL_DIRECTION.md` — canonical art direction
2. `builds/screenshots/map.png` — atmosphere reference
3. `builds/screenshots/final.png` — silhouette specificity reference (look at the kingdom-icon row, NOT the individual species)
4. `builds/screenshots/making_biomes_and_species_visible.png` — the layered rendering model these icons drop into
