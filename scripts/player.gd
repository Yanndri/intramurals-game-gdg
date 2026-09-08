extends CharacterBody2D

@export var speed := 240.0
@export var jump_velocity := -420.0
@export var gravity := 1200.0

func _physics_process(_delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * _delta

	if Input.is_action_just_pressed("player1forward") and is_on_floor():
		velocity.y = jump_velocity

	var direction := Input.get_axis("player1left", "player1right")
	velocity.x = direction * speed

	if Input.is_action_pressed("player1backward") and not is_on_floor():
		velocity.y += gravity * _delta

	move_and_slide()
