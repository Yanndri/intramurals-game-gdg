extends Control

@export_file("*.tscn") var game_scene_path := "res://scenes/player.tscn"

@onready var play_button: Button = $Center/MenuCard/Margin/Menu/PlayButton
@onready var status: Label = $Center/MenuCard/Margin/Menu/Status


func _ready() -> void:
	play_button.grab_focus()


func _on_play_button_pressed() -> void:
	if game_scene_path.is_empty() or not ResourceLoader.exists(game_scene_path):
		status.text = "Set a gameplay scene on the Main Menu node to start the game."
		return

	get_tree().change_scene_to_file(game_scene_path)


func _on_exit_button_pressed() -> void:
	get_tree().quit()
