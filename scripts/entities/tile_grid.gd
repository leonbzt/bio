extends Node2D
##
## TileGrid — 2026-05-21 visual-direction refactor.
## Was: TileMap with ColorRect species overlays + Polygon2D animal markers.
## Now: Sprite2D-per-tile for biome bases, custom Node2D icons drawn on top
## for species (biome stays visible underneath), plus an explicit symbiosis
## ring overlay when multiple kingdoms share a tile.
##
## Public API preserved: set_occupant, clear_occupant, clear_all_occupants,
## clear_owned, map_to_local, local_to_map, set_fog_state, reveal_tiles,
## set_obstacles, add_structure_halo, remove_structure_halo,
## GRID_WIDTH/GRID_HEIGHT/TILE_SIZE constants.
##

const GRID_WIDTH: int = 32
const GRID_HEIGHT: int = 48
const TILE_SIZE: int = 48   # Locked 2026-05-22 — see VISUAL_DIRECTION.md
							# "Locked long-term canvas (2026-05-22)". Cluster
							# sprite fills the tile (48×48 native), biome shows
							# through transparent margins and between organisms.
							# Cluster rendering itself lands in VM-B1; for now,
							# the existing 32-px kingdom icons render oversized
							# relative to the smaller tile (~67% coverage) —
							# temporary visual state until VM-B1.

const SPECIES_INDEX_PATH: String = "res://data/species/_index.tres"

const BIOME_IDS: Array[StringName] = [
	&"grassland", &"rich_soil", &"forest_edge",
	&"tundra", &"mineral_vent", &"swamp", &"rock"
]

# Locked palette: gold marker color for symbiosis adjacency indicators
# (corner dots + edge highlights). Used by VM-B3 when adjacency-symbiosis
# rendering lands.
const SYMBIOSIS_GOLD: Color = Color(0.85, 0.72, 0.28, 1.0)

# Phase 15a tile pulse — disabled, kept as concept for slime-mold-style flow.
const PULSE_CHANCE: float = 0.0
const PULSE_DURATION: float = 0.35
const PULSE_BRIGHTNESS_BUMP: float = 0.60

const FOG_COLOR: Color = Color(0.04, 0.04, 0.06, 1.0)
const FOG_EDGE_COLOR: Color = Color(0.08, 0.08, 0.10, 1.0)

# Animal marker — small inset diamond at tile center, on top of biome + species.
const ANIMAL_MARKER_RADIUS: float = 6.0

# Cluster outline placeholders, currently disabled.
const EDGE_WIDTH: float = 1.0
const EDGE_INSET_PLANTAE: float = 1.5
const EDGE_INSET_FUNGI: float = 3.5


class _EdgesOverlay extends Node2D:
	var tile_grid

	func _draw() -> void:
		# Cluster edges disabled 2026-05-20 — revisit with halo-per-cluster
		# approach. Keep overlay node so re-enabling is a single return removal.
		return


class _FogOverlay extends Node2D:
	var tile_grid

	func _draw() -> void:
		if tile_grid == null:
			return
		for y in range(tile_grid.GRID_HEIGHT):
			for x in range(tile_grid.GRID_WIDTH):
				var c := Vector2i(x, y)
				if tile_grid._revealed_set.has(c):
					continue
				var origin: Vector2 = tile_grid.map_to_local(c) - Vector2(tile_grid.TILE_SIZE * 0.5, tile_grid.TILE_SIZE * 0.5)
				draw_rect(Rect2(origin, Vector2(tile_grid.TILE_SIZE, tile_grid.TILE_SIZE)), tile_grid.FOG_COLOR, true)


class _HaloOverlay extends Node2D:
	var tile_grid

	func _draw() -> void:
		if tile_grid == null:
			return
		for key in tile_grid._structure_halos.keys():
			# Fusion-aware structures render their composite instead of a
			# perimeter halo. The halo dict still tracks them so structure
			# bookkeeping (the dirty key set) stays uniform.
			if tile_grid._fusion_kinds.has(key):
				continue
			var coords: Array = tile_grid._structure_halos[key]
			var color: Color = tile_grid._halo_colors.get(key, Color(1, 1, 1, 0.5))
			for c in coords:
				var origin: Vector2 = tile_grid.map_to_local(c) - Vector2(tile_grid.TILE_SIZE * 0.5, tile_grid.TILE_SIZE * 0.5)
				draw_rect(Rect2(origin, Vector2(tile_grid.TILE_SIZE, tile_grid.TILE_SIZE)), color, false, 1.5)


