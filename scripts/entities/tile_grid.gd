extends TileMap

const GRID_WIDTH: int = 32
const GRID_HEIGHT: int = 48
const TILE_SIZE: int = 16
const SOURCE_ID: int = 0
const ATLAS_BASE: Vector2i = Vector2i(0, 0)
const ATLAS_PLANTAE: Vector2i = Vector2i(1, 0)
const ATLAS_FUNGI: Vector2i = Vector2i(2, 0)

const LAYER_BASE: int = 0
const LAYER_SURFACE: int = 1
const LAYER_SUBSURFACE: int = 2

@export var tile_texture: Texture2D = preload("res://assets/art/tiles/placeholder_tile.png")


func _ready() -> void:
	if tile_set == null:
		tile_set = _build_tileset()
	while get_layers_count() < 3:
		add_layer(get_layers_count())
	_populate()


func _build_tileset() -> TileSet:
	var set := TileSet.new()
	set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	var atlas := TileSetAtlasSource.new()
	atlas.texture = _build_atlas_texture()
	atlas.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	set.add_source(atlas, SOURCE_ID)
	atlas.create_tile(ATLAS_BASE)
	atlas.create_tile(ATLAS_PLANTAE)
	atlas.create_tile(ATLAS_FUNGI)

	return set


func _build_atlas_texture() -> Texture2D:
	var base_image := tile_texture.get_image()
	if base_image.is_empty():
		return tile_texture
	base_image.convert(Image.FORMAT_RGBA8)

	var atlas_image := Image.create(TILE_SIZE * 3, TILE_SIZE, false, Image.FORMAT_RGBA8)
	var rect := Rect2i(0, 0, TILE_SIZE, TILE_SIZE)
	atlas_image.blit_rect(base_image, rect, Vector2i(0, 0))

	var overlay := base_image.duplicate()
	for y in range(TILE_SIZE):
		for x in range(TILE_SIZE):
			var color: Color = overlay.get_pixel(x, y)
			var bright: Color = Color(
				min(color.r * 1.2, 1.0),
				min(color.g * 1.4, 1.0),
				min(color.b * 1.2, 1.0),
				color.a
			)
			overlay.set_pixel(x, y, bright)
	atlas_image.blit_rect(overlay, rect, Vector2i(TILE_SIZE, 0))

	var fungi := base_image.duplicate()
	var fungi_fill: Color = Color8(0x7a, 0x5f, 0xa8, 160)
	var fungi_border: Color = Color8(0x63, 0x4c, 0x87, 220)
	for y in range(TILE_SIZE):
		for x in range(TILE_SIZE):
			var is_border: bool = x == 0 or y == 0 or x == TILE_SIZE - 1 or y == TILE_SIZE - 1
			fungi.set_pixel(x, y, fungi_border if is_border else fungi_fill)
	atlas_image.blit_rect(fungi, rect, Vector2i(TILE_SIZE * 2, 0))

	return ImageTexture.create_from_image(atlas_image)


func _populate() -> void:
	clear()
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			set_cell(LAYER_BASE, Vector2i(x, y), SOURCE_ID, ATLAS_BASE)


func set_surface_owner(coord: Vector2i, kingdom_id: StringName) -> void:
	if String(kingdom_id) == "":
		erase_cell(LAYER_SURFACE, coord)
	elif kingdom_id == &"plantae":
		set_cell(LAYER_SURFACE, coord, SOURCE_ID, ATLAS_PLANTAE)


func set_subsurface_owner(coord: Vector2i, kingdom_id: StringName) -> void:
	if String(kingdom_id) == "":
		erase_cell(LAYER_SUBSURFACE, coord)
	elif kingdom_id == &"fungi":
		set_cell(LAYER_SUBSURFACE, coord, SOURCE_ID, ATLAS_FUNGI)


func clear_owned() -> void:
	clear_layer(LAYER_SURFACE)
	clear_layer(LAYER_SUBSURFACE)
