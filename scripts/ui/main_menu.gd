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

@onready var _title: Label = $CenterContainer/VBoxContainer/Title
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
