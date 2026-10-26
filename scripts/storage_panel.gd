extends CanvasLayer
## Phase 4 storage panel: opened by pressing E near the storage keeper.
## Left: your inventory, Deposit moves one item into storage.
## Right: storage, Withdraw moves one item back into inventory.
## Esc (handled centrally in hud.gd, frontmost panel only) or the
## Close button closes the panel.

@onready var gold_label: Label = $Panel/GoldLabel
@onready var inventory_box: VBoxContainer = $Panel/InventoryBox
@onready var storage_box: VBoxContainer = $Panel/StorageBox


func _ready() -> void:
	add_to_group("storage_panel")
	visible = false
	($Panel/CloseButton as Button).pressed.connect(_on_close_pressed)


func _on_close_pressed() -> void:
	visible = false


func refresh() -> void:
	gold_label.text = "Gold: %d" % GameManager.gold
	_clear_box(inventory_box)
	_clear_box(storage_box)
	for slot: Dictionary in GameManager.inventory:
		var item: ItemData = slot["item"]
		var count: int = slot["count"]
		var label_text: String = item.item_name
		if item.stackable:
			label_text += " x%d" % count
		var button: Button = _add_row(inventory_box, label_text, "Deposit", item)
		button.pressed.connect(_on_deposit_pressed.bind(item))
	for slot: Dictionary in GameManager.storage:
		var item: ItemData = slot["item"]
		var count: int = slot["count"]
		var label_text: String = item.item_name
		if item.stackable:
			label_text += " x%d" % count
		var button: Button = _add_row(storage_box, label_text, "Withdraw", item)
		button.pressed.connect(_on_withdraw_pressed.bind(item))


func _on_deposit_pressed(item: ItemData) -> void:
	GameManager.deposit_item(item)
	refresh()


func _on_withdraw_pressed(item: ItemData) -> void:
	GameManager.withdraw_item(item)
	refresh()


func _clear_box(box: VBoxContainer) -> void:
	for child: Node in box.get_children():
		box.remove_child(child)
		child.free()


func _add_row(box: VBoxContainer, text_value: String, button_text: String, item: ItemData = null) -> Button:
	var row := HBoxContainer.new()
	if item != null:
		var icon_tex: Texture2D = ItemIcons.get_texture(item.item_id)
		if icon_tex != null:
			var icon_rect := TextureRect.new()
			icon_rect.texture = icon_tex
			icon_rect.custom_minimum_size = Vector2(32, 32)
			icon_rect.expand_mode = TextureRect.EXPAND_KEEP_SIZE
			row.add_child(icon_rect)

	var label := Label.new()
	label.text = text_value
	label.size_flags_horizontal = 3
	row.add_child(label)
	var button := Button.new()
	button.text = button_text
	row.add_child(button)
	box.add_child(row)
	return button