# Phase E (2026-05-21) — fused-tile structure rendering. When a structure of
# a known "fusion kind" is promoted, its constituent tiles' individual species
# composites are hidden and this overlay draws the structure as one continuous
# object. Pilot kind: fairy_ring (3×3 ring with empty center).
class _StructureFusionOverlay extends Node2D:
	var tile_grid

	func _draw() -> void:
		if tile_grid == null:
			return
		for key in tile_grid._fusion_kinds.keys():
			var kind: StringName = tile_grid._fusion_kinds[key]
			var anchor: Vector2i = tile_grid._fusion_anchors.get(key, Vector2i.ZERO)
			match kind:
				&"fairy_ring":
					_draw_fairy_ring(anchor)
				_:
					pass

	func _draw_fairy_ring(anchor: Vector2i) -> void:
		# Anchor is the ring center (per StructureRegistry._match_ring). With
		# radius 1, the 3×3 footprint spans anchor.x-1..anchor.x+1.
		var center_world: Vector2 = tile_grid.map_to_local(anchor)
		var ts: float = float(tile_grid.TILE_SIZE)
		# Bare-earth center: darken the central tile so it reads as "empty middle".
		var center_rect := Rect2(
			center_world - Vector2(ts * 0.5, ts * 0.5),
			Vector2(ts, ts)
		)
		draw_rect(center_rect, Color(0.06, 0.04, 0.07, 0.65), true)
		# Ring of mycelium: a soft violet annulus traced around the 3×3 outer ring.
		var ring_outer: float = ts * 1.45
		var ring_inner: float = ts * 0.70
		var fungi_violet := Color(0.48, 0.30, 0.62, 1.0)
		# Draw concentric rings of decreasing alpha to fake an annulus
		# (Godot 4 doesn't have a built-in fill-annulus primitive).
		var steps: int = 12
		for i in range(steps):
			var t: float = float(i) / float(steps - 1)
			var r: float = lerp(ring_inner, ring_outer, t)
			var alpha: float = 0.85 * (1.0 - abs(t - 0.5) * 1.8)
			alpha = max(0.0, alpha)
			var c := fungi_violet
			c.a = alpha
			draw_arc(center_world, r, 0.0, TAU, 48, c, 1.5)
		# Fruiting bodies — 5 small caps spaced around the ring.
		var caps: int = 5
		var cap_radius: float = ts * 1.05
		for i in range(caps):
			var angle: float = TAU * (float(i) / float(caps)) - PI * 0.5
			var pos := center_world + Vector2(cos(angle), sin(angle)) * cap_radius
			draw_circle(pos, ts * 0.10, Color(0.78, 0.58, 0.92, 0.95))
			# Small dark stem hint
			draw_circle(pos + Vector2(0, ts * 0.06), ts * 0.05, Color(0.30, 0.18, 0.38, 0.85))


