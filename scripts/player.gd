class_name TestPlayer
extends CharacterBody2D

## TileMap uses layers 1 and 2; StaticPlatforms uses layer 3 (bit 4).
const TILEMAP_MASK := 0b011
const STATIC_PLATFORM_MASK := 0b100
const ALL_WORLD_MASK := TILEMAP_MASK | STATIC_PLATFORM_MASK

@export var move_speed := 180.0
@export var jump_velocity := -340.0
@export var drop_through_duration := 0.25

@onready var platform_detector: RayCast2D = $PlatformDetector

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var drop_through_time_left := 0.0


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	var direction := Input.get_axis("player1left", "player1right")
	velocity.x = move_toward(velocity.x, direction * move_speed, move_speed * 8.0 * delta)

	if Input.is_action_just_pressed("player1forward") and is_on_floor():
		velocity.y = jump_velocity

	# Only the layer-3 ray can initiate a drop. TileMap collision remains active.
	if Input.is_action_just_pressed("player1backward") and platform_detector.is_colliding():
		drop_through_time_left = drop_through_duration
		collision_mask = TILEMAP_MASK
		velocity.y = maxf(velocity.y, 30.0)

	if drop_through_time_left > 0.0:
		drop_through_time_left -= delta
		if drop_through_time_left <= 0.0:
			collision_mask = ALL_WORLD_MASK

	move_and_slide()
