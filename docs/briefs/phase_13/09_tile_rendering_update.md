# Brief 09 — Tile rendering update (base color + animal border)

**Suggested agent**: ChatGPT 5.2. Route diff to Claude — mobile readability.

Read first:
1. `scripts/world/tile_grid.gd` — current 3-layer TileMap + procedural atlas (7 hardcoded slots: BASE, PLANTAE, FUNGI, PARASITE_PLANTAE, MYCORRHIZAL_FUNGI, ANIMAL_HERBIVORE, ANIMAL_PREDATOR).
2. Brief 04 — `TerritorySystem.add_occupant` triggers `_tile_grid.set_occupant(coord, kingdom_id, species_id)`.
3. `docs/SPECIES_MODEL.md` §Rendering — target rules.

## Goal

Replace the 7-hardcoded-atlas-slot rendering with a species-data-driven approach: plantae/fungi share base tile color (blended for both); animals render as a 2px border.

## New TileGrid API

```gdscript
# Replaces set_surface_owner / set_subsurface_owner.
# kingdom_id ∈ {&"plantae", &"fungi", &"animals"} (extensible).
func set_occupant(coord: Vector2i, kingdom_id: StringName, species_id: StringName) -> void
func clear_occupant(coord: Vector2i, kingdom_id: StringName) -> void
func clear_all_occupants(coord: Vector2i) -> void
```

Old `set_surface_owner` / `set_subsurface_owner` stay as shims (call `set_occupant` with the kingdom inferred from the previous semantics).

## Rendering rules

```gdscript
const KINGDOM_LAYER_FILL: int = 1     # plantae+fungi blend lives here
const KINGDOM_LAYER_BORDER: int = 2   # animal border

# Per-tile bookkeeping for the renderer.
var _tile_occupants: Dictionary[Vector2i, Dictionary] = {}   # coord → {kingdom_id → species_id}

func set_occupant(coord: Vector2i, kingdom_id: StringName, species_id: StringName) -> void:
    var occ: Dictionary = _tile_occupants.get(coord, {})
    occ[kingdom_id] = species_id
    _tile_occupants[coord] = occ
    _repaint_tile(coord)

func clear_occupant(coord: Vector2i, kingdom_id: StringName) -> void:
    if not _tile_occupants.has(coord):
        return
    var occ: Dictionary = _tile_occupants[coord]
    occ.erase(kingdom_id)
    if occ.is_empty():
        _tile_occupants.erase(coord)
    _repaint_tile(coord)

func _repaint_tile(coord: Vector2i) -> void:
    var occ: Dictionary = _tile_occupants.get(coord, {})
    _paint_fill_layer(coord, occ)
    _paint_border_layer(coord, occ)


func _paint_fill_layer(coord: Vector2i, occ: Dictionary) -> void:
    var plant_id: StringName = occ.get(&"plantae", &"")
    var fungi_id: StringName = occ.get(&"fungi", &"")
    if plant_id == &"" and fungi_id == &"":
        set_cell(KINGDOM_LAYER_FILL, coord, -1)
        return
    var plant_color: Color = _species_color(plant_id)
    var fungi_color: Color = _species_color(fungi_id)
    var fill_color: Color
    if plant_id != &"" and fungi_id != &"":
        # Blend → warm yellow-green (the symbiosis cue).
        fill_color = plant_color.lerp(fungi_color, 0.5)
        # Boost saturation a touch so the blend reads as distinct, not muddy.
        fill_color = fill_color.lightened(0.05)
    elif plant_id != &"":
        fill_color = plant_color
    else:
        fill_color = fungi_color
    set_cell(KINGDOM_LAYER_FILL, coord, SOURCE_ID, ATLAS_FILL)
    set_layer_modulate(KINGDOM_LAYER_FILL, fill_color)   # if per-cell modulate not supported,
                                                          # use a per-tile sprite child instead


func _paint_border_layer(coord: Vector2i, occ: Dictionary) -> void:
    var animal_id: StringName = occ.get(&"animals", &"")
    if animal_id == &"":
        set_cell(KINGDOM_LAYER_BORDER, coord, -1)
        return
    var border_color: Color = _species_color(animal_id)
    set_cell(KINGDOM_LAYER_BORDER, coord, SOURCE_ID, ATLAS_BORDER)
    set_layer_modulate(KINGDOM_LAYER_BORDER, border_color)


func _species_color(species_id: StringName) -> Color:
    if species_id == &"":
        return Color(1, 1, 1, 1)
    var sp: SpeciesData = _species_lookup(species_id)
    if sp == null:
        return Color(1, 1, 1, 1)
    return sp.tile_marker_color
```

