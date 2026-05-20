# Brief 00 — Phase 15b entry (spatial discovery + structures starter)

**Suggested agent**: do this yourself.

## Pre-flight
- [ ] Phase 15a smoke-tested (multipliers + maturation + cost scaling in place).
- [ ] Save at `save_version: 15`.

## What Phase 15b is

The "I architect an ecosystem and stumble upon emergent structures" layer. Three additions stack to produce that feel:

1. **Fog of war** — tiles start hidden; colonizing reveals a 4×4 area. Growth becomes discovery, not just placement.
2. **Permanent rock obstacles** — ~5% of map tiles are impassable rocks (deterministic from `run_seed`). Adds spatial puzzle: you grow around them.
3. **Structures starter set** — every N ticks the engine scans owned tiles for known patterns. Matched patterns get *promoted* into a named structure with a glow, name banner, and a strong mechanical bonus.

Plus the supporting UI:
4. **Recipe book** — small HUD panel listing known structures. Each entry shows the pattern + bonus (if discovered) or `???` (silhouette + hint).
5. **Fog-aware biome legend + species picker** — only show biomes the player has revealed; species filter respects what's visible.

## Decisions locked

From 2026-05-20 conversation:
1. **Fog**: per-run reveal (resets on prestige), 4×4 reveal radius on colonization.
2. **Obstacles**: rocks only for v1, ~5% of map, deterministic from `run_seed`. Conditional + destructible obstacles → Phase 16+.
3. **Structures**: small starter set, 4 recipes. Detection emergent (no "craft" button) — structures form *as you place tiles* and the engine recognizes them.
4. **Recipe book**: Minecraft-style log, displayed but compact. Undiscovered = silhouette + hint.
5. **Starter recipes**: Mycorrhizal Hub, Old-Growth Stand, Fairy Ring, Decay Pit.
6. **Structure bonus** persists while pattern is intact. Removing any constituent tile reverts the structure.

## Contracts landing in Phase 15b

- **Save schema v15 → v16**:
  - `run.fog_revealed: Array[String]` — list of revealed `"x,y"` coords (per-run)
  - `run.obstacles: Array[String]` — list of impassable `"x,y"` coords (generated from seed)
  - `run.active_structures: Array[Dictionary]` — `[{id, anchor_coord, tile_coords[]}]`
  - `meta.structures_discovered: Array[String]` — structure ids ever discovered (for recipe book)
- **`StructureData` resource** (new): `id, display_name, description, pattern, bonus_handler_id`
- **`StructureRegistry`** (new autoload or system child): scans periodically, manages active structures, applies bonuses
- **`FogSystem`** (new system child): tracks revealed coords, exposes `is_revealed(coord)`
- **`ObstacleSystem`** (new system child): generates rocks at run start, exposes `is_obstacle(coord)`
- **`TileGrid`** renders fog overlay + rock tiles + structure halos
- **`ColonizationRulesRegistry`** rejects placement on obstacles + on unrevealed tiles
- **New scenes**: `recipe_book.tscn`, `structure_banner.tscn`

## Brief routing

| # | Brief | Agent | Diff review |
|---|---|---|---|
| 00 | This file | — | — |
| 01 | Save v15 → v16 migration | ChatGPT 5.2 | Claude |
| 02 | Fog of war (system + render) | ChatGPT 5.2 | **Claude** (perf) |
| 03 | Rock obstacles (deterministic generation + render) | ChatGPT 5.2 | Claude |
| 04 | Biome legend + species picker respect fog | ChatGPT 5.2 | Claude |
| 05 | Structure pattern detector (scan + match + promote) | ChatGPT 5.2 | **Claude** (algorithm) |
| 06 | Recipe book UI | ChatGPT 5.2 | Claude |
| 07 | 4 starter structures + bonus handlers | Kilo (data) + ChatGPT (handlers) | Claude (balance) |
| 08 | Phase 15b smoke test | you on device | — |

## Order of work

1. **01** save migration.
2. **03** obstacles before **02** fog (fog reveals obstacles too).
3. **02** fog of war.
4. **04** UI fog awareness.
5. **05** structure detector framework.
6. **07** starter structures (data + handlers).
7. **06** recipe book UI (visualizes 05+07).
8. **08** smoke test.

## Exit criteria

- A fresh run starts with map mostly dark; only the area around the starting tile is visible.
- ~5% of tiles are rocks; you cannot colonize them.
- Placing a tile reveals a 4×4 area around it.
- Building a 3×3 fungi cluster with ≥4 plantae neighbors triggers a "Mycorrhizal Hub" structure: visual halo + name banner + bonus applies.
- Removing a tile from a structure: structure reverts (halo + bonus gone).
- Recipe book HUD entry opens a panel showing 4 entries, ones you've discovered fully visible.
- Save v15 → v16 lossless.

## Out of scope

- Conditional obstacles (water, ice needing specific species) — Phase 16+.
- Destructible obstacles (spend resources to break) — Phase 16+.
- 3-component recipe structures (Coral, Termite Mound) — Phase 15+ when those species exist.
- Structure-vs-structure interaction (e.g., Mycorrhizal Hub linking two Old-Growth Stands) — Phase 17+.
- Animated structure formation (Phase 16+).
- Fog dissipation animation (snap-reveal is fine for v1).
- Multi-tap on fog tiles to "scout" without colonizing — future ability.
