extends Node2D
##
## TileGrid — world grid renderer.
## Sprite2D-per-tile for biome bases, procedural scatter overlay for organisms,
## flow arrows for resource transfer, buffer bars for tile fill state.
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

const FOG_COLOR: Color = Color(0.04, 0.04, 0.06, 1.0)

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






class _FlowOverlay extends Node2D:
	var tile_grid
	const COLOR_NUTRIENTS: Color = Color(1.0, 0.85, 0.35, 0.7)
	const COLOR_BIOMASS: Color = Color(0.55, 0.85, 0.40, 0.7)
	const COLOR_DETRITUS: Color = Color(0.65, 0.45, 0.28, 0.7)
	const ARROW_HEAD_PX: float = 7.0
	const LINE_WIDTH: float = 2.0
	const _OFFSETS: Array[Vector2i] = [
		Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN
	]

	func _draw() -> void:
		if tile_grid == null:
			return
		var species_index: Dictionary = tile_grid._species_by_id
		var drawn: Dictionary = {}
		for coord in tile_grid._tile_occupants.keys():
			var occupants: Dictionary = tile_grid._tile_occupants[coord]
			if occupants.is_empty():
				continue
			var species_id: StringName = occupants.values()[0]
			var consumer: SpeciesData = species_index.get(species_id, null)
			if consumer == null or consumer.consume_input.is_empty():
				continue
			for offset in _OFFSETS:
				var neighbor: Vector2i = coord + offset
				if not tile_grid._tile_occupants.has(neighbor):
					continue
				var nocc: Dictionary = tile_grid._tile_occupants[neighbor]
				if nocc.is_empty():
					continue
				var nsid: StringName = nocc.values()[0]
				var producer: SpeciesData = species_index.get(nsid, null)
				if producer == null:
					continue
				for input_v in consumer.consume_input.keys():
					var rid: StringName = StringName(input_v)
					if not _produces(producer, rid):
						continue
					var key: int = coord.x * 100000 + coord.y * 1000 + neighbor.x * 10 + neighbor.y + rid.hash()
					if drawn.has(key):
						continue
					drawn[key] = true
					_draw_arrow(
						tile_grid.map_to_local(neighbor),
						tile_grid.map_to_local(coord),
						_resource_color(rid)
					)

	func _produces(species: SpeciesData, rid: StringName) -> bool:
		for k in species.tick_yield.keys():
			if StringName(k) == rid:
				return true
		return false

	func _resource_color(rid: StringName) -> Color:
		if rid == &"nutrients":
			return COLOR_NUTRIENTS
		if rid == &"biomass":
			return COLOR_BIOMASS
		if rid == &"decay":
			return COLOR_DETRITUS
		return Color(0.7, 0.7, 0.7, 0.6)

	func _draw_arrow(from: Vector2, to: Vector2, color: Color) -> void:
		var dir: Vector2 = (to - from)
		if dir.length_squared() < 4.0:
			return
		dir = dir.normalized()
		var inset: float = tile_grid.TILE_SIZE * 0.38
		var start: Vector2 = from + dir * inset
		var end: Vector2 = to - dir * inset
		draw_line(start, end, Color(0, 0, 0, 0.4), LINE_WIDTH + 1.5)
		draw_line(start, end, color, LINE_WIDTH)
		var perp: Vector2 = Vector2(-dir.y, dir.x)
		var p1: Vector2 = end
		var p2: Vector2 = end - dir * ARROW_HEAD_PX + perp * (ARROW_HEAD_PX * 0.55)
		var p3: Vector2 = end - dir * ARROW_HEAD_PX - perp * (ARROW_HEAD_PX * 0.55)
		draw_colored_polygon([p1, p2, p3], color)


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


