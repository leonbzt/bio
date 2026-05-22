# Visual Migration Plan (2026-05-22 lock execution)

Concrete plan for migrating Bio's codebase from the prior 2026-05-21 96-px focal-icon visual lock to the 2026-05-22 cluster-in-biome lock. Source of truth for the lock itself: `docs/VISUAL_DIRECTION.md` ("Locked long-term canvas — 2026-05-22"). See `docs/DEV_GUARDRAILS.md` for the practices that constrain how this work is done.

**Phase naming convention**: this plan uses **VM-A / VM-B / VM-C** ("Visual Migration") to disambiguate from `docs/GAMEPLAY_DESIGN.md` which uses unqualified "Phase A/B/C" for its gameplay-design implementation phases. The two plans are largely orthogonal — VM phases concern tile rendering and data shape; Gameplay phases concern Hero, Pressure, and run mechanics.

---

## The vision in one paragraph

Each tile renders as **a few small organisms scattered within the biome substrate** — sparse at first, dense once neighbors arrive. The biome is always visible through gaps. Symbiosis is an interaction between two *adjacent* tiles (gold corner dot + edge highlight), not stacked icons in one tile. Cluster density scales with same-kingdom neighbor count: isolated tiles look like "just placed"; tiles surrounded by same kingdom develop into groves, mushroom colonies, or larger ecological features. The "growing together" feel emerges from clustering, not from auto-tile geometry. TILE_SIZE 48 px native, single species per tile. The cellular-automata growth overlay (β) is explicitly off the roadmap.

---

## Three macro phases

```
VM-A. Foundation       (engine groundwork, no art needed)
        ↓
VM-B. Visual prototype (placeholders to validate cluster-in-biome before commissioning)
        ↓
VM-C. Production       (commission art → drop in → polish → pre-alpha audit)
```

VM-B is the gate. Do not send commissions until VM-B feels right with procedural placeholders.

---

## VM-A — Foundation (~3-4 days engineering)

### VM-A1. Save versioning + migration framework — **ALREADY IN PLACE** (verified 2026-05-22)

`scripts/autoloads/save_system.gd` already implements a full save-versioning pipeline:
- `SAVE_VERSION = 17` (constant, currently)
- `migrate(old, from_version)` cascades v0 → v17 through ordered blocks
- Per-version helpers `_migrate_v11_to_v12()` through `_migrate_v16_to_v17()` for the multi-step ones
- `_repair_species_unlocked()` runs on every load as a defensive backfill (the pattern for schema drift fixes)
- `_try_load()` reads `save_version`, calls `migrate()`, sets to current — clean
- Backup chain (`save.json.bak`, `save.json.tmp`) for crash safety

**Status**: VM-A1 needs no engineering work. The pattern is established and proven. The upcoming VM-A2 single-species-per-tile change will become save_version **18**, following the existing pattern (new `_migrate_v17_to_v18()` helper added to the cascading chain).

**What was originally planned for VM-A1** (no longer needed):
- Add `save_version` field — already exists
- Migration chain — already exists
- Start version + bump pattern — already established

This means VM-A2 can begin immediately without prerequisite engineering.

### VM-A2. Single species per tile — data model migration (~1-2 days)

**Current data shape** (per `save_system.gd` v17): each tile in `run.tiles` is
```
{
  "coord": [x, y],
  "occupants": { "plantae": "pioneer_grass", "fungi": "mycelium_thread", ... },  // Dictionary keyed by kingdom_id
  "data": { ... }
}
```
A tile can currently hold one species per kingdom (up to 3 co-occupants: plantae + fungi + animals).

**Target data shape** (single species per tile):
```
{
  "coord": [x, y],
  "species_id": "pioneer_grass",  // scalar — single occupant
  "data": { ... }
}
```

**Migration `v17 → v18`** — implement as `_migrate_v17_to_v18(save)` in `save_system.gd` following the established pattern:
- For each tile with `occupants` dict: pick the dominant occupant using a fixed kingdom precedence (suggest **plantae > fungi > animals**, but the rule must be explicit and documented)
- Discard the others, log a warning per discarded entry, update `species_tile_counts` to match
- Set `species_id` scalar, remove `occupants` dict
- Bump `SAVE_VERSION = 18`

