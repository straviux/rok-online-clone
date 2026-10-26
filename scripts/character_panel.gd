extends CanvasLayer
## Phase 3 character panel: press C to open/close, spend stat points
## with the + buttons. The game keeps running while it is open.
## Labels refresh every frame while visible, from the player node.

@onready var level_label: Label = $Panel/LevelLabel
@onready var xp_label: Label = $Panel/XPLabel
@onready var hp_label: Label = $Panel/HPLabel
@onready var sp_label: Label = $Panel/SPLabel
@onready var points_label: Label = $Panel/PointsLabel
@onready var str_label: Label = $Panel/STRLabel
@onready var agi_label: Label = $Panel/AGILabel
@onready var vit_label: Label = $Panel/VITLabel
@onready var int_label: Label = $Panel/INTLabel
@onready var dex_label: Label = $Panel/DEXLabel
@onready var luk_label: Label = $Panel/LUKLabel
@onready var derived_label: Label = $Panel/DerivedLabel
@onready var equipment1_label: Label = $Panel/EquipmentLabel1
@onready var equipment2_label: Label = $Panel/EquipmentLabel2


func _ready() -> void:
	add_to_group("character_panel")
	visible = false
	($Panel/CloseButton as Button).pressed.connect(_on_close_pressed)
	($Panel/STRButton as Button).pressed.connect(_on_add_stat.bind("STR"))
	($Panel/AGIButton as Button).pressed.connect(_on_add_stat.bind("AGI"))
	($Panel/VITButton as Button).pressed.connect(_on_add_stat.bind("VIT"))
	($Panel/INTButton as Button).pressed.connect(_on_add_stat.bind("INT"))
	($Panel/DEXButton as Button).pressed.connect(_on_add_stat.bind("DEX"))
	($Panel/LUKButton as Button).pressed.connect(_on_add_stat.bind("LUK"))


func _on_add_stat(stat_name: String) -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if player != null:
		player.spend_stat_point(stat_name)


func _on_close_pressed() -> void:
	visible = false


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.keycode == KEY_C:
				visible = not visible
			elif event.keycode == KEY_ESCAPE and visible:
				# Esc closes whichever panel is in front.
				visible = false


func _process(_delta: float) -> void:
	if not visible:
		return
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	level_label.text = "Level: %d" % player.level
	xp_label.text = "XP: %d / %d" % [player.xp, player.xp_to_next()]
	hp_label.text = "HP: %d / %d" % [int(player.hp), player.max_hp]
	sp_label.text = "SP: %d / %d" % [int(player.sp), player.max_sp]
	points_label.text = "Stat points: %d" % player.stat_points
	str_label.text = "STR: %d" % player.stat_str
	agi_label.text = "AGI: %d" % player.stat_agi
	vit_label.text = "VIT: %d" % player.stat_vit
	int_label.text = "INT: %d" % player.stat_int
	dex_label.text = "DEX: %d" % player.stat_dex
	luk_label.text = "LUK: %d" % player.stat_luk
	derived_label.text = "Atk: %d  Def: %d  Range: %d  Crit: %d%%  Heal: %d  Bolt: %d" % [
		player.attack_damage,
		player.defence,
		int(player.attack_range),
		int(player.crit_chance * 100.0),
		player.heal_amount,
		player.fire_bolt_damage,
	]
	equipment1_label.text = "Weapon: %s  Armor: %s" % [
		_equipment_name(GameManager.equipment["weapon"]),
		_equipment_name(GameManager.equipment["armor"]),
	]
	equipment2_label.text = "Head: %s  Accessory: %s" % [
		_equipment_name(GameManager.equipment["headgear"]),
		_equipment_name(GameManager.equipment["accessory"]),
	]


func _equipment_name(item: ItemData) -> String:
	if item == null:
		return "(none)"
	return item.item_name
