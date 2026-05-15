extends Control

const MAIN_MENU_SCENE: String = "res://scenes/main/main_menu.tscn"


func _ready() -> void:
	SaveSystem.load_or_create()
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
