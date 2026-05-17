extends Control

const STRINGS := {
	"title": "Bio-Fantasy RPG",
	"play": "Play",
	"continue": "Continue",
	"reset": "Reset Save",
	"reset_title": "Reset Save",
	"reset_body": "Delete your local save? This cannot be undone.",
	"confirm": "Reset",
	"cancel": "Cancel"
}

const WORLD_SCENE: String = "res://scenes/world/world.tscn"
const MENU_SCENE: String = "res://scenes/main/main_menu.tscn"
const PRESTIGE_SCENE: String = "res://scenes/ui/prestige_screen.tscn"
const WORLD_MAP_SCENE: String = "res://scenes/ui/world_map.tscn"

@onready var _title: Label = $CenterContainer/VBoxContainer/Title
@onready var _generations_label: Label = $CenterContainer/VBoxContainer/GenerationsLabel
@onready var _play_button: Button = $CenterContainer/VBoxContainer/PlayButton
@onready var _continue_button: Button = $CenterContainer/VBoxContainer/ContinueButton
@onready var _reset_button: Button = $CenterContainer/VBoxContainer/ResetButton
@onready var _reset_dialog: ConfirmationDialog = $ResetDialog
@onready var _prestige_system: Node = get_node("/root/PrestigeSystem")


func _ready() -> void:
	_title.text = _s("title")
	_play_button.text = _s("play")
	_continue_button.text = _s("continue")
	_reset_button.text = _s("reset")
	_refresh_generations_label()

	_reset_dialog.title = _s("reset_title")
	_reset_dialog.dialog_text = _s("reset_body")
	_reset_dialog.ok_button_text = _s("confirm")
	_reset_dialog.cancel_button_text = _s("cancel")

	_play_button.pressed.connect(_on_play_pressed)
	_continue_button.pressed.connect(_on_continue_pressed)
	_reset_button.pressed.connect(_on_reset_pressed)
	_reset_dialog.confirmed.connect(_on_reset_confirmed)


func _on_play_pressed() -> void:
	if _has_active_run():
		get_tree().change_scene_to_file(WORLD_SCENE)
		return
	_open_kingdom_select()


func _on_continue_pressed() -> void:
	if _has_active_run():
		get_tree().change_scene_to_file(WORLD_SCENE)
	else:
		_open_kingdom_select()


func _on_reset_pressed() -> void:
	_reset_dialog.popup_centered()


func _on_reset_confirmed() -> void:
	SaveSystem.reset_save()
	get_tree().change_scene_to_file(MENU_SCENE)


func _s(key: String) -> String:
	return String(STRINGS.get(key, ""))


func _has_active_run() -> bool:
	var run: Dictionary = GameState.run_save
	if not (run is Dictionary):
		return false
	var tiles: Array = run.get("tiles", [])
	if tiles.size() > 0:
		return true
	var organisms: Array = run.get("organisms", [])
	if organisms.size() > 0:
		return true
	var events: Array = run.get("active_events", [])
	return events.size() > 0


func _open_kingdom_select() -> void:
	# Phase 12: route through the world map first; that flow eventually
	# instantiates prestige_screen with skip_to_kingdom_select after the
	# player picks an ecosystem.
	var scene := load(WORLD_MAP_SCENE)
	if scene == null or not (scene is PackedScene):
		_open_prestige_directly()
		return
	var map := (scene as PackedScene).instantiate()
	if map == null:
		_open_prestige_directly()
		return
	add_child(map)


func _open_prestige_directly() -> void:
	# Legacy / fallback path if world_map is missing.
	var scene := load(PRESTIGE_SCENE)
	if scene == null or not (scene is PackedScene):
		return
	var screen := (scene as PackedScene).instantiate()
	if screen == null:
		return
	if screen.has_method("setup"):
		screen.setup(_prestige_system)
	if screen.has_method("set"):
		screen.set("skip_to_kingdom_select", true)
	add_child(screen)


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
