# Brief 05 — Structure pattern detector (scan + match + promote)

**Suggested agent**: ChatGPT 5.2. Route diff to **Claude** — pattern-matching algorithm.

Read first:
1. `scripts/systems/territory_system.gd.get_occupants / get_occupant` — tile state queries.
2. `scripts/entities/tile_grid.gd._EdgesOverlay` — single-draw overlay pattern.
3. `scripts/autoloads/resource_ledger.gd.set_multiplier_source` (brief 02 of Phase 15a) — structure bonuses go through this API.

## Goal

Add a system that periodically scans the map for known structure patterns. When a pattern matches, the constituent tiles are "promoted" into an active structure: visual halo + name banner + mechanical bonus (applied via the multiplier registry or direct tile_data flag).

This brief builds the **framework**; brief 07 authors the actual structure recipes.

## Data model

### `scripts/data/structure_data.gd` (new resource)

```gdscript
class_name StructureData
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""

# Pattern definition.
# Recognized values:
#   &"block_NxM_same_species"     - NxM block of same species in same kingdom
#   &"ring_radius_N"              - hollow ring (radius N) of same species around a center
#   &"square_NxM_with_adjacent"   - NxM block + ≥K adjacent tiles of another kingdom/species
#   &"area_on_biome"              - block on specific biome with extra constraints
@export var pattern_type: StringName = &""
@export var pattern_params: Dictionary = {}   # type-specific: width, height, species_tag, etc.

# Bonus handler id — looked up by StructureRegistry to apply on promotion.
@export var bonus_handler: StringName = &""

# Display.
@export var halo_color: Color = Color(1.0, 0.9, 0.4, 0.5)
```

### `scripts/data/structure_index.gd` (new)

```gdscript
class_name StructureIndex
extends Resource

@export var structures: Array[StructureData] = []
```

Add `data/structures/_index.tres` (populated in brief 07).

## StructureRegistry system

`scripts/systems/structure_registry.gd` (mounted under World/Systems):

