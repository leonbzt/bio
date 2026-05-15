extends Node2D

@export var world_min: Vector2 = Vector2.ZERO
@export var world_max: Vector2 = Vector2(512.0, 768.0)

@onready var _camera: Camera2D = $Camera2D

var _touches: Dictionary[int, Vector2] = {}
var _last_pinch_distance: float = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		_handle_touch(event)
		return

	if OS.has_feature("mobile"):
		return
	_handle_mouse(event)


func _handle_touch(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
			if _touches.size() == 2:
				_last_pinch_distance = _get_touch_distance()
		else:
			_touches.erase(event.index)
			if _touches.size() < 2:
				_last_pinch_distance = 0.0
		return

	if event is InputEventScreenDrag:
		_touches[event.index] = event.position
		if _touches.size() == 1:
			_pan_by(-event.relative / _camera.zoom.x)
			return
		if _touches.size() == 2:
			var distance: float = _get_touch_distance()
			if _last_pinch_distance > 0.0:
				var ratio: float = distance / _last_pinch_distance
				_zoom_at(_get_touch_center(), ratio)
			_last_pinch_distance = distance


func _handle_mouse(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_at(event.position, 1.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_at(event.position, 0.9)
		return

	if event is InputEventMouseMotion:
		if (event.button_mask & MOUSE_BUTTON_MASK_RIGHT) != 0:
			_pan_by(-event.relative / _camera.zoom.x)


func _pan_by(delta: Vector2) -> void:
	global_position += delta
	_clamp_position()


func _zoom_at(screen_pos: Vector2, ratio: float) -> void:
	if ratio == 1.0:
		return
	var old_zoom: float = _camera.zoom.x
	var new_zoom: float = clamp(old_zoom * ratio, 0.5, 2.0)
	if is_equal_approx(old_zoom, new_zoom):
		return

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var world_before: Vector2 = global_position + (screen_pos - viewport_size * 0.5) / old_zoom
	_camera.zoom = Vector2(new_zoom, new_zoom)
	var world_after: Vector2 = global_position + (screen_pos - viewport_size * 0.5) / new_zoom
	global_position += (world_before - world_after)
	_clamp_position()


func _clamp_position() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var zoom: Vector2 = _camera.zoom
	var half: Vector2 = Vector2(viewport_size.x / zoom.x, viewport_size.y / zoom.y) * 0.5
	var min_pos: Vector2 = world_min + half
	var max_pos: Vector2 = world_max - half
	var pos: Vector2 = global_position

	if min_pos.x > max_pos.x:
		pos.x = (world_min.x + world_max.x) * 0.5
	else:
		pos.x = clamp(pos.x, min_pos.x, max_pos.x)

	if min_pos.y > max_pos.y:
		pos.y = (world_min.y + world_max.y) * 0.5
	else:
		pos.y = clamp(pos.y, min_pos.y, max_pos.y)

	global_position = pos


func _get_touch_center() -> Vector2:
	var keys := _touches.keys()
	var p0: Vector2 = _touches[keys[0]]
	var p1: Vector2 = _touches[keys[1]]
	return (p0 + p1) * 0.5


func _get_touch_distance() -> float:
	var keys := _touches.keys()
	var p0: Vector2 = _touches[keys[0]]
	var p1: Vector2 = _touches[keys[1]]
	return p0.distance_to(p1)
