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
@onready var cast_label: Label = $CastLabel
@onready var cast_bar: ProgressBar = $CastBar
@onready var xp_label: Label = $XPLabel

# Phase 6 pause menu, built lazily on first Esc (see _input).
var _pause_menu_scene: PackedScene = preload("res://scenes/ui/pause_menu.tscn")
var _pause_menu: Node = null


func _ready() -> void:
	# UI pack icons next to the bars (textures are code-generated, so
	# they are assigned here rather than in the scene file).
	($HeartIcon as TextureRect).texture = UISprites.get_texture("heart")
	($ManaIcon as TextureRect).texture = UISprites.get_texture("mana_crystal")
	($CoinIcon as TextureRect).texture = UISprites.get_texture("gold_coin")
	($XPIcon as TextureRect).texture = UISprites.get_texture("star")
	hp_bar.show_percentage = false
	sp_bar.show_percentage = false
	xp_bar.show_percentage = false
	target_bar.show_percentage = false
	cast_bar.show_percentage = false


func _input(event: InputEvent) -> void:
	# Esc closes ONLY the frontmost open panel, one per press.
	# This has to live in exactly one place: when every panel handled
	# Esc itself, one press closed them all. Order here is the panels'
	# scene order (later = drawn in front): dialogue, quest log,
	# storage, shop, inventory, character. Press Esc repeatedly to
	# close them front to back. Only when no panel is open does Esc
	# open the Phase 6 pause menu; Esc inside that menu resumes
	# (handled by the menu itself, since the tree is paused then and
	# this HUD no longer receives input).
	# Note: Esc no longer cancels an armed skill — that is now the
	# same skill key, or a ground click, as before. An armed skill
	# simply stays armed under the pause menu.
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed and not event.echo:
			for group_name: String in ["dialogue_panel", "quest_log_panel", "storage_panel", "shop_panel", "inventory_panel", "character_panel"]:
				for panel: Node in get_tree().get_nodes_in_group(group_name):
					if panel.visible:
						panel.visible = false
						return
			# No panel open: open the pause menu (built once, reused).
			if _pause_menu == null:
				_pause_menu = _pause_menu_scene.instantiate()
				add_child(_pause_menu)
			_pause_menu.open()


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
	xp_label.text = "%d / %d" % [int(player.xp), player.xp_to_next()]
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
	if player.cast_chase_skill != "":
		skill_label.text += "  |  %s - moving into range" % player._skill_display_name(player.cast_chase_skill)
	elif player.pending_skill != "":
		skill_label.text += "  |  %s armed - click a monster" % player._skill_display_name(player.pending_skill)
	if player.casting_skill != "":
		cast_label.text = "Casting %s..." % player._skill_display_name(player.casting_skill)
		cast_bar.max_value = player.casting_duration
		cast_bar.value = player.casting_duration - player.casting_time_left
		cast_label.visible = true
		cast_bar.visible = true
	else:
		cast_label.visible = false
		cast_bar.visible = false

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
