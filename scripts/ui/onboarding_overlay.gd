extends Control

const CHECKPOINT_TEXT: Dictionary[StringName, String] = {
	&"place_hero": "Place your first producer on a wetland tile. Tap it to harvest biomass once it grows.",
	&"place_recycler": "Place your recycler (fungi) adjacent to your plants — it converts decay into nutrients.",
	&"place_harvester": "Place your harvester (animal) next to plants. It auto-harvests biomass and feeds the cycle.",
	&"bottleneck_nutrients": "Your tiles are starving for nutrients. Place more fungi adjacent to your plants.",
	&"bottleneck_detritus": "Decay is piling up with nowhere to go. Place another harvester nearby.",
	&"run_complete": "Ecosystem sustained. Run complete!"
}
const CHECKPOINT_ORDER: Array[StringName] = [
	&"place_hero",
	&"place_recycler",
	&"place_harvester",
	&"bottleneck_nutrients",
	&"bottleneck_detritus",
	&"run_complete"
]

@onready var _backdrop: ColorRect = $Backdrop
@onready var _body: Label = $Bubble/Margin/VBox/Body
@onready var _step_label: Label = $Bubble/Margin/VBox/StepLabel
@onready var _next_btn: Button = $Bubble/Margin/VBox/Actions/NextButton
@onready var _skip_btn: Button = $Bubble/Margin/VBox/Actions/SkipButton

var _queue: Array[StringName] = []
var _processed: Dictionary[StringName, bool] = {}


func _load_dismissed() -> Dictionary:
	return GameState.run_save.get("checkpoints_dismissed", {}) as Dictionary


func _mark_dismissed(id: StringName) -> void:
	var dismissed: Dictionary = _load_dismissed()
	dismissed[String(id)] = true
	GameState.run_save["checkpoints_dismissed"] = dismissed
	SaveSystem.save_now()


static func should_show() -> bool:
	return true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop.visible = false
	_next_btn.text = "Dismiss"
	_next_btn.visible = true
	_next_btn.pressed.connect(_dismiss_current)
	_skip_btn.text = "Hide"
	_skip_btn.pressed.connect(_hide_overlay)
	EventBus.checkpoint_triggered.connect(_on_checkpoint_triggered)
	EventBus.tile_colonized.connect(_on_tile_colonized)
	var territory: Node = get_tree().root.get_node_or_null("World/Systems/TerritorySystem")
	if territory != null and territory.has_method("get_kingdom_tile_count"):
		if int(territory.get_kingdom_tile_count(&"plantae")) > 0:
			_processed[&"place_hero"] = true
	var fired: Dictionary = GameState.run_save.get("checkpoints_fired", {}) as Dictionary
	var dismissed: Dictionary = _load_dismissed()
	for id in CHECKPOINT_ORDER:
		if not bool(fired.get(String(id), false)):
			continue
		if bool(dismissed.get(String(id), false)):
			_processed[id] = true
		else:
			_on_checkpoint_triggered(id, {})
	_refresh()


func _on_checkpoint_triggered(id: StringName, _payload: Dictionary) -> void:
	if _processed.get(id, false) or _queue.has(id):
		return
	_queue.push_back(id)
	_refresh()


func _on_tile_colonized(_coord: Vector2i, owner_id: StringName) -> void:
	if owner_id == &"plantae":
		_complete_checkpoint(&"place_hero")
	elif owner_id == &"fungi":
		_dismiss_if_queued(&"bottleneck_nutrients")
		_dismiss_if_queued(&"place_recycler")
	elif owner_id == &"animals":
		_dismiss_if_queued(&"bottleneck_detritus")
		_dismiss_if_queued(&"place_harvester")


func _dismiss_current() -> void:
	if _queue.is_empty():
		_hide_overlay()
		return
	var id: StringName = _queue.pop_front()
	_processed[id] = true
	_mark_dismissed(id)
	_refresh()


func _complete_checkpoint(id: StringName) -> void:
	if _queue.has(id):
		_queue.erase(id)
	_processed[id] = true
	_mark_dismissed(id)
	_refresh()


func _dismiss_if_queued(id: StringName) -> void:
	if not _queue.has(id):
		return
	_queue.erase(id)
	_processed[id] = true
	_mark_dismissed(id)
	_refresh()


func _hide_overlay() -> void:
	visible = false


func _refresh() -> void:
	if _queue.is_empty():
		visible = false
		return
	visible = true
	var id: StringName = _queue[0]
	_body.text = String(CHECKPOINT_TEXT.get(id, String(id)))
	_step_label.text = "Checkpoint"
