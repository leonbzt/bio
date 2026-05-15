extends GutTest

const WORLD_PATH: String = "res://scenes/world/tile_grid.tscn"

var _world: Node = null
var _systems: Node = null
var _territory: Node = null


func before_each() -> void:
	_world = Node.new()
	add_child_autofree(_world)
	var tile_grid_scene := load(WORLD_PATH)
	if tile_grid_scene != null and tile_grid_scene is PackedScene:
		var tile_grid := (tile_grid_scene as PackedScene).instantiate()
		_world.add_child(tile_grid)
	_systems = Node.new()
	_systems.name = "Systems"
	_world.add_child(_systems)
	_territory = load("res://scripts/systems/territory_system.gd").new()
	_territory.name = "TerritorySystem"
	_systems.add_child(_territory)
	await get_tree().process_frame


func test_add_surface_and_subsurface_same_tile() -> void:
	var coord := Vector2i(5, 7)
	assert_true(_territory.add_surface(coord, &"plantae"))
	assert_true(_territory.add_subsurface(coord, &"fungi"))
	assert_eq(_territory.get_surface_owner(coord), &"plantae")
	assert_eq(_territory.get_subsurface_owner(coord), &"fungi")


func test_remove_surface_keeps_subsurface() -> void:
	var coord := Vector2i(3, 4)
	_territory.add_surface(coord, &"plantae")
	_territory.add_subsurface(coord, &"fungi")
	_territory.remove_surface(coord, &"herbivore")
	assert_eq(_territory.get_surface_owner(coord), &"")
	assert_eq(_territory.get_subsurface_owner(coord), &"fungi")
	_territory.remove_subsurface(coord, &"cleanup")
	assert_eq(_territory.get_surface_owner(coord), &"")
	assert_eq(_territory.get_subsurface_owner(coord), &"")
