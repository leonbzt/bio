extends Node2D

@export var world_min: Vector2 = Vector2.ZERO
@export var world_max: Vector2 = Vector2(1536.0, 2304.0)

# 2026-05-22 lock: snap-zoom levels. Pinch / scroll wheel only ever lands on
# one of these values. Non-integer scales are blocked to prevent pixel-art
# shimmer on the 48-px tile grid. See docs/VISUAL_DIRECTION.md
# "Locked long-term canvas (2026-05-22)".
const ALLOWED_ZOOMS: Array[float] = [0.5, 1.0, 2.0]
const _DEFAULT_LEVEL: int = 1  # index into ALLOWED_ZOOMS → 1.0 (native 1:1)

# Cumulative pinch ratio from the start of a 2-touch gesture (or from the last
# zoom step within the same gesture) needed to trigger one step up/down.
const _PINCH_STEP_RATIO_UP: float = 1.4
const _PINCH_STEP_RATIO_DOWN: float = 0.71

@onready var _camera: Camera2D = $Camera2D

var _zoom_level: int = _DEFAULT_LEVEL
var _touches: Dictionary[int, Vector2] = {}
var _pinch_start_distance: float = 0.0


func _ready() -> void:
	# At TILE_SIZE=48 the full grid is 1536×2304. Phone viewport is 360×640.
	# Default zoom 1.0 (native 1:1) shows ~7.5×13 tiles on portrait phone —
	# strategy overview is the default state. Pinch out to 0.5 for full-map
	# (~15×26 tiles), pinch in to 2.0 for inspect (~3.75×6.7 tiles).
	if _camera != null:
		_camera.zoom = Vector2(ALLOWED_ZOOMS[_zoom_level], ALLOWED_ZOOMS[_zoom_level])


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
				_pinch_start_distance = _get_touch_distance()
		else:
			_touches.erase(event.index)
			if _touches.size() < 2:
				_pinch_start_distance = 0.0
		return

	if event is InputEventScreenDrag:
		_touches[event.index] = event.position
		if _touches.size() == 1:
			_pan_by(-event.relative / _camera.zoom.x)
			return
		if _touches.size() == 2 and _pinch_start_distance > 0.0:
			var distance: float = _get_touch_distance()
			var total_ratio: float = distance / _pinch_start_distance
			if total_ratio >= _PINCH_STEP_RATIO_UP:
				_step_zoom(1, _get_touch_center())
				_pinch_start_distance = distance
			elif total_ratio <= _PINCH_STEP_RATIO_DOWN:
				_step_zoom(-1, _get_touch_center())
				_pinch_start_distance = distance


func _handle_mouse(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_step_zoom(1, event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_step_zoom(-1, event.position)
		return

	if event is InputEventMouseMotion:
		if (event.button_mask & MOUSE_BUTTON_MASK_RIGHT) != 0:
			_pan_by(-event.relative / _camera.zoom.x)


func _pan_by(delta: Vector2) -> void:
	global_position += delta
	_clamp_position()


func _step_zoom(delta: int, screen_pos: Vector2) -> void:
	var new_level: int = clamp(_zoom_level + delta, 0, ALLOWED_ZOOMS.size() - 1)
	if new_level == _zoom_level:
		return
	var old_zoom: float = _camera.zoom.x
	var new_zoom: float = ALLOWED_ZOOMS[new_level]
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var world_before: Vector2 = global_position + (screen_pos - viewport_size * 0.5) / old_zoom
	_camera.zoom = Vector2(new_zoom, new_zoom)
	var world_after: Vector2 = global_position + (screen_pos - viewport_size * 0.5) / new_zoom
	global_position += (world_before - world_after)
	_clamp_position()
	_zoom_level = new_level


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