# Per-kingdom icon renderer drawn ON TOP of biome substrate. Tinted by
# species.tile_marker_color. Shape varies by kingdom. Maturation handled
# by scale + alpha + accent rim done by the parent in set_state().
class _SpeciesCluster extends Node2D:
	# VM-B1 (2026-05-22 lock): cluster-in-biome rendering. Replaces the prior
	# _SpeciesIcon focal-icon model. Each tile renders as a few small
	# organisms scattered within the inner area; biome substrate shows
	# through transparent margins and between organisms. Density variant
	# steps up with same-kingdom neighbor count, giving the "growing
	# together" feel without auto-tile geometry. See
	# docs/VISUAL_DIRECTION.md "Locked long-term canvas (2026-05-22)".

	# Cluster fills the tile. Hardcoded to track TILE_SIZE 48 — update both
	# in sync if the tile size ever changes.
	const CLUSTER_SIZE: float = 48.0
	const CLUSTER_HALF: float = 24.0
	# Transparent margin so biome shows at tile edges in every variant.
	const INNER_MARGIN: float = 4.0

	const VARIANT_PIONEER: int = 0
	const VARIANT_ESTABLISHING: int = 1
	const VARIANT_ESTABLISHED: int = 2
	const VARIANT_MATURE: int = 3

	const _VARIANT_NAMES: Array[StringName] = [
		&"pioneer", &"establishing", &"established", &"mature"
	]

	# Commissioned cluster textures. File naming: <kingdom>_NN.png where NN
	# is 01..04 corresponding to pioneer/establishing/established/mature.
	# White-on-transparent expected; species tile_marker_color modulates at
	# draw time. If a PNG is missing the procedural placeholder draws instead.
	const _CLUSTER_TEXTURE_PATHS: Dictionary[StringName, String] = {
		&"plantae_pioneer":      "res://assets/art/kingdoms/plantae_01.png",
		&"plantae_establishing": "res://assets/art/kingdoms/plantae_02.png",
		&"plantae_established":  "res://assets/art/kingdoms/plantae_03.png",
		&"plantae_mature":       "res://assets/art/kingdoms/plantae_04.png",
		&"fungi_pioneer":        "res://assets/art/kingdoms/fungi_01.png",
		&"fungi_establishing":   "res://assets/art/kingdoms/fungi_02.png",
		&"fungi_established":    "res://assets/art/kingdoms/fungi_03.png",
		&"fungi_mature":         "res://assets/art/kingdoms/fungi_04.png"
	}

	static var _texture_cache: Dictionary[StringName, Texture2D] = {}
	static var _texture_cache_warmed: bool = false

	static func _warm_texture_cache() -> void:
		if _texture_cache_warmed:
			return
		_texture_cache_warmed = true
		for key in _CLUSTER_TEXTURE_PATHS.keys():
			var path: String = _CLUSTER_TEXTURE_PATHS[key]
			if ResourceLoader.exists(path):
				var tex := load(path) as Texture2D
				if tex != null:
					_texture_cache[key] = tex

	var kingdom_id: StringName = &""
	var cluster_color: Color = Color.WHITE
	var variant: int = 0
	var seed_value: int = 0
	var stage: int = 1            # 0 sprout, 1 mature, 2 ancient
	var cluster_alpha: float = 0.95

	func _init() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_warm_texture_cache()

	func set_state(kid: StringName, color: Color, v: int, p_seed: int, m_stage: int) -> void:
		kingdom_id = kid
		cluster_color = color
		variant = clamp(v, 0, 3)
		seed_value = p_seed
		stage = m_stage
		match stage:
			0:    cluster_alpha = 0.55
			2:    cluster_alpha = 1.0
			_:    cluster_alpha = 0.95
		queue_redraw()

	func _draw() -> void:
		var c: Color = cluster_color
		c.a = cluster_alpha

		# Prefer commissioned PNG (modulated by species color); fall back
		# to procedural placeholder if no asset exists for this (kingdom,
		# variant) pair. The 4 density variants per kingdom drop into the
		# same slot when VM-C1 commission art arrives.
		var key: StringName = StringName(String(kingdom_id) + "_" + String(_VARIANT_NAMES[variant]))
		var tex: Texture2D = _texture_cache.get(key, null)
		if tex != null:
			var rect := Rect2(Vector2(-CLUSTER_HALF, -CLUSTER_HALF), Vector2(CLUSTER_SIZE, CLUSTER_SIZE))
			draw_texture_rect(tex, rect, false, c)
		else:
			_draw_procedural(c)

		# Ancient stage rim accent (carried from prior model — subtle inner
		# rim to signal maturation weight without overpowering the cluster).
		if stage == 2:
			var rim: Color = c.lightened(0.40)
			rim.a = 0.55
			var rim_rect := Rect2(
				Vector2(-CLUSTER_HALF + INNER_MARGIN, -CLUSTER_HALF + INNER_MARGIN),
				Vector2(CLUSTER_SIZE - INNER_MARGIN * 2.0, CLUSTER_SIZE - INNER_MARGIN * 2.0)
			)
			draw_rect(rim_rect, rim, false, 1.0)

	# Procedural placeholder: scattered small organisms within the inner
	# area, kingdom-shaped, deterministically positioned by seed_value so
	# each tile has a stable layout across redraws.
	func _draw_procedural(c: Color) -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value

		var inner_half: float = CLUSTER_HALF - INNER_MARGIN
		var dark: Color = c.darkened(0.35)
		dark.a = c.a
		var light: Color = c.lightened(0.20)
		light.a = c.a

		# Mature: grove pattern — one large central organism + 4 satellites
		# in a rough ring. Reads as "this tile is the defining feature."
		if variant == VARIANT_MATURE:
			_draw_organism(Vector2.ZERO, _organism_size(variant) * 1.7, light, dark)
			var ring_radius: float = inner_half * 0.65
			for i in range(4):
				var angle: float = TAU * float(i) / 4.0 + rng.randf_range(-0.4, 0.4)
				var radial_jitter: float = ring_radius * rng.randf_range(0.85, 1.05)
				var p: Vector2 = Vector2(cos(angle), sin(angle)) * radial_jitter
				_draw_organism(p, _organism_size(variant) * 0.7, light, dark)
			return

		# Pioneer / establishing / established: scattered placement, count
		# steps up with density. Stable across redraws via seeded RNG.
		var org_count: int = [2, 3, 5][variant]
		for i in range(org_count):
			var x: float = rng.randf_range(-inner_half, inner_half)
			var y: float = rng.randf_range(-inner_half, inner_half)
			_draw_organism(Vector2(x, y), _organism_size(variant), light, dark)

	func _organism_size(v: int) -> float:
		return [3.5, 4.0, 4.5, 5.5][v]

	# Each organism's shape distinguishes its kingdom. Dark fill carries
	# the kingdom-tinted species color; light accent is a small highlight
	# (mostly for fungi caps so they read with a hint of dimensionality).
	func _draw_organism(center: Vector2, size: float, light: Color, dark: Color) -> void:
		match kingdom_id:
			&"plantae":
				# Upward-pointing triangle (stem/sprout from above).
				var plant_pts := PackedVector2Array([
					center + Vector2(0.0, -size),
					center + Vector2(size * 0.7, size * 0.6),
					center + Vector2(-size * 0.7, size * 0.6)
				])
				draw_colored_polygon(plant_pts, dark)
			&"fungi":
				# Round cap with a small light highlight (top-down mushroom).
				draw_circle(center, size * 0.8, dark)
				draw_circle(center + Vector2(-size * 0.25, -size * 0.25), size * 0.3, light)
			&"animals":
				# Diamond marker (consistent with prior animal inset).
				var animal_pts := PackedVector2Array([
					center + Vector2(0.0, -size),
					center + Vector2(size, 0.0),
					center + Vector2(0.0, size),
					center + Vector2(-size, 0.0)
				])
				draw_colored_polygon(animal_pts, dark)
			&"hybrid":
				# Composite dot (lichen-like).
				draw_circle(center, size * 0.7, light)
				draw_circle(center, size * 0.35, dark)
			_:
				draw_circle(center, size * 0.5, dark)


