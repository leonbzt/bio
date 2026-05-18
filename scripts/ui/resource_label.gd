extends Label

@export var resource_id: StringName = &""
@export var tooltip_when_inactive: String = ""
@export var active_kingdoms: Array[StringName] = []
@export var active_niches: Array[StringName] = []

const RESOURCE_NAMES: Dictionary = {
	&"biomass": "Biomass",
	&"nutrients": "Nutrients",
	&"sunlight": "Sunlight",
	&"decay": "Decay",
	&"spores": "Spores",
	&"protein": "Protein",
	&"lifeforce": "Lifeforce",
	&"blood_cohesion": "Blood Cohesion",
	&"gray_matter": "Gray Matter",
	&"mycelial_stability": "Mycelial Stability"
}


func _ready() -> void:
	EventBus.resource_changed.connect(_on_resource_changed)
	EventBus.run_started.connect(func(_k): _refresh())
	EventBus.run_loaded.connect(func(_v): _refresh())
	_refresh()


func _on_resource_changed(resource_key: StringName, _amount: float) -> void:
	if resource_key == resource_id:
		_refresh()


func _refresh() -> void:
	if resource_id == &"":
		return
	var amount: float = ResourceLedger.get_amount(resource_id)
	var label_name: String = RESOURCE_NAMES.get(resource_id, String(resource_id))
	text = "%s: %s" % [label_name, FormatUtils.abbreviate(amount)]
	var active: bool = _is_active()
	modulate = Color(1.0, 1.0, 1.0) if active else Color(0.65, 0.65, 0.65)
	tooltip_text = "" if active else tooltip_when_inactive


func _is_active() -> bool:
	var kingdom_match: bool = active_kingdoms.is_empty() or active_kingdoms.has(GameState.current_kingdom_id)
	var starter_species: StringName = StringName(GameState.run_save.get("starting_species_id", ""))
	var niche_match: bool = active_niches.is_empty() or active_niches.has(starter_species)
	if not active_kingdoms.is_empty() and not active_niches.is_empty():
		return kingdom_match or niche_match
	return kingdom_match and niche_match
