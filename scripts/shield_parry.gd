extends Node2D

@export var rise_distance := 24.0
@export var lifetime := 0.6

var elapsed := 0.0
var start_position := Vector2.ZERO


func _ready() -> void:
	start_position = position


func _process(delta: float) -> void:
	elapsed += delta
	var progress := clampf(elapsed / lifetime, 0.0, 1.0)
	position = start_position + Vector2(0.0, -rise_distance * progress)
	modulate.a = 1.0 - progress
	if progress >= 1.0:
		queue_free()