# VM-B1.5 (2026-05-25): procedural world-space organism scatter using the
# commissioned side-view sprites (plantae_01..04, fungi_01..04) as the
# organism icons. Each candidate is placed on a jittered world-coord
# grid, culled by tile occupancy, then drawn as a sprite anchored at
# bottom-center so it "stands" on its cell position (3/4 side-view
# feel). Candidates are y-sorted so lower-screen sprites draw over
# upper-screen ones. Animals/hybrid use procedural fallbacks until
# their sprites exist.
class _OrganismScatterOverlay extends Node2D:
	var tile_grid

	# Average spacing between organism candidate centers, in world px.
	# 20 px on 48 px tiles → ~6 candidates per fully-occupied tile.
	# Tuned sparser than the original 14 px (~12/tile) — keeps clusters
	# readable now that biome tile art is landing under the organisms.
	const CELL_SIZE: int = 20
	const JITTER_RANGE: float = 6.0

	# Sprite indices per kingdom. _01 is single organism (most common),
	# _02 small cluster, _03 denser cluster, _04 mature feature (rare).
	const _SPRITE_PATHS: Dictionary[StringName, Array] = {
		&"plantae": [
			"res://assets/art/kingdoms/plantae_01.png",
			"res://assets/art/kingdoms/plantae_02.png",
			"res://assets/art/kingdoms/plantae_03.png",
			"res://assets/art/kingdoms/plantae_04.png",
		],
		&"fungi": [
			"res://assets/art/kingdoms/fungi_01.png",
			"res://assets/art/kingdoms/fungi_02.png",
			"res://assets/art/kingdoms/fungi_03.png",
			"res://assets/art/kingdoms/fungi_04.png",
		]
	}

	# Size-class roll → (sprite_idx, scale). ~65% single small organism,
	# ~25% small cluster, ~8% denser feature, ~2% mature canopy.
	# Scales tuned for 48 px native sprites: 0.35 ~ 17 px, 0.85 ~ 40 px.
	const _SIZE_CLASSES: Array = [
		[166, 0, 0.38],   # roll < 166: sprite_01 at 0.38
		[230, 1, 0.48],   # roll < 230: sprite_02 at 0.48
		[250, 2, 0.62],   # roll < 250: sprite_03 at 0.62
		[256, 3, 0.85],   # otherwise:  sprite_04 at 0.85
	]

	static var _texture_cache: Dictionary[StringName, Array] = {}
	static var _species_texture_cache: Dictionary[StringName, Array] = {}
	static var _cache_warmed: bool = false

	static func _warm_cache() -> void:
		if _cache_warmed:
			return
		_cache_warmed = true
		for kingdom in _SPRITE_PATHS.keys():
			var paths: Array = _SPRITE_PATHS[kingdom]
			var textures: Array = []
			for path in paths:
				if ResourceLoader.exists(path):
					var tex := load(path) as Texture2D
					if tex != null:
						textures.append(tex)
			if not textures.is_empty():
				_texture_cache[kingdom] = textures
		# Per-species overrides — any species that authored tile_sprite_paths
		# gets its own cached texture array; the draw loop prefers these over
		# the kingdom fallback.
		var species_index := load("res://data/species/_index.tres")
		if species_index is SpeciesIndex:
			for species in (species_index as SpeciesIndex).species:
				if species == null or species.tile_sprite_paths.is_empty():
					continue
				var textures: Array = []
				for path in species.tile_sprite_paths:
					if path != "" and ResourceLoader.exists(path):
						var tex := load(path) as Texture2D
						if tex != null:
							textures.append(tex)
				if not textures.is_empty():
					_species_texture_cache[species.id] = textures

	func _init() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_warm_cache()

	func _draw() -> void:
		if tile_grid == null:
			return
		var occupants: Dictionary = tile_grid._tile_occupants
		if occupants.is_empty():
			return
		var ts: int = tile_grid.TILE_SIZE

		# Cell window covering the bounding box of all occupied tiles, plus
		# 1-cell bleed so candidates whose center jitters in from the next
		# tile still get evaluated.
		var min_c: Vector2i = Vector2i(2147483647, 2147483647)
		var max_c: Vector2i = Vector2i(-2147483648, -2147483648)
		for coord in occupants.keys():
			if coord.x < min_c.x: min_c.x = coord.x
			if coord.y < min_c.y: min_c.y = coord.y
			if coord.x > max_c.x: max_c.x = coord.x
			if coord.y > max_c.y: max_c.y = coord.y
		var cx_start: int = (min_c.x * ts) / CELL_SIZE - 1
		var cy_start: int = (min_c.y * ts) / CELL_SIZE - 1
		var cx_end: int = ((max_c.x + 1) * ts) / CELL_SIZE + 1
		var cy_end: int = ((max_c.y + 1) * ts) / CELL_SIZE + 1

		# Collect first, sort by y, draw back-to-front. Side-view sprites
		# need lower-screen ones on top of upper-screen ones at overlap.
		# Each entry: [pos, kingdom_id, species_id, sprite_idx, scale, alpha_mul]
		var candidates: Array = []
		for cy in range(cy_start, cy_end):
			for cx in range(cx_start, cx_end):
				var h: int = _cell_hash(cx, cy)
				var jx: float = ((float(h & 0xFF) / 255.0) * 2.0 - 1.0) * JITTER_RANGE
				var jy: float = ((float((h >> 8) & 0xFF) / 255.0) * 2.0 - 1.0) * JITTER_RANGE
				var pos := Vector2(
					float(cx * CELL_SIZE) + float(CELL_SIZE) * 0.5 + jx,
					float(cy * CELL_SIZE) + float(CELL_SIZE) * 0.5 + jy
				)
				var tile := Vector2i(
					int(floor(pos.x / float(ts))),
					int(floor(pos.y / float(ts)))
				)
				if not occupants.has(tile):
					continue
				if tile_grid._is_in_active_fusion(tile):
					continue
				var occ: Dictionary = occupants[tile]
				var keys: Array = occ.keys()
				if keys.is_empty():
					continue
				var kingdom_id: StringName = keys[0]
				var species_id: StringName = occ[kingdom_id]

				# Size-class roll picks sprite + scale.
				var roll: int = (h >> 16) & 0xFF
				var sprite_idx: int = 0
				var scale: float = 0.4
				for sc in _SIZE_CLASSES:
					if roll < sc[0]:
						sprite_idx = sc[1]
						scale = sc[2]
						break

				# Stage modulates scale only (0 sprout, 1 mature, 2 ancient).
				# Opacity stays at 1.0 — organisms read more clearly when their
				# growth is shown by size, not by fading in/out.
				var stage: int = tile_grid._last_stage_by_coord.get(tile, 1)
				var alpha_mul: float = 1.0
				var size_mul: float = [0.75, 1.0, 1.10][stage]
				scale *= size_mul

				candidates.append([pos, kingdom_id, species_id, sprite_idx, scale, alpha_mul])

		candidates.sort_custom(func(a, b): return a[0].y < b[0].y)

		for cand in candidates:
			_draw_organism(cand[0], cand[1], cand[2], cand[3], cand[4], cand[5])

	func _draw_organism(pos: Vector2, kingdom_id: StringName, species_id: StringName,
			sprite_idx: int, scale: float, alpha_mul: float) -> void:
		# Prefer per-species art when authored; fall back to kingdom-level art.
		var textures: Array = _species_texture_cache.get(species_id, [])
		if textures.is_empty():
			textures = _texture_cache.get(kingdom_id, [])
		if not textures.is_empty():
			var tex: Texture2D = textures[mini(sprite_idx, textures.size() - 1)]
			var w: float = float(tex.get_width()) * scale
			var h: float = float(tex.get_height()) * scale
			# Bottom-center anchor — sprite stands on pos (3/4 side-view).
			var rect := Rect2(pos - Vector2(w * 0.5, h), Vector2(w, h))
			var mod := Color(1.0, 1.0, 1.0, alpha_mul)
			draw_texture_rect(tex, rect, false, mod)
			return
		# Procedural fallback for animals/hybrid (no sprites yet).
		var color: Color = tile_grid._species_color(species_id)
		color.a = alpha_mul
		var size: float = 6.0 * scale
		var dark: Color = color.darkened(0.30)
		dark.a = color.a
		var light: Color = color.lightened(0.25)
		light.a = color.a
		match kingdom_id:
			&"animals":
				var d_top := pos + Vector2(0.0, -size)
				var d_right := pos + Vector2(size, 0.0)
				var d_bot := pos + Vector2(0.0, size)
				var d_left := pos + Vector2(-size, 0.0)
				draw_colored_polygon(PackedVector2Array([d_top, d_right, d_bot, d_left]), dark)
			&"hybrid":
				draw_circle(pos, size * 0.8, light)
				draw_circle(pos, size * 0.4, dark)
			_:
				draw_circle(pos, size * 0.5, dark)

	# Deterministic hash from cell coord. Stable across redraws so layout
	# doesn't shimmer when occupancy changes.
	func _cell_hash(cx: int, cy: int) -> int:
		var h: int = cx * 374761393 + cy * 668265263
		h = (h ^ (h >> 13)) * 1274126177
		h = h ^ (h >> 16)
		return h & 0x7FFFFFFF


