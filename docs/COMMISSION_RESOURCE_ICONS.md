# Commission Brief — Resource Icons

**Status**: ready to send 2026-05-21. References `docs/VISUAL_DIRECTION.md` and `scripts/autoloads/kingdom_theme.gd` (canonical resource palette).

**Deliverable (alpha, send now)**: **5 primary HUD resource icons** (`biomass`, `nutrients`, `sunlight`, `decay`, `spores`) — those are what the HUD strip displays every run. Defer the 7 secondary + the EP star to a second wave once the alpha proves out.

Full list below is documented for completeness; pick the 5 primary now.

---

## Why we need these

Current HUD uses text-only resource labels ("Biomass: 573"). Phase D upgrade swaps to icon-chip format ("[●] 573" but with proper bitmap art instead of the Unicode glyph). The icons must:

- **Read at 16×16 px** on a 360-wide mobile HUD strip (resources displayed in a tight horizontal or vertical row).
- **Encode resource identity by shape AND color** so colorblind players can still distinguish them.
- **Match the kingdom-theme palette** so they harmonize with the rest of the HUD.

These icons appear in: HUD resource bar, evolve modal cost lines, ability tooltips, recipe book, prestige screen reward summary. They get reused everywhere.

---

## Format spec

- **Native size**: 16×16 px PNG, transparent background.
- **Optional 2x asset**: 32×32 px PNG for tooltip-sized display. If only one size, do 32×32 native and downscale cleanly to 16×16 (pixel-art with no anti-aliasing).
- **Pixel art**, chunky retro feel matching `assets/ui/fonts/PressStart2P` aesthetic.
- **Anti-aliasing OFF**: hard pixel edges only.
- **Transparent background**: icons must drop onto any HUD panel color.
- **Naming**: `<resource_id>.png`. Drop into `assets/art/resources/`.

---

## Primary resource list (8 icons)

These are the resources the player sees every run. Top priority.

| ID | Display name | Color (hex) | Shape direction |
|---|---|---|---|
| `biomass` | Biomass | `#7eba5a` warm forest green | Filled solid pixel circle, slightly dimensional (lighter top-left, darker bottom-right). The bread-and-butter resource. |
| `nutrients` | Nutrients | `#d8b858` warm gold/ochre | Diamond shape, filled, with a subtle internal highlight. Reads as "rich earth." |
| `sunlight` | Sunlight | `#88ccee` cool sky-blue | Sun/star burst — central dot with 8 short pixel-rays. Reads at-a-glance as light. |
| `decay` | Decay | `#aa7aca` dusty violet | Hollow ring (donut), suggesting a cycle / closed loop / decomposition. The fungi resource. |
| `spores` | Spores | `#7a9aba` cool blue-grey | Small dot cluster — 4-5 specks scattered in a 16×16 area, suggesting drift. |
| `protein` | Protein | `#daa85a` warm amber | Filled triangle pointing up, simple and bold. Reads as "structure / building block." |
| `lifeforce` | Lifeforce | `#c85a5a` deep red | Heart-ish or pulse-line shape. Animal kingdom's currency. Be careful — should NOT be cute / video-gamey health icon. Maybe an abstract pulse-bar or a flame-shape in red. |
| `ep` | Evolution Points | `#e8d070` bright gold | Five-pointed star, filled, slightly chunky. The prestige currency. Must feel "earned" — reuse this in the prestige screen as the reward icon. |

## Secondary resource list (7 icons) — stub tier, hidden until active

These resources exist in code but only become visible when relevant unlocks happen. Lower priority — can be commissioned in a second wave if budget is tight, but please at least lock the visual direction now.

| ID | Display name | Color (hex) | Shape direction |
|---|---|---|---|
| `pollination` | Pollination | `#b8c84a` yellow-green | Small dotted swirl, suggesting drift + intent (not random drift like spores). |
| `cellulose` | Cellulose | `#8aaa6a` muted green | Lattice/grid texture in a small square — the "structural plant" resource. |
| `chitin` | Chitin | `#9a8a6a` muted bronze | Hexagonal scale shape. Insect/arthropod structural. |
| `phosphate` | Phosphate | `#6a9aba` cool grey-blue | Cluster of 3-4 small dot-crystals, faceted. Mineral feel. |
| `blood_cohesion` | Blood Cohesion | `#c85a5a` deep red | DIFFERENT from lifeforce — same hue, but a connected-chain-link or droplet-coalescing shape. Animal kingdom advanced resource. |
| `gray_matter` | Gray Matter | `#b0b0c8` cool grey | Wrinkled lobe shape, brain-suggestion but abstract. Sentience-tier resource. Far horizon. |
| `mycelial_stability` | Mycelial Stability | `#aa7aca` violet (same as decay) | Networked node shape — small interconnected dots, fungi-network. Differentiate from `decay` by being a connected pattern vs decay's hollow ring. |

## Bonus: action ability icons (optional, defer if needed)

If budget allows, also commission icons for the active interventions. Same 16×16 format. Lower priority — text labels still work.

- `irrigate` (water drop)
- `bundle` (stacked sticks / warmth)
- `cull` (X-mark or claw)
- `quarantine` (circle-slash containment)

---

## Reference attachments

Hand the artist (or paste into the AI prompt):

1. `docs/VISUAL_DIRECTION.md` — canonical art direction
2. `scripts/autoloads/kingdom_theme.gd` — exact hex codes per resource (the `RESOURCES` dictionary is the source of truth)
3. The Unicode-glyph version of the chip ("[●] 573 biomass") that the icons will replace — visible in the current HUD
4. `builds/screenshots/swamp_biome_gpt.png` — the resource strip at the top of this mockup is the layout target

---

## Acceptance criteria

- At 16×16 on a dark HUD panel, can a stranger tell which resource is which after 2 seconds of looking? If no, the shape isn't distinctive enough.
- Does each icon retain identity when desaturated (grayscale test)? If a colorblind player sees only shape, can they still distinguish biomass from nutrients from decay?
- Do all 16 icons look like they belong to the same set (consistent line weight, style, complexity)?
- Pixel-perfect at 16×16 with no anti-aliasing? Crisp at 32×32 if upscaled?
