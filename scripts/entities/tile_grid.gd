extends TileMap

const GRID_WIDTH: int = 32
const GRID_HEIGHT: int = 48
const TILE_SIZE: int = 16
const SOURCE_ID: int = 0
const ATLAS_BASE: Vector2i = Vector2i(0, 0)
const ATLAS_BIOME_TUNDRA: Vector2i = Vector2i(1, 0)
const ATLAS_BIOME_MINERAL_VENT: Vector2i = Vector2i(2, 0)
const ATLAS_BIOME_SWAMP: Vector2i = Vector2i(3, 0)
const ATLAS_BIOME_GRASSLAND: Vector2i = Vector2i(4, 0)
const ATLAS_BIOME_RICH_SOIL: Vector2i = Vector2i(5, 0)
const ATLAS_BIOME_FOREST_EDGE: Vector2i = Vector2i(6, 0)

const LAYER_BASE: int = 0

const SPECIES_INDEX_PATH: String = "res://data/species/_index.tres"

const BIOME_ATLAS_BY_ID: Dictionary[StringName, Vector2i] = {
	&"grassland": ATLAS_BIOME_GRASSLAND,
	&"rich_soil": ATLAS_BIOME_RICH_SOIL,
	&"forest_edge": ATLAS_BIOME_FOREST_EDGE,
	&"tundra": ATLAS_BIOME_TUNDRA,
	&"mineral_vent": ATLAS_BIOME_MINERAL_VENT,
	&"swamp": ATLAS_BIOME_SWAMP
}

# Symbiosis tile color (Locked palette 2026-05-18) — plantae+fungi co-occupied
# tiles get a warm-gold fill so symbiosis reads instantly. Per-species hint
# is preserved at 30% via lerp.
const SYMBIOSIS_GOLD: Color = Color(0.85, 0.72, 0.28, 1.0)
# Biome shows as a visible frame around species fills. 3px on each side =
# 6px / 16px = 37% of tile area, enough to read biome identity at a glance.
const FILL_INSET: float = 3.0
# Animal marker — small diamond at tile center, on top of any species fill.
const ANIMAL_MARKER_RADIUS: float = 3.0
# Cluster outline — drawn per-kingdom on the perimeter of contiguous
# same-species tiles. Plant outermost, fungi inset; animals use the diamond.
const EDGE_WIDTH: float = 1.0
const EDGE_INSET_PLANTAE: float = 1.5
const EDGE_INSET_FUNGI: float = 3.5
# Phase 15a: tile pulse on production tick.
# Tuned 2026-05-20 for visibility — was too subtle to feel.
const PULSE_CHANCE: float = 0.18        # ~18% of owned tiles pulse per tick (more frequent)
const PULSE_DURATION: float = 0.35      # longer hold, easier to track at a glance
const PULSE_BRIGHTNESS_BUMP: float = 0.60   # bigger flash — pops against dark biomes
class _EdgesOverlay extends Node2D:
	var tile_grid

	func _draw() -> void:
		# Cluster edges disabled 2026-05-20 — visual was wonky on irregular
		# shapes (L-clusters, holes, multi-kingdom overlap). Will revisit
		# with a different approach (single soft halo per cluster vs per-tile
		# edges) when the design is locked. Keep the overlay node so we
		# can re-enable by removing this early return.
		return

@export var tile_texture: Texture2D = preload("res://assets/art/tiles/placeholder_tile.png")

var _tile_occupants: Dictionary[Vector2i, Dictionary] = {}
var _species_by_id: Dictionary[StringName, SpeciesData] = {}
var _fill_nodes: Dictionary[Vector2i, ColorRect] = {}
var _border_nodes: Dictionary[Vector2i, Polygon2D] = {}
var _overlay_layer: Node2D
var _edges_overlay: _EdgesOverlay   # single child; _draw() renders all cluster edges
var _pulse_rng: RandomNumberGenerator = RandomNumberGenerator.new()  # Phase 15a