**Code changes** (paired with migration):
- `scripts/systems/territory_system.gd`: occupant storage `Dictionary[kingdom_id, species_id]` per coord → single `species_id`
  - `peek_occupants` → `peek_occupant`
  - `place_occupant` becomes idempotent replace, not per-kingdom slot
  - Indices `_species_to_coords`, `_kingdom_to_coords` simplify (no multi-membership)
- `scripts/systems/growth_system.gd`: remove per-occupant iteration, use single lookup
- `scripts/systems/structure_registry.gd`: pattern detection still works (one occupant per coord is a subset of the prior arity)
- `scripts/systems/nutrient_system.gd`: verify still correct after model change

**Test gate**: load an existing pre-migration (v17) save, verify game plays without errors, verify no occupants are missing where they shouldn't be (per the precedence rule).

### VM-A3. TILE_SIZE migration 96 → 48 (~½ day)

- `scripts/entities/tile_grid.gd`: `TILE_SIZE = 48`, sprite slot = 48 (matches tile), drop the focal-icon constants
- `scripts/entities/camera_rig.gd`: `world_max = Vector2(1536, 2304)`, default zoom 1.0, snap pinch to {0.5, 1.0, 2.0}
- `scenes/world/world.tscn`: CameraRig position (768, 1152), world_max attribute
- `scripts/systems/tile_input_router.gd`: verify coord math still works against new tile size
- `scripts/systems/structure_registry.gd`: any pixel calcs should use `TILE_SIZE` constant — verify no hardcoded 96
- Delete or move aside the outdated 32-px focal-icon PNGs in `assets/art/kingdoms/` (`plantae.png`, `fungi.png`) — they don't fit the cluster model and will be replaced by Phase C art

**Test gate**: game renders at the new size, taps hit the right tile, camera bounds correct.

---

## VM-B — Visual prototype (~3-4 days engineering)

### VM-B1. Cluster rendering with procedural placeholders (~2 days)

- `scripts/entities/tile_grid.gd`:
  - Rename `_SpeciesIcon` → `_SpeciesCluster`
  - `_draw()` picks variant based on same-kingdom 4-neighbor count (0 / 1-2 / 3-4 / all 4)
  - 4 procedural patterns per kingdom, drawn in code with a deterministic seed per coord:
    - Plantae: 1, 3, 5, 7+ small triangle stems scattered in inner area
    - Fungi: 1, 3, 5, 7+ small circle caps scattered in inner area
  - Tinted by `species.tile_marker_color`
  - Texture cache keyed by `(kingdom, density_variant)` — ready for PNG drops in Phase C
- Engine helper: `_compute_density_variant(coord, kingdom_id) -> int 0..3` counts cardinal same-kingdom neighbors

**Test gate**: place 1, 2, 3, 4 adjacent plantae tiles and visually confirm density steps up across the cluster.

### VM-B2. Tile-edge tint (~½ day)

- `scripts/entities/tile_grid.gd` `_draw()`: 1-2 px darker biome-shade band on tile inner perimeter
- Subtle — should read as "grid clarity" not "grid lines"

### VM-B3. Adjacency-symbiosis rendering (~1 day)

- Detection: per tile, check 4 cardinal neighbors for compatible-kingdom partner species (existing symbiosis pair data in `data/species/`)
- Render per partnered direction:
  - 4 × 4 px gold dot in tile corner facing the partner
  - Gold tint on the shared edge pixels
- Remove the prior dual-icon + ring code from the cohabitation symbiosis model
- Hybrid-pair fusion sprite (Lichen, Coral): defer until real species art exists — placeholder is fine

**Test gate**: place a plantae + compatible fungi adjacent, see gold corner dots + edge highlight on both.

### VM-B4. Validate the visual model (~1-2 days play)

- Play through Cryogenian + Devonian content with placeholders
- Verify: clustering progression feels rewarding, single-species feels strategic (not limiting), adjacency symbiosis reads clearly, performance fine at 1.0 default zoom
- Tune neighbor thresholds if needed
- **Sit with it 2-3 days** before authorizing commissions — visual decisions made under fatigue tend to be wrong

---

## VM-C — Production (gated on Phase B validating)

### VM-C1. Commission kingdom cluster art (external turnaround)

- Send `docs/COMMISSION_KINGDOM_ICONS.md` — 8 PNGs (4 density × plantae+fungi) at 48 × 48
- AI-gen iteration: expect 5-15 generations per density variant for consistency
- Drop into `assets/art/kingdoms/clusters/`, verify they read in-engine
- Procedural placeholders remain as fallback if a PNG is missing