var _tile_occupants: Dictionary[Vector2i, Dictionary] = {}
var _species_by_id: Dictionary[StringName, SpeciesData] = {}
var _biome_textures: Dictionary[StringName, Texture2D] = {}
var _biome_sprites: Dictionary[Vector2i, Sprite2D] = {}
# Per-tile composite Node2D parented at tile center; holds species icons +
# animal marker + symbiosis ring as children.
var _tile_composites: Dictionary[Vector2i, Node2D] = {}
var _overlay_layer: Node2D
var _edges_overlay: _EdgesOverlay
var _fog_overlay: _FogOverlay
var _halo_overlay: _HaloOverlay
var _pulse_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _revealed_set: Dictionary[Vector2i, bool] = {}
var _obstacle_set: Dictionary[Vector2i, bool] = {}
var _structure_halos: Dictionary[String, Array] = {}
var _halo_colors: Dictionary[String, Color] = {}
# Phase E: structures that fuse their tiles into one composite render.
# _fusion_kinds maps active-structure key -> structure id (e.g. &"fairy_ring").
# _fusion_anchors maps key -> anchor coord for the draw routine.
# _fusion_footprints maps key -> Array[Vector2i] (all tiles to hide composites on).
var _fusion_kinds: Dictionary[String, StringName] = {}
var _fusion_anchors: Dictionary[String, Vector2i] = {}
var _fusion_footprints: Dictionary[String, Array] = {}
var _fusion_overlay: _StructureFusionOverlay

# Structures that fuse their constituent tiles (hide individual species
# composites within the footprint and draw as one). Pilot: fairy_ring only.
# Add more entries here as composites are authored.
const _FUSION_STRUCTURE_IDS: Dictionary[StringName, bool] = {
	&"fairy_ring": true
}

# Phase 15a maturation tracking.
const MATURATION_SPROUTING_TICKS: int = 15
const MATURATION_MATURE_TICKS: int = 45
const AGE_REFRESH_INTERVAL: int = 5
var _ticks_since_age_refresh: int = 0
var _last_stage_by_coord: Dictionary[Vector2i, int] = {}


func _ready() -> void:
	_build_species_index()
	_biome_textures = _build_biome_textures()
	_create_biome_sprite_grid()

	_overlay_layer = Node2D.new()
	_overlay_layer.name = "OccupantOverlay"
	add_child(_overlay_layer)

	_edges_overlay = _EdgesOverlay.new()
	_edges_overlay.name = "EdgesOverlay"
	_edges_overlay.tile_grid = self
	_edges_overlay.z_index = 2
	_overlay_layer.add_child(_edges_overlay)

	_halo_overlay = _HaloOverlay.new()
	_halo_overlay.name = "StructureHalos"
	_halo_overlay.tile_grid = self
	_halo_overlay.z_index = 3
	_overlay_layer.add_child(_halo_overlay)

	_fusion_overlay = _StructureFusionOverlay.new()
	_fusion_overlay.name = "StructureFusion"
	_fusion_overlay.tile_grid = self
	_fusion_overlay.z_index = 3
	_overlay_layer.add_child(_fusion_overlay)

	_fog_overlay = _FogOverlay.new()
	_fog_overlay.name = "FogOverlay"
	_fog_overlay.tile_grid = self
	_fog_overlay.z_index = 4
	_overlay_layer.add_child(_fog_overlay)

	EventBus.era_changed.connect(_on_era_changed)
	EventBus.run_loaded.connect(_on_run_loaded)
	EventBus.tick.connect(_on_tick_pulse)
	_pulse_rng.randomize()

	call_deferred("_populate")