```gdscript
extends Node

const SCAN_INTERVAL_TICKS: int = 5     # scan every 5 ticks (~5s @ 1Hz)
const STRUCTURE_INDEX_PATH: String = "res://data/structures/_index.tres"

var _structures: Array[StructureData] = []
var _structures_by_id: Dictionary[StringName, StructureData] = {}
var _active: Array[Dictionary] = []     # [{id, anchor_coord, tile_coords}]
var _last_scan_tick: int = 0

@onready var _territory: Node = get_node("../TerritorySystem")
@onready var _tile_grid: Node = get_node("../../TileGrid")


func _ready() -> void:
    _load_structures()
    EventBus.tick.connect(_on_tick)
    EventBus.run_loaded.connect(_on_run_loaded)
    EventBus.tile_colonized.connect(func(_c, _o): _maybe_scan_on_change())
    EventBus.tile_lost.connect(func(_c, _o): _maybe_scan_on_change())


func _load_structures() -> void:
    _structures.clear()
    _structures_by_id.clear()
    var index: StructureIndex = load(STRUCTURE_INDEX_PATH) as StructureIndex
    if index == null:
        return
    for sd in index.structures:
        if sd != null:
            _structures.append(sd)
            _structures_by_id[sd.id] = sd


func _on_run_loaded(_v: int) -> void:
    _active.clear()
    _clear_all_structure_bonuses()
    # Don't restore from save; structures re-detect via the next scan.
    # Saved active_structures (brief 01) is for UI continuity only.
    _scan()


func _on_tick(_delta: float) -> void:
    _last_scan_tick += 1
    if _last_scan_tick < SCAN_INTERVAL_TICKS:
        return
    _last_scan_tick = 0
    _scan()


func _maybe_scan_on_change() -> void:
    # Eager scan when tiles change; cheap if no patterns near.
    _scan()


func _scan() -> void:
    var newly_active: Array[Dictionary] = []
    for sd in _structures:
        var matches: Array = _find_pattern_matches(sd)
        for m in matches:
            newly_active.append({
                "id": sd.id,
                "anchor": m["anchor"],
                "tiles": m["tiles"]
            })

    # Diff against previous active set.
    var old_keys: Dictionary = {}
    for entry in _active:
        old_keys[_active_key(entry)] = entry
    var new_keys: Dictionary = {}
    for entry in newly_active:
        new_keys[_active_key(entry)] = entry

    # Removed: in old, not in new → revert bonus.
    for k in old_keys.keys():
        if not new_keys.has(k):
            _revert_structure(old_keys[k])

    # Added: in new, not in old → apply bonus.
    for k in new_keys.keys():
        if not old_keys.has(k):
            _promote_structure(new_keys[k])

    _active = newly_active
    _persist_active()


func _active_key(entry: Dictionary) -> String:
    return "%s@%s" % [String(entry["id"]), str(entry["anchor"])]


func _promote_structure(entry: Dictionary) -> void:
    var sd: StructureData = _structures_by_id.get(entry["id"], null)
    if sd == null:
        return
    _apply_bonus(sd, entry)
    if _tile_grid.has_method("add_structure_halo"):
        _tile_grid.add_structure_halo(_active_key(entry), entry["tiles"], sd.halo_color)
    # Discovery + banner.
    EventBus.structure_promoted.emit(sd.id, entry["anchor"])
    var played: Array = GameState.meta_save.get("structures_discovered", []) as Array
    if not played.has(String(sd.id)):
        played.append(String(sd.id))
        GameState.meta_save["structures_discovered"] = played
        SaveSystem.save_now()


func _revert_structure(entry: Dictionary) -> void:
    var sd: StructureData = _structures_by_id.get(entry["id"], null)
    if sd == null:
        return
    _revert_bonus(sd, entry)
    if _tile_grid.has_method("remove_structure_halo"):
        _tile_grid.remove_structure_halo(_active_key(entry))


# Dispatch table for bonus handlers. Implementations land in brief 07.
func _apply_bonus(sd: StructureData, entry: Dictionary) -> void:
    var handler: StringName = sd.bonus_handler
    match handler:
        &"mycorrhizal_hub":
            _bonus_mycorrhizal_hub(entry, true)
        &"old_growth_stand":
            _bonus_old_growth_stand(entry, true)
        &"fairy_ring":
            _bonus_fairy_ring(entry, true)
        &"decay_pit":
            _bonus_decay_pit(entry, true)
        _:
            push_warning("StructureRegistry: unknown bonus handler %s" % String(handler))


func _revert_bonus(sd: StructureData, entry: Dictionary) -> void:
    match sd.bonus_handler:
        &"mycorrhizal_hub":
            _bonus_mycorrhizal_hub(entry, false)
        &"old_growth_stand":
            _bonus_old_growth_stand(entry, false)
        &"fairy_ring":
            _bonus_fairy_ring(entry, false)
        &"decay_pit":
            _bonus_decay_pit(entry, false)


func _clear_all_structure_bonuses() -> void:
    for entry in _active:
        var sd: StructureData = _structures_by_id.get(entry["id"], null)
        if sd != null:
            _revert_bonus(sd, entry)


func _persist_active() -> void:
    var arr: Array = []
    for entry in _active:
        arr.append({
            "id": String(entry["id"]),
            "anchor": [entry["anchor"].x, entry["anchor"].y],
            "tiles": entry["tiles"].map(func(c): return [c.x, c.y])
        })
    GameState.run_save["active_structures"] = arr


# === Pattern matching ===

func _find_pattern_matches(sd: StructureData) -> Array:
    match sd.pattern_type:
        &"block_NxM_same_species":
            return _match_block(sd.pattern_params)
        &"ring_radius_N":
            return _match_ring(sd.pattern_params)
        &"square_NxM_with_adjacent":
            return _match_block_with_adjacent(sd.pattern_params)
        &"area_on_biome":
            return _match_area_on_biome(sd.pattern_params)
        _:
            return []


func _match_block(params: Dictionary) -> Array:
    var w: int = int(params.get("width", 3))
    var h: int = int(params.get("height", 3))
    var kingdom_id: StringName = StringName(params.get("kingdom_id", ""))
    var out: Array = []
    for y in range(_tile_grid.GRID_HEIGHT - h + 1):
        for x in range(_tile_grid.GRID_WIDTH - w + 1):
            var anchor: Vector2i = Vector2i(x, y)
            var coords: Array[Vector2i] = []
            var first_species: StringName = &""
            var ok: bool = true
            for dy in range(h):
                for dx in range(w):
                    var c: Vector2i = Vector2i(x + dx, y + dy)
                    var sp: StringName = _territory.get_occupant(c, kingdom_id)
                    if sp == &"":
                        ok = false
                        break
                    if first_species == &"":
                        first_species = sp
                    elif sp != first_species:
                        ok = false
                        break
                    coords.append(c)
                if not ok: break
            if ok:
                out.append({"anchor": anchor, "tiles": coords})
    return out


func _match_block_with_adjacent(params: Dictionary) -> Array:
    var block_matches: Array = _match_block(params)
    var adj_kingdom: StringName = StringName(params.get("adjacent_kingdom_id", ""))
    var min_adj: int = int(params.get("min_adjacent", 4))
    var out: Array = []
    for m in block_matches:
        var coord_set: Dictionary = {}
        for c in m["tiles"]:
            coord_set[c] = true
        var adj_count: int = 0
        var seen_adj: Dictionary = {}
        for c in m["tiles"]:
            for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
                var n: Vector2i = c + offset
                if coord_set.has(n) or seen_adj.has(n):
                    continue
                if _territory.get_occupant(n, adj_kingdom) != &"":
                    seen_adj[n] = true
                    adj_count += 1
        if adj_count >= min_adj:
            out.append(m)
    return out


func _match_ring(params: Dictionary) -> Array:
    var radius: int = int(params.get("radius", 1))
    var kingdom_id: StringName = StringName(params.get("kingdom_id", ""))
    var out: Array = []
    # Iterate possible centers.
    for cy in range(radius, _tile_grid.GRID_HEIGHT - radius):
        for cx in range(radius, _tile_grid.GRID_WIDTH - radius):
            var center: Vector2i = Vector2i(cx, cy)
            # Ring requires: all tiles at exact distance == radius (Chebyshev or Manhattan)
            # have the same species in this kingdom. Center MUST be unoccupied
            # in this kingdom (the "hollow").
            if _territory.get_occupant(center, kingdom_id) != &"":
                continue
            var ring_coords: Array[Vector2i] = []
            var first_species: StringName = &""
            var ok: bool = true
            for dy in range(-radius, radius + 1):
                for dx in range(-radius, radius + 1):
                    if max(abs(dx), abs(dy)) != radius:
                        continue
                    var c: Vector2i = Vector2i(cx + dx, cy + dy)
                    var sp: StringName = _territory.get_occupant(c, kingdom_id)
                    if sp == &"":
                        ok = false; break
                    if first_species == &"":
                        first_species = sp
                    elif sp != first_species:
                        ok = false; break
                    ring_coords.append(c)
                if not ok: break
            if ok:
                out.append({"anchor": center, "tiles": ring_coords})
    return out


func _match_area_on_biome(params: Dictionary) -> Array:
    # NxM block on tiles whose biome matches biome_id, with optional corpse-nearby check.
    var w: int = int(params.get("width", 2))
    var h: int = int(params.get("height", 2))
    var kingdom_id: StringName = StringName(params.get("kingdom_id", ""))
    var biome_id: StringName = StringName(params.get("biome_id", ""))
    var require_corpse_adj: bool = bool(params.get("require_adjacent_corpse", false))
    var nutrients: Node = get_node_or_null("../NutrientSystem")
    var corpses: Node = get_node_or_null("../CorpseSystem")
    var out: Array = []
    for y in range(_tile_grid.GRID_HEIGHT - h + 1):
        for x in range(_tile_grid.GRID_WIDTH - w + 1):
            var anchor: Vector2i = Vector2i(x, y)
            var coords: Array[Vector2i] = []
            var first_species: StringName = &""
            var ok: bool = true
            for dy in range(h):
                for dx in range(w):
                    var c: Vector2i = Vector2i(x + dx, y + dy)
                    var sp: StringName = _territory.get_occupant(c, kingdom_id)
                    if sp == &"":
                        ok = false; break
                    if first_species == &"":
                        first_species = sp
                    elif sp != first_species:
                        ok = false; break
                    if nutrients != null and nutrients.has_method("get_biome_at"):
                        var biome: BiomeData = nutrients.get_biome_at(c)
                        if biome == null or biome.id != biome_id:
                            ok = false; break
                    coords.append(c)
                if not ok: break
            if ok and require_corpse_adj:
                ok = _has_adjacent_corpse(coords, corpses)
            if ok:
                out.append({"anchor": anchor, "tiles": coords})
    return out


func _has_adjacent_corpse(coords: Array[Vector2i], corpses: Node) -> bool:
    if corpses == null or not corpses.has_method("is_corpse_at"):
        return false
    var coord_set: Dictionary = {}
    for c in coords:
        coord_set[c] = true
    for c in coords:
        for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
            var n: Vector2i = c + offset
            if coord_set.has(n):
                continue
            if corpses.is_corpse_at(n):
                return true
    return false
```

