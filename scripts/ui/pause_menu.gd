extends Control

@export var prestige_scene: PackedScene

@onready var _prestige_button: Button = $Panel/VBox/PrestigeButton
@onready var _resume_button: Button = $Panel/VBox/ResumeButton
@onready var _reset_button: Button = $Panel/VBox/ResetSaveButton
@onready var _reset_dialog: ConfirmationDialog = $ResetDialog


func _ready() -> void:
	_prestige_button.pressed.connect(_on_prestige_pressed)
	_resume_button.pressed.connect(_on_resume_pressed)
	_reset_button.pressed.connect(_on_reset_pressed)
	_reset_dialog.confirmed.connect(_on_reset_confirmed)
	_reset_dialog.title = "Reset Save"
	_reset_dialog.dialog_text = "Delete your local save? This cannot be undone."
	_reset_dialog.ok_button_text = "Reset"
	_reset_dialog.cancel_button_text = "Cancel"


func open() -> void:
	visible = true
	TickClock.pause()
	_update_prestige_label()


func close() -> void:
	visible = false
	TickClock.resume()


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func _update_prestige_label() -> void:
	var prestige_system := _get_prestige_system()
	if prestige_system != null and prestige_system.has_method("get_pending_reward"):
		var reward: int = prestige_system.get_pending_reward()
		_prestige_button.text = "Prestige (earn %d EP)" % reward
	else:
		_prestige_button.text = "Prestige"


func _on_prestige_pressed() -> void:
	var prestige_system := _get_prestige_system()
	if prestige_system == null or prestige_scene == null:
		return
	var screen := prestige_scene.instantiate()
	if screen == null:
		return
	if screen.has_method("setup"):
		screen.setup(prestige_system)
	get_parent().add_child(screen)
	visible = false


func _on_resume_pressed() -> void:
	close()


func _on_reset_pressed() -> void:
	_reset_dialog.popup_centered()


func _on_reset_confirmed() -> void:
	SaveSystem.reset_save()
	TickClock.resume()
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")


func _get_prestige_system() -> Node:
	var node := get_tree().get_first_node_in_group("prestige_system")
	if node != null:
		return node
	if has_node("/root/PrestigeSystem"):
		return get_node("/root/PrestigeSystem")
	return null
