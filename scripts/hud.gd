extends CanvasLayer
## Phase 3 HUD: player HP/SP/XP, level, gold, target HP, and skill status.
## The target bars hide when nothing is targeted (town, or no monster).

@onready var hp_bar: ProgressBar = $HPBar
@onready var sp_bar: ProgressBar = $SPBar
@onready var xp_bar: ProgressBar = $XPBar
@onready var level_label: Label = $LevelLabel
@onready var gold_label: Label = $GoldLabel
@onready var target_label: Label = $TargetLabel
@onready var target_bar: ProgressBar = $TargetBar
@onready var skill_label: Label = $SkillLabel


func _ready() -> void:
	hp_bar.show_percentage = false
	sp_bar.show_percentage = false
	xp_bar.show_percentage = false
	target_bar.show_percentage = false


func _input(event: InputEvent) -> void:
	# Esc closes ONLY the frontmost open panel, one per press.
	# This has to live in exactly one place: when every panel handled
	# Esc itself, one press closed them all. Order here is the panels'
	# scene order (later = drawn in front): storage, shop, inventory,
	# character. Press Esc repeatedly to close them front to back.
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed and not event.echo:
			for group_name: String in ["storage_panel", "shop_panel", "inventory_panel", "character_panel"]:
				for panel: Node in get_tree().get_nodes_in_group(group_name):
					if panel.visible:
						panel.visible = false
						return


func _cooldown_text(timer: float) -> String:
	if timer <= 0.0:
		return "ready"
	return "%.1fs" % timer


func _process(_delta: float) -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	hp_bar.max_value = player.max_hp
	hp_bar.value = player.hp
	sp_bar.max_value = player.max_sp
	sp_bar.value = player.sp
	xp_bar.max_value = player.xp_to_next()
	xp_bar.value = player.xp
	if player.stat_points > 0:
		level_label.text = "Lv %d (%d pts)" % [player.level, player.stat_points]
	else:
		level_label.text = "Lv %d" % player.level
	gold_label.text = "Gold: %d" % GameManager.gold
	skill_label.text = "1 Power Strike [%s]  2 Heal [%s]  3 Fire Bolt [%s]  4 HP Potion x%d  |  C Stats  I Inventory" % [
		_cooldown_text(player.power_strike_timer),
		_cooldown_text(player.heal_timer),
		_cooldown_text(player.fire_bolt_timer),
		GameManager.count_item("hp_potion") + GameManager.count_item("small_hp_potion"),
	]

	var target: Node = player.target
	if target != null and is_instance_valid(target) and not target.dead:
		var target_name: String = "Monster"
		if target.data != null:
			target_name = target.data.monster_name
		target_label.text = target_name
		target_bar.max_value = target.max_hp
		target_bar.value = target.hp
		target_label.visible = true
		target_bar.visible = true
	else:
		target_label.visible = false
		target_bar.visible = false