class _SpeciesOutlineOverlay extends Node2D:
	var tile_grid

	func _draw() -> void:
		if tile_grid == null:
			return
		var ts: float = float(tile_grid.TILE_SIZE)
		for coord in tile_grid._tile_occupants.keys():
			var occupants: Dictionary = tile_grid._tile_occupants[coord]
			if occupants.is_empty():
				continue
			var species_id: StringName = occupants.values()[0]
			var species: SpeciesData = tile_grid._species_by_id.get(species_id, null)
			if species == null:
				continue
			var color: Color = species.tile_marker_color
			color.a = 0.55
			var origin: Vector2 = tile_grid.map_to_local(coord) - Vector2(ts * 0.5, ts * 0.5)
			draw_rect(Rect2(origin, Vector2(ts, ts)), color, false, 1.5)


class _BufferBarOverlay extends Node2D:
	var tile_grid
	const BAR_HEIGHT: float = 3.0
	const BAR_INSET: float = 4.0
	const COLOR_LOW: Color = Color(0.55, 0.85, 0.40, 0.8)
	const COLOR_MID: Color = Color(0.92, 0.78, 0.30, 0.8)
	const COLOR_FULL: Color = Color(0.86, 0.30, 0.30, 0.9)
	const BG_COLOR: Color = Color(0.08, 0.08, 0.10, 0.6)
	var _pulse_time: float = 0.0

	func _process(delta: float) -> void:
		_pulse_time += delta
		queue_redraw()

	func _draw() -> void:
		if tile_grid == null:
			return
		var growth: Node = tile_grid._get_growth_system()
		if growth == null or not growth.has_method("get_tile_biomass_fill"):
			return
		var ts: float = float(tile_grid.TILE_SIZE)
		var bar_width: float = ts - BAR_INSET * 2.0
		for coord in tile_grid._tile_occupants.keys():
			var occ: Dictionary = tile_grid._tile_occupants[coord]
			if occ.is_empty():
				continue
			var sid: StringName = occ.values()[0]
			var sp: SpeciesData = tile_grid._species_by_id.get(sid, null)
			if sp != null and sp.role != &"producer":
				continue
			var fill: float = float(growth.get_tile_biomass_fill(coord))
			if fill <= 0.0:
				continue
			var origin: Vector2 = tile_grid.map_to_local(coord)
			var bar_origin: Vector2 = origin + Vector2(-bar_width * 0.5, ts * 0.5 - BAR_HEIGHT - 2.0)
			draw_rect(Rect2(bar_origin, Vector2(bar_width, BAR_HEIGHT)), BG_COLOR, true)
			var color: Color = _fill_color(fill)
			if fill >= 1.0:
				color.a = 0.5 + 0.4 * abs(sin(_pulse_time * 3.0))
			draw_rect(Rect2(bar_origin, Vector2(bar_width * fill, BAR_HEIGHT)), color, true)

	func _fill_color(fill: float) -> Color:
		if fill >= 0.9:
			return COLOR_FULL
		if fill >= 0.5:
			return COLOR_MID
		return COLOR_LOW