## EventBus signal

```gdscript
signal structure_promoted(structure_id: StringName, anchor: Vector2i)
```

## Bonus handler placeholders

These are real implementations in brief 07. Stub here so structure_registry compiles:

```gdscript
func _bonus_mycorrhizal_hub(entry: Dictionary, apply: bool) -> void:
    var key: String = "run:structure:mycorrhizal_hub:%s" % str(entry["anchor"])
    if apply:
        ResourceLedger.set_multiplier_source(&"biomass", StringName(key), 1.50)
    else:
        ResourceLedger.clear_multiplier_source(&"biomass", StringName(key))

func _bonus_old_growth_stand(entry: Dictionary, apply: bool) -> void:
    var key: String = "run:structure:old_growth:%s" % str(entry["anchor"])
    if apply:
        ResourceLedger.set_multiplier_source(&"biomass", StringName(key), 2.00)
    else:
        ResourceLedger.clear_multiplier_source(&"biomass", StringName(key))

func _bonus_fairy_ring(entry: Dictionary, apply: bool) -> void:
    # Free sporulate ability — flag in run_save; AbilitySystem reads it.
    var run: Dictionary = GameState.run_save
    run["fairy_ring_active"] = apply
    GameState.run_save = run

func _bonus_decay_pit(entry: Dictionary, apply: bool) -> void:
    var key: String = "run:structure:decay_pit:%s" % str(entry["anchor"])
    if apply:
        ResourceLedger.set_multiplier_source(&"nutrients", StringName(key), 1.30)
    else:
        ResourceLedger.clear_multiplier_source(&"nutrients", StringName(key))
```

