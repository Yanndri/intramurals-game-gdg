class_name TestPlayer
extends CharacterBody2D

## TileMap uses layers 1 and 2; StaticPlatforms uses layer 3 (bit 4).
const TILEMAP_MASK := 0b011
const STATIC_PLATFORM_MASK := 0b100
const ALL_WORLD_MASK := TILEMAP_MASK | STATIC_PLATFORM_MASK
const PLAYER_MASK := 0b1000
const ALL_COLLISION_MASK := ALL_WORLD_MASK | PLAYER_MASK
const DAMAGE_SLOW_TIME_SCALE := 0.2
const DAMAGE_SLOW_DURATION_MSEC := 200

static var damage_slow_until_msec := 0
static var time_scale_before_damage_slow := 1.0

@export var move_speed := 180.0
@export var jump_velocity := -390.0
@export var drop_through_duration := 0.25
@export var input_prefix := "player1"
@export var max_health := 200
@export_group("Combat")
@export var brawler_attack_range := 50.0
@export var bullet_attack_range := 55.0
@export var katana_attack_range := 58.0
@export var sword_attack_range := 64.0

@onready var platform_detector: RayCast2D = $PlatformDetector
@onready var sprite_model: Sprite2D = $SpriteModel
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var drop_through_time_left := 0.0
var was_on_floor := false
var health := max_health
var is_dead := false
var equipped_gear: StringName = &""
var brawler_attack_time_left := 0.0
var brawler_next_attack_is_cross := true
var bullet_attack_time_left := 0.0
var sword_attack_time_left := 0.0

signal health_changed(current_health: int, maximum_health: int)


func _ready() -> void:
	add_to_group("players")


func _physics_process(delta: float) -> void:
	_update_damage_slow_motion()
	if is_dead:
		velocity = Vector2.ZERO
		return

	if brawler_attack_time_left > 0.0:
		brawler_attack_time_left -= delta
	if bullet_attack_time_left > 0.0:
		bullet_attack_time_left -= delta
	if sword_attack_time_left > 0.0:
		sword_attack_time_left -= delta

	if not is_on_floor():
		velocity.y += gravity * delta

	var direction := Input.get_axis(input_prefix + "left", input_prefix + "right")
	if Input.is_action_just_pressed("attack_" + input_prefix):
		if equipped_gear == &"katana":
			animation_player.play(&"player_katana_continous_attack")
			_deal_attack_damage(10, katana_attack_range)
		elif equipped_gear == &"brawler" and brawler_attack_time_left <= 0.0:
			var brawler_attack: StringName = &"player_punch_cross" if brawler_next_attack_is_cross else &"player_punch_jab"
			animation_player.play(brawler_attack)
			brawler_next_attack_is_cross = not brawler_next_attack_is_cross
			brawler_attack_time_left = 0.7
			_deal_attack_damage(10, brawler_attack_range)
		elif equipped_gear == &"bullet" and bullet_attack_time_left <= 0.0:
			# Both players use their own attack action after picking up Bullet
			# gear: shoot while moving, or use the two-handed shot while still.
			var bullet_attack: StringName = &"player_shooting_running" if direction != 0.0 else &"player_shooting_two_handed"
			animation_player.play(bullet_attack)
			bullet_attack_time_left = 1.0 if direction == 0.0 else 0.8
			_deal_attack_damage(20, bullet_attack_range)
		elif equipped_gear == &"sword" and sword_attack_time_left <= 0.0:
			animation_player.play(&"player_sword_attack")
			sword_attack_time_left = 0.6
			_deal_attack_damage(15, sword_attack_range)

	velocity.x = move_toward(velocity.x, direction * move_speed, move_speed * 8.0 * delta)

	if Input.is_action_just_pressed(input_prefix + "forward") and is_on_floor():
		velocity.y = jump_velocity

	# Only the layer-3 ray can initiate a drop. TileMap collision remains active.
	if Input.is_action_just_pressed(input_prefix + "backward") and platform_detector.is_colliding():
		drop_through_time_left = drop_through_duration
		collision_mask = TILEMAP_MASK
		velocity.y = maxf(velocity.y, 30.0)

	if drop_through_time_left > 0.0:
		drop_through_time_left -= delta
		if drop_through_time_left <= 0.0:
			collision_mask = ALL_COLLISION_MASK

	move_and_slide()
	_update_animation(direction)
	was_on_floor = is_on_floor()