var _tile_occupants: Dictionary[Vector2i, Dictionary] = {}
var _species_by_id: Dictionary[StringName, SpeciesData] = {}
var _biome_textures: Dictionary[StringName, Texture2D] = {}
var _biome_sprites: Dictionary[Vector2i, Sprite2D] = {}
var _overlay_layer: Node2D
var _fog_overlay: _FogOverlay
var _halo_overlay: _HaloOverlay
var _flow_overlay: _FlowOverlay
var _organism_overlay: _OrganismScatterOverlay
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
var _outline_overlay: _SpeciesOutlineOverlay
var _buffer_bar_overlay: _BufferBarOverlay

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
var _status_redraw_tick: int = 0
var _animal_harvest_accum: Dictionary[Vector2i, float] = {}
var _animal_harvest_ticks: Dictionary[Vector2i, int] = {}
const ANIMAL_FLOAT_INTERVAL: int = 4
var _soil_replenish_accum: Dictionary[Vector2i, float] = {}
var _soil_replenish_ticks: Dictionary[Vector2i, int] = {}
const SOIL_FLOAT_INTERVAL: int = 6


func _ready() -> void:
	_build_species_index()
	_biome_textures = _build_biome_textures()
	_create_biome_sprite_grid()

	_overlay_layer = Node2D.new()
	_overlay_layer.name = "OccupantOverlay"
	add_child(_overlay_layer)

	_organism_overlay = _OrganismScatterOverlay.new()
	_organism_overlay.name = "OrganismScatter"
	_organism_overlay.tile_grid = self
	_organism_overlay.z_index = 1
	_overlay_layer.add_child(_organism_overlay)

	_halo_overlay = _HaloOverlay.new()
	_halo_overlay.name = "StructureHalos"
	_halo_overlay.tile_grid = self
	_halo_overlay.z_index = 3
	_overlay_layer.add_child(_halo_overlay)

	_flow_overlay = _FlowOverlay.new()
	_flow_overlay.name = "FlowOverlay"
	_flow_overlay.tile_grid = self
	_flow_overlay.z_index = 5
	_overlay_layer.add_child(_flow_overlay)

	_fusion_overlay = _StructureFusionOverlay.new()
	_fusion_overlay.name = "StructureFusion"
	_fusion_overlay.tile_grid = self
	_fusion_overlay.z_index = 3
	_overlay_layer.add_child(_fusion_overlay)

	_outline_overlay = _SpeciesOutlineOverlay.new()
	_outline_overlay.name = "SpeciesOutline"
	_outline_overlay.tile_grid = self
	_outline_overlay.z_index = 1
	_overlay_layer.add_child(_outline_overlay)

	_buffer_bar_overlay = _BufferBarOverlay.new()
	_buffer_bar_overlay.name = "BufferBar"
	_buffer_bar_overlay.tile_grid = self
	_buffer_bar_overlay.z_index = 5
	_overlay_layer.add_child(_buffer_bar_overlay)

	_fog_overlay = _FogOverlay.new()
	_fog_overlay.name = "FogOverlay"
	_fog_overlay.tile_grid = self
	_fog_overlay.z_index = 4
	_overlay_layer.add_child(_fog_overlay)

	EventBus.era_changed.connect(_on_era_changed)
	EventBus.run_loaded.connect(_on_run_loaded)
	EventBus.tick.connect(_on_tick_pulse)
	EventBus.tile_harvested.connect(_on_tile_harvested)
	EventBus.animal_harvested.connect(_on_animal_harvested)
	EventBus.soil_replenished.connect(_on_soil_replenished)

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
	# Alpha biomes — procedural fallbacks; authored PNGs override below.
	# Wetland: warm green-brown peat (formerly &"swamp").
	out[&"wetland"] = _make_biome_texture(Color8(0x5a, 0x70, 0x2a), Color8(0x37, 0x4a, 0x18), era_tint, 0.10, false, false)
	# Open ground: charred earth — black ash for Carbo burn scar.
	out[&"open_ground"] = _make_biome_texture(Color8(0x33, 0x2a, 0x24), Color8(0x1c, 0x16, 0x12), era_tint, 0.06, false, false)
	# Lush canopy: cool deep forest green (formerly &"forest_edge").
	out[&"lush_canopy"] = _make_biome_texture(Color8(0x35, 0x55, 0x28), Color8(0x1f, 0x36, 0x18), era_tint, 0.10, false, false)
	# Tundra: pale cool blue.
	out[&"tundra"] = _make_biome_texture(Color8(0xa5, 0xc8, 0xee), Color8(0x6f, 0x95, 0xc5), era_tint, 0.10, false, true)
	# Rock: neutral dark gray (fallback for unconfigured biomes).
	out[&"rock"] = _make_biome_texture(Color8(0x55, 0x55, 0x55), Color8(0x2a, 0x2a, 0x2c), era_tint, 0.05, false, false)
	# Authored biome tile art overrides — any BiomeData with a non-null
	# `tile_texture` replaces its procedural fallback.
	var biome_index := load("res://data/biomes/_index.tres")
	if biome_index is BiomeIndex:
		for biome in (biome_index as BiomeIndex).biomes:
			if biome == null:
				continue
			if biome.tile_texture != null:
				out[biome.id] = biome.tile_texture
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
		# Scatter overlay culls organisms inside active fusion footprints
		# via _is_in_active_fusion, so a single redraw is enough.
		_request_scatter_redraw()
		if _fusion_overlay != null:
			_fusion_overlay.queue_redraw()
	_redraw_halos()


