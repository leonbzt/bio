extends Node

const TAP_MAX_DISTANCE: float = 8.0

var _press_pos: Vector2 = Vector2.ZERO
var _press_index: int = -1
var _moved: float = 0.0
var _active_touches: Dictionary[int, Vector2] = {}
var _mouse_down: bool = false

@onready var _tile_grid: TileMap = get_node("../../TileGrid")


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
