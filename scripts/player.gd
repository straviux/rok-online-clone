extends CharacterBody2D
## Player: WASD / arrow-key movement, camera follows, Phase 2 combat.
##
## Combat model, kept deliberately simple:
## - Left-click a monster to target it (yellow marker + HUD target bar).
##   Left-clicking empty ground clears the target.
## - While a target is alive and within attack_range, the player attacks
##   automatically every attack_cooldown seconds.
## - Walk close with WASD/arrows first: there is no click-to-move yet.
## - On death the player respawns in town at full HP (gold is kept for
##   now; the small gold loss on death comes with Phase 4).
##
## Movement reads keys directly (instead of an Input Map) so this project
## runs without any extra project setup.

@export var speed: float = 220.0
@export var max_hp: int = 100
@export var attack_damage: int = 10
@export var attack_range: float = 80.0
@export var attack_cooldown: float = 0.8

var hp: int = max_hp
var target: Node = null
var dying: bool = false

var _attack_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("player")
	hp = max_hp
	# Placeholder art: a plain coloured box until real sprites arrive.
	# Only generated when no texture has been assigned in the editor.
	if sprite.texture == null:
		var image := Image.create(32, 48, false, Image.FORMAT_RGBA8)
		image.fill(Color(0.35, 0.65, 1.0))
		sprite.texture = ImageTexture.create_from_image(image)


func set_target(new_target: Node) -> void:
	if target != null and is_instance_valid(target) and target.has_method("set_targeted"):
		target.set_targeted(false)
	target = new_target
	if target != null and target.has_method("set_targeted"):
		target.set_targeted(true)


func _input(event: InputEvent) -> void:
	if dying:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_target_at_mouse()


func _target_at_mouse() -> void:
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = get_global_mouse_position()
	query.collide_with_bodies = true
	var results: Array = space_state.intersect_point(query)
	for result: Dictionary in results:
		var collider: Object = result["collider"]
		if collider is Node and collider.is_in_group("monsters"):
			set_target(collider)
			return
	set_target(null)


func take_damage(amount: int) -> void:
	if dying:
		return
	hp -= amount
	if hp <= 0:
		hp = 0
		dying = true
		set_target(null)
		# Brief pause so the killing hit is visible, then respawn in town.
		await get_tree().create_timer(0.5).timeout
		GameManager.travel_to("res://scenes/world/town.tscn", Vector2(0, 300))


func _physics_process(delta: float) -> void:
	if dying:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1.0

	velocity = direction.normalized() * speed
	move_and_slide()

	if velocity.x < 0.0:
		sprite.flip_h = true
	elif velocity.x > 0.0:
		sprite.flip_h = false

	_attack_target(delta)


func _attack_target(delta: float) -> void:
	if target == null or not is_instance_valid(target) or target.dead:
		set_target(null)
		_attack_timer = 0.0
		return
	var distance: float = global_position.distance_to(target.global_position)
	if distance > attack_range:
		_attack_timer = 0.0
		return
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = attack_cooldown
		target.take_damage(attack_damage)
