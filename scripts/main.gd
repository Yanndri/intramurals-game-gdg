extends Node2D

@onready var player1: TestPlayer = $Player
@onready var player2: TestPlayer = $Player2
@onready var player1_health_bar: TextureProgressBar = $HUD/Player1Health
@onready var player2_health_bar: TextureProgressBar = $HUD/Player2Health
@onready var player1_health_value: Label = $HUD/Player1HealthValue
@onready var player2_health_value: Label = $HUD/Player2HealthValue
@onready var player1_health_label: Label = $HUD/Player1HealthLabel
@onready var player2_health_label: Label = $HUD/Player2HealthLabel

const HEALTH_LABEL_OFFSET := Vector2(-128.0, -70.0)
const HEALTH_BAR_OFFSET := Vector2(-128.0, -62.0)
const HEALTH_VALUE_OFFSET := Vector2(-128.0, -55.0)


func _ready() -> void:
	player1.health_changed.connect(_update_player1_health)
	player2.health_changed.connect(_update_player2_health)
	_update_player1_health(player1.health, player1.max_health)
	_update_player2_health(player2.health, player2.max_health)


func _process(_delta: float) -> void:
	_position_health_display(player1, player1_health_label, player1_health_bar, player1_health_value)
	_position_health_display(player2, player2_health_label, player2_health_bar, player2_health_value)


func _position_health_display(player: TestPlayer, health_label: Label, health_bar: TextureProgressBar, health_value: Label) -> void:
	# This transform includes camera movement, keeping the HUD elements above the player on screen.
	var player_screen_position := player.get_global_transform_with_canvas().origin
	health_label.size.x = health_value.size.x
	health_label.position = player_screen_position + HEALTH_LABEL_OFFSET
	health_bar.position = player_screen_position + HEALTH_BAR_OFFSET
	health_value.position = player_screen_position + HEALTH_VALUE_OFFSET


func _update_player1_health(current_health: int, maximum_health: int) -> void:
	player1_health_bar.max_value = maximum_health
	player1_health_bar.value = current_health
	player1_health_value.text = "%d / %d" % [current_health, maximum_health]


func _update_player2_health(current_health: int, maximum_health: int) -> void:
	player2_health_bar.max_value = maximum_health
	player2_health_bar.value = current_health
	player2_health_value.text = "%d / %d" % [current_health, maximum_health]
