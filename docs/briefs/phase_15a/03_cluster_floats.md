# Brief 03 — Connected-cluster detection + per-cluster income floats

**Suggested agent**: ChatGPT 5.2. Route diff to Claude — perf.

Read first:
1. `scripts/systems/territory_system.gd` — occupants storage.
2. `scripts/entities/tile_grid.gd._EdgesOverlay` — single-draw overlay pattern.
3. `scripts/autoloads/tick_clock.gd` — tick signal source.

## Goal

Detect connected clusters of tiles sharing the same species in the same kingdom slot. Every ~8 seconds, each cluster spawns a "+N biomass" floating label at its centroid showing how much biomass that cluster produced since its last float. Stagger per-cluster so they don't all pop at once.

This is the **per-second visible income** layer — players see life producing without staring at totals.

## Cluster detection

Add to `TerritorySystem` (or a new helper):

```gdscript
# Returns Array of clusters; each cluster is {species_id, kingdom_id, coords: Array[Vector2i]}.
# Connected via 4-neighbor adjacency, sharing the same species in the same kingdom slot.
func get_clusters() -> Array:
    var visited: Dictionary[Vector2i, bool] = {}
    var clusters: Array = []
    for coord in _tiles.keys():
        var occ: Dictionary = _tiles[coord].get("occupants", {}) as Dictionary
        for kingdom_id in occ.keys():
            var species_id: StringName = StringName(occ[kingdom_id])
            var key: Vector2i = coord  # visited per-coord-per-kingdom would be better; simplify v1
            # Use composite key for visited tracking across kingdoms on same tile.
            var visit_key: String = "%d,%d:%s" % [coord.x, coord.y, String(kingdom_id)]
            if visited.has(visit_key):
                continue
            var cluster_coords: Array[Vector2i] = _flood_fill(coord, kingdom_id, species_id, visited, visit_key)
            if not cluster_coords.is_empty():
                clusters.append({
                    "species_id": species_id,
                    "kingdom_id": kingdom_id,
                    "coords": cluster_coords
                })
    return clusters


func _flood_fill(start: Vector2i, kingdom_id: StringName, species_id: StringName,
                 visited: Dictionary, _seed_key: String) -> Array[Vector2i]:
    var out: Array[Vector2i] = []
    var stack: Array[Vector2i] = [start]
    while not stack.is_empty():
        var c: Vector2i = stack.pop_back()
        var k: String = "%d,%d:%s" % [c.x, c.y, String(kingdom_id)]
        if visited.has(k):
            continue
        visited[k] = true
        var occ: Dictionary = _tiles.get(c, {}).get("occupants", {}) as Dictionary
        if StringName(occ.get(kingdom_id, &"")) != species_id:
            continue
        out.append(c)
        for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
            stack.push_back(c + offset)
    return out
```

Note: visited keys use kingdom because two kingdoms on the same tile are independent clusters.

## Cluster manager (new)

New node `scripts/systems/cluster_income_tracker.gd` (mounted under World/Systems):