# Public coord helpers — replace TileMap built-ins.
func map_to_local(coord: Vector2i) -> Vector2:
	return Vector2(
		float(coord.x) * float(TILE_SIZE) + float(TILE_SIZE) * 0.5,
		float(coord.y) * float(TILE_SIZE) + float(TILE_SIZE) * 0.5
	)


func local_to_map(pos: Vector2) -> Vector2i:
	return Vector2i(
		int(floor(pos.x / float(TILE_SIZE))),
		int(floor(pos.y / float(TILE_SIZE)))
	)


func _build_species_index() -> void:
	_species_by_id.clear()
	var index: SpeciesIndex = load(SPECIES_INDEX_PATH) as SpeciesIndex
	if index == null:
		return
	for species in index.species:
		if species != null:
			_species_by_id[species.id] = species


# Per-biome procedural textures. Drops the TileSet atlas approach; each biome
# is its own Texture2D assigned to one Sprite2D per cell.
func _build_biome_textures() -> Dictionary[StringName, Texture2D]:
	var out: Dictionary[StringName, Texture2D] = {}
	var era_tint: Color = _get_era_tint()
	out[&"base"] = _make_biome_texture(Color8(0x2a, 0x2a, 0x2c), Color8(0x1a, 0x1a, 0x1c), era_tint, 0.05, false, false)
	# Tundra: pale cool blue.
	out[&"tundra"] = _make_biome_texture(Color8(0xa5, 0xc8, 0xee), Color8(0x6f, 0x95, 0xc5), era_tint, 0.10, false, true)
	# Mineral vent: dark stone, orange flecks.
	out[&"mineral_vent"] = _make_biome_texture(Color8(0x3a, 0x3a, 0x40), Color8(0x26, 0x26, 0x2b), era_tint, 0.08, true, false)
	# Swamp: warm green-brown peat.
	out[&"swamp"] = _make_biome_texture(Color8(0x5a, 0x70, 0x2a), Color8(0x37, 0x4a, 0x18), era_tint, 0.10, false, false)
	# Grassland: yellow-green meadow.
	out[&"grassland"] = _make_biome_texture(Color8(0x78, 0x95, 0x4a), Color8(0x52, 0x6e, 0x2e), era_tint, 0.10, false, false)
	# Rich soil: warm umber brown.
	out[&"rich_soil"] = _make_biome_texture(Color8(0x6a, 0x55, 0x38), Color8(0x45, 0x35, 0x20), era_tint, 0.10, false, false)
	# Forest edge: cooler forest green.
	out[&"forest_edge"] = _make_biome_texture(Color8(0x4a, 0x6a, 0x35), Color8(0x2a, 0x42, 0x1e), era_tint, 0.10, false, false)
	# Rock: neutral dark gray.
	out[&"rock"] = _make_biome_texture(Color8(0x55, 0x55, 0x55), Color8(0x2a, 0x2a, 0x2c), era_tint, 0.05, false, false)
	return out


func _make_biome_texture(
	base_body: Color,
	base_border: Color,
	era_tint: Color,
	era_blend: float,
	with_flecks: bool,
	with_speckles: bool
) -> Texture2D:
	var body: Color = base_body.lerp(era_tint, era_blend)
	var border: Color = base_border.lerp(era_tint, era_blend)
	var fleck: Color = Color8(0xe8, 0x7e, 0x3a).lerp(era_tint, era_blend * 0.5)
	var speckle: Color = Color8(0xee, 0xf4, 0xff).lerp(era_tint, era_blend * 0.5)
	var img := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	# Border is proportional to tile size so it stays visible at every scale
	# we might lock to. At TILE_SIZE 48 → border 2 px (~4%); at 96 → 3 px (~6%).
	var border_w: int = maxi(2, int(TILE_SIZE / 32))
	for y in range(TILE_SIZE):
		for x in range(TILE_SIZE):
			var target: Color = body
			if x < border_w or y < border_w or x >= TILE_SIZE - border_w or y >= TILE_SIZE - border_w:
				target = border
			# Subtle dither: every 5th diagonal gets a slight darken
			elif (x + y) % 5 == 0:
				target = body.darkened(0.06)
			elif with_flecks and ((x * 3 + y * 7) % 11 == 0):
				target = fleck
			elif with_speckles and ((x * 5 + y * 3) % 13 == 0):
				target = speckle
			img.set_pixel(x, y, target)
	return ImageTexture.create_from_image(img)


