# Commission Brief — Kingdom Cluster Sprites (Alpha Set)

**Status**: ready to send 2026-05-22. Supersedes the prior 2026-05-21 brief for 32-px monochrome focal-icon silhouettes (sized around the abandoned focal-icon-in-biome visual model). The two existing PNGs in `assets/art/kingdoms/` (`plantae.png`, `fungi.png` at 32 px focal silhouette) are **outdated** — they don't fit the cluster-in-biome rendering and will be replaced by the deliverables from this brief.

**Why this brief exists**: per the 2026-05-22 "Locked long-term canvas" in `docs/VISUAL_DIRECTION.md`, Bio's tile rendering uses cluster-in-biome — each species tile renders as a few small organisms scattered within the biome, biome substrate visible around and between them. Cluster density per tile steps up with same-kingdom neighbor count to give a "growing together" feel without auto-tile geometry. This brief commissions the 4 cluster density variants per kingdom that make this work.

**Deliverable for alpha**: **8 PNGs total** (4 density variants × 2 alpha kingdoms: plantae + fungi). Animals + hybrid use procedural placeholders in alpha; commission as a second wave once Devonian content lands.

(Filename note: this file is named `COMMISSION_KINGDOM_ICONS.md` for continuity; the content is cluster sprites, not icons. May be renamed post-alpha.)

---

## Format spec

- **Native size**: **48 × 48 px PNG, square**, transparent background.
- **Sprite content**: **a few small organisms scattered within the tile area** — not a single silhouette filling the tile, not a centered focal icon. Top-down view of a patch of ground with N small plants/mushrooms on it. The biome substrate (handled by engine) shows through the gaps between organisms.
- **Style**: top-down pixel art, chunky retro, naturalist mythic-scientific. Matches `docs/VISUAL_DIRECTION.md`. No anthropomorphism, no fantasy magic, no neon, no UI candy.
- **Color**: deliver each variant **monochrome white-on-transparent** (or with a single base color). The engine multiplies the texture by `species.tile_marker_color` at draw time — so the artist authors VALUE/SHAPE only; color tinting happens in code. One PNG covers N species per kingdom.
- **Anti-aliasing OFF**: hard pixel edges only.
- **Margin**: leave at least **2 px transparent border** on all sides of the 48×48 frame so the biome shows at tile edges in EVERY variant — including mature.
- **Delivery**: one PNG per (kingdom, density) variant. Filenames: `<kingdom_id>_01.png` (pioneer) through `<kingdom_id>_04.png` (mature). Drop into `assets/art/kingdoms/`. Numeric ordering keeps the assets sorted in increasing density when listed.

---

## Density variant spec (the key authoring constraint)

Per kingdom, deliver **4 PNGs** showing the same kingdom organisms at progressively denser cluster compositions. The same organism style (same fern shape, same mushroom shape) repeats across variants; only the count and arrangement change.

| Variant | Org count | Coverage of inner 44 × 44 area | Reads as |
|---|---|---|---|
| **Pioneer** | 1-2 organisms | ~15% | "Just placed, getting established. Biome dominates the tile." |
| **Establishing** | 3-4 organisms | ~30% | "Taking hold. Beginning to spread." |
| **Established** | 5-6 organisms | ~50% | "Settled colony. Recognizable patch." |
| **Mature** | Larger-scale feature (small grove pattern, dense field, dominant central organism) | ~70-80% | "Defining feature of the area. Fully developed." |

**Critical**: each variant must read as the SAME kingdom — viewer should instantly see "this is a plantae tile" and then notice "this one's denser." Do not change silhouette style across density variants.

---

## Per-kingdom direction

### Plantae — 4 variants

Top-down view of a patch of rooted, upward-growing organisms. Each organism a small tuft, blade, sprout, or fern frond. Verticality conveyed even from above via taper, tip directions, stem hint.

- **`plantae_pioneer`**: 1-2 small sprouts, ~6-8 px tall each, scattered. Lots of bare substrate showing through.
- **`plantae_establishing`**: 3-4 sprouts/tufts, ~6-10 px tall each, loosely clustered, biome still very visible.
- **`plantae_established`**: 5-6 organisms — mix of small sprouts and larger tufts — taking ~50% of the inner area. Reads as "fern patch."
- **`plantae_mature`**: dense cluster suggesting a small grove. Could be 2-3 larger central organisms with smaller surrounding ones, or a unified canopy pattern with hints of structure. Reads as "this tile is now a grove."

### Fungi — 4 variants

Top-down view of decomposer life. Each organism a small cap-on-stem, shelf-fungus bracket, or mycelial radial. Rounder, cap-based silhouettes — distinguishable from plantae's vertical taper.

- **`fungi_pioneer`**: 1-2 small caps, ~5-7 px across, scattered. Mostly substrate.
- **`fungi_establishing`**: 3-4 caps or brackets, loosely clustered, biome still very visible.
- **`fungi_established`**: 5-6 organisms — mix of cap sizes, possibly a hint of mycelial threads connecting them — taking ~50% of inner area. Reads as "mushroom patch."
- **`fungi_mature`**: dense cluster. Could be a fairy-ring-style arrangement of larger caps, heavy mycelial sprawl with prominent fruiting bodies, or shelf-fungus dominated arrangement. Reads as "fungal colony."

---

## What's NOT in this brief

- **Symbiosis cohabitation art**: in the 2026-05-22 visual model, symbiosis is an adjacency interaction between two adjacent tiles, NOT cohabitation in one tile. Symbiosis markers (corner gold dot + edge highlight) are drawn procedurally by the engine. No commission needed.
- **Hybrid-pair fusion sprite** (Lichen, Coral when added): true-cohabitant hybrid species get a single fused sprite that renders on both partner tiles. Commission as a separate small brief when Lichen visual is the focus.
- **Per-species art**: still deferred per `docs/COMMISSION_SPECIES.md`. The 8 PNGs from this brief cover all plantae and fungi species via color tinting in code.

---

## Tinting test

Every kingdom variant PNG will be code-tinted by N different `tile_marker_color` values:

- Plantae variants tinted with: `#73c74d` Pioneer Stem, `#8c802d` Bramble, `#338c40` Tree-Fern, `#669933` Vine, `#33a68c` Cyanobacteria
- Fungi variants tinted with: `#7f59b8` Mycelium, `#a566c0` Mycorrhizal, `#8c4d73` Wood-Rot, `#d9d98c` Cryo-Lichen, `#4d338c` Vent Archaeon, `#9966cc` Spore Drift

Test: render each white variant over each tint color and confirm the silhouette still reads at 48 px — no detail lost when tinted dark, no detail blown out when tinted bright. Test at 1.0 zoom on a 360 × 640 phone viewport.

---

## Reference attachments

Hand the artist (or paste into the AI prompt):

1. `docs/VISUAL_DIRECTION.md` — especially "Locked long-term canvas (2026-05-22)" and the cluster-in-biome rendering section
2. `builds/screenshots/map.png` — atmosphere reference (moody dither substrate)
3. `builds/screenshots/making_biomes_and_species_visible.png` — the layered model these clusters fit into
4. `builds/screenshots/final.png` — silhouette specificity reference (look at the kingdom-row clusters, not individual species)
