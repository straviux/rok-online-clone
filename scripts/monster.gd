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
var xp: int = 10
var drop_item_id: String = ""
var drop_chance: float = 0.0
var drop_item_id2: String = ""
var drop_chance2: float = 0.0
var monster_id: String = ""
var special_damage: int = 0
var special_cooldown: float = 0.0
var special_range: float = 0.0

var dead: bool = false
var returning: bool = false

var _spawn_position: Vector2 = Vector2.ZERO
var _attack_timer: float = 0.0
var _respawn_timer: float = 0.0
var _special_timer: float = 0.0
var _flash_timer: float = 0.0

var _damage_number_scene: PackedScene = preload("res://scenes/ui/damage_number.tscn")
var _gold_pickup_scene: PackedScene = preload("res://scenes/items/gold_pickup.tscn")
var _item_pickup_scene: PackedScene = preload("res://scenes/items/item_pickup.tscn")

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
		xp = data.xp
		drop_item_id = data.drop_item_id
		drop_chance = data.drop_chance
		drop_item_id2 = data.drop_item_id2
		drop_chance2 = data.drop_chance2
		monster_id = data.monster_id
		special_damage = data.special_damage
		special_cooldown = data.special_cooldown
		special_range = data.special_range
		_special_timer = special_cooldown
	hp = max_hp
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	hp_bar.show_percentage = false
	if data != null and data.sprite_name != "":
		sprite.texture = SpriteData.get_texture(data.sprite_name)
		# Sprites are 32x32, but scale to fit anyway so a differently
		# sized sprite never breaks the 32x32 collision box.
		var tex_size: Vector2 = sprite.texture.get_size()
		var fit: float = 32.0 / max(tex_size.x, tex_size.y)
		sprite.scale = Vector2(fit, fit)
	elif sprite.texture == null:
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
	# Phase 3: the player who killed it earns its XP.
	# Phase 5: quest kill/boss progress is reported the same way.
	var player: Node = get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("gain_xp"):
		player.gain_xp(xp)
	GameManager.notify_kill(monster_id)
	var pickup: Node2D = _gold_pickup_scene.instantiate()
	pickup.amount = gold_drop
	pickup.position = global_position + Vector2(randf_range(-12.0, 12.0), 0.0)
	get_tree().current_scene.add_child(pickup)
	# Phase 4 loot rolls, one per drop slot (Phase 5 adds a second
	# slot, so mushrooms can drop both a potion and a herb).
	_try_drop(drop_item_id, drop_chance)
	_try_drop(drop_item_id2, drop_chance2)


func _try_drop(item_id: String, chance: float) -> void:
	if item_id == "" or randf() >= chance:
		return
	var loot_item: ItemData = _load_item(item_id)
	if loot_item != null:
		var item_pickup: Node2D = _item_pickup_scene.instantiate()
		item_pickup.item = loot_item
		item_pickup.position = global_position + Vector2(randf_range(-20.0, 20.0), randf_range(-10.0, 10.0))
		get_tree().current_scene.add_child(item_pickup)


func _load_item(item_id: String) -> ItemData:
	match item_id:
		"small_hp_potion":
			return preload("res://data/items/small_hp_potion.tres")
		"sp_potion":
			return preload("res://data/items/sp_potion.tres")
		"wooden_ring":
			return preload("res://data/items/wooden_ring.tres")
		"herb":
			return preload("res://data/items/herb.tres")
		"hp_potion":
			return preload("res://data/items/hp_potion.tres")
		"silver_ring":
			return preload("res://data/items/silver_ring.tres")
	return null


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

	# Phase 5 boss special: every few seconds, a roar hits the player
	# if they are close. The warning number is the telegraph — step
	# back out of range to avoid it.
	if special_damage > 0 and special_cooldown > 0.0:
		_special_timer -= delta
		if _special_timer <= 0.0:
			_special_timer = special_cooldown
			if player_distance <= special_range:
				player.take_damage(special_damage)
				_spawn_damage_number_at(player.global_position, "Roar!", Color(1.0, 0.3, 0.3, 1.0))

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
			# take_damage returns the damage after defence, so the
			# number shown matches the HP actually lost.
			var dealt: int = player.take_damage(attack_damage)
			_spawn_damage_number_at(player.global_position, str(dealt), Color(1.0, 0.3, 0.3, 1.0))
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
