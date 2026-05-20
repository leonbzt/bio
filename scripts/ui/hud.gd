extends Control

const RESOURCE_ORDER: Array[StringName] = [
	ResourceLedger.BIOMASS,
	ResourceLedger.NUTRIENTS,
	ResourceLedger.SUNLIGHT,
	ResourceLedger.DECAY,
	ResourceLedger.SPORES
]

const RESOURCE_NAMES: Dictionary = {
	ResourceLedger.BIOMASS: "Biomass",
	ResourceLedger.NUTRIENTS: "Nutrients",
	ResourceLedger.SUNLIGHT: "Sunlight",
	ResourceLedger.DECAY: "Decay",
	ResourceLedger.SPORES: "Spores"
}

const SPECIES_INDEX_PATH: String = "res://data/species/_index.tres"
const EVENT_INDEX_PATH: String = "res://data/events/_index.tres"

@onready var _tick_indicator: ColorRect = $TickIndicator
@onready var _abilities_bar: HBoxContainer = $AbilitiesBar
@onready var _pause_button: Button = $PauseButton
@onready var _toast_panel: PanelContainer = $EventToast
@onready var _toast_title: Label = $EventToast/ToastContent/ToastTitle
@onready var _toast_body: Label = $EventToast/ToastContent/ToastBody
@onready var _identity_label: Label = $IdentityStrip/IdentityLabel
@onready var _biomass_label: Label = $Bar/Margin/ResourcesRow/Resources/BiomassLabel
@onready var _nutrients_label: Label = $Bar/Margin/ResourcesRow/Resources/NutrientsLabel
@onready var _sunlight_label: Label = $Bar/Margin/ResourcesRow/Resources/SunlightLabel
@onready var _decay_label: Label = $Bar/Margin/ResourcesRow/Resources/DecayLabel
@onready var _spores_label: Label = $Bar/Margin/ResourcesRow/Resources/SporesLabel
@onready var _ability_system: Node = get_node("../../Systems/AbilitySystem")
@onready var _pause_menu: Control = get_node("../PauseMenu")
@onready var _bar_panel: PanelContainer = $Bar
@onready var _identity_strip: PanelContainer = $IdentityStrip

var _labels: Dictionary[StringName, Label] = {}
var _is_replaying: bool = false
var _events_by_id: Dictionary[StringName, EventData] = {}
var _species_by_id: Dictionary[StringName, SpeciesData] = {}
var _toast_event_id: StringName = StringName()
var _toast_tween: Tween = null
var _buttons_by_id: Dictionary[StringName, Button] = {}


func _ready() -> void:
	_bind_labels()
	_sync_labels()
	_build_event_index()
	_build_species_index()
	_pause_button.pressed.connect(_on_pause_pressed)
	EventBus.resource_changed.connect(_on_resource_changed)
	EventBus.tick.connect(_on_tick)
	EventBus.input_mode_changed.connect(_on_input_mode_changed)
	EventBus.event_started.connect(_on_event_started)
	EventBus.event_resolved.connect(_on_event_resolved)
	EventBus.replay_started.connect(_on_replay_started)
	EventBus.replay_finished.connect(_on_replay_finished)
	EventBus.run_started.connect(_on_run_started)
	EventBus.run_loaded.connect(_on_run_loaded_for_ui)
	EventBus.era_transition_started.connect(_on_era_transition_started)
	EventBus.evolution_node_unlocked.connect(func(_id): _refresh_abilities())
	_refresh_identity_strip()
	_refresh_abilities()


func _bind_labels() -> void:
	_labels = {
		ResourceLedger.BIOMASS: _biomass_label,
		ResourceLedger.NUTRIENTS: _nutrients_label,
		ResourceLedger.SUNLIGHT: _sunlight_label,
		ResourceLedger.DECAY: _decay_label,
		ResourceLedger.SPORES: _spores_label
	}
	# Apply per-resource colors from the identity palette so each metric has
	# its own visual voice in the HUD.
	for resource_id in _labels.keys():
		_labels[resource_id].add_theme_color_override(
			"font_color", KingdomTheme.resource_color(resource_id)
		)


func _sync_labels() -> void:
	for resource_id in RESOURCE_ORDER:
		_labels[resource_id].text = _format_resource(resource_id, ResourceLedger.get_amount(resource_id))


func _on_resource_changed(resource_id: StringName, new_amount: float) -> void:
	if _labels.has(resource_id):
		_labels[resource_id].text = _format_resource(resource_id, new_amount)
	_refresh_abilities()


func _on_tick(_delta_seconds: float) -> void:
	if _is_replaying:
		return
	var tween := create_tween()
	_tick_indicator.modulate.a = 1.0
	tween.tween_property(_tick_indicator, "modulate:a", 0.3, 0.1)
	tween.tween_property(_tick_indicator, "modulate:a", 1.0, 0.1)
	_refresh_abilities()


func _on_replay_started(_ticks: int) -> void:
	_is_replaying = true


func _on_replay_finished() -> void:
	_is_replaying = false


func _on_run_started(_kingdom_id: StringName) -> void:
	_refresh_identity_strip()
	_refresh_abilities()
	_apply_kingdom_theme()


func _on_run_loaded_for_ui(_save_version: int) -> void:
	_refresh_identity_strip()
	_refresh_abilities()
	_apply_kingdom_theme()