func _create_biome_sprite_grid() -> void:
	# 1536 Sprite2D nodes — one per cell. Default texture replaced by
	# _populate_base_from_biomes when the nutrient system is ready.
	var base_tex: Texture2D = _biome_textures.get(&"base")
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var coord := Vector2i(x, y)
			var sprite := Sprite2D.new()
			sprite.texture = base_tex
			sprite.centered = true
			sprite.position = map_to_local(coord)
			sprite.z_index = 0
			add_child(sprite)
			_biome_sprites[coord] = sprite


func _populate() -> void:
	_populate_base_from_biomes()
	if _fog_overlay != null:
		_fog_overlay.queue_redraw()
	if _halo_overlay != null:
		_halo_overlay.queue_redraw()


func set_fog_state(revealed: Array[Vector2i]) -> void:
	_revealed_set.clear()
	for c in revealed:
		_revealed_set[c] = true
	if _fog_overlay != null:
		_fog_overlay.queue_redraw()


func reveal_tiles(coords: Array[Vector2i]) -> void:
	for c in coords:
		_revealed_set[c] = true
	if _fog_overlay != null:
		_fog_overlay.queue_redraw()


func set_obstacles(coords: Array[Vector2i]) -> void:
	_obstacle_set.clear()
	for c in coords:
		_obstacle_set[c] = true
	_populate_base_from_biomes()


func add_structure_halo(key: String, tiles: Array[Vector2i], color: Color) -> void:
	_structure_halos[key] = tiles
	_halo_colors[key] = color
	# Detect fusion-kind structures by parsing the key prefix
	# (StructureRegistry._active_key format: "<id>@<anchor>").
	var struct_id: StringName = _parse_structure_id(key)
	if _FUSION_STRUCTURE_IDS.get(struct_id, false):
		_fusion_kinds[key] = struct_id
		_fusion_anchors[key] = _parse_structure_anchor(key)
		# Footprint = the actual tile coords passed in (the ring tiles)
		# PLUS the bounding-box interior, so hidden-composite covers the
		# whole visual footprint, not just the colonized cells.
		_fusion_footprints[key] = _expand_footprint(tiles, _fusion_anchors[key], struct_id)
		# Hide composites within the footprint by repainting (composites
		# check _is_in_active_fusion and skip rendering).
		for coord in _fusion_footprints[key]:
			_repaint_tile(coord)
		if _fusion_overlay != null:
			_fusion_overlay.queue_redraw()
	_redraw_halos()


func remove_structure_halo(key: String) -> void:
	_structure_halos.erase(key)
	_halo_colors.erase(key)
	if _fusion_kinds.has(key):
		var footprint: Array = _fusion_footprints.get(key, [])
		_fusion_kinds.erase(key)
		_fusion_anchors.erase(key)
		_fusion_footprints.erase(key)
		# Restore composite visibility on tiles that just left a fused
		# structure footprint.
		for coord in footprint:
			_repaint_tile(coord)
		if _fusion_overlay != null:
			_fusion_overlay.queue_redraw()
	_redraw_halos()


func _redraw_halos() -> void:
	if _halo_overlay != null:
		_halo_overlay.queue_redraw()


func _parse_structure_id(key: String) -> StringName:
	var at: int = key.find("@")
	if at < 0:
		return StringName(key)
	return StringName(key.substr(0, at))


func _parse_structure_anchor(key: String) -> Vector2i:
	var at: int = key.find("@")
	if at < 0:
		return Vector2i.ZERO
	# Anchor format from StructureRegistry is "(x, y)" — Vector2i str().
	var rest: String = key.substr(at + 1)
	rest = rest.replace("(", "").replace(")", "").replace(" ", "")
	var parts: PackedStringArray = rest.split(",", false)
	if parts.size() != 2:
		return Vector2i.ZERO
	return Vector2i(int(parts[0]), int(parts[1]))


# Expand the structure's colonized-tile list into the full visual footprint
# that should hide composites. For fairy_ring (radius 1) that's the 3×3
# block centered on the anchor. For other future fusion kinds, switch on id.
func _expand_footprint(tiles: Array[Vector2i], anchor: Vector2i, struct_id: StringName) -> Array:
	var out: Array = []
	match struct_id:
		&"fairy_ring":
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					out.append(Vector2i(anchor.x + dx, anchor.y + dy))
		_:
			for t in tiles:
				out.append(t)
	return out


func _is_in_active_fusion(coord: Vector2i) -> bool:
	for key in _fusion_footprints.keys():
		var footprint: Array = _fusion_footprints[key]
		if footprint.has(coord):
			return true
	return false


