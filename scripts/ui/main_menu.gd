extends Control

const STRINGS := {
	"title": "Bio-Fantasy RPG",
	"play": "Start Run",
	"reset": "Reset Save",
	"reset_title": "Reset Save",
	"reset_body": "Delete your local save? This cannot be undone.",
	"confirm": "Reset",
	"cancel": "Cancel"
}

const WORLD_SCENE: String = "res://scenes/world/world.tscn"
const MENU_SCENE: String = "res://scenes/main/main_menu.tscn"
const CALAMITES_PATH: String = "res://data/species/calamites.tres"

@onready var _title: Label = $CenterContainer/VBoxContainer/Title
@onready var _generations_label: Label = $CenterContainer/VBoxContainer/GenerationsLabel
@onready var _play_button: Button = $CenterContainer/VBoxContainer/PlayButton
@onready var _continue_button: Button = $CenterContainer/VBoxContainer/ContinueButton
@onready var _reset_button: Button = $CenterContainer/VBoxContainer/ResetButton
@onready var _reset_dialog: ConfirmationDialog = $ResetDialog


func _ready() -> void:
	_title.text = _s("title")
	_play_button.text = _s("play")
	_continue_button.visible = false
	_reset_button.text = _s("reset")
	_refresh_generations_label()

	_reset_dialog.title = _s("reset_title")
	_reset_dialog.dialog_text = _s("reset_body")
	_reset_dialog.ok_button_text = _s("confirm")
	_reset_dialog.cancel_button_text = _s("cancel")

	_play_button.pressed.connect(_on_play_pressed)
	_reset_button.pressed.connect(_on_reset_pressed)
	_reset_dialog.confirmed.connect(_on_reset_confirmed)

	if GameState.auto_start_run:
		GameState.auto_start_run = false
		call_deferred("_on_play_pressed")


func _on_play_pressed() -> void:
	# Resume an in-progress run instead of wiping it. PrestigeSystem.start_run
	# calls _reset_run_state, so unconditionally starting from the menu would
	# silently destroy hours of progress when the player just wanted to return
	# to the world.
	if _has_active_run():
		get_tree().change_scene_to_file(WORLD_SCENE)
		return
	var species: SpeciesData = load(CALAMITES_PATH) as SpeciesData
	if species == null:
		return
	GameState.meta_save["current_ecosystem_id"] = "carbo_coal_swamp"
	GameState.meta_save["current_era_id"] = "carboniferous"
	PrestigeSystem.start_run(species)
	get_tree().change_scene_to_file(WORLD_SCENE)


func _has_active_run() -> bool:
	var run: Dictionary = GameState.run_save
	if not (run is Dictionary):
		return false
	if float(run.get("hero_biomass_lifetime_produced", 0.0)) > 0.0:
		return true
	if (run.get("tiles", []) as Array).size() > 0:
		return true
	if (run.get("organisms", []) as Array).size() > 0:
		return true
	return false


func _on_reset_pressed() -> void:
	_reset_dialog.popup_centered()


func _on_reset_confirmed() -> void:
	SaveSystem.reset_save()
	get_tree().change_scene_to_file(MENU_SCENE)


func _s(key: String) -> String:
	return String(STRINGS.get(key, ""))


const _DESCRIPTOR_THRESHOLDS: Array = [
	[101, "The Anthropocene Watches"],
	[21, "Networked Life"],
	[6, "Settled Colonies"],
	[1, "Pioneers"]
]


func _refresh_generations_label() -> void:
	var generations: int = _read_prestige_count()
	if generations <= 0:
		_generations_label.visible = false
		return
	_generations_label.visible = true
	var descriptor: String = _get_descriptor(generations)
	_generations_label.text = "%s · %d generations" % [descriptor, generations]


func _read_prestige_count() -> int:
	if GameState.meta_save is Dictionary and not (GameState.meta_save as Dictionary).is_empty():
		var stats: Dictionary = (GameState.meta_save as Dictionary).get("statistics", {})
		return int(stats.get("prestige_count", 0))
	if not FileAccess.file_exists(SaveSystem.SAVE_PATH):
		return 0
	var file := FileAccess.open(SaveSystem.SAVE_PATH, FileAccess.READ)
	if file == null:
		return 0
	var text := file.get_as_text()
	file.close()
	var parser := JSON.new()
	if parser.parse(text) != OK:
		return 0
	var data: Variant = parser.data
	if not (data is Dictionary):
		return 0
	var meta: Variant = (data as Dictionary).get("meta", {})
	if not (meta is Dictionary):
		return 0
	var stats: Variant = (meta as Dictionary).get("statistics", {})
	if not (stats is Dictionary):
		return 0
	return int((stats as Dictionary).get("prestige_count", 0))


func _get_descriptor(count: int) -> String:
	for entry in _DESCRIPTOR_THRESHOLDS:
		if count >= int(entry[0]):
			return String(entry[1])
	return "Pioneers"
