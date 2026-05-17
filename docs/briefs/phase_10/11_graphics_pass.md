# Brief 11 — Graphics pass: niche icons, animal sprites, Lichen visual, stub resource icons

**Suggested agent**: Kilo for asset wiring + tile variant registration. Hand-authored sprites OK at placeholder quality. Route diff to Claude only if scene structure changes substantially.

Read first:
1. `scripts/entities/tile_grid.gd` — existing tile variant registration (Phase 8 added parasite + mycorrhizal variants).
2. `scenes/ui/hud.tscn` — niche badge location, resource label icons.
3. `data/niches/*.tres` — `tile_variant` field values.

## Goal

Light visual pass to make Phase 10's new content distinguishable at a glance:
1. **Niche icons** for Lichen, Herbivore, Predator (shown in HUD niche badge).
2. **Animal tile variants** for Herbivore + Predator (the anchored animal tiles).
3. **Lichen visual** — a teal-tinted overlay where Lichen tiles exist (both layers).
4. **Stub resource icons** — 6 small icons next to the resource labels.

Placeholder quality is acceptable. Goal is *distinct enough to read*, not polished art. Final art replaces these in a Tier 2 polish window.

## Concrete asset deliverables

### Niche icons (3 new, in `assets/ui/niches/`)

| File | Description | Style |
|---|---|---|
| `lichen.png` | Teal + green blob with a fungal undertone | 32×32, transparent BG |
| `herbivore.png` | Stylized cervine silhouette | 32×32 |
| `predator.png` | Stylized canid/feline silhouette | 32×32 |

Wire via the existing niche-badge code (Phase 8). The badge already reads `niche.icon` or a similar field — verify. If `NicheData` lacks an `icon: Texture2D` field, add one:

```gdscript
@export var icon: Texture2D = null
```

(Schema add. Add this in brief 11 — not brief 02 — because it's content-related, not contract-locking.)

Then set the icon in each niche `.tres`:
```
icon = ExtResource("<icon_uid>")
```

### Animal tile variants (in `assets/tiles/animals/`)

| File | Variant id | Used by |
|---|---|---|
| `herbivore.png` | `&"animals_herbivore"` | herbivore.tres `tile_variant` |
| `predator.png` | `&"animals_predator"` | predator.tres `tile_variant` |

Each 32×48 (matching grid). Color: amber/tan for herbivore, deep red-brown for predator. Simple silhouette on top of base ground.

Register in `tile_grid.gd` alongside existing variants:
```gdscript
const TILE_VARIANTS: Dictionary = {
    # ... existing ...
    &"animals_herbivore": preload("res://assets/tiles/animals/herbivore.png"),
    &"animals_predator": preload("res://assets/tiles/animals/predator.png"),
}
```

(Or the equivalent of whatever existing variant-registry pattern is in use.)

### Lichen visual

Lichen is a 2-layer species — a Lichen run renders fungi tiles (subsurface, violet) + plant tiles (surface, green) at the same coords. No new tile variant needed; the existing variants stack naturally because they're on different layers.

**Optional polish**: when both layers are populated at the same coord (i.e., a bonded Lichen tile), tint the entire cell with a faint teal overlay (alpha 0.2) drawn between the two layers. Skip if it conflicts with the mycorrhizal-bond teal tint (brief 07).

### Stub resource icons (6 new, in `assets/ui/resources/`)

| File | Resource | Symbol |
|---|---|---|
| `protein.png` | Protein | Spiral (DNA/molecule allusion) |
| `cellulose.png` | Cellulose | Hexagonal pattern (cell-wall structure) |
| `chitin.png` | Chitin | Cross-hatch / scale pattern |
| `phosphate.png` | Phosphate | Crystalline triangle cluster |
| `lifeforce.png` | Lifeforce | Glowing droplet / wisp |
| `pollination.png` | Pollination | Stylized pollen burst |

Each 16×16. Render alongside the resource label text.

Existing 5 resources should also have icons for consistency — if they don't yet, add stubs in the same style. Out of scope for this brief if it's a big refactor; flag as a follow-up.

### `unlock_lichen` evolution-tree node visual

The evolution-tree canvas (Phase 9 brief 05) renders nodes as colored rectangles based on `wing`. The `unlock_symbiosis` (now "Lichen Heritage") node has `wing = &"hybrid"`. No new asset needed; the teal wing color already applies.

## Implementation notes

- All sprites at **placeholder quality** — pixel art or simple shapes, not painterly. The goal is to ship a recognizable visual; replacement is planned for Tier 2 polish (Phase 13's "Ecosystem-specific biomes + graphics" already includes a graphics pass).
- Kilo can generate the icons from text prompts ("32×32 stylized silhouette of a cervine on transparent BG, simple pixel art"). Review for visual coherence with existing assets.
- Wire only — no algorithmic changes. If a scene reference is broken, fix the reference (not the algorithm).

## Acceptance criteria
- [ ] 3 niche icons exist, wired into respective `.tres` files, visible in HUD when each niche is active.
- [ ] 2 animal tile variants exist, registered in `tile_grid.gd`, visible when animals are placed.
- [ ] Lichen runs visually distinct (both layers visible; optional teal overlay if implemented).
- [ ] 6 stub resource icons exist, visible alongside resource labels in HUD.
- [ ] No regressions in existing tile/niche visuals.

## Out of scope
- Polished art (Tier 2 polish window).
- Resource icon refresh for existing 5 resources (separate concern).
- Animations on tile transitions (Tier 3 polish).
- Per-species sprite differentiation within a niche (Phase 14+ when multiple species per niche exist).
- Ability icons (Phase 11 abilities ship without icons; HUD ability bar is text-only).
