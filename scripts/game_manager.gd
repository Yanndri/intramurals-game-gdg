class_name GameManager
extends Node

## Runs a best-of-three match. A player receives a point only when the other
## player's health reaches zero while they are still alive.
const TOTAL_ROUNDS := 3

@export var round_scene: PackedScene
@export var arena_scenes: Array[PackedScene] = []
@export var round_transition_delay := 1.5

@onready var match_status: Label = $MatchHUD/MatchStatus

var current_round := 0
var player_scores := [0, 0]
var last_arena_index := -1
var active_round: Node2D
var round_is_resolving := false


func _ready() -> void:
	if round_scene == null or arena_scenes.size() < 2:
		push_error("GameManager needs a round scene and at least two arena scenes.")
		return

	randomize()
	_start_next_round()


func _start_next_round() -> void:
	current_round += 1
	round_is_resolving = false
	active_round = round_scene.instantiate() as Node2D
	add_child(active_round)
	_install_next_arena()

	var player1: TestPlayer = active_round.get_node("Player")
	var player2: TestPlayer = active_round.get_node("Player2")
	player1.health_changed.connect(_on_player_health_changed)
	player2.health_changed.connect(_on_player_health_changed)
	_update_match_status("ROUND %d / %d" % [current_round, TOTAL_ROUNDS])


func _install_next_arena() -> void:
	var available_indices: Array[int] = []
	for arena_index: int in range(arena_scenes.size()):
		if arena_index != last_arena_index:
			available_indices.append(arena_index)

	var chosen_index: int = available_indices[randi() % available_indices.size()]
	last_arena_index = chosen_index

	var default_arena := active_round.get_node_or_null("Graveyard_Arena_3")
	if default_arena != null:
		active_round.remove_child(default_arena)
		default_arena.queue_free()

	var arena: Node = arena_scenes[chosen_index].instantiate()
	arena.name = "CurrentArena"
	active_round.add_child(arena)
	# Keep the arena behind the players, as it is in the original gameplay scene.
	active_round.move_child(arena, 1)


func _on_player_health_changed(_current_health: int, _maximum_health: int) -> void:
	if round_is_resolving:
		return

	var player1: TestPlayer = active_round.get_node("Player")
	var player2: TestPlayer = active_round.get_node("Player2")
	if player1.health <= 0 and player2.health <= 0:
		_finish_round(0)
	elif player1.health <= 0:
		_finish_round(2)
	elif player2.health <= 0:
		_finish_round(1)


func _finish_round(winning_player: int) -> void:
	round_is_resolving = true
	if winning_player > 0:
		player_scores[winning_player - 1] += 1
		_update_match_status("PLAYER %d WINS ROUND %d\nP1 %d  -  %d P2" % [winning_player, current_round, player_scores[0], player_scores[1]])
	else:
		_update_match_status("ROUND %d IS A DRAW\nP1 %d  -  %d P2" % [current_round, player_scores[0], player_scores[1]])

	await get_tree().create_timer(round_transition_delay).timeout
	active_round.queue_free()
	if current_round == TOTAL_ROUNDS:
		_show_match_result()
	else:
		_start_next_round()


func _show_match_result() -> void:
	if player_scores[0] == player_scores[1]:
		_update_match_status("MATCH DRAW\nP1 %d  -  %d P2" % [player_scores[0], player_scores[1]])
	else:
		var winner := 1 if player_scores[0] > player_scores[1] else 2
		_update_match_status("PLAYER %d WINS THE MATCH\nP1 %d  -  %d P2" % [winner, player_scores[0], player_scores[1]])


func _update_match_status(message: String) -> void:
	match_status.text = message
