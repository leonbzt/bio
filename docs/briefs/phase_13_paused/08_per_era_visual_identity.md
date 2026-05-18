# Brief 08 — Per-era visual identity (tile + background tint, biome textures)

**Suggested agent**: ChatGPT 5.2. Route diff to Claude — mobile readability.

Read first:
1. `scripts/world/tile_grid.gd` — the procedural atlas is built in `_build_atlas_texture`. New biomes need entries there.
2. `scenes/world.tscn` — find the background ColorRect (or add one if absent).
3. `scripts/autoloads/era_system.gd` — `get_current_era()` provides the `tint_color`.
4. `data/eras/cryogenian.tres`, `data/eras/devonian.tres` — confirm/set `tint_color` to sensible values.
5. `scripts/data/biome_data.gd` — `tile_texture` is already there but unused; we still use the procedural atlas for v1.

## Goal

Two visible changes per era:

1. **Tile-grid tint** — apply `EraData.tint_color` as a `modulate` on the TileGrid so all tiles take on the era's hue (cool blue for Cryogenian, warm green for Devonian).
2. **Background tint** — same `tint_color` applied to a background `ColorRect` behind the world for an at-a-glance era cue.

Plus the new biomes need flat placeholder atlas entries so they render at all.

## Per-era tint values

Set these in `data/eras/*.tres`:

| Era | tint_color (R, G, B, A) | Look |
|---|---|---|
| `cryogenian` | `Color(0.85, 0.92, 1.0, 1.0)` | Cool desaturated blue-white; reads as "cold, ancient, pre-life-rich" |
| `devonian` | `Color(1.0, 0.97, 0.88, 1.0)` | Warm parchment-amber; reads as "fertile, alive, sun-warm" |

A is `1.0` because we apply via `modulate` directly — alpha isn't tinting, it's transparency. Adjust intensities if mobile testing shows tiles wash out (Devonian especially risks bleached-looking).

## Tile-grid tinting

### `scripts/world/tile_grid.gd`

Add a per-frame or per-event tint update. Two hookable moments:
- `EventBus.era_changed.connect(_on_era_changed)` (already fires from EraSystem).
- `_ready()` — apply the current era's tint immediately on world load.

```gdscript
func _ready() -> void:
    # ... existing setup ...
    EventBus.era_changed.connect(_on_era_changed)
    _apply_era_tint()

func _on_era_changed(_era_id: StringName) -> void:
    _apply_era_tint()

func _apply_era_tint() -> void:
    var era_system := _get_era_system()
    if era_system == null:
        modulate = Color(1, 1, 1, 1)
        return
    var era: EraData = era_system.get_current_era()
    if era == null:
        modulate = Color(1, 1, 1, 1)
        return
    modulate = era.tint_color

func _get_era_system() -> Node:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null:
        return null
    return tree.root.get_node_or_null("EraSystem")
```

Tinting via `modulate` is multiplicative against the source pixels, so a `tint_color` of `Color(0.85, 0.92, 1.0)` cools all the existing kingdom/biome colors without washing them out. Pure white modulate (`Color(1,1,1,1)`) = no change, which is the safe default.

## Background tinting

### `scenes/world.tscn` (or wherever the world root is)

Ensure there's a `ColorRect` named `EraBackgroundTint` behind the TileGrid, fullscreen, with mouse_filter = IGNORE. Add a script (or extend an existing one) to:

```gdscript
extends ColorRect

@export var base_color: Color = Color(0.07, 0.07, 0.08, 1.0)  # current world bg

func _ready() -> void:
    EventBus.era_changed.connect(_on_era_changed)
    _apply()

func _on_era_changed(_era_id: StringName) -> void:
    _apply()

func _apply() -> void:
    var tree := Engine.get_main_loop() as SceneTree
    var era_system := tree.root.get_node_or_null("EraSystem") if tree != null else null
    if era_system == null:
        color = base_color
        return
    var era: EraData = era_system.get_current_era()
    if era == null:
        color = base_color
        return
    # Blend the era tint into the base color at ~25% strength.
    color = base_color.lerp(era.tint_color, 0.25)
```

The 0.25 blend keeps the background dim enough that tiles read clearly (full era tint would compete with tiles for attention).

If world.tscn doesn't currently have a background ColorRect, add one. Anchor it to fill the parent (Anchor preset "Full Rect"), put it as the *first* child of the world root so it renders behind everything else.