func take_damage(amount: int) -> void:
	if health <= 0:
		return

	health = maxi(health - amount, 0)
	print("%s took %d damage. Health: %d/%d" % [name, amount, health, max_health])
	if health == 0:
		is_dead = true
		velocity = Vector2.ZERO
		animation_player.play(&"player_death")
	else:
		animation_player.play(&"player_hurt-damaged")
	_trigger_damage_slow_motion()
	health_changed.emit(health, max_health)


func _trigger_damage_slow_motion() -> void:
	var now_msec := Time.get_ticks_msec()
	if now_msec >= damage_slow_until_msec:
		time_scale_before_damage_slow = Engine.time_scale
		Engine.time_scale = time_scale_before_damage_slow * DAMAGE_SLOW_TIME_SCALE
	damage_slow_until_msec = now_msec + DAMAGE_SLOW_DURATION_MSEC


func _update_damage_slow_motion() -> void:
	if damage_slow_until_msec > 0 and Time.get_ticks_msec() >= damage_slow_until_msec:
		Engine.time_scale = time_scale_before_damage_slow
		damage_slow_until_msec = 0


func _deal_attack_damage(damage: int, attack_range: float) -> void:
	var facing_direction := -1.0 if sprite_model.flip_h else 1.0
	var closest_target: TestPlayer
	var closest_distance := INF

	for player_node in get_tree().get_nodes_in_group("players"):
		var target := player_node as TestPlayer
		if target == null or target == self or target.health <= 0:
			continue

		var offset := target.global_position - global_position
		if offset.x * facing_direction < 0.0:
			continue

		var distance := offset.length()
		if distance <= attack_range and distance < closest_distance:
			closest_target = target
			closest_distance = distance

	if closest_target != null:
		closest_target.take_damage(damage)


func grant_gear(gear_id: StringName) -> void:
	equipped_gear = gear_id
	if equipped_gear == &"katana":
		animation_player.play(&"player_katana_idle")
	elif equipped_gear == &"brawler":
		brawler_next_attack_is_cross = true
		animation_player.play(&"player_brawler_idle")
	elif equipped_gear == &"bullet":
		animation_player.play(&"player_bullet_idle")
	elif equipped_gear == &"sword":
		animation_player.play(&"player_sword_idle")


func _update_animation(direction: float) -> void:
	if animation_player.current_animation == &"player_hurt-damaged" and animation_player.is_playing():
		return
	# Do not replace the one-shot Katana attack while it is playing.
	if animation_player.current_animation == &"player_katana_continous_attack" and animation_player.is_playing():
		return
	if brawler_attack_time_left > 0.0 and animation_player.current_animation in [&"player_punch_cross", &"player_punch_jab"]:
		return
	if bullet_attack_time_left > 0.0 and animation_player.current_animation in [&"player_shooting_running", &"player_shooting_two_handed"]:
		return
	if sword_attack_time_left > 0.0 and animation_player.current_animation == &"player_sword_attack":
		return

	if direction != 0.0:
		sprite_model.flip_h = direction < 0.0

	var animation_name: StringName = &"player_idle"
	if equipped_gear == &"katana":
		animation_name = &"player_katana_idle"
	elif equipped_gear == &"brawler":
		animation_name = &"player_brawler_idle"
	elif equipped_gear == &"bullet":
		animation_name = &"player_bullet_idle"
	elif equipped_gear == &"sword":
		animation_name = &"player_sword_idle"
	if not is_on_floor():
		animation_name = &"player_jump"
	elif not was_on_floor and animation_player.has_animation(&"player_land"):
		animation_name = &"player_land"
	elif direction != 0.0:
		if equipped_gear == &"katana":
			animation_name = &"player_katana_run"
		elif equipped_gear == &"sword":
			animation_name = &"player_sword_run"
		else:
			animation_name = &"player_run"

	if animation_player.has_animation(animation_name) and animation_player.current_animation != animation_name:
		animation_player.play(animation_name)