## Atlas additions

Add two new atlas slots:

```gdscript
const ATLAS_FILL: Vector2i = Vector2i(7, 0)     # solid filled square, white (modulated per-tile)
const ATLAS_BORDER: Vector2i = Vector2i(8, 0)   # 2px-thick hollow border, transparent interior
```

In `_build_atlas_texture`:
- Extend atlas image width to `TILE_SIZE * 9`.
- `ATLAS_FILL` (slot 7): fill the cell with solid white. Per-tile `set_layer_modulate` (or per-cell tinting via the TileMap's custom-data feature) gives the actual color.
- `ATLAS_BORDER` (slot 8): draw a 2px border (white) with transparent interior. Same modulate trick gives the per-animal color.

The legacy slots (PLANTAE, FUNGI, PARASITE_PLANTAE, etc.) become unused after the migration — kept in the atlas for backward-compat during the brief; remove in Phase 14 cleanup.

## Per-cell modulate caveat

Godot 4's TileMap doesn't support per-cell modulate on built-in cells. Two implementation options:

**Option A — Per-cell custom data + shader.** Add a `custom_data_layers` definition to the TileSet with a `Color` field; write a small shader on the TileMap layer that reads `CUSTOM0` and multiplies into `COLOR`. Cleanest, scales.

**Option B — Sprite2D children.** For each occupied tile, instantiate a `Sprite2D` child with the modulate set per-species. Heavier on the scene tree but simpler to implement.

For the migration phase, **start with Option B** (faster to get behavior parity); Phase 14 polish can migrate to Option A for performance if profiling shows draw-call pressure. With a 32×48 grid (max 1536 tiles), Option B sprite children are well within budget on mid-range Android devices.

Implementation hint: use a pooled `Sprite2D` pool to avoid per-frame allocations.

## Run-load full repaint

`TerritorySystem._on_run_loaded` (brief 04) calls `_tile_grid.set_occupant(coord, kingdom_id, species_id)` for each loaded tile. This triggers `_repaint_tile` automatically, so loading a save reconstructs the visual state. Confirm by loading a Phase 12 lichen save (post-migration) and seeing the lichen tiles render with the blended yellow-green fill.

## Mobile readability sanity check

After the rendering update:

- [ ] Empty tile: biome color only.
- [ ] Plantae-only tile: pioneer_grass green clearly visible.
- [ ] Fungi-only tile: mycelium_thread purple clearly visible.
- [ ] Lichen tile (plantae + fungi): warm yellow-green blend distinct from either parent.
- [ ] Animal-only tile (e.g., grazer on empty grass): orange border around the biome color.
- [ ] Animal-on-plantae: green fill + orange border — both visible.
- [ ] Animal-on-fungi: purple fill + orange border.
- [ ] All-three tile (rare): blended fill + border, readable.
- [ ] No flickering on tile placement / removal.

If the lichen blend reads muddy, tune the lerp toward 0.4 (more plantae weight) or 0.6 (more fungi weight) — single-line change.

## Acceptance criteria

- [ ] `TileGrid.set_occupant` / `clear_occupant` / `clear_all_occupants` implemented.
- [ ] Old `set_surface_owner` / `set_subsurface_owner` work as shims.
- [ ] Plantae, fungi, plantae+fungi, animal, animal+plantae, animal+fungi, all-three all render correctly.
- [ ] Border color matches animal species' `tile_marker_color`.
- [ ] Fill blend produces visible warm yellow-green for plantae+fungi.
- [ ] Loading a v12 save reconstructs all tile visuals.
- [ ] No regression on Phase 12 ecosystems' visual look on legacy biomes.

## Out of scope

- Sprite-art replacement (Phase 14+).
- Animated tile placements / decay transitions.
- Custom-data + shader implementation (Phase 14 polish if Option B perf is a problem).
- Era-tinted backgrounds (Phase 14).
- Biome cluster visualization improvements (Phase 14).
- Tile-tap feedback effects beyond placement.