func _ready() -> void:
	_build_species_index()
	tile_set = _build_tileset()
	while get_layers_count() < 1:
		add_layer(get_layers_count())
	_overlay_layer = Node2D.new()
	_overlay_layer.name = "OccupantOverlay"
	add_child(_overlay_layer)
	# Single _draw() overlay draws ALL cluster edges in one pass — keeps
	# Node count flat regardless of how many tiles are colonized.
	_edges_overlay = _EdgesOverlay.new()
	_edges_overlay.name = "EdgesOverlay"
	_edges_overlay.tile_grid = self
	_edges_overlay.z_index = 2
	_overlay_layer.add_child(_edges_overlay)
	EventBus.era_changed.connect(_on_era_changed)
	EventBus.run_loaded.connect(_on_run_loaded)
	EventBus.tick.connect(_on_tick_pulse)  # Phase 15a
	_pulse_rng.randomize()  # Phase 15a
	# Deferred: on scene change (picker → world), TileGrid._ready runs before
	# NutrientSystem._ready. Calling _populate synchronously paints ATLAS_BASE
	# for every cell because NutrientSystem hasn't populated biome_map yet.
	# Deferring lets all sibling _ready hooks run first.
	call_deferred("_populate")


func _build_species_index() -> void:
	_species_by_id.clear()
	var index: SpeciesIndex = load(SPECIES_INDEX_PATH) as SpeciesIndex
	if index == null:
		return
	for species in index.species:
		if species != null:
			_species_by_id[species.id] = species


func _build_tileset() -> TileSet:
	var set := TileSet.new()
	set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = _build_atlas_texture()
	atlas.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	set.add_source(atlas, SOURCE_ID)
	atlas.create_tile(ATLAS_BASE)
	atlas.create_tile(ATLAS_BIOME_TUNDRA)
	atlas.create_tile(ATLAS_BIOME_MINERAL_VENT)
	atlas.create_tile(ATLAS_BIOME_SWAMP)
	atlas.create_tile(ATLAS_BIOME_GRASSLAND)
	atlas.create_tile(ATLAS_BIOME_RICH_SOIL)
	atlas.create_tile(ATLAS_BIOME_FOREST_EDGE)
	return set


func _build_atlas_texture() -> Texture2D:
	var base_image := tile_texture.get_image()
	if base_image.is_empty():
		return tile_texture
	base_image.convert(Image.FORMAT_RGBA8)
	var atlas_width: int = max(base_image.get_width(), TILE_SIZE) + TILE_SIZE * 6
	var atlas_height: int = max(base_image.get_height(), TILE_SIZE)
	var atlas_image := Image.create(atlas_width, atlas_height, false, Image.FORMAT_RGBA8)
	atlas_image.fill(Color(0, 0, 0, 0))
	atlas_image.blit_rect(base_image, Rect2i(Vector2i.ZERO, base_image.get_size()), Vector2i.ZERO)

	var era_tint: Color = _get_era_tint()
	for y in range(mini(TILE_SIZE, atlas_image.get_height())):
		for x in range(mini(TILE_SIZE, atlas_image.get_width())):
			var px: Color = atlas_image.get_pixel(x, y)
			atlas_image.set_pixel(x, y, px.lerp(era_tint, 0.12))

	# Tundra: more saturated cool blue-white so it reads distinctly vs the
	# placeholder gray base.
	_draw_biome_tile(
		atlas_image,
		Vector2i(TILE_SIZE, 0),
		Color8(0xa5, 0xc8, 0xee),
		Color8(0x6f, 0x95, 0xc5),
		era_tint,
		0.10,
		false
	)
	# Mineral vent: dark with orange flecks — distinct already.
	_draw_biome_tile(
		atlas_image,
		Vector2i(TILE_SIZE * 2, 0),
		Color8(0x3a, 0x3a, 0x40),
		Color8(0x26, 0x26, 0x2b),
		era_tint,
		0.08,
		true
	)
	# Swamp: richer warm green-brown so it reads distinctly from rich_soil
	# and forest_edge placeholder gray.
	_draw_biome_tile(
		atlas_image,
		Vector2i(TILE_SIZE * 3, 0),
		Color8(0x5a, 0x70, 0x2a),
		Color8(0x37, 0x4a, 0x18),
		era_tint,
		0.10,
		false
	)
	# Grassland: vivid yellow-green meadow.
	_draw_biome_tile(
		atlas_image,
		Vector2i(TILE_SIZE * 4, 0),
		Color8(0x78, 0x95, 0x4a),
		Color8(0x52, 0x6e, 0x2e),
		era_tint,
		0.10,
		false
	)
	# Rich soil: warm umber-brown, distinct from any green.
	_draw_biome_tile(
		atlas_image,
		Vector2i(TILE_SIZE * 5, 0),
		Color8(0x6a, 0x55, 0x38),
		Color8(0x45, 0x35, 0x20),
		era_tint,
		0.10,
		false
	)
	# Forest edge: darker forest green with cool undertone.
	_draw_biome_tile(
		atlas_image,
		Vector2i(TILE_SIZE * 6, 0),
		Color8(0x4a, 0x6a, 0x35),
		Color8(0x2a, 0x42, 0x1e),
		era_tint,
		0.10,
		false
	)
	return ImageTexture.create_from_image(atlas_image)


