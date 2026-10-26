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
## Combat (from Phase 2, plus click-to-move):
## - Left-click a monster: target it AND walk to it, then attack
##   automatically once in range. Left-click ground: walk to that point.
## - WASD at any time cancels click movement (the target stays set).
## - While a target is alive and in range, basic attacks fire automatically.
## - Hotkeys: 1 Power Strike (5 SP, 3s), 2 Heal (10 SP, 5s),
##   3 Fire Bolt (8 SP, 4s, 300 range), 4 use an HP potion from inventory.
## - C opens the character panel, where stat points are spent with + buttons.
## - I opens inventory, E near an NPC opens shop/storage (Phase 4).
## - Phase 4: equipped items add their bonuses in recalculate_derived(),
##   and defence reduces monster damage (minimum 1 per hit).
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
var defence: int = 0

var target: Node = null
var dying: bool = false

# Click-to-move state. chasing = the click was on a monster (its position
# is re-read every frame, so a moving monster is followed); otherwise the
# click was on ground and click_destination is a fixed point.
var click_moving: bool = false
var click_chasing: bool = false
var click_destination: Vector2 = Vector2.ZERO

var power_strike_timer: float = 0.0
var heal_timer: float = 0.0
var fire_bolt_timer: float = 0.0

var _attack_timer: float = 0.0
var _click_stuck_timer: float = 0.0
var _damage_number_scene: PackedScene = preload("res://scenes/ui/damage_number.tscn")
var _fire_bolt_scene: PackedScene = preload("res://scenes/skills/fire_bolt.tscn")

@onready var sprite: Sprite2D = $Sprite2D


func xp_to_next() -> int:
	return 25 * level


func recalculate_derived() -> void:
	# Phase 4 equipment bonuses, summed from GameManager.equipment.
	var eq_attack: int = 0
	var eq_defence: int = 0
	var eq_hp: int = 0
	var eq_sp: int = 0
	for equipped: ItemData in GameManager.equipment.values():
		if equipped != null:
			eq_attack += equipped.attack_bonus
			eq_defence += equipped.defence_bonus
			eq_hp += equipped.hp_bonus
			eq_sp += equipped.sp_bonus
	max_hp = 100 + stat_vit * 10 + (level - 1) * 10 + eq_hp
	max_sp = 50 + stat_int * 8 + (level - 1) * 5 + eq_sp
	attack_damage = 10 + stat_str * 2 + eq_attack
	defence = eq_defence
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
	# Load progression saved in GameManager before deriving anything:
	# without this, every new map spawned a fresh level 1 player.
	if GameManager.has_player_state:
		level = GameManager.player_level
		xp = GameManager.player_xp
		stat_points = GameManager.player_stat_points
		stat_str = GameManager.player_stat_str
		stat_agi = GameManager.player_stat_agi
		stat_vit = GameManager.player_stat_vit
		stat_int = GameManager.player_stat_int
		stat_dex = GameManager.player_stat_dex
		stat_luk = GameManager.player_stat_luk
	recalculate_derived()
	if GameManager.has_player_state and GameManager.player_hp >= 0.0:
		hp = min(GameManager.player_hp, float(max_hp))
		sp = min(GameManager.player_sp, float(max_sp))
	else:
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
	# Clicking buttons on any open panel must not retarget/move.
	for group_name: String in ["character_panel", "inventory_panel", "shop_panel", "storage_panel", "dialogue_panel", "quest_log_panel"]:
		for panel: Node in get_tree().get_nodes_in_group(group_name):
			if panel.visible:
				return
	var mouse_position: Vector2 = get_global_mouse_position()
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = mouse_position
	query.collide_with_bodies = true
	var results: Array = space_state.intersect_point(query)
	for result: Dictionary in results:
		var collider: Object = result["collider"]
		if collider is Node and collider.is_in_group("monsters"):
			set_target(collider)
			click_chasing = true
			click_moving = true
			_click_stuck_timer = 0.0
			return
	# Ground click: walk there, and drop any monster target.
	set_target(null)
	click_chasing = false
	click_destination = mouse_position
	click_moving = true
	_click_stuck_timer = 0.0


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
	# Key 4: best HP potion in the inventory, or nothing.
	for item_id: String in ["hp_potion", "small_hp_potion"]:
		for slot: Dictionary in GameManager.inventory:
			if slot["item"].item_id == item_id:
				use_item(slot["item"])
				return
	_show_message("No potions", Color(1.0, 1.0, 1.0, 1.0))


