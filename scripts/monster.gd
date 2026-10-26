extends CharacterBody2D
## Phase 2 monster: idle / chase / attack, with leash, death and respawn.
##
## A monster only attacks once it notices the player (aggro_range). If it
## is pulled too far from its spawn point it stops, walks back, and
## recovers full HP — so a player cannot drag a wolf all the way to town.
## On death it hides, drops a gold pickup, and respawns in place after
## respawn_time. It is never freed, so the player's target stays valid.

@export var data: MonsterData

var max_hp: int = 30
var hp: int = 30
var attack_damage: int = 5
var speed: float = 60.0
var aggro_range: float = 120.0
var attack_range: float = 45.0
var attack_cooldown: float = 1.0
var leash_range: float = 400.0
var gold_drop: int = 3
var respawn_time: float = 5.0

var dead: bool = false
var returning: bool = false

var _spawn_position: Vector2 = Vector2.ZERO
var _attack_timer: float = 0.0
var _respawn_timer: float = 0.0
var _flash_timer: float = 0.0

var _damage_number_scene: PackedScene = preload("res://scenes/ui/damage_number.tscn")
var _gold_pickup_scene: PackedScene = preload("res://scenes/items/gold_pickup.tscn")

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hp_bar: ProgressBar = $HPBar
@onready var target_marker: ColorRect = $TargetMarker


func _ready() -> void:
	add_to_group("monsters")
	_spawn_position = position
	if data != null:
		max_hp = data.max_hp
		attack_damage = data.attack_damage
		speed = data.speed
		aggro_range = data.aggro_range
		attack_range = data.attack_range
		attack_cooldown = data.attack_cooldown
		leash_range = data.leash_range
		gold_drop = data.gold_drop
		respawn_time = data.respawn_time
	hp = max_hp
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	hp_bar.show_percentage = false
	if sprite.texture == null:
		var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
		if data != null:
			image.fill(data.color)
		else:
			image.fill(Color(0.3, 0.9, 0.4, 1))
		sprite.texture = ImageTexture.create_from_image(image)


func set_targeted(is_targeted: bool) -> void:
	target_marker.visible = is_targeted


func take_damage(amount: int) -> void:
	if dead:
		return
	hp -= amount
	hp_bar.value = hp
	sprite.modulate = Color(1.0, 0.4, 0.4, 1.0)
	_flash_timer = 0.1
	_spawn_damage_number(str(amount), Color(1.0, 0.9, 0.3, 1.0))
	if hp <= 0:
		_die()


func _die() -> void:
	dead = true
	visible = false
	collision_shape.disabled = true
	target_marker.visible = false
	_respawn_timer = respawn_time
	var pickup: Node2D = _gold_pickup_scene.instantiate()
	pickup.amount = gold_drop
	pickup.position = global_position + Vector2(randf_range(-12.0, 12.0), 0.0)
	get_tree().current_scene.add_child(pickup)


func _respawn() -> void:
	dead = false
	returning = false
	hp = max_hp
	hp_bar.value = hp
	position = _spawn_position
	visible = true
	collision_shape.disabled = false
	sprite.modulate = Color.WHITE


func _spawn_damage_number(text_value: String, color_value: Color) -> void:
	_spawn_damage_number_at(global_position, text_value, color_value)


func _spawn_damage_number_at(at_position: Vector2, text_value: String, color_value: Color) -> void:
	var number: Node = _damage_number_scene.instantiate()
	number.position = at_position + Vector2(0.0, -30.0)
	get_tree().current_scene.add_child(number)
	number.setup_damage(text_value, color_value)


func _physics_process(delta: float) -> void:
	if dead:
		_respawn_timer -= delta
		if _respawn_timer <= 0.0:
			_respawn()
		return

	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			sprite.modulate = Color.WHITE

	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var to_player: Vector2 = player.global_position - global_position
	var player_distance: float = to_player.length()
	var spawn_distance: float = global_position.distance_to(_spawn_position)

	if returning:
		var to_spawn: Vector2 = _spawn_position - global_position
		if to_spawn.length() < 10.0:
			returning = false
			hp = max_hp
			hp_bar.value = hp
			velocity = Vector2.ZERO
		else:
			velocity = to_spawn.normalized() * speed
		move_and_slide()
		return

	if spawn_distance > leash_range:
		returning = true
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if player_distance <= attack_range:
		velocity = Vector2.ZERO
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_attack_timer = attack_cooldown
			player.take_damage(attack_damage)
			_spawn_damage_number_at(player.global_position, str(attack_damage), Color(1.0, 0.3, 0.3, 1.0))
		move_and_slide()
		return

	if player_distance <= aggro_range:
		_attack_timer = 0.0
		velocity = to_player.normalized() * speed
		if velocity.x < 0.0:
			sprite.flip_h = true
		elif velocity.x > 0.0:
			sprite.flip_h = false
		move_and_slide()
		return

	velocity = Vector2.ZERO
	move_and_slide()
