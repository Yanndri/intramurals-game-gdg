extends Control


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	pass


func _on_exit_button_pressed() -> void:
	pass  # actual quit logic lives in main_menu.gd


func _on_mouse_entered() -> void:
	$hover.play()  # play hover sound