func remove_structure_halo(key: String) -> void:
	_structure_halos.erase(key)
	_halo_colors.erase(key)
	if _fusion_kinds.has(key):
		_fusion_kinds.erase(key)
		_fusion_anchors.erase(key)
		_fusion_footprints.erase(key)
		_request_scatter_redraw()
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
	_update_tile_stage(coord)
	_request_scatter_redraw()


func clear_occupant(coord: Vector2i, kingdom_id: StringName) -> void:
	if not _tile_occupants.has(coord):
		return
	var occ: Dictionary = _tile_occupants[coord]
	occ.erase(kingdom_id)
	if occ.is_empty():
		_tile_occupants.erase(coord)
	else:
		_tile_occupants[coord] = occ
	_update_tile_stage(coord)
	_request_scatter_redraw()


func clear_all_occupants(coord: Vector2i) -> void:
	_tile_occupants.erase(coord)
	_update_tile_stage(coord)
	_request_scatter_redraw()


func _update_tile_stage(coord: Vector2i) -> void:
	if not _tile_occupants.has(coord):
		_last_stage_by_coord.erase(coord)
		return
	var age_ticks: int = _get_tile_age_ticks(coord)
	_last_stage_by_coord[coord] = _maturation_stage(age_ticks)


func _request_scatter_redraw() -> void:
	if _organism_overlay != null:
		_organism_overlay.queue_redraw()
	if _flow_overlay != null:
		_flow_overlay.queue_redraw()
	if _outline_overlay != null:
		_outline_overlay.queue_redraw()
	if _buffer_bar_overlay != null:
		_buffer_bar_overlay.queue_redraw()


