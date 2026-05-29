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


func _load_dismissed() -> Dictionary:
	# Persistent record of bubbles the player has dismissed. Distinct from
	# CheckpointSystem's "fired" set: a checkpoint can be fired (the system
	# recorded it) without having been seen yet (overlay loaded later in
	# the frame). Only re-show on reload if NOT in dismissed.
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
	# Replay fired-but-not-dismissed checkpoints. CheckpointSystem may fire a
	# checkpoint (e.g. place_hero on run_started) before this overlay is even
	# instantiated, so the live signal is missed. Loading from save here is
	# the catch-up path. Already-dismissed checkpoints are marked processed
	# instead, so they don't re-show across sessions.
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
		# Only dismiss the bottleneck bubble if it's actually showing —
		# don't pre-empt a future post-closure bottleneck just because the
		# player placed fungi early.
		_dismiss_if_queued(&"bottleneck_nutrients")
	elif owner_id == &"animals":
		_dismiss_if_queued(&"bottleneck_detritus")


func _on_species_introduced(species_id: StringName) -> void:
	if species_id == &"mycorrhizal_network":
		_complete_checkpoint(&"unlock_mycorrhizal")
	elif species_id == &"arthropleura":
		_complete_checkpoint(&"unlock_arthropleura")


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
	# Only acts when the bubble is currently in the queue. Used for bottleneck
	# checkpoints so an early placement of fungi/animals doesn't pre-emptively
	# suppress the post-closure bottleneck bubble.
	if not _queue.has(id):
		return
	_queue.erase(id)
	_processed[id] = true
	_mark_dismissed(id)
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
