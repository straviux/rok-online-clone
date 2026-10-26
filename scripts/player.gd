extends CharacterBody2D
## Player: movement, combat, and Phase 3 progression.
##
## Progression, in one place (all formulas are here, so balancing is
## editing numbers below, not hunting through several scripts):
## - XP to next level: 25 * level. On level-up: +5 stat points.
## - max_hp = 100 + VIT*10 + (level-1)*10
## - max_sp = 50 + INT*8 + (level-1)*5
## - attack_damage = 10 + STR*2, attack_range = 80 + DEX*2
## - auto-attack cooldown = max(0.4, 0.8 - AGI*0.02) seconds
## - crit chance = 5% + LUK*1% (basic attacks only, damage x2)
## - HP regen = 2 + VIT*0.5 per second, SP regen = 1.5 + INT*0.4,
##   both x3 while in town (the current scene is named "Town").
## - Heal = 20 + INT*3, Fire Bolt = 15 + INT*3, Power Strike = x1.8 damage.
##
## Combat (from Phase 2, unchanged in spirit):
## - Left-click a monster to target it, left-click ground to clear it.
## - While a target is alive and in range, basic attacks fire automatically.
## - Hotkeys: 1 Power Strike (5 SP, 3s), 2 Heal (10 SP, 5s),
##   3 Fire Bolt (8 SP, 4s, 300 range), 4 HP Potion (+30 HP, starts with 3).
## - C opens the character panel, where stat points are spent with + buttons.
## - On death the player respawns in town at full HP/SP (gold kept for now).

@export var speed: float = 220.0

# Base stats (all start at 5). Spend points on these in the C panel.
var stat_str: int = 5
var stat_agi: int = 5
var stat_vit: int = 5
var stat_int: int = 5
var stat_dex: int = 5
var stat_luk: int = 5

var level: int = 1
var xp: int = 0
var stat_points: int = 0

var max_hp: int = 100
var max_sp: int = 50
var hp: float = 100.0
var sp: float = 50.0
var attack_damage: int = 10
var attack_range: float = 80.0
var attack_cooldown: float = 0.8
var crit_chance: float = 0.05
var hp_regen: float = 2.0
var sp_regen: float = 1.5
var heal_amount: int = 20
var fire_bolt_damage: int = 15

var potions: int = 3
var target: Node = null
var dying: bool = false

var power_strike_timer: float = 0.0
var heal_timer: float = 0.0
var fire_bolt_timer: float = 0.0

var _attack_timer: float = 0.0
var _damage_number_scene: PackedScene = preload("res://scenes/ui/damage_number.tscn")
var _fire_bolt_scene: PackedScene = preload("res://scenes/skills/fire_bolt.tscn")

@onready var sprite: Sprite2D = $Sprite2D


func xp_to_next() -> int:
	return 25 * level


func recalculate_derived() -> void:
	max_hp = 100 + stat_vit * 10 + (level - 1) * 10
	max_sp = 50 + stat_int * 8 + (level - 1) * 5
	attack_damage = 10 + stat_str * 2
	attack_range = 80.0 + stat_dex * 2.0
	attack_cooldown = max(0.4, 0.8 - stat_agi * 0.02)
	crit_chance = 0.05 + stat_luk * 0.01
	hp_regen = 2.0 + stat_vit * 0.5
	sp_regen = 1.5 + stat_int * 0.4
	heal_amount = 20 + stat_int * 3
	fire_bolt_damage = 15 + stat_int * 3
	hp = min(hp, float(max_hp))
	sp = min(sp, float(max_sp))


func spend_stat_point(stat_name: String) -> void:
	if stat_points <= 0:
		return
	match stat_name:
		"STR":
			stat_str += 1
		"AGI":
			stat_agi += 1
		"VIT":
			stat_vit += 1
		"INT":
			stat_int += 1
		"DEX":
			stat_dex += 1
		"LUK":
			stat_luk += 1
		_:
			return
	stat_points -= 1
	recalculate_derived()


func gain_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_to_next():
		xp -= xp_to_next()
		level += 1
		stat_points += 5
		recalculate_derived()
		_show_message("Level Up!", Color(0.4, 1.0, 0.4, 1.0))


func _ready() -> void:
	add_to_group("player")
	recalculate_derived()
	hp = float(max_hp)
	sp = float(max_sp)
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