func _populate() -> void:
	_populate_base_from_biomes()


func set_occupant(coord: Vector2i, kingdom_id: StringName, species_id: StringName) -> void:
	var occ: Dictionary = _tile_occupants.get(coord, {})
	occ[kingdom_id] = species_id
	_tile_occupants[coord] = occ
	_repaint_tile_with_neighbors(coord)


func clear_occupant(coord: Vector2i, kingdom_id: StringName) -> void:
	if not _tile_occupants.has(coord):
		return
	var occ: Dictionary = _tile_occupants[coord]
	occ.erase(kingdom_id)
	if occ.is_empty():
		_tile_occupants.erase(coord)
	else:
		_tile_occupants[coord] = occ
	_repaint_tile_with_neighbors(coord)


func clear_all_occupants(coord: Vector2i) -> void:
	_tile_occupants.erase(coord)
	_repaint_tile_with_neighbors(coord)


func _repaint_tile_with_neighbors(coord: Vector2i) -> void:
	# Neighbor edge changes are picked up by the shared edge overlay redraw.
	_repaint_tile(coord)


func _repaint_tile(coord: Vector2i) -> void:
	var occ: Dictionary = _tile_occupants.get(coord, {})
	_paint_fill(coord, occ)
	_paint_border(coord, occ)
	_paint_cluster_edges(coord, occ)


func _paint_fill(coord: Vector2i, occ: Dictionary) -> void:
	var plant_id: StringName = occ.get(&"plantae", &"")
	var fungi_id: StringName = occ.get(&"fungi", &"")
	if plant_id == &"" and fungi_id == &"":
		if _fill_nodes.has(coord):
			_fill_nodes[coord].queue_free()
			_fill_nodes.erase(coord)
		return
	var fill_color: Color
	if plant_id != &"" and fungi_id != &"":
		# Symbiosis blend: 70% symbiosis-gold + 30% per-species mix.
		# Reads as symbiosis at a glance; species identity hinted at 30%.
		var species_mix: Color = _species_color(plant_id).lerp(_species_color(fungi_id), 0.5)
		fill_color = SYMBIOSIS_GOLD.lerp(species_mix, 0.30)
	elif plant_id != &"":
		fill_color = _species_color(plant_id)
	else:
		fill_color = _species_color(fungi_id)
	# Phase 15a: tile maturation visual. Tuned 2026-05-20 for clarity —
	# previous settings were too subtle to read at a glance.
	#   Sprouting: heavily desaturated + low alpha → "barely there"
	#   Mature:    untouched base color
	#   Ancient:   pronounced lightening + slight saturation boost → "lush"
	var age_ticks: int = _get_tile_age_ticks(coord)
	var stage: int = _maturation_stage(age_ticks)
	if stage == 0:    # Sprouting — desaturate hard, dim alpha
		fill_color = fill_color.lerp(Color(0.45, 0.45, 0.45, 1.0), 0.55)
		fill_color.a = 0.55
	elif stage == 2:    # Ancient — bright + slight color punch
		fill_color = fill_color.lightened(0.25)
		fill_color.a = 1.0
	# Mature (stage 1) keeps the base color untouched.

	var fill: ColorRect = _fill_nodes.get(coord, null)
	if fill == null:
		fill = ColorRect.new()
		fill.size = Vector2(TILE_SIZE - FILL_INSET * 2.0, TILE_SIZE - FILL_INSET * 2.0)
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fill.z_index = 1
		fill.position = map_to_local(coord) - Vector2(TILE_SIZE * 0.5 - FILL_INSET, TILE_SIZE * 0.5 - FILL_INSET)
		_overlay_layer.add_child(fill)
		_fill_nodes[coord] = fill
	fill.color = fill_color


