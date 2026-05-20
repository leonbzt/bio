extends ColorRect

@export var base_color: Color = Color(0.07, 0.07, 0.08, 1.0)


func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = -100
	EventBus.era_changed.connect(_on_era_changed)
	_apply()


func _on_era_changed(_era_id: StringName) -> void:
	_apply()


func _apply() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var era_system: Node = tree.root.get_node_or_null("EraSystem") if tree != null else null
	if era_system == null or not era_system.has_method("get_current_era"):
		color = base_color
		return
	var era: EraData = era_system.get_current_era()
	if era == null:
		color = base_color
		return
	color = base_color.lerp(era.tint_color, 0.25)