func _show_message(text_value: String, color_value: Color) -> void:
	var number: Node = _damage_number_scene.instantiate()
	number.position = global_position + Vector2(0.0, -50.0)
	get_tree().current_scene.add_child(number)
	number.setup_damage(text_value, color_value)


func _input(event: InputEvent) -> void:
	if dying:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_target_at_mouse()
	elif event is InputEventKey:
		if event.pressed and not event.echo:
			match event.keycode:
				KEY_1:
					_cast_power_strike()
				KEY_2:
					_cast_heal()
				KEY_3:
					_cast_fire_bolt()
				KEY_4:
					_use_potion()


func _target_at_mouse() -> void:
	# Clicking a + button on the character panel must not retarget.
	for panel: Node in get_tree().get_nodes_in_group("character_panel"):
		if panel.visible:
			return
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


func _target_ready() -> bool:
	return target != null and is_instance_valid(target) and not target.dead


func _cast_power_strike() -> void:
	if not _target_ready():
		_show_message("No target", Color(1.0, 1.0, 1.0, 1.0))
		return
	if global_position.distance_to(target.global_position) > attack_range:
		_show_message("Out of range", Color(1.0, 1.0, 1.0, 1.0))
		return
	if power_strike_timer > 0.0:
		_show_message("Cooling down", Color(1.0, 1.0, 1.0, 1.0))
		return
	if sp < 5.0:
		_show_message("Not enough SP", Color(0.4, 0.7, 1.0, 1.0))
		return
	sp -= 5.0
	power_strike_timer = 3.0
	target.take_damage(int(attack_damage * 1.8))


func _cast_heal() -> void:
	if hp >= float(max_hp):
		_show_message("HP full", Color(0.4, 1.0, 0.4, 1.0))
		return
	if heal_timer > 0.0:
		_show_message("Cooling down", Color(1.0, 1.0, 1.0, 1.0))
		return
	if sp < 10.0:
		_show_message("Not enough SP", Color(0.4, 0.7, 1.0, 1.0))
		return
	sp -= 10.0
	heal_timer = 5.0
	hp = min(float(max_hp), hp + float(heal_amount))
	_show_message("+%d" % heal_amount, Color(0.4, 1.0, 0.4, 1.0))


func _cast_fire_bolt() -> void:
	if not _target_ready():
		_show_message("No target", Color(1.0, 1.0, 1.0, 1.0))
		return
	if global_position.distance_to(target.global_position) > 300.0:
		_show_message("Out of range", Color(1.0, 1.0, 1.0, 1.0))
		return
	if fire_bolt_timer > 0.0:
		_show_message("Cooling down", Color(1.0, 1.0, 1.0, 1.0))
		return
	if sp < 8.0:
		_show_message("Not enough SP", Color(0.4, 0.7, 1.0, 1.0))
		return
	sp -= 8.0
	fire_bolt_timer = 4.0
	var bolt: Node = _fire_bolt_scene.instantiate()
	bolt.position = global_position
	bolt.target = target
	bolt.damage = fire_bolt_damage
	get_tree().current_scene.add_child(bolt)


func _use_potion() -> void:
	if potions <= 0:
		_show_message("No potions", Color(1.0, 1.0, 1.0, 1.0))
		return
	if hp >= float(max_hp):
		_show_message("HP full", Color(0.4, 1.0, 0.4, 1.0))
		return
	potions -= 1
	hp = min(float(max_hp), hp + 30.0)
	_show_message("+30", Color(0.4, 1.0, 0.4, 1.0))


func take_damage(amount: int) -> void:
	if dying:
		return
	hp -= float(amount)
	if hp <= 0.0:
		hp = 0.0
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

	# Regen (x3 in town). Timers tick even while standing still.
	var regen_multiplier: float = 3.0 if get_tree().current_scene.name == "Town" else 1.0
	hp = min(float(max_hp), hp + hp_regen * regen_multiplier * delta)
	sp = min(float(max_sp), sp + sp_regen * regen_multiplier * delta)
	power_strike_timer = max(0.0, power_strike_timer - delta)
	heal_timer = max(0.0, heal_timer - delta)
	fire_bolt_timer = max(0.0, fire_bolt_timer - delta)

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
	if not _target_ready():
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
		var damage: int = attack_damage
		if randf() < crit_chance:
			damage *= 2
		target.take_damage(damage)
