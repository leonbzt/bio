# Brief 07 — Per-era visual identity (tile + background tint, biome textures)

**Suggested agent**: ChatGPT 5.2. Route diff to Claude — mobile readability.

Read first:
1. `scripts/entities/tile_grid.gd` — post-Phase-13 rendering (base color + animal border).
2. `scenes/world/world.tscn` — find/add background ColorRect.
3. `scripts/autoloads/era_system.gd` — `get_current_era().tint_color`.
4. `data/eras/cryogenian.tres` + `devonian.tres`.
5. `docs/briefs/phase_13_paused/08_per_era_visual_identity.md` — direct source.

## Goal

1. Set era `tint_color` values.
2. Apply per-era tint to TileGrid + background.
3. Add placeholder atlas tiles for the 3 new biomes (tundra/mineral_vent/swamp).
4. Map biome ids → atlas slots in TileGrid base layer.

## Tint values

Edit `data/eras/cryogenian.tres`:
```
tint_color = Color(0.85, 0.92, 1.0, 1.0)
```

Edit `data/eras/devonian.tres`:
```
tint_color = Color(1.0, 0.97, 0.88, 1.0)
```

## TileGrid tint

`scripts/entities/tile_grid.gd`:

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

## Background tint

Add (or extend) a fullscreen `ColorRect` named `EraBackgroundTint` as the first child of the world root. New script:

```gdscript
extends ColorRect

@export var base_color: Color = Color(0.07, 0.07, 0.08, 1.0)

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
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
    color = base_color.lerp(era.tint_color, 0.25)
```

25% blend keeps tile fills readable on tinted background.

## New biome atlas tiles

`scripts/entities/tile_grid.gd._build_atlas_texture` currently builds N hardcoded atlas slots. Extend with 3 new slots:

```gdscript
const ATLAS_BIOME_TUNDRA: Vector2i = Vector2i(X, 0)
const ATLAS_BIOME_MINERAL_VENT: Vector2i = Vector2i(X+1, 0)
const ATLAS_BIOME_SWAMP: Vector2i = Vector2i(X+2, 0)
```

Where X = current atlas width / TILE_SIZE. Extend atlas texture by `TILE_SIZE * 3` and fill:

- **Tundra**: pale icy gray-blue body `Color8(0xc8, 0xd8, 0xe5)`, border `Color8(0xa0, 0xb5, 0xc8)`.
- **Mineral vent**: dark gray body `Color8(0x3a, 0x3a, 0x40)`, sparse orange flecks `Color8(0xe8, 0x7e, 0x3a)` (checkerboard or modulo-5 pattern).
- **Swamp**: dull olive body `Color8(0x4f, 0x5a, 0x36)`, border `Color8(0x37, 0x42, 0x25)`.

In `_build_tileset`, add `atlas.create_tile(ATLAS_BIOME_*)` for each.

## Base layer biome lookup

In TileGrid, add:

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

In `_populate` (or wherever base tiles are painted), look up biome at each coord via `NutrientSystem.get_biome_at(coord)` and pick the atlas. Legacy biomes use `ATLAS_BASE`; new biomes use their dedicated atlas slot.

If `NutrientSystem` returns null (early load), fall back to `ATLAS_BASE`.

## Mobile readability sanity

On portrait 360×640 verify:
- Owned plantae tile (green) still readable on tundra-tinted Cryogenian background.
- Owned fungi tile (purple) still readable on Devonian amber background.
- Animal border still visible.
- HUD text remains legible.

If any cue washes out, drop tint intensity (e.g., Cryogenian `Color(0.92, 0.96, 1.0)` instead).

## Acceptance criteria

- [ ] `cryogenian.tres` and `devonian.tres` have correct `tint_color` values.
- [ ] Cryogenian runs visibly cool blue.
- [ ] Devonian runs visibly warm amber.
- [ ] Era change updates tint immediately.
- [ ] Tundra, mineral_vent, swamp tiles render with distinct placeholder colors.
- [ ] Legacy biomes unchanged.
- [ ] Owned-tile fill + animal border still readable.

## Out of scope

- Authored sprite art (Phase 15+).
- Per-era music (Phase 15 — audio asset blocker).
- Particle effects / weather.
- Era-transition screen-wipe VFX.
- HUD recolor per era.
- Mid-run biome regeneration animation.