## Use one consumable from the inventory (inventory panel and key 4).
## Returns false if it could not be used (not a consumable, or already full).
func use_item(item: ItemData) -> bool:
	if item.item_type != ItemData.ItemType.CONSUMABLE:
		return false
	var hp_full: bool = item.heal_hp == 0 or hp >= float(max_hp)
	var sp_full: bool = item.heal_sp == 0 or sp >= float(max_sp)
	if hp_full and sp_full:
		_show_message("Full", Color(0.4, 1.0, 0.4, 1.0))
		return false
	if not GameManager.remove_item(item, 1):
		return false
	if item.heal_hp > 0:
		hp = min(float(max_hp), hp + float(item.heal_hp))
		_show_message("+%d" % item.heal_hp, Color(0.4, 1.0, 0.4, 1.0))
	if item.heal_sp > 0:
		sp = min(float(max_sp), sp + float(item.heal_sp))
		_show_message("+%d SP" % item.heal_sp, Color(0.4, 0.7, 1.0, 1.0))
	return true


func take_damage(amount: int) -> int:
	if dying:
		return 0
	# Phase 4 defence: at least 1 damage always gets through.
	var effective: int = max(1, amount - defence)
	hp -= float(effective)
	if hp <= 0.0:
		hp = 0.0
		dying = true
		set_target(null)
		# The pause-then-respawn lives in its own coroutine, so this
		# function can still return the damage dealt right away.
		_respawn_after_death()
	return effective


func _respawn_after_death() -> void:
	# Brief pause so the killing hit is visible, then respawn in town.
	# keep_hp=false: level/XP/stats are kept, HP/SP come back full.
	await get_tree().create_timer(0.5).timeout
	GameManager.travel_to("res://scenes/world/town.tscn", Vector2(0, 300), false)


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

	if direction != Vector2.ZERO:
		# WASD always wins and cancels click movement (target stays set).
		click_moving = false
		click_chasing = false
		_click_stuck_timer = 0.0
		velocity = direction.normalized() * speed
	elif click_moving:
		if click_chasing:
			if not _target_ready():
				click_moving = false
				click_chasing = false
				velocity = Vector2.ZERO
			elif global_position.distance_to(target.global_position) <= attack_range:
				# In range: stand still, _attack_target below does the work.
				velocity = Vector2.ZERO
			else:
				velocity = (target.global_position - global_position).normalized() * speed
		elif global_position.distance_to(click_destination) < 8.0:
			click_moving = false
			velocity = Vector2.ZERO
		else:
			velocity = (click_destination - global_position).normalized() * speed
	else:
		velocity = Vector2.ZERO

	var intended_moving: bool = velocity.length() > 0.0
	move_and_slide()

	# Stuck detection: if we tried to move but barely did (a wall, tree,
	# or house in the way) for 0.5s, stop trying instead of pushing forever.
	if click_moving and intended_moving and velocity.length() < 20.0:
		var stuck_destination: Vector2 = target.global_position if click_chasing and _target_ready() else click_destination
		if global_position.distance_to(stuck_destination) > 20.0:
			_click_stuck_timer += delta
			if _click_stuck_timer > 0.5:
				click_moving = false
				click_chasing = false
				_click_stuck_timer = 0.0
		else:
			_click_stuck_timer = 0.0
	else:
		_click_stuck_timer = 0.0

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
