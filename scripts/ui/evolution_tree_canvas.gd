extends Control

signal node_purchase_requested(node_id: StringName)

var _list: VBoxContainer = null


func _ready() -> void:
	if _list == null:
		_build_ui()
	refresh()


func setup(_prestige_system: Node) -> void:
	if _list == null:
		_build_ui()
	refresh()


func refresh() -> void:
	if _list == null:
		return
	for child in _list.get_children():
		child.queue_free()
	var runs: Array = GameState.meta_save.get("lineage_runs", []) as Array
	if runs.is_empty():
		var empty := Label.new()
		empty.text = "No completed runs yet."
		_list.add_child(empty)
		return
	for i in range(runs.size() - 1, -1, -1):
		var run: Dictionary = runs[i] as Dictionary
		var row := Label.new()
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.text = _format_run(run)
		_list.add_child(row)


func get_wings() -> Array[StringName]:
	return []


func get_wing_color(_wing: StringName) -> Color:
	return Color(0.5, 0.5, 0.5)


func get_wing_x(_wing: StringName) -> int:
	return 0


func _build_ui() -> void:
	var scroll := ScrollContainer.new()
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_list)


func _format_run(run: Dictionary) -> String:
	var run_index: int = int(run.get("run_index", 0))
	var biomass: float = float(run.get("biomass", 0.0))
	var ep: int = int(run.get("evolution_earned", 0))
	var date_unix: int = int(run.get("date_unix", 0))
	var date_text: String = "unknown date"
	if date_unix > 0:
		date_text = Time.get_datetime_string_from_unix_time(date_unix, true)
	return "Run #%d — biomass %s — +%d EP — %s" % [run_index, FormatUtils.abbreviate(biomass), ep, date_text]