func _species_color(species_id: StringName) -> Color:
	if species_id == &"":
		return Color(1, 1, 1, 1)
	var species: SpeciesData = _species_by_id.get(species_id, null)
	if species == null:
		return Color(1, 1, 1, 1)
	return species.tile_marker_color


func clear_owned() -> void:
	_tile_occupants.clear()
	_structure_halos.clear()
	_halo_colors.clear()
	_last_stage_by_coord.clear()
	_animal_harvest_accum.clear()
	_animal_harvest_ticks.clear()
	_soil_replenish_accum.clear()
	_soil_replenish_ticks.clear()
	_request_scatter_redraw()
	_redraw_halos()


func _on_era_changed(_era_id: StringName) -> void:
	# NutrientSystem may need to refresh biome map first.
	call_deferred("_rebuild_base_visuals")


func _on_run_loaded(_save_version: int) -> void:
	_status_redraw_tick = 0
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




func _get_growth_system() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	var world: Node = tree.root.get_node_or_null("World")
	if world == null:
		return null
	return world.get_node_or_null("Systems/GrowthSystem")


func _get_territory_for_age() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null("World/Systems/TerritorySystem")


func _on_tick_pulse(_delta: float) -> void:
	_status_redraw_tick += 1
	if _status_redraw_tick >= 10:
		_status_redraw_tick = 0
		if _flow_overlay != null:
			_flow_overlay.queue_redraw()
	# Maturation refresh: bump stages; one global redraw if anything changed.
	_ticks_since_age_refresh += 1
	if _ticks_since_age_refresh >= AGE_REFRESH_INTERVAL:
		_ticks_since_age_refresh = 0
		var any_changed: bool = false
		for coord in _tile_occupants.keys():
			var stage: int = _maturation_stage(_get_tile_age_ticks(coord))
			if _last_stage_by_coord.get(coord, -1) == stage:
				continue
			_last_stage_by_coord[coord] = stage
			any_changed = true
		if any_changed:
			_request_scatter_redraw()


