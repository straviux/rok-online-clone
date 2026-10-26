extends CanvasLayer
## Phase 2 HUD: player HP, gold, and the current target's HP.
## The target bars hide when nothing is targeted (town, or no monster).

@onready var hp_bar: ProgressBar = $HPBar
@onready var gold_label: Label = $GoldLabel
@onready var target_label: Label = $TargetLabel
@onready var target_bar: ProgressBar = $TargetBar


func _ready() -> void:
	hp_bar.show_percentage = false
	target_bar.show_percentage = false


func _process(_delta: float) -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	hp_bar.max_value = player.max_hp
	hp_bar.value = player.hp
	gold_label.text = "Gold: %d" % GameManager.gold

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
