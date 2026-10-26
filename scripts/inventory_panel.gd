extends CanvasLayer
## Phase 4 inventory panel: press I to open/close.
## Rows are built in code (the list length changes as items are
## gained, used, or equipped), from GameManager.inventory and
## GameManager.equipment. Equipping calls player.recalculate_derived()
## so the new bonuses apply immediately.

@onready var gold_label: Label = $Panel/GoldLabel
@onready var equipped_box: VBoxContainer = $Panel/EquippedBox
@onready var inventory_box: VBoxContainer = $Panel/InventoryBox


func _ready() -> void:
	add_to_group("inventory_panel")
	visible = false
	($Panel/CloseButton as Button).pressed.connect(_on_close_pressed)


func _on_close_pressed() -> void:
	visible = false


func _input(event: InputEvent) -> void:
	# Esc is handled centrally in hud.gd (frontmost panel only), so
	# this panel must not close itself on Esc too — that is what made
	# one Esc press close every open panel.
	if event is InputEventKey:
		if event.keycode == KEY_I and event.pressed and not event.echo:
			visible = not visible
			if visible:
				refresh()


func refresh() -> void:
	gold_label.text = "Gold: %d" % GameManager.gold
	_clear_box(equipped_box)
	_clear_box(inventory_box)
	for slot_name: String in ["weapon", "armor", "headgear", "accessory"]:
		var equipped: ItemData = GameManager.equipment[slot_name]
		if equipped != null:
			_add_unequip_row(equipped_box, "%s: %s" % [slot_name.capitalize(), _summary(equipped, 1)], slot_name, false)
		else:
			_add_unequip_row(equipped_box, "%s: (empty)" % slot_name.capitalize(), slot_name, true)
	for slot: Dictionary in GameManager.inventory:
		var item: ItemData = slot["item"]
		var count: int = slot["count"]
		if item.item_type == ItemData.ItemType.CONSUMABLE:
			_add_item_row(inventory_box, _summary(item, count), "Use", item, "use")
		elif item.slot_name() != "":
			_add_item_row(inventory_box, _summary(item, count), "Equip", item, "equip")
		else:
			_add_item_row(inventory_box, _summary(item, count), "-", item, "none")


func _clear_box(box: VBoxContainer) -> void:
	for child: Node in box.get_children():
		box.remove_child(child)
		child.free()


func _add_row(box: VBoxContainer, text_value: String, button_text: String) -> Button:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = text_value
	label.size_flags_horizontal = 3
	row.add_child(label)
	var button := Button.new()
	button.text = button_text
	row.add_child(button)
	box.add_child(row)
	return button


func _add_item_row(box: VBoxContainer, text_value: String, button_text: String, item: ItemData, action: String) -> void:
	var button: Button = _add_row(box, text_value, button_text)
	if action == "none":
		button.disabled = true
	else:
		button.pressed.connect(_on_item_pressed.bind(item, action))


func _add_unequip_row(box: VBoxContainer, text_value: String, slot_name: String, disabled: bool) -> void:
	var button: Button = _add_row(box, text_value, "Unequip")
	button.disabled = disabled
	if not disabled:
		button.pressed.connect(_on_unequip_pressed.bind(slot_name))


func _on_item_pressed(item: ItemData, action: String) -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	if action == "equip":
		if GameManager.equip(item):
			player.recalculate_derived()
	elif action == "use":
		player.use_item(item)
	refresh()


func _on_unequip_pressed(slot_name: String) -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if GameManager.unequip(slot_name) and player != null:
		player.recalculate_derived()
	refresh()


func _summary(item: ItemData, count: int) -> String:
	var text_value: String = item.item_name
	if item.stackable:
		text_value += " x%d" % count
	if item.attack_bonus > 0:
		text_value += "  +%d Atk" % item.attack_bonus
	if item.defence_bonus > 0:
		text_value += "  +%d Def" % item.defence_bonus
	if item.hp_bonus > 0:
		text_value += "  +%d HP" % item.hp_bonus
	if item.sp_bonus > 0:
		text_value += "  +%d SP" % item.sp_bonus
	if item.heal_hp > 0:
		text_value += "  Heals %d HP" % item.heal_hp
	if item.heal_sp > 0:
		text_value += "  Heals %d SP" % item.heal_sp
	return text_value
