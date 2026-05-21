extends Node
##
## Phase 15a: Cluster income tracker — emits floating "+X biomass" labels.
##

const FLOAT_INTERVAL_TICKS: int = 8       # one float per cluster every ~8s @ 1Hz tick
const FLOAT_SCENE: PackedScene = preload("res://scenes/ui/cluster_float.tscn")
const SPECIES_INDEX_PATH: String = "res://data/species/_index.tres"

@onready var _territory: Node = get_node("../TerritorySystem")
@onready var _tile_grid: Node = get_node("../../TileGrid")

# Per-cluster running sum of biomass produced since the last float emission.
# Key: composite of species_id + sorted coords hash, value: float biomass.
var _accumulated: Dictionary[String, float] = {}
var _last_emit_tick: Dictionary[String, int] = {}
var _seen_clusters: Dictionary[String, bool] = {}  # Track first sighting for lifetime counter

# Perf: cache biomass-per-tile lookup by species_id so the per-tick hot path
# doesn't load the species index from disk and linear-scan every cluster.
var _biomass_per_tile_by_species: Dictionary[StringName, float] = {}


func _ready() -> void:
	_cache_species_yields()
	EventBus.tick.connect(_on_tick)
	EventBus.run_loaded.connect(func(_v): _accumulated.clear())


func _cache_species_yields() -> void:
	_biomass_per_tile_by_species.clear()
	var index: SpeciesIndex = load(SPECIES_INDEX_PATH) as SpeciesIndex
	if index == null:
		return
	for sp in index.species:
		if sp == null:
			continue
		_biomass_per_tile_by_species[sp.id] = float(sp.tick_yield.get("biomass", 0.0))


func _on_tick(_delta: float) -> void:
	var current_tick: int = _get_current_tick()
	var clusters: Array = _territory.get_clusters()
	for cluster in clusters:
		_process_cluster(cluster, current_tick)


func _process_cluster(cluster: Dictionary, current_tick: int) -> void:
	var species_id: StringName = cluster["species_id"]
	var coords: Array[Vector2i] = cluster["coords"]
	var key: String = _cluster_key(cluster)
	
	# First sighting tracking
	if not _seen_clusters.has(key):
		_seen_clusters[key] = true
		_increment_clusters_formed_lifetime()
	
	# Compute biomass produced this tick by this cluster
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
	# Use a STABLE cluster identifier: species_id + top-left bounding coord.
	# Previously we hashed all coords, which meant every tile add/remove
	# changed the key → orphaned accumulated biomass + shifted stagger
	# hash → irregular float timing. The top-left coord is stable as long
	# as the cluster keeps growing outward (which is the common case).
	var coords: Array = cluster["coords"]
	if coords.is_empty():
		return String(cluster["species_id"])
	var min_x: int = int(coords[0].x)
	var min_y: int = int(coords[0].y)
	for c in coords:
		if c.x < min_x: min_x = int(c.x)
		if c.y < min_y: min_y = int(c.y)
	return "%s:%s:%d,%d" % [
		String(cluster["species_id"]),
		String(cluster["kingdom_id"]),
		min_x, min_y
	]


func _compute_cluster_biomass_this_tick(species_id: StringName, coords: Array[Vector2i]) -> float:
	# Cheap approximation: cluster size × base biomass yield × current biomass multiplier.
	# Species lookup is precomputed in _cache_species_yields() — was a disk load
	# + linear scan per cluster per tick before, which spiked late-game frames.
	var biomass_per_tile: float = _biomass_per_tile_by_species.get(species_id, 0.0)
	if biomass_per_tile == 0.0:
		return 0.0
	return biomass_per_tile * float(coords.size()) * ResourceLedger.get_multiplier(&"biomass")


func _spawn_float(coords: Array[Vector2i], amount: float) -> void:
	var centroid: Vector2 = Vector2.ZERO
	for c in coords:
		centroid += Vector2(c.x, c.y)
	centroid /= float(coords.size())
	var world_pos: Vector2 = _tile_grid.map_to_local(Vector2i(int(centroid.x), int(centroid.y)))
	var label_node: Node = FLOAT_SCENE.instantiate()
	# Biomass icon (assets/art/resources/biomass.png) is part of the scene now;
	# the amount label sits next to it. Drop the leading ● glyph.
	label_node.set_amount("+%s" % FormatUtils.abbreviate(amount))
	label_node.position = world_pos
	_tile_grid.add_child(label_node)


func _get_current_tick() -> int:
	var stats: Dictionary = GameState.run_save.get("statistics", {}) as Dictionary
	return int(stats.get("tick_count", 0))


func _increment_clusters_formed_lifetime() -> void:
	var meta: Dictionary = GameState.meta_save if GameState.meta_save is Dictionary else {}
	var counters: Dictionary = meta.get("lifetime_counters", {}) as Dictionary
	counters["clusters_formed_lifetime"] = int(counters.get("clusters_formed_lifetime", 0)) + 1
	meta["lifetime_counters"] = counters
