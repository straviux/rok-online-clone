extends Area2D
## Phase 4 item drop: a monster's loot, lying on the ground.
## Walk over it to collect it into the inventory. The pickup's colour
## comes from its item, so potions, weapons, and rings look different.

var item: ItemData = null

var _damage_number_scene: PackedScene = preload("res://scenes/ui/damage_number.tscn")

@onready var icon: Sprite2D = $Icon


func _ready() -> void:
	if item != null:
		# Laphkal icon if the pack has one for this item, otherwise
		# the old coloured square (herb has no icon in the pack).
		var tex: Texture2D = ItemIcons.get_texture(item.item_id)
		if tex != null:
			icon.texture = tex
		else:
			var image := Image.create(20, 20, false, Image.FORMAT_RGBA8)
			image.fill(item.color)
			icon.texture = ImageTexture.create_from_image(image)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	if item != null:
		SFX.play("pickup")
		GameManager.add_item(item, 1)
		# Phase 5: collect quests count pickups, not inventory totals,
		# so herbs found before accepting the quest do not count.
		GameManager.notify_item_collected(item.item_id)
		var number: Node = _damage_number_scene.instantiate()
		number.position = body.global_position + Vector2(0.0, -50.0)
		get_tree().current_scene.add_child(number)
		number.setup_damage("Got " + item.item_name, Color(0.4, 1.0, 0.4, 1.0))
	queue_free()
