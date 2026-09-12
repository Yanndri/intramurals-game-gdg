class_name FloatingGear
extends Area2D

## Reusable arena pickup. Connect gear_collected to apply the gear's gameplay
## effect; this component handles only its world presence and respawn cycle.
@export_range(0.1, 300.0, 0.1, "suffix:s") var respawn_seconds := 60.0
@export var gear_id: StringName = &""
@export var float_height := 6.0
@export var float_speed := 2.5

@onready var respawn_timer: Timer = $RespawnTimer

var home_position := Vector2.ZERO
var float_time := 0.0
var is_available := true

signal gear_collected(player: TestPlayer)


func _ready() -> void:
	home_position = position
	body_entered.connect(_on_body_entered)
	respawn_timer.timeout.connect(_respawn)


func _process(delta: float) -> void:
	if not is_available:
		return

	float_time += delta
	position.y = home_position.y + sin(float_time * float_speed) * float_height


func _on_body_entered(body: Node2D) -> void:
	var player := body as TestPlayer
	if not is_available or player == null:
		return

	is_available = false
	if gear_id != &"":
		player.grant_gear(gear_id)
	gear_collected.emit(player)
	visible = false
	set_deferred("monitoring", false)
	respawn_timer.start(respawn_seconds)


func _respawn() -> void:
	position = home_position
	visible = true
	is_available = true
	set_deferred("monitoring", true)
