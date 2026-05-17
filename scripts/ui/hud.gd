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

const VISIBLE_RESOURCES_BY_KINGDOM := {
	&"plantae": [
		ResourceLedger.BIOMASS,
		ResourceLedger.NUTRIENTS,
		ResourceLedger.SUNLIGHT
	],
	&"fungi": [
		ResourceLedger.NUTRIENTS,
		ResourceLedger.DECAY,
		ResourceLedger.SPORES
	],
	&"animals": [
		ResourceLedger.BIOMASS
	],
	&"": [
		ResourceLedger.BIOMASS,
		ResourceLedger.NUTRIENTS,
		ResourceLedger.SUNLIGHT,
		ResourceLedger.DECAY,
		ResourceLedger.SPORES
	]
}

const EVENT_INDEX_PATH: String = "res://data/events/_index.tres"
const NICHE_INDEX_PATH: String = "res://data/niches/_index.tres"

@onready var _labels_container: Container = $Bar/Margin/ResourcesRow/Resources
@onready var _tick_indicator: ColorRect = $TickIndicator
@onready var _abilities_bar: HBoxContainer = $AbilitiesBar
@onready var _pause_button: Button = $PauseButton
@onready var _layer_toggle: HBoxContainer = $LayerToggle
@onready var _layer_plantae_button: Button = $LayerToggle/PlantaeButton
@onready var _layer_fungi_button: Button = $LayerToggle/FungiButton
@onready var _niche_badge: Label = $NicheBadge
@onready var _mycorrhizal_hint: Label = $MycorrhizalHint
@onready var _toast_panel: PanelContainer = $EventToast
@onready var _toast_title: Label = $EventToast/ToastContent/ToastTitle
@onready var _toast_body: Label = $EventToast/ToastContent/ToastBody
@onready var _biomass_label: Label = $Bar/Margin/ResourcesRow/Resources/BiomassLabel
@onready var _nutrients_label: Label = $Bar/Margin/ResourcesRow/Resources/NutrientsLabel
@onready var _sunlight_label: Label = $Bar/Margin/ResourcesRow/Resources/SunlightLabel
@onready var _decay_label: Label = $Bar/Margin/ResourcesRow/Resources/DecayLabel
@onready var _spores_label: Label = $Bar/Margin/ResourcesRow/Resources/SporesLabel
@onready var _ability_system: Node = get_node("../../Systems/AbilitySystem")
@onready var _pause_menu: Control = get_node("../PauseMenu")

var _labels: Dictionary[StringName, Label] = {}
var _is_replaying: bool = false
var _events_by_id: Dictionary[StringName, EventData] = {}
var _niches_by_id: Dictionary[StringName, NicheData] = {}
var _toast_event_id: StringName = StringName()
var _toast_tween: Tween = null
var _buttons_by_id: Dictionary[StringName, Button] = {}


func _ready() -> void:
	_bind_labels()
	_sync_labels()
	_build_event_index()
	_build_niche_index()
	_pause_button.pressed.connect(_on_pause_pressed)
	_layer_plantae_button.pressed.connect(func() -> void:
		_set_placement_target(&"plantae")
	)
	_layer_fungi_button.pressed.connect(func() -> void:
		_set_placement_target(&"fungi")
	)
	EventBus.resource_changed.connect(_on_resource_changed)
	EventBus.tick.connect(_on_tick)
	EventBus.input_mode_changed.connect(_on_input_mode_changed)
	EventBus.event_started.connect(_on_event_started)
	EventBus.event_resolved.connect(_on_event_resolved)
	EventBus.replay_started.connect(_on_replay_started)
	EventBus.replay_finished.connect(_on_replay_finished)
	EventBus.placement_target_changed.connect(_on_placement_target_changed)
	EventBus.run_started.connect(_on_run_started)
	EventBus.run_loaded.connect(_on_run_loaded_for_layer)
	EventBus.niche_changed.connect(_on_niche_changed)
	EventBus.evolution_node_unlocked.connect(func(_id): _refresh_abilities())
	_refresh_layer_toggle_visibility()
	_refresh_layer_toggle_state()
	_refresh_resource_visibility()
	_refresh_niche_badge()
	_refresh_abilities()


func _bind_labels() -> void:
	_labels = {
		ResourceLedger.BIOMASS: _biomass_label,
		ResourceLedger.NUTRIENTS: _nutrients_label,
		ResourceLedger.SUNLIGHT: _sunlight_label,
		ResourceLedger.DECAY: _decay_label,
		ResourceLedger.SPORES: _spores_label
	}


