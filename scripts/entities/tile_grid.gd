extends TileMap

const GRID_WIDTH: int = 32
const GRID_HEIGHT: int = 48
const TILE_SIZE: int = 16
const SOURCE_ID: int = 0
const ATLAS_BASE: Vector2i = Vector2i(0, 0)

const LAYER_BASE: int = 0

const SPECIES_INDEX_PATH: String = "res://data/species/_index.tres"

@export var tile_texture: Texture2D = preload("res://assets/art/tiles/placeholder_tile.png")

var _tile_occupants: Dictionary[Vector2i, Dictionary] = {}
var _species_by_id: Dictionary[StringName, SpeciesData] = {}
var _fill_nodes: Dictionary[Vector2i, ColorRect] = {}
var _border_nodes: Dictionary[Vector2i, Line2D] = {}
var _overlay_layer: Node2D


func _ready() -> void:
	_build_species_index()
	if tile_set == null:
		tile_set = _build_tileset()
	while get_layers_count() < 1:
		add_layer(get_layers_count())
	_overlay_layer = Node2D.new()
	_overlay_layer.name = "OccupantOverlay"
	add_child(_overlay_layer)
	_populate()


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
	return set


func _build_atlas_texture() -> Texture2D:
	var base_image := tile_texture.get_image()
	if base_image.is_empty():
		return tile_texture
	base_image.convert(Image.FORMAT_RGBA8)
	return ImageTexture.create_from_image(base_image)


func _populate() -> void:
	clear()
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			set_cell(LAYER_BASE, Vector2i(x, y), SOURCE_ID, ATLAS_BASE)


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
	else:
		_tile_occupants[coord] = occ
	_repaint_tile(coord)


func clear_all_occupants(coord: Vector2i) -> void:
	_tile_occupants.erase(coord)
	_repaint_tile(coord)


func _repaint_tile(coord: Vector2i) -> void:
	var occ: Dictionary = _tile_occupants.get(coord, {})
	_paint_fill(coord, occ)
	_paint_border(coord, occ)


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
		fill_color = _species_color(plant_id).lerp(_species_color(fungi_id), 0.5).lightened(0.05)
	elif plant_id != &"":
		fill_color = _species_color(plant_id)
	else:
		fill_color = _species_color(fungi_id)
	var fill: ColorRect = _fill_nodes.get(coord, null)
	if fill == null:
		fill = ColorRect.new()
		fill.size = Vector2(TILE_SIZE, TILE_SIZE)
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fill.z_index = 1
		fill.position = map_to_local(coord) - Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5)
		_overlay_layer.add_child(fill)
		_fill_nodes[coord] = fill
	fill.color = fill_color


func _paint_border(coord: Vector2i, occ: Dictionary) -> void:
	var animal_id: StringName = occ.get(&"animals", &"")
	if animal_id == &"":
		if _border_nodes.has(coord):
			_border_nodes[coord].queue_free()
			_border_nodes.erase(coord)
		return
	var border: Line2D = _border_nodes.get(coord, null)
	if border == null:
		border = Line2D.new()
		border.width = 2.0
		border.closed = true
		border.default_color = Color.WHITE
		border.add_point(Vector2(0, 0))
		border.add_point(Vector2(TILE_SIZE, 0))
		border.add_point(Vector2(TILE_SIZE, TILE_SIZE))
		border.add_point(Vector2(0, TILE_SIZE))
		border.position = map_to_local(coord) - Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5)
		border.z_index = 2
		_overlay_layer.add_child(border)
		_border_nodes[coord] = border
	border.default_color = _species_color(animal_id)


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
	for coord in _fill_nodes.keys():
		_fill_nodes[coord].queue_free()
	_fill_nodes.clear()
	for coord in _border_nodes.keys():
		_border_nodes[coord].queue_free()
	_border_nodes.clear()