```gdscript
extends Node

const FLOAT_INTERVAL_TICKS: int = 8       # one float per cluster every ~8s @ 1Hz tick
const FLOAT_SCENE: PackedScene = preload("res://scenes/ui/cluster_float.tscn")

@onready var _territory: Node = get_node("../TerritorySystem")
@onready var _tile_grid: Node = get_node("../../TileGrid")

# Per-cluster running sum of biomass produced since the last float emission.
# Key: composite of species_id + sorted coords hash, value: float biomass.
var _accumulated: Dictionary[String, float] = {}
var _last_emit_tick: Dictionary[String, int] = {}


func _ready() -> void:
    EventBus.tick.connect(_on_tick)
    EventBus.run_loaded.connect(func(_v): _accumulated.clear())


func _on_tick(_delta: float) -> void:
    var current_tick: int = int(TickClock.tick_count) if TickClock.has_method("tick_count") else 0
    if Engine.has_method("get_process_frames"):
        current_tick = Engine.get_process_frames()  # fallback if tick_count unavailable
    var clusters: Array = _territory.get_clusters()
    for cluster in clusters:
        _process_cluster(cluster, current_tick)


func _process_cluster(cluster: Dictionary, current_tick: int) -> void:
    var species_id: StringName = cluster["species_id"]
    var coords: Array[Vector2i] = cluster["coords"]
    var key: String = _cluster_key(cluster)
    # Compute biomass produced this tick by this cluster (approximate via
    # species.tick_yield.biomass × per-tile multipliers × tile count).
    var biomass_this_tick: float = _compute_cluster_biomass_this_tick(species_id, coords)
    _accumulated[key] = float(_accumulated.get(key, 0.0)) + biomass_this_tick

    # Stagger emissions by cluster-key hash so they don't all pop together.
    var stagger: int = abs(key.hash()) % FLOAT_INTERVAL_TICKS
    if (current_tick + stagger) % FLOAT_INTERVAL_TICKS != 0:
        return
    var amount: float = _accumulated.get(key, 0.0)
    if amount <= 0.0:
        return
    _accumulated[key] = 0.0
    _spawn_float(coords, amount)


func _cluster_key(cluster: Dictionary) -> String:
    var ids: Array = []
    for c in cluster["coords"]:
        ids.append("%d,%d" % [c.x, c.y])
    ids.sort()
    return "%s:%s" % [String(cluster["species_id"]), "|".join(ids)]


func _compute_cluster_biomass_this_tick(species_id: StringName, coords: Array[Vector2i]) -> float:
    # Cheap approximation: cluster size × base biomass yield × current biomass multiplier.
    # Brief 05 + 06 will refine once maturation + cost don't affect yield rate the same way.
    var index: SpeciesIndex = load("res://data/species/_index.tres") as SpeciesIndex
    if index == null:
        return 0.0
    var biomass_per_tile: float = 0.0
    for sp in index.species:
        if sp.id == species_id:
            biomass_per_tile = float(sp.tick_yield.get("biomass", 0.0))
            break
    return biomass_per_tile * float(coords.size()) * ResourceLedger.get_multiplier(&"biomass")


func _spawn_float(coords: Array[Vector2i], amount: float) -> void:
    var centroid: Vector2 = Vector2.ZERO
    for c in coords:
        centroid += Vector2(c.x, c.y)
    centroid /= float(coords.size())
    var world_pos: Vector2 = _tile_grid.map_to_local(Vector2i(int(centroid.x), int(centroid.y)))
    var label_node: Node = FLOAT_SCENE.instantiate()
    label_node.text = "+%s" % FormatUtils.abbreviate(amount)
    label_node.position = world_pos
    _tile_grid.add_child(label_node)
```

## Float visual scene

`scenes/ui/cluster_float.tscn` — a `Label` (top-level) with a small script that drifts up + fades out over 1.5s then `queue_free()`s. Color = resource_color biomass.

```gdscript
# scripts/ui/cluster_float.gd
extends Label

const DRIFT_DISTANCE: float = 18.0
const DURATION: float = 1.5

func _ready() -> void:
    add_theme_font_override("font", KingdomTheme.SMALL_FONT)
    add_theme_font_size_override("font_size", KingdomTheme.SMALL_FONT_SIZE)
    add_theme_color_override("font_color", KingdomTheme.resource_color(&"biomass"))
    z_index = 5
    var tween := create_tween()
    tween.parallel().tween_property(self, "position:y", position.y - DRIFT_DISTANCE, DURATION)
    tween.parallel().tween_property(self, "modulate:a", 0.0, DURATION).set_delay(DURATION * 0.3)
    tween.tween_callback(queue_free)
```

## Lifetime counter increment

When a new cluster is detected (first time we see a given cluster key in this run), bump `meta.lifetime_counters.clusters_formed_lifetime` by 1. Optional but cheap; powers later Adaptation sources.

## Perf

- `get_clusters()` is O(N) where N = owned tiles. Called every tick.
- For 1000 tiles, that's fine in GDScript.
- If profiling shows hotspot, cache cluster list and invalidate only on tile change. Defer optimization until smoke test reveals it.

## Acceptance criteria

- [ ] `TerritorySystem.get_clusters()` returns one entry per connected same-species region.
- [ ] `ClusterIncomeTracker` mounted under World/Systems.
- [ ] A cluster of 5+ tiles spawns a "+N biomass" float at its centroid every ~8s.
- [ ] Floats stagger across clusters (not all popping the same tick).
- [ ] Float visual drifts up + fades out cleanly.
- [ ] No frame drops on a 200-tile run.
- [ ] `clusters_formed_lifetime` counter increments on first sighting per run.

## Out of scope

- Per-cluster info popup on tap (Phase 16+).
- Per-resource floats (only biomass in v1 — extend later if useful).
- Cluster boundary highlight beyond existing edge overlay.
- Animations on first cluster formation (Phase 16+).