func _apply_kingdom_theme() -> void:
	# Tint the HUD chrome (resource bar + identity strip) in the current
	# kingdom's surface color. Subtle but consistent visual identity.
	var k: StringName = KingdomTheme.current_kingdom_id()
	if k == &"":
		return
	if _bar_panel != null:
		_bar_panel.add_theme_stylebox_override("panel", KingdomTheme.panel_stylebox(k))
	if _identity_strip != null:
		_identity_strip.add_theme_stylebox_override("panel", KingdomTheme.panel_stylebox(k))


func _format_resource(resource_id: StringName, amount: float) -> String:
	var name: String = RESOURCE_NAMES.get(resource_id, String(resource_id))
	return "%s: %s" % [name, FormatUtils.abbreviate(amount)]


func _on_input_mode_changed(_mode: StringName) -> void:
	for id in _buttons_by_id.keys():
		var button: Button = _buttons_by_id[id]
		if button != null:
			button.modulate = Color(1.0, 1.0, 1.0)


func _on_pause_pressed() -> void:
	if _pause_menu != null and _pause_menu.has_method("toggle"):
		_pause_menu.toggle()


func _build_event_index() -> void:
	_events_by_id.clear()
	var index := load(EVENT_INDEX_PATH)
	if index == null or not (index is EventIndex):
		push_error("HUD: missing event index at %s" % EVENT_INDEX_PATH)
		return
	for event_data in (index as EventIndex).events:
		if event_data != null:
			_events_by_id[event_data.id] = event_data


func _build_species_index() -> void:
	_species_by_id.clear()
	var index: SpeciesIndex = load(SPECIES_INDEX_PATH) as SpeciesIndex
	if index == null:
		return
	for species in index.species:
		if species != null:
			_species_by_id[species.id] = species


func _on_event_started(event_id: StringName, _payload: Dictionary) -> void:
	_toast_event_id = event_id
	var title: String = String(event_id)
	var body: String = ""
	if _events_by_id.has(event_id):
		var data: EventData = _events_by_id[event_id]
		title = data.display_name
		body = data.description
	_toast_title.text = title
	_toast_body.text = body
	_show_toast()


func _on_event_resolved(event_id: StringName, _outcome: StringName) -> void:
	if event_id != _toast_event_id:
		return
	_hide_toast()


func _show_toast() -> void:
	_toast_panel.visible = true
	_toast_panel.modulate.a = 0.0
	if _toast_tween != null:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast_panel, "modulate:a", 1.0, 0.2)
	_toast_tween.tween_interval(4.0)
	_toast_tween.tween_callback(_hide_toast)


func _hide_toast() -> void:
	if not _toast_panel.visible:
		return
	if _toast_tween != null:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast_panel, "modulate:a", 0.0, 0.2)
	_toast_tween.tween_callback(func() -> void:
		_toast_panel.visible = false
	)


func _refresh_identity_strip() -> void:
	var species_id: StringName = StringName(GameState.run_save.get("starting_species_id", ""))
	var species_name: String = String(species_id).replace("_", " ").capitalize()
	if _species_by_id.has(species_id):
		species_name = _species_by_id[species_id].display_name
	var eco_name: String = ""
	if has_node("/root/EraSystem"):
		var era_system: Node = get_node("/root/EraSystem")
		if era_system.has_method("get_current_ecosystem"):
			var eco: EcosystemData = era_system.get_current_ecosystem()
			if eco != null:
				eco_name = eco.display_name
	_identity_label.text = "%s — %s" % [species_name if species_name != "" else "No Run", eco_name]


func _on_era_transition_started(_from_era: StringName, to_era: StringName) -> void:
	if not has_node("/root/EraSystem"):
		return
	var era_system: Node = get_node("/root/EraSystem")
	if not era_system.has_method("get_era"):
		return
	var era: EraData = era_system.get_era(to_era)
	if era == null or era.transition_narrative == "":
		return
	var scene := preload("res://scenes/ui/era_transition.tscn")
	var transition := scene.instantiate()
	if transition.has_method("setup"):
		transition.setup(era.transition_narrative)
	get_parent().add_child(transition)


func _refresh_abilities() -> void:
	if _ability_system == null or not _ability_system.has_method("get_all_abilities"):
		return
	var usable: Array = _ability_system.get_all_abilities()
	var seen: Dictionary = {}
	for ability in usable:
		if ability == null:
			continue
		if _ability_system.has_method("is_ability_available"):
			if not _ability_system.is_ability_available(ability.id):
				continue
		seen[ability.id] = true
		if not _buttons_by_id.has(ability.id):
			var button := Button.new()
			button.text = String(ability.display_name)
			button.pressed.connect(func() -> void:
				if _ability_system.has_method("request_ability"):
					_ability_system.request_ability(ability.id)
			)
			_abilities_bar.add_child(button)
			_buttons_by_id[ability.id] = button
		if _ability_system.has_method("can_afford_ability"):
			_buttons_by_id[ability.id].disabled = not _ability_system.can_afford_ability(ability.id)
		else:
			_buttons_by_id[ability.id].disabled = false
	for id in _buttons_by_id.keys():
		if seen.has(id):
			continue
		var button: Button = _buttons_by_id[id]
		if button != null:
			button.queue_free()
		_buttons_by_id.erase(id)