func set_occupant(coord: Vector2i, kingdom_id: StringName, species_id: StringName) -> void:
	var occ: Dictionary = _tile_occupants.get(coord, {})
	occ[kingdom_id] = species_id
	_tile_occupants[coord] = occ
	_repaint_tile(coord)
	# Density variant for cardinal neighbors may have stepped up — repaint them.
	_repaint_neighbors(coord)


func clear_occupant(coord: Vector2i, kingdom_id: StringName) -> void:
	if not _tile_occupants.has(coord):
		return
	var occ: Dictionary = _tile_occupants[coord]
	occ.erase(kingdom_id)
	if occ.is_empty():
		_tile_occupants.erase(coord)
	else:
		_tile_occupants[coord] = occ
	_repaint_tile(coord)
	# Density variant for cardinal neighbors may have stepped down — repaint them.
	_repaint_neighbors(coord)


func clear_all_occupants(coord: Vector2i) -> void:
	_tile_occupants.erase(coord)
	_repaint_tile(coord)
	_repaint_neighbors(coord)


func _repaint_tile(coord: Vector2i) -> void:
	var occ: Dictionary = _tile_occupants.get(coord, {})
	_paint_composite(coord, occ)


# Cardinal neighbors' density variants depend on this tile's occupancy.
# Called from set/clear/clear_all_occupants so they refresh when the
# center tile changes.
func _repaint_neighbors(coord: Vector2i) -> void:
	for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var n: Vector2i = coord + offset
		if _tile_occupants.has(n):
			_repaint_tile(n)


# Composite painter (VM-B1, 2026-05-22 lock): one cluster Node2D per tile.
# Single species per tile (VM-A2 invariant), density variant chosen by
# same-kingdom neighbor count. Biome substrate stays visible underneath
# because the cluster sprite has transparent margins and gaps between
# organisms. Adjacency-symbiosis rendering (corner dots + edge highlights
# for compatible-kingdom neighbors) lands in VM-B3 as a separate pass.
func _paint_composite(coord: Vector2i, occ: Dictionary) -> void:
	# Tear down existing composite if any.
	var existing: Node2D = _tile_composites.get(coord, null)
	if existing != null:
		existing.queue_free()
		_tile_composites.erase(coord)

	if occ.is_empty():
		_last_stage_by_coord.erase(coord)
		return

	# Phase E: if this tile is inside an active fused structure footprint,
	# don't render its individual species composite — the structure overlay
	# handles the visual.
	if _is_in_active_fusion(coord):
		_last_stage_by_coord.erase(coord)
		return

	# Single-species invariant — pick the one occupant.
	var keys: Array = occ.keys()
	if keys.is_empty():
		return
	var kingdom_id: StringName = keys[0]
	var species_id: StringName = occ[kingdom_id]

	var composite := Node2D.new()
	composite.position = map_to_local(coord)
	composite.z_index = 1
	_overlay_layer.add_child(composite)
	_tile_composites[coord] = composite

	# Maturation stage drives cluster alpha + ancient rim accent.
	var age_ticks: int = _get_tile_age_ticks(coord)
	var stage: int = _maturation_stage(age_ticks)
	_last_stage_by_coord[coord] = stage

	# Density variant by same-kingdom cardinal neighbor count.
	var variant: int = _compute_density_variant(coord, kingdom_id)
	# Deterministic per-coord seed so layout is stable across redraws.
	# coord.x ∈ [0..31], coord.y ∈ [0..47]; the offset is large enough that
	# nearby tiles get visibly different layouts.
	var cluster_seed: int = coord.x * 73 + coord.y * 131

	var cluster := _SpeciesCluster.new()
	cluster.set_state(kingdom_id, _species_color(species_id), variant, cluster_seed, stage)
	composite.add_child(cluster)


# Same-kingdom 4-neighbor count → density variant. See VISUAL_DIRECTION.md
# "Ecological-stage clustering" table.
#   0      → 0 pioneer       (1-2 organisms, lots of biome visible)
#   1-2    → 1 establishing  (3 organisms, moderate cover)
#   3      → 2 established   (5 organisms, dense cluster)
#   4      → 3 mature        (grove pattern: central organism + 4 satellites)
func _compute_density_variant(coord: Vector2i, kingdom_id: StringName) -> int:
	var count: int = 0
	for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var n: Vector2i = coord + offset
		var n_occ: Dictionary = _tile_occupants.get(n, {})
		if n_occ.has(kingdom_id):
			count += 1
	if count == 0:
		return 0
	if count <= 2:
		return 1
	if count == 3:
		return 2
	return 3


func _species_color(species_id: StringName) -> Color:
	if species_id == &"":
		return Color(1, 1, 1, 1)
	var species: SpeciesData = _species_by_id.get(species_id, null)
	if species == null:
		return Color(1, 1, 1, 1)
	return species.tile_marker_color


