class_name InstantDeathZone
extends Area2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	var player := body as TestPlayer
	if player != null:
		player.take_damage(player.health)
