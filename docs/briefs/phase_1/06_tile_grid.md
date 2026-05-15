# Brief 06 — Tile grid (32×48)

**Suggested agent**: ChatGPT 5.2 via Copilot.

Read `docs/ARCHITECTURE.md` section 1 (grid size lock) and section 6 (scene composition).

## Goal
Render a static 32×48 tile grid using a single placeholder tile texture. No gameplay logic yet — this is purely the display substrate that `TerritorySystem` will sit on top of in Phase 2.

## Outputs (create)
- `scenes/world/world.tscn` — root scene containing CameraRig (instance from brief 04), TileGrid, Organisms (empty Node2D), Systems (empty Node), HUDLayer (empty CanvasLayer).
- `scenes/world/tile_grid.tscn` — a `TileMapLayer` (Godot 4.3+) or `TileMap` node configured with a 16×16 placeholder tile.
- `assets/art/tiles/placeholder_tile.png` — a 16×16 PNG. Generate as a simple solid colored square with a 1px darker border. Any neutral green like `#3a5a3a`.
- `scripts/entities/tile_grid.gd` — populates all 32×48 cells with the placeholder tile in `_ready()`.

## Implementation notes
- Tile size: 16×16 pixels. World extent: 32×16 = 512 px wide, 48×16 = 768 px tall. Camera bounds (`world_min`, `world_max` on the rig) should match.
- Use `TileMapLayer.set_cell(coord, source_id, atlas_coords)` in a nested loop.
- Don't use input events on tiles yet — Phase 2 brief will add `TerritorySystem`.
- `world.tscn` autoloads are already global, so no autoload references needed in the scene tree.

## Acceptance criteria
- [ ] Launching `world.tscn` (via Play in the menu) shows a 32×48 grid filling the portrait viewport area, with the camera centered.
- [ ] Pinch-zoom and pan work via the rig.
- [ ] No errors in the output.
- [ ] No gameplay scripts attached — Systems node is empty.

## Out of scope
- Colonization, organism rendering, HUD content. Later briefs.