func _on_tile_harvested(coord: Vector2i, amounts: Dictionary) -> void:
	var center: Vector2 = map_to_local(coord)
	var total: float = 0.0
	for v in amounts.values():
		total += float(v)
	if total <= 0.0:
		return

	var sprite: Sprite2D = _biome_sprites.get(coord, null)
	if sprite != null:
		var tween: Tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(2.0, 2.0, 2.0, 1.0), 0.08)
		tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2)

	var combo: int = _get_harvest_combo()
	var bonus: float = 1.0 + 0.10 * float(combo)
	_spawn_harvest_float(center, total * bonus, combo)


func _on_animal_harvested(coord: Vector2i, amount: float) -> void:
	_animal_harvest_accum[coord] = _animal_harvest_accum.get(coord, 0.0) + amount
	var tick_count: int = _animal_harvest_ticks.get(coord, 0) + 1
	_animal_harvest_ticks[coord] = tick_count
	if tick_count >= ANIMAL_FLOAT_INTERVAL:
		var total: float = _animal_harvest_accum.get(coord, 0.0)
		_animal_harvest_accum[coord] = 0.0
		_animal_harvest_ticks[coord] = 0
		if total > 0.0:
			_spawn_animal_float(map_to_local(coord), total)


func _on_soil_replenished(coord: Vector2i, amount: float) -> void:
	_soil_replenish_accum[coord] = _soil_replenish_accum.get(coord, 0.0) + amount
	var tick_count: int = _soil_replenish_ticks.get(coord, 0) + 1
	_soil_replenish_ticks[coord] = tick_count
	if tick_count >= SOIL_FLOAT_INTERVAL:
		var total: float = _soil_replenish_accum.get(coord, 0.0)
		_soil_replenish_accum[coord] = 0.0
		_soil_replenish_ticks[coord] = 0
		if total > 0.0:
			_spawn_soil_float(map_to_local(coord), total)


func _get_harvest_combo() -> int:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return 0
	var router: Node = tree.root.get_node_or_null("World/Systems/TileInputRouter")
	if router != null and router.has_method("get_combo_level"):
		return router.get_combo_level()
	return 0


func _spawn_harvest_float(pos: Vector2, amount: float, combo: int = 0) -> void:
	var label := Label.new()
	label.text = "+%s" % FormatUtils.abbreviate(amount)
	var t: float = clampf(float(combo) / 5.0, 0.0, 1.0)
	var color: Color = Color(0.55, 0.85, 0.40).lerp(Color(1.0, 0.85, 0.25), t)
	label.add_theme_color_override("font_color", color)
	var font_size: int = 14 + combo * 2
	label.add_theme_font_size_override("font_size", font_size)
	label.position = pos - Vector2(20, 10)
	label.z_index = 10
	add_child(label)
	var base_scale: float = 1.0 + 0.1 * float(combo)
	label.scale = Vector2(base_scale * 1.3, base_scale * 1.3)
	var tween := create_tween()
	tween.tween_property(label, "scale", Vector2(base_scale, base_scale), 0.1).set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", pos.y - 35.0, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tween.chain().tween_callback(label.queue_free)


func _spawn_animal_float(pos: Vector2, amount: float) -> void:
	var label := Label.new()
	label.text = "+%s" % FormatUtils.abbreviate(amount)
	label.add_theme_color_override("font_color", Color(0.92, 0.72, 0.28, 0.85))
	label.add_theme_font_size_override("font_size", 11)
	label.position = pos - Vector2(14, 8)
	label.z_index = 10
	add_child(label)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", pos.y - 22.0, 1.2)
	tween.tween_property(label, "modulate:a", 0.0, 1.2).set_delay(0.4)
	tween.chain().tween_callback(label.queue_free)


func _spawn_soil_float(pos: Vector2, _amount: float) -> void:
	var label := Label.new()
	label.text = "soil +"
	label.add_theme_color_override("font_color", Color(0.45, 0.78, 0.35, 0.75))
	label.add_theme_font_size_override("font_size", 9)
	label.position = pos - Vector2(14, -4)
	label.z_index = 10
	add_child(label)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", pos.y - 8.0, 1.4)
	tween.tween_property(label, "modulate:a", 0.0, 1.4).set_delay(0.5)
	tween.chain().tween_callback(label.queue_free)
