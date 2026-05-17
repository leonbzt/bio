extends TileMap

const GRID_WIDTH: int = 32
const GRID_HEIGHT: int = 48
const TILE_SIZE: int = 16
const SOURCE_ID: int = 0
const ATLAS_BASE: Vector2i = Vector2i(0, 0)
const ATLAS_PLANTAE: Vector2i = Vector2i(1, 0)
const ATLAS_FUNGI: Vector2i = Vector2i(2, 0)
const ATLAS_PARASITE_PLANTAE: Vector2i = Vector2i(3, 0)
const ATLAS_MYCORRHIZAL_FUNGI: Vector2i = Vector2i(4, 0)
const ATLAS_ANIMAL_HERBIVORE: Vector2i = Vector2i(5, 0)
const ATLAS_ANIMAL_PREDATOR: Vector2i = Vector2i(6, 0)

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
	atlas.create_tile(ATLAS_PARASITE_PLANTAE)
	atlas.create_tile(ATLAS_MYCORRHIZAL_FUNGI)
	atlas.create_tile(ATLAS_ANIMAL_HERBIVORE)
	atlas.create_tile(ATLAS_ANIMAL_PREDATOR)

	return set


func _build_atlas_texture() -> Texture2D:
	var base_image := tile_texture.get_image()
	if base_image.is_empty():
		return tile_texture
	base_image.convert(Image.FORMAT_RGBA8)

	var atlas_image := Image.create(TILE_SIZE * 7, TILE_SIZE, false, Image.FORMAT_RGBA8)
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
	var fungi_fill: Color = Color8(0x7a, 0x5f, 0xa8, 255)
	var fungi_border: Color = Color8(0x63, 0x4c, 0x87, 255)
	for y in range(TILE_SIZE):
		for x in range(TILE_SIZE):
			var is_border: bool = x == 0 or y == 0 or x == TILE_SIZE - 1 or y == TILE_SIZE - 1
			fungi.set_pixel(x, y, fungi_border if is_border else fungi_fill)
	atlas_image.blit_rect(fungi, rect, Vector2i(TILE_SIZE * 2, 0))

	var parasite := base_image.duplicate()
	var parasite_fill: Color = Color8(0xa8, 0x42, 0x5f, 255)
	var parasite_border: Color = Color8(0x86, 0x33, 0x4a, 255)
	for y in range(TILE_SIZE):
		for x in range(TILE_SIZE):
			var is_parasite_border: bool = x == 0 or y == 0 or x == TILE_SIZE - 1 or y == TILE_SIZE - 1
			parasite.set_pixel(x, y, parasite_border if is_parasite_border else parasite_fill)
	atlas_image.blit_rect(parasite, rect, Vector2i(TILE_SIZE * 3, 0))

	var mycorrhizal := base_image.duplicate()
	var mycorrhizal_fill: Color = Color8(0x5f, 0xa8, 0x88, 255)
	var mycorrhizal_border: Color = Color8(0x4a, 0x86, 0x6d, 255)
	for y in range(TILE_SIZE):
		for x in range(TILE_SIZE):
			var is_mycorrhizal_border: bool = x == 0 or y == 0 or x == TILE_SIZE - 1 or y == TILE_SIZE - 1
			mycorrhizal.set_pixel(x, y, mycorrhizal_border if is_mycorrhizal_border else mycorrhizal_fill)
	atlas_image.blit_rect(mycorrhizal, rect, Vector2i(TILE_SIZE * 4, 0))

	var herbivore := base_image.duplicate()
	var herbivore_fill: Color = Color8(0xc4, 0x8a, 0x3f, 255)
	var herbivore_border: Color = Color8(0x8e, 0x60, 0x2a, 255)
	for y in range(TILE_SIZE):
		for x in range(TILE_SIZE):
			var is_h_border: bool = x == 0 or y == 0 or x == TILE_SIZE - 1 or y == TILE_SIZE - 1
			herbivore.set_pixel(x, y, herbivore_border if is_h_border else herbivore_fill)
	atlas_image.blit_rect(herbivore, rect, Vector2i(TILE_SIZE * 5, 0))

	var predator := base_image.duplicate()
	var predator_fill: Color = Color8(0x86, 0x33, 0x2b, 255)
	var predator_border: Color = Color8(0x5c, 0x20, 0x1c, 255)
	for y in range(TILE_SIZE):
		for x in range(TILE_SIZE):
			var is_p_border: bool = x == 0 or y == 0 or x == TILE_SIZE - 1 or y == TILE_SIZE - 1
			predator.set_pixel(x, y, predator_border if is_p_border else predator_fill)
	atlas_image.blit_rect(predator, rect, Vector2i(TILE_SIZE * 6, 0))

	return ImageTexture.create_from_image(atlas_image)


func _populate() -> void:
	clear()
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			set_cell(LAYER_BASE, Vector2i(x, y), SOURCE_ID, ATLAS_BASE)


func set_surface_owner(coord: Vector2i, kingdom_id: StringName, variant: StringName = &"") -> void:
	if String(kingdom_id) == "":
		erase_cell(LAYER_SURFACE, coord)
	elif kingdom_id == &"plantae":
		var atlas: Vector2i = ATLAS_PARASITE_PLANTAE if variant == &"parasite" else ATLAS_PLANTAE
		set_cell(LAYER_SURFACE, coord, SOURCE_ID, atlas)
	elif kingdom_id == &"animals":
		var animal_atlas: Vector2i = ATLAS_ANIMAL_PREDATOR if variant == &"animals_predator" else ATLAS_ANIMAL_HERBIVORE
		set_cell(LAYER_SURFACE, coord, SOURCE_ID, animal_atlas)


func set_subsurface_owner(coord: Vector2i, kingdom_id: StringName, variant: StringName = &"") -> void:
	if String(kingdom_id) == "":
		erase_cell(LAYER_SUBSURFACE, coord)
	elif kingdom_id == &"fungi":
		var atlas: Vector2i = ATLAS_MYCORRHIZAL_FUNGI if variant == &"mycorrhizal" else ATLAS_FUNGI
		set_cell(LAYER_SUBSURFACE, coord, SOURCE_ID, atlas)


func clear_owned() -> void:
	clear_layer(LAYER_SURFACE)
	clear_layer(LAYER_SUBSURFACE)