func _paint_border(coord: Vector2i, occ: Dictionary) -> void:
	# Animal is drawn as a small diamond at tile center, on top of any
	# species fill. Biome stays visible as the frame around the species fill.
	var animal_id: StringName = occ.get(&"animals", &"")
	if animal_id == &"":
		if _border_nodes.has(coord):
			_border_nodes[coord].queue_free()
			_border_nodes.erase(coord)
		return
	var marker: Polygon2D = _border_nodes.get(coord, null) as Polygon2D
	if marker == null:
		marker = Polygon2D.new()
		var cx: float = TILE_SIZE * 0.5
		var cy: float = TILE_SIZE * 0.5
		marker.polygon = PackedVector2Array([
			Vector2(cx, cy - ANIMAL_MARKER_RADIUS),
			Vector2(cx + ANIMAL_MARKER_RADIUS, cy),
			Vector2(cx, cy + ANIMAL_MARKER_RADIUS),
			Vector2(cx - ANIMAL_MARKER_RADIUS, cy)
		])
		marker.position = map_to_local(coord) - Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5)
		marker.z_index = 2
		_overlay_layer.add_child(marker)
		_border_nodes[coord] = marker
	marker.color = _species_color(animal_id)


func _species_color(species_id: StringName) -> Color:
	if species_id == &"":
		return Color(1, 1, 1, 1)
	var species: SpeciesData = _species_by_id.get(species_id, null)
	if species == null:
		return Color(1, 1, 1, 1)
	return species.tile_marker_color


func _paint_cluster_edges(_coord: Vector2i, _occ: Dictionary) -> void:
	# Shared overlay redraws all cluster edges in one pass.
	_queue_edges_redraw()


func _draw_edges_for_tile(canvas: CanvasItem, coord: Vector2i, occ: Dictionary) -> void:
	if occ.has(&"plantae"):
		_draw_edges_for_kingdom(canvas, coord, &"plantae", occ[&"plantae"], EDGE_INSET_PLANTAE)
	if occ.has(&"fungi"):
		_draw_edges_for_kingdom(canvas, coord, &"fungi", occ[&"fungi"], EDGE_INSET_FUNGI)


func _draw_edges_for_kingdom(
	canvas: CanvasItem,
	coord: Vector2i,
	kingdom_id: StringName,
	species_id: StringName,
	inset: float
) -> void:
	var color: Color = _species_color(species_id)
	var tile_origin: Vector2 = map_to_local(coord) - Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5)
	var p_min: float = inset
	var p_max: float = TILE_SIZE - inset
	# UP (top edge)
	if not _neighbor_has_same_species(coord + Vector2i.UP, kingdom_id, species_id):
		canvas.draw_line(
			tile_origin + Vector2(p_min, p_min),
			tile_origin + Vector2(p_max, p_min),
			color,
			EDGE_WIDTH
		)
	# DOWN (bottom edge)
	if not _neighbor_has_same_species(coord + Vector2i.DOWN, kingdom_id, species_id):
		canvas.draw_line(
			tile_origin + Vector2(p_min, p_max),
			tile_origin + Vector2(p_max, p_max),
			color,
			EDGE_WIDTH
		)
	# LEFT
	if not _neighbor_has_same_species(coord + Vector2i.LEFT, kingdom_id, species_id):
		canvas.draw_line(
			tile_origin + Vector2(p_min, p_min),
			tile_origin + Vector2(p_min, p_max),
			color,
			EDGE_WIDTH
		)
	# RIGHT
	if not _neighbor_has_same_species(coord + Vector2i.RIGHT, kingdom_id, species_id):
		canvas.draw_line(
			tile_origin + Vector2(p_max, p_min),
			tile_origin + Vector2(p_max, p_max),
			color,
			EDGE_WIDTH
		)


func _neighbor_has_same_species(coord: Vector2i, kingdom_id: StringName, species_id: StringName) -> bool:
	var n_occ: Dictionary = _tile_occupants.get(coord, {})
	return StringName(n_occ.get(kingdom_id, &"")) == species_id


func _queue_edges_redraw() -> void:
	if _edges_overlay != null:
		_edges_overlay.queue_redraw()


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
	for coord in _fill_nodes.keys():
		_fill_nodes[coord].queue_free()
	_fill_nodes.clear()
	for coord in _border_nodes.keys():
		_border_nodes[coord].queue_free()
	_border_nodes.clear()
	_queue_edges_redraw()


func _on_era_changed(_era_id: StringName) -> void:
	# Deferred: NutrientSystem may not have updated biome_map for the new
	# ecosystem yet when era_changed fires; defer to next idle frame.
	call_deferred("_rebuild_base_visuals")