(Brief 07 refines these into proper per-cluster bonuses; for now they apply globally.)

## TileGrid structure halos

Single Node2D overlay layer that draws colored rings around structure tile sets:

```gdscript
var _structure_halos: Dictionary[String, Array] = {}    # key → [coords]
var _halo_colors: Dictionary[String, Color] = {}


func add_structure_halo(key: String, tiles: Array[Vector2i], color: Color) -> void:
    _structure_halos[key] = tiles
    _halo_colors[key] = color
    _redraw_halos()


func remove_structure_halo(key: String) -> void:
    _structure_halos.erase(key)
    _halo_colors.erase(key)
    _redraw_halos()


# Implement via _draw() on a new halo overlay Node2D, similar to _EdgesOverlay.
```

## Acceptance criteria

- [ ] `StructureData` resource + `StructureIndex` resource defined.
- [ ] `StructureRegistry` mounted, scans every 5 ticks + on tile change.
- [ ] Pattern matchers: block, ring, block-with-adjacent, area-on-biome all return correct matches against test patterns.
- [ ] On match, `EventBus.structure_promoted` fires, halo renders, bonus applied via multiplier source.
- [ ] On tile change that breaks pattern, bonus reverts + halo disappears.
- [ ] `meta.structures_discovered` accumulates structure ids ever seen.
- [ ] `run.active_structures` persists for save round-trip.
- [ ] Performance: scan of 1500-tile map completes in <50ms.

## Out of scope

- Multi-anchor matches (a single structure covering > one location) — handled by per-anchor entries in `_active`.
- Custom pattern types beyond the 4 listed.
- Animated structure formation effects (Phase 16+).
- Player-facing UI for active structures list (brief 06 builds recipe book; in-world list deferred).