### VM-C2. Commission structure art (external turnaround)

- Send updated `docs/COMMISSION_STRUCTURES.md` — 4 structures at 48 px per tile (Fairy Ring 144 × 144, Old-Growth 144 × 192, Mycorrhizal Hub 144 × 144, Decay Pit 96 × 96)
- Wire `_StructureFusionOverlay` to use real PNGs via `draw_texture`
- Procedural overlays remain as fallback

### VM-C3. Phase D HUD polish (can parallelize after Phase B validates)

Per existing `docs/VISUAL_DIRECTION.md` Phase D plan: D1 dither backgrounds, D2 glow lines, D4 biome legend chip restyle, D5 structure banner restyle, D6 evolve modal restyle, D7 onboarding overlay polish. ~3-5 days total.

### VM-C4. Pre-alpha audit (~1-2 days)

Per `docs/DEV_GUARDRAILS.md` open commitments:
- Touch-target audit (44 px minimum, G4)
- Shared palette consolidation in `scripts/visual/palette.gd` (G7)
- Onboarding drip-feed plan beyond the 7 initial tips (G8)
- Idle / offline-progress hook surfaced on return (G9)
- Write `docs/ALPHA_GATE.md` documenting MUST-ship vs WILL-cut (G2)

---

## File-by-file change summary

| File | Phase | Change |
|---|---|---|
| `scripts/autoloads/save_system.gd` | VM-A2 | Add `_migrate_v17_to_v18` (bumps SAVE_VERSION to 18) |
| `scripts/systems/territory_system.gd` | VM-A2 | Single occupant storage |
| `scripts/systems/growth_system.gd` | VM-A2 | Single-occupant iteration |
| `scripts/systems/nutrient_system.gd` | VM-A2 | Verify single-occupant compat |
| `scripts/systems/structure_registry.gd` | VM-A2, VM-A3 | Single-occupant pattern detection; `TILE_SIZE` cleanup |
| `scripts/systems/tile_input_router.gd` | VM-A3 | Verify against TILE_SIZE 48 |
| `scripts/entities/camera_rig.gd` | VM-A3 | world_max 1536 × 2304; snap zoom; default 1.0 |
| `scenes/world/world.tscn` | VM-A3 | Camera position + world_max |
| `scripts/entities/tile_grid.gd` | VM-A3, VM-B1-B3 | TILE_SIZE 48, cluster rendering, edge tint, adjacency symbiosis |
| `assets/art/kingdoms/plantae.png`, `fungi.png` | VM-A3 | Delete / move aside (outdated focal icons) |
| `assets/art/kingdoms/clusters/*` | VM-C1 | New cluster PNGs (8 total alpha) |
| `assets/art/structures/*` | VM-C2 | New structure PNGs at 48-px-per-tile dims |
| `scripts/visual/palette.gd` | VM-C4 | New — shared color palette |
| `docs/ALPHA_GATE.md` | VM-C4 | New — alpha scope lock |

---

## Recommended starting point

**VM-A2 (single species per tile, data + migration).** VM-A1 is already in place (save versioning exists at v17). The actual first code work is the `_migrate_v17_to_v18()` migration + the territory/growth/structure system updates. VM-B1 is the first "shows up visually" step — that's the morale checkpoint.

---

## What this plan does NOT do

- Preserve hooks for β (CA growth overlay) — explicitly off, see `DEV_GUARDRAILS.md` G3
- Address hex grid (deferred indefinitely)
- Address layer toggles (defer to post-alpha)
- Commission per-species art (defer per `COMMISSION_SPECIES.md`)
- Animals + hybrid kingdom cluster art (second wave commission, after alpha proves Devonian content)

---

## Cross-references

- Visual canvas lock: `docs/VISUAL_DIRECTION.md` → "Locked long-term canvas (2026-05-22)"
- Practices and pitfalls: `docs/DEV_GUARDRAILS.md`
- Commission specs: `docs/COMMISSION_KINGDOM_ICONS.md`, `docs/COMMISSION_STRUCTURES.md`, `docs/COMMISSION_SPECIES.md`
- Existing phase D polish plan: `docs/VISUAL_DIRECTION.md` → "Phase D — HUD restyle"
