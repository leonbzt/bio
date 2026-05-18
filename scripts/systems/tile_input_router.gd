extends Node

const TAP_MAX_DISTANCE: float = 8.0
const SPECIES_INDEX_PATH: String = "res://data/species/_index.tres"

var _press_pos: Vector2 = Vector2.ZERO
var _press_index: int = -1
var _moved: float = 0.0
var _active_touches: Dictionary[int, Vector2] = {}
var _mouse_down: bool = false
var _species_by_id: Dictionary[StringName, SpeciesData] = {}

@onready var _tile_grid: TileMap = get_node("../../TileGrid")
@onready var _rules: Node = get_node("/root/ColonizationRulesRegistry")
@onready var _territory: Node = get_node("../TerritorySystem")


func _ready() -> void:
	_build_species_index()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		_handle_touch(event)
		return
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		_handle_mouse(event)


func _handle_touch(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_active_touches[event.index] = event.position
			if _active_touches.size() >= 2:
				_press_index = -1
				return
			_press_pos = event.position
			_press_index = event.index
			_moved = 0.0
			return
		_active_touches.erase(event.index)
		if event.index == _press_index and _moved <= TAP_MAX_DISTANCE:
			_emit_tap(_press_pos)
		_press_index = -1
		return

	if event is InputEventScreenDrag:
		_active_touches[event.index] = event.position
		if _active_touches.size() >= 2:
			_press_index = -1
			return
		if event.index == _press_index:
			_moved += event.relative.length()


func _handle_mouse(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_mouse_down = true
			_press_pos = event.position
			_moved = 0.0
		else:
			if _mouse_down and _moved <= TAP_MAX_DISTANCE:
				_emit_tap(_press_pos)
			_mouse_down = false
		return
	if event is InputEventMouseMotion and _mouse_down:
		_moved += event.relative.length()


func _emit_tap(screen_pos: Vector2) -> void:
	if _tile_grid == null:
		return
	var canvas_xform: Transform2D = _tile_grid.get_global_transform_with_canvas()
	var local_pos: Vector2 = canvas_xform.affine_inverse() * screen_pos
	var coord: Vector2i = _tile_grid.local_to_map(local_pos)
	if coord.x < 0 or coord.x >= _tile_grid.GRID_WIDTH:
		return
	if coord.y < 0 or coord.y >= _tile_grid.GRID_HEIGHT:
		return
	EventBus.tile_tapped.emit(coord)
	if GameState.input_mode != GameState.INPUT_MODE_COLONIZE:
		return
	var species: SpeciesData = _resolve_active_placement_species()
	if species == null:
		return
	var result: Dictionary = _rules.evaluate(coord, species)
	if not result.get("valid", false):
		return
	var cost: Dictionary = result.get("cost", {})
	if not ResourceLedger.can_afford(cost):
		return
	ResourceLedger.spend_bundle(cost)
	for placement in result.get("placements", []):
		_territory.add_occupant(placement["coord"], placement["kingdom_id"], placement["species_id"])
		for key in placement.get("data", {}).keys():
			_territory.set_tile_data(placement["coord"], key, placement["data"][key])
	for key in result.get("data", {}).keys():
		_territory.set_tile_data(coord, key, result["data"][key])
	SaveSystem.save_now()


func _resolve_active_placement_species() -> SpeciesData:
	var species_id: StringName = StringName(GameState.placement_target_species_id)
	if species_id == &"":
		return null
	return _species_by_id.get(species_id, null)


func _build_species_index() -> void:
	_species_by_id.clear()
	var index: SpeciesIndex = load(SPECIES_INDEX_PATH) as SpeciesIndex
	if index == null:
		return
	for species in index.species:
		if species != null:
			_species_by_id[species.id] = species