## New biome atlas tiles

`tile_grid.gd._build_atlas_texture` currently builds 7 hard-coded tiles. Phase 13 doesn't have art assets yet for tundra/mineral_vent/swamp. For visibility, add 3 flat-color placeholder atlas tiles (same approach as the fungi/animal placeholder tiles in the existing code):

Atlas slot constants:
```gdscript
const ATLAS_BIOME_TUNDRA: Vector2i = Vector2i(7, 0)
const ATLAS_BIOME_MINERAL_VENT: Vector2i = Vector2i(8, 0)
const ATLAS_BIOME_SWAMP: Vector2i = Vector2i(9, 0)
```

In `_build_atlas_texture`, extend the atlas image width to `TILE_SIZE * 10` and fill the three new tiles:
- Tundra: pale icy gray-blue `Color8(0xc8, 0xd8, 0xe5, 255)` body, border `Color8(0xa0, 0xb5, 0xc8, 255)`.
- Mineral vent: dark gray `Color8(0x3a, 0x3a, 0x40, 255)` body with sparse orange flecks `Color8(0xe8, 0x7e, 0x3a, 255)` (modulo-based: every 5th pixel in a checkerboard pattern).
- Swamp: dull olive `Color8(0x4f, 0x5a, 0x36, 255)` body, border `Color8(0x37, 0x42, 0x25, 255)`.

These are placeholder visuals — Phase 14 swaps to authored sprites. Keep the procedural-fill pattern identical to the existing fungi/animal blocks for consistency.

Then in `_build_tileset` add the three new `atlas.create_tile(ATLAS_BIOME_*)` calls.

## Biome rendering integration

`tile_grid.gd` currently paints the base layer with `ATLAS_BASE` for everything. The biome layer needs to switch the base atlas coordinate per tile:

```gdscript
const BIOME_ATLAS_BY_ID: Dictionary[StringName, Vector2i] = {
    &"grassland": ATLAS_BASE,
    &"rich_soil": ATLAS_BASE,
    &"forest_edge": ATLAS_BASE,
    &"tundra": ATLAS_BIOME_TUNDRA,
    &"mineral_vent": ATLAS_BIOME_MINERAL_VENT,
    &"swamp": ATLAS_BIOME_SWAMP,
}
```

In `_populate` (or whatever method sets base-layer cells), look up the biome at each coord via NutrientSystem and pick the atlas coord from this map. For legacy biomes the value is `ATLAS_BASE`, so nothing changes for existing maps.

If `NutrientSystem.get_biome_at(coord)` returns null (e.g., during early load), fall back to `ATLAS_BASE`.

## Mobile readability sanity check

After tint + biome textures land, verify on portrait 360×640:
- Owned-plant tile is still clearly green (not washed to blue) on a Cryogenian tundra map.
- Owned-fungi tile is still clearly purple (not washed) on a Devonian swamp map.
- Background tint doesn't make HUD text harder to read.

If any of these fail, drop the modulate intensity (use `Color(0.92, 0.96, 1.0)` cooler instead of `0.85, 0.92, 1.0` for Cryogenian) or apply tint only to a subset of layers.

## Acceptance criteria

- [ ] `cryogenian.tres` and `devonian.tres` have explicit `tint_color` values per the table above.
- [ ] Starting any Cryogenian run, the TileGrid + background visibly take on a cool blue tint.
- [ ] Starting any Devonian run, the TileGrid + background visibly take on a warm amber tint.
- [ ] `EventBus.era_changed` retints both surfaces immediately.
- [ ] `tundra`, `mineral_vent`, `swamp` tiles render with their distinct placeholder colors.
- [ ] Biome-distinct tiles are visible on the world: a `cryo_volcanic_vent` run looks dark/orange-flecked, a `dev_inland_swamp` run looks olive.
- [ ] Owned-tile colors (plant green, fungi purple, animal amber) remain readable on both era backgrounds.
- [ ] No regression on existing biomes — grassland/rich_soil/forest_edge still render as before.

## Out of scope

- Authored sprite art for the new biomes (Phase 14).
- Per-era music swaps (Phase 14 — audio asset blocker).
- Particle effects / weather (Phase 14).
- Era-transition VFX (screen fade, particle wipe) — Phase 14.
- HUD recoloring per era. Stays neutral.
- Animated tile transitions on biome change mid-run (biomes are static for the run lifetime).
