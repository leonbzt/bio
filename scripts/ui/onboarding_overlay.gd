extends Control

const CHECKPOINT_TEXT: Dictionary[StringName, String] = {
	&"place_hero": "Place your first Calamites on a wetland tile (dark green-brown). It thrives in wet ground.",
	&"unlock_mycorrhizal": "Soil nutrients run thin. Mycorrhizal Network turns dead litter into nutrients. Place it adjacent to your Calamites.",
	&"unlock_arthropleura": "Dead matter piling up. Arthropleura eats litter and feeds the fungi. Place it nearby.",
	&"bottleneck_nutrients": "Your nutrients pool is depleted. Place another Mycorrhizal Network.",
	&"bottleneck_detritus": "Your detritus pool is depleted. Place another Arthropleura.",
	&"run_complete": "The forest is self-sustaining. Run complete."
}
const CHECKPOINT_ORDER: Array[StringName] = [
	&"place_hero",
	&"unlock_mycorrhizal",
	&"unlock_arthropleura",
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
	EventBus.species_introduced.connect(_on_species_introduced)
	var territory: Node = get_tree().root.get_node_or_null("World/Systems/TerritorySystem")
	if territory != null and territory.has_method("get_kingdom_tile_count"):
		if int(territory.get_kingdom_tile_count(&"plantae")) > 0:
			_processed[&"place_hero"] = true
	var in_run: Array = GameState.run_save.get("unlocked_species_in_run", []) as Array
	if in_run.has("mycorrhizal_network"):
		_processed[&"unlock_mycorrhizal"] = true
	if in_run.has("arthropleura"):
		_processed[&"unlock_arthropleura"] = true
	var fired: Dictionary = GameState.run_save.get("checkpoints_fired", {}) as Dictionary
	for id in CHECKPOINT_ORDER:
		if bool(fired.get(String(id), false)):
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


func _on_species_introduced(species_id: StringName) -> void:
	if species_id == &"mycorrhizal_network":
		_complete_checkpoint(&"unlock_mycorrhizal")
		_complete_checkpoint(&"bottleneck_nutrients")
	elif species_id == &"arthropleura":
		_complete_checkpoint(&"unlock_arthropleura")
		_complete_checkpoint(&"bottleneck_detritus")


func _dismiss_current() -> void:
	if _queue.is_empty():
		_hide_overlay()
		return
	var id: StringName = _queue.pop_front()
	_processed[id] = true
	_refresh()


func _complete_checkpoint(id: StringName) -> void:
	if _queue.has(id):
		_queue.erase(id)
	_processed[id] = true
	_refresh()


func _hide_overlay() -> void:
	queue_free()


func _refresh() -> void:
	if _queue.is_empty():
		visible = false
		return
	visible = true
	var id: StringName = _queue[0]
	_body.text = String(CHECKPOINT_TEXT.get(id, String(id)))
	_step_label.text = "Checkpoint"
