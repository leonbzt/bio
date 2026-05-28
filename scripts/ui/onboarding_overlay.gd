extends Control
##
## Action-triggered onboarding tooltips. Each step advances when the player
## performs the action it teaches — not on a Next button. The bubble stays
## small and non-blocking so the player can interact with the game underneath.
## State persisted in meta.onboarding_step (-1 = done, 0..STEPS.size()-1 = current).
##

# Each step: { text, advance_on: signal name, predicate: Callable(payload) -> bool }
# advance_on is an EventBus signal name. predicate (optional) gates whether
# the signal fires the advance — e.g., only "species_introduced for mycorrhizal_network".
const STEPS: Array[Dictionary] = [
	{
		"text": "Tap a [Wetland] tile (dark green-brown) to place your first Calamites. It thrives in wet ground.",
		"advance_on": &"tile_colonized",
	},
	{
		"text": "You have enough biomass — open the species panel below and introduce [Mycorrhizal Network].",
		"advance_on": &"species_introduced",
		"species_filter": &"mycorrhizal_network",
		"hide_until_affordable": &"mycorrhizal_network",
	},
	{
		"text": "Place the network next to your Calamites — the bond boosts both yields.",
		"advance_on": &"tile_colonized",
	},
	{
		"text": "Plants will die here. Their biomass piles up instead of fully decaying — that is coal forming. Watch the gauge on the left.",
		"advance_on": &"goal_progress_changed",
		"progress_threshold": 10.0,
	},
	{
		"text": "Decay is too slow to keep the loop going. Introduce [Arthropleura] — it recycles dead plant matter.",
		"advance_on": &"species_introduced",
		"species_filter": &"arthropleura",
		"hide_until_affordable": &"arthropleura",
	},
	{
		"text": "Now grow your forest. Fill the Coal Gauge to 1000 to complete the Coal Swamp.",
		"advance_on": &"ecosystem_completed",
	},
]

@onready var _backdrop: ColorRect = $Backdrop
@onready var _bubble: PanelContainer = $Bubble
@onready var _body: Label = $Bubble/Margin/VBox/Body
@onready var _step_label: Label = $Bubble/Margin/VBox/StepLabel
@onready var _next_btn: Button = $Bubble/Margin/VBox/Actions/NextButton
@onready var _skip_btn: Button = $Bubble/Margin/VBox/Actions/SkipButton

var _current: int = 0
var _species_by_id: Dictionary[StringName, SpeciesData] = {}


static func should_show() -> bool:
	# Driven solely by onboarding_step: 0..N-1 = show that step, -1 = dismissed.
	return int(GameState.meta_save.get("onboarding_step", 0)) >= 0


func _ready() -> void:
	# Non-blocking: the player needs to interact with the game underneath to
	# trigger the actions this overlay is teaching. Backdrop hidden; bubble
	# accepts only its own button input.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _backdrop != null:
		_backdrop.visible = false
	_current = int(GameState.meta_save.get("onboarding_step", 0))
	if _current < 0 or _current >= STEPS.size():
		queue_free()
		return
	if _next_btn != null:
		_next_btn.visible = false  # action-triggered, no manual advance
	if _skip_btn != null:
		_skip_btn.pressed.connect(_skip)
	# Connect to every trigger signal once; per-step gating happens in _on_trigger.
	EventBus.tile_colonized.connect(_on_tile_colonized)
	EventBus.species_introduced.connect(_on_species_introduced)
	EventBus.goal_progress_changed.connect(_on_goal_progress_changed)
	EventBus.ecosystem_completed.connect(_on_ecosystem_completed)
	# Resource updates drive affordability gating — a step asking the player to
	# introduce a species stays hidden until they actually have the biomass.
	EventBus.resource_changed.connect(_on_resource_changed)
	_load_species_index()
	_refresh()


func _load_species_index() -> void:
	var index: SpeciesIndex = load("res://data/species/_index.tres") as SpeciesIndex
	if index == null:
		return
	for sp in index.species:
		if sp != null:
			_species_by_id[sp.id] = sp


func _on_resource_changed(_id: StringName, _amount: float) -> void:
	# Any resource change might flip affordability — recompute bubble visibility.
	_apply_visibility()


func _apply_visibility() -> void:
	if _current < 0 or _current >= STEPS.size():
		visible = false
		return
	var step: Dictionary = STEPS[_current]
	if step.has("hide_until_affordable"):
		var sid: StringName = StringName(step["hide_until_affordable"])
		var species: SpeciesData = _species_by_id.get(sid, null)
		if species != null and not _is_affordable(species.introduce_cost):
			visible = false
			return
	visible = true


func _is_affordable(cost: Dictionary) -> bool:
	for key in cost.keys():
		var have: float = ResourceLedger.get_amount(StringName(key))
		if have < float(cost[key]):
			return false
	return true


func _on_tile_colonized(_coord: Vector2i, _owner: StringName) -> void:
	_try_advance(&"tile_colonized", {})


func _on_species_introduced(species_id: StringName) -> void:
	_try_advance(&"species_introduced", {"species_id": species_id})


func _on_goal_progress_changed(progress: Dictionary) -> void:
	_try_advance(&"goal_progress_changed", progress)


func _on_ecosystem_completed(_eco_id: StringName) -> void:
	_try_advance(&"ecosystem_completed", {})


func _try_advance(signal_name: StringName, payload: Dictionary) -> void:
	if _current < 0 or _current >= STEPS.size():
		return
	var step: Dictionary = STEPS[_current]
	if StringName(step.get("advance_on", &"")) != signal_name:
		return
	# Per-step predicate (one of a small set).
	if step.has("species_filter"):
		if StringName(payload.get("species_id", &"")) != StringName(step["species_filter"]):
			return
	if step.has("progress_threshold"):
		if float(payload.get("value", 0.0)) < float(step["progress_threshold"]):
			return
	_advance()


func _advance() -> void:
	_current += 1
	if _current >= STEPS.size():
		_finish()
		return
	GameState.meta_save["onboarding_step"] = _current
	SaveSystem.save_now()
	_refresh()


func _skip() -> void:
	_finish()


func _finish() -> void:
	GameState.meta_save["onboarding_step"] = -1
	SaveSystem.save_now()
	queue_free()


func _refresh() -> void:
	var step: Dictionary = STEPS[_current]
	_body.text = String(step.get("text", ""))
	_step_label.text = "%d / %d" % [_current + 1, STEPS.size()]
	_apply_visibility()