func _sync_labels() -> void:
	for resource_id in RESOURCE_ORDER:
		_labels[resource_id].text = _format_resource(
			resource_id,
			ResourceLedger.get_amount(resource_id)
		)


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
	_refresh_layer_toggle_visibility()
	_refresh_layer_toggle_state()
	_refresh_resource_visibility()
	_refresh_niche_badge()
	_refresh_abilities()


func _on_run_loaded_for_layer(_save_version: int) -> void:
	_refresh_layer_toggle_visibility()
	_refresh_layer_toggle_state()
	_refresh_resource_visibility()
	_refresh_niche_badge()
	_refresh_abilities()


func _on_niche_changed(_niche_id: StringName) -> void:
	_refresh_niche_badge()
	_refresh_abilities()


func _refresh_layer_toggle_visibility() -> void:
	_layer_toggle.visible = _is_layered_run()

func _set_placement_target(target: StringName) -> void:
	if not _is_layered_run():
		return
	GameState.placement_target = target
	EventBus.placement_target_changed.emit(target)


func _on_placement_target_changed(_target: StringName) -> void:
	_refresh_layer_toggle_state()


func _refresh_layer_toggle_state() -> void:
	var target: StringName = GameState.placement_target
	var plant_active: bool = target == &"plantae"
	var fungi_active: bool = target == &"fungi"
	_layer_plantae_button.disabled = plant_active
	_layer_fungi_button.disabled = fungi_active
	_layer_plantae_button.modulate = Color(0.55, 0.85, 0.55) if plant_active else Color(1.0, 1.0, 1.0)
	_layer_fungi_button.modulate = Color(0.78, 0.55, 0.85) if fungi_active else Color(1.0, 1.0, 1.0)


func _refresh_resource_visibility() -> void:
	var visible_set: Array = VISIBLE_RESOURCES_BY_KINGDOM.get(
		GameState.current_kingdom_id,
		VISIBLE_RESOURCES_BY_KINGDOM[&""]
	)
	for resource_id in _labels.keys():
		_labels[resource_id].visible = visible_set.has(resource_id)



func _format_resource(resource_id: StringName, amount: float) -> String:
	var name: String = RESOURCE_NAMES.get(resource_id, String(resource_id))
	return "%s: %s" % [name, FormatUtils.abbreviate(amount)]


func _on_input_mode_changed(mode: StringName) -> void:
	for id in _buttons_by_id.keys():
		var button: Button = _buttons_by_id[id]
		if button == null:
			continue
		if mode == GameState.INPUT_MODE_TARGET and GameState.input_mode == mode:
			button.modulate = Color(1.0, 1.0, 1.0)
		else:
			button.modulate = Color(1.0, 1.0, 1.0)


func _on_pause_pressed() -> void:
	if _pause_menu == null:
		return
	if _pause_menu.has_method("toggle"):
		_pause_menu.toggle()


func _build_event_index() -> void:
	_events_by_id.clear()
	var index := load(EVENT_INDEX_PATH)
	if index == null or not (index is EventIndex):
		push_error("HUD: missing event index at %s" % EVENT_INDEX_PATH)
		return
	for event_data in (index as EventIndex).events:
		if event_data == null:
			continue
		_events_by_id[event_data.id] = event_data


func _build_niche_index() -> void:
	_niches_by_id.clear()
	var index := load(NICHE_INDEX_PATH)
	if index == null or not (index is NicheIndex):
		return
	for niche in (index as NicheIndex).niches:
		if niche == null:
			continue
		_niches_by_id[niche.id] = niche


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


func _refresh_niche_badge() -> void:
	var niche_id: StringName = GameState.current_niche_id
	if niche_id == &"" or not _niches_by_id.has(niche_id):
		_niche_badge.visible = false
		_mycorrhizal_hint.visible = false
		return
	_niche_badge.text = _niches_by_id[niche_id].display_name
	_niche_badge.visible = true
	_mycorrhizal_hint.visible = (niche_id == &"mycorrhizal_fungi")


func _is_layered_run() -> bool:
	if has_node("/root/MultiLayerPlacementSystem"):
		var system: Node = get_node("/root/MultiLayerPlacementSystem")
		if system != null and system.has_method("is_layered_run"):
			return bool(system.is_layered_run())
		if system != null and system.has_meta("is_layered"):
			return bool(system.get_meta("is_layered"))
		if system != null and system.has_method("get"):
			return bool(system.get("is_layered"))
	return false


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