func _on_run_loaded(_save_version: int) -> void:
	# Deferred: TileGrid is a sibling BEFORE Systems in world.tscn, so this
	# handler runs synchronously before NutrientSystem._on_run_loaded
	# generates the biome map. Defer past the current frame so the painted
	# atlas reflects the regenerated biome map, not a stale/empty one.
	call_deferred("_rebuild_base_visuals")


func _rebuild_base_visuals() -> void:
	tile_set = _build_tileset()
	_populate_base_from_biomes()


func _populate_base_from_biomes() -> void:
	clear_layer(LAYER_BASE)
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var coord := Vector2i(x, y)
			set_cell(LAYER_BASE, coord, SOURCE_ID, _atlas_for_coord(coord))


func _atlas_for_coord(coord: Vector2i) -> Vector2i:
	var nutrients: Node = _get_nutrient_system()
	if nutrients == null or not nutrients.has_method("get_biome_at"):
		return ATLAS_BASE
	var biome: BiomeData = nutrients.get_biome_at(coord)
	if biome == null:
		return ATLAS_BASE
	return BIOME_ATLAS_BY_ID.get(biome.id, ATLAS_BASE)


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


func _draw_biome_tile(
	image: Image,
	origin: Vector2i,
	base_body: Color,
	base_border: Color,
	era_tint: Color,
	era_blend: float,
	with_flecks: bool
) -> void:
	var body: Color = base_body.lerp(era_tint, era_blend)
	var border: Color = base_border.lerp(era_tint, era_blend)
	var fleck_color: Color = Color8(0xe8, 0x7e, 0x3a).lerp(era_tint, era_blend * 0.5)
	for y in range(TILE_SIZE):
		for x in range(TILE_SIZE):
			var target: Color = body
			if x == 0 or y == 0 or x == TILE_SIZE - 1 or y == TILE_SIZE - 1:
				target = border
			elif with_flecks and ((x + y) % 5 == 0):
				target = fleck_color
			image.set_pixel(origin.x + x, origin.y + y, target)


# Phase 15a: maturation stage constants (mirror growth_system).
const MATURATION_SPROUTING_TICKS: int = 15
const MATURATION_MATURE_TICKS: int = 45     # mature lasts 45 ticks → ancient at 60+
const AGE_REFRESH_INTERVAL: int = 5         # repaint fills every N ticks
var _ticks_since_age_refresh: int = 0


func _get_tile_age_ticks(coord: Vector2i) -> int:
	var territory: Node = _get_territory_for_age()
	if territory == null or not territory.has_method("get_tile_placed_tick"):
		return 0
	var placed: int = territory.get_tile_placed_tick(coord)
	var stats: Dictionary = GameState.run_save.get("statistics", {}) as Dictionary
	var current: int = int(stats.get("tick_count", 0))
	return maxi(0, current - placed)


func _maturation_stage(age_ticks: int) -> int:
	# 0 = Sprouting (0-14), 1 = Mature (15-59), 2 = Ancient (60+).
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


# Phase 15a: tile pulse on tick
func _on_tick_pulse(_delta: float) -> void:
	# Sample a fraction of owned tiles to pulse this tick.
	for coord in _fill_nodes.keys():
		if _pulse_rng.randf() > PULSE_CHANCE:
			continue
		_pulse_tile(coord)
	# Periodically refresh fills so tiles crossing maturation stage boundaries
	# update their visual without waiting for an unrelated repaint.
	_ticks_since_age_refresh += 1
	if _ticks_since_age_refresh >= AGE_REFRESH_INTERVAL:
		_ticks_since_age_refresh = 0
		for coord in _tile_occupants.keys():
			var occ: Dictionary = _tile_occupants[coord]
			_paint_fill(coord, occ)


func _pulse_tile(coord: Vector2i) -> void:
	var fill: ColorRect = _fill_nodes.get(coord, null)
	if fill == null:
		return
	var base_color: Color = fill.color
	var bright_color: Color = base_color.lightened(PULSE_BRIGHTNESS_BUMP)
	# Snap-bright, brief hold, ease-out fade. Feels like a heartbeat.
	fill.color = bright_color
	var tween := create_tween()
	tween.tween_interval(0.08)                                 # hold at bright
	tween.tween_property(fill, "color", base_color, PULSE_DURATION) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_OUT)