# DEPRECATED shim.
func set_surface_owner(coord: Vector2i, kingdom_id: StringName, variant: StringName = &"") -> void:
	if kingdom_id == &"":
		clear_occupant(coord, &"plantae")
		clear_occupant(coord, &"animals")
		return
	if kingdom_id == &"plantae":
		set_occupant(coord, &"plantae", &"pioneer_grass")
	elif kingdom_id == &"animals":
		var species_id: StringName = &"common_predator" if variant == &"animals_predator" else &"common_grazer"
		set_occupant(coord, &"animals", species_id)


# DEPRECATED shim.
func set_subsurface_owner(coord: Vector2i, kingdom_id: StringName, variant: StringName = &"") -> void:
	if kingdom_id == &"":
		clear_occupant(coord, &"fungi")
		return
	if kingdom_id == &"fungi":
		var species_id: StringName = &"mycelium_thread_mycorrhizal" if variant == &"mycorrhizal" else &"mycelium_thread"
		set_occupant(coord, &"fungi", species_id)


func clear_owned() -> void:
	_tile_occupants.clear()
	for coord in _tile_composites.keys():
		var c: Node2D = _tile_composites[coord]
		if c != null:
			c.queue_free()
	_tile_composites.clear()
	_structure_halos.clear()
	_halo_colors.clear()
	_last_stage_by_coord.clear()
	_redraw_halos()


func _on_era_changed(_era_id: StringName) -> void:
	# NutrientSystem may need to refresh biome map first.
	call_deferred("_rebuild_base_visuals")


func _on_run_loaded(_save_version: int) -> void:
	call_deferred("_rebuild_base_visuals")


func _rebuild_base_visuals() -> void:
	_biome_textures = _build_biome_textures()
	_populate_base_from_biomes()


func _populate_base_from_biomes() -> void:
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var coord := Vector2i(x, y)
			var biome_id: StringName = _biome_id_for_coord(coord)
			var tex: Texture2D = _biome_textures.get(biome_id, _biome_textures.get(&"base"))
			var sprite: Sprite2D = _biome_sprites.get(coord, null)
			if sprite != null and tex != null:
				sprite.texture = tex


func _biome_id_for_coord(coord: Vector2i) -> StringName:
	if _obstacle_set.has(coord):
		return &"rock"
	var nutrients: Node = _get_nutrient_system()
	if nutrients == null or not nutrients.has_method("get_biome_at"):
		return &"base"
	var biome: BiomeData = nutrients.get_biome_at(coord)
	if biome == null:
		return &"base"
	return biome.id


func _get_nutrient_system() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null("World/Systems/NutrientSystem")


func _get_era_tint() -> Color:
	var era_system: Node = _get_era_system()
	if era_system == null or not era_system.has_method("get_current_era"):
		return Color(1, 1, 1, 1)
	var era: EraData = era_system.get_current_era()
	if era == null:
		return Color(1, 1, 1, 1)
	return era.tint_color


func _get_era_system() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null("EraSystem")


func _get_tile_age_ticks(coord: Vector2i) -> int:
	var territory: Node = _get_territory_for_age()
	if territory == null or not territory.has_method("get_tile_placed_tick"):
		return 0
	var placed: int = territory.get_tile_placed_tick(coord)
	var stats: Dictionary = GameState.run_save.get("statistics", {}) as Dictionary
	var current: int = int(stats.get("tick_count", 0))
	return maxi(0, current - placed)


func _maturation_stage(age_ticks: int) -> int:
	if age_ticks < MATURATION_SPROUTING_TICKS:
		return 0
	if age_ticks < MATURATION_SPROUTING_TICKS + MATURATION_MATURE_TICKS:
		return 1
	return 2


func _get_territory_for_age() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null("World/Systems/TerritorySystem")


func _on_tick_pulse(_delta: float) -> void:
	if PULSE_CHANCE > 0.0:
		for coord in _tile_composites.keys():
			if _pulse_rng.randf() > PULSE_CHANCE:
				continue
			_pulse_tile(coord)
	# Maturation refresh: only repaint composites whose stage actually changed.
	_ticks_since_age_refresh += 1
	if _ticks_since_age_refresh >= AGE_REFRESH_INTERVAL:
		_ticks_since_age_refresh = 0
		for coord in _tile_occupants.keys():
			var stage: int = _maturation_stage(_get_tile_age_ticks(coord))
			if _last_stage_by_coord.get(coord, -1) == stage:
				continue
			_repaint_tile(coord)


func _pulse_tile(_coord: Vector2i) -> void:
	# Slime-mold pulse parked. Reintroduce as a flow effect (cluster centroid
	# outward) rather than per-tile sampling once design re-locked.
	return
