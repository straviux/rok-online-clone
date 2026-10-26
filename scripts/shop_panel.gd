extends CanvasLayer
## Phase 4 shop panel: opened by pressing E near the shopkeeper.
## Left: stock to buy (first click arms "Confirm?", second click buys —
## that is the buy confirmation). Right: your inventory to sell, at
## half the item's price. Esc (handled centrally in hud.gd, frontmost
## panel only) or the Close button closes the panel.

var _stock: Array = [
	preload("res://data/items/wooden_sword.tres"),
	preload("res://data/items/iron_sword.tres"),
	preload("res://data/items/leather_armor.tres"),
	preload("res://data/items/iron_armor.tres"),
	preload("res://data/items/novice_cap.tres"),
	preload("res://data/items/iron_helm.tres"),
	preload("res://data/items/wooden_ring.tres"),
	preload("res://data/items/silver_ring.tres"),
	preload("res://data/items/small_hp_potion.tres"),
	preload("res://data/items/hp_potion.tres"),
	preload("res://data/items/sp_potion.tres"),
]

var _pending_buy: ItemData = null

@onready var gold_label: Label = $Panel/GoldLabel
@onready var message_label: Label = $Panel/MessageLabel
@onready var stock_box: VBoxContainer = $Panel/StockBox
@onready var sell_box: VBoxContainer = $Panel/SellBox


func _ready() -> void:
	add_to_group("shop_panel")
	visible = false
	($Panel/CloseButton as Button).pressed.connect(_on_close_pressed)


func _on_close_pressed() -> void:
	visible = false


func refresh() -> void:
	gold_label.text = "Gold: %d" % GameManager.gold
	_clear_box(stock_box)
	_clear_box(sell_box)
	for stock_item: ItemData in _stock:
		var button_text: String = "Confirm?" if _pending_buy == stock_item else "Buy"
		var button: Button = _add_row(stock_box, "%s — %d gold%s" % [stock_item.item_name, stock_item.price, _bonus_text(stock_item)], button_text)
		button.pressed.connect(_on_buy_pressed.bind(stock_item))
	for slot: Dictionary in GameManager.inventory:
		var item: ItemData = slot["item"]
		var count: int = slot["count"]
		var label_text: String = item.item_name
		if item.stackable:
			label_text += " x%d" % count
		label_text += " — sells for %d gold" % (item.price / 2)
		var button: Button = _add_row(sell_box, label_text, "Sell")
		button.pressed.connect(_on_sell_pressed.bind(item))


func _on_buy_pressed(item: ItemData) -> void:
	if _pending_buy != item:
		_pending_buy = item
		refresh()
		return
	_pending_buy = null
	if GameManager.gold < item.price:
		message_label.text = "Not enough gold!"
		refresh()
		return
	GameManager.gold -= item.price
	GameManager.add_item(item, 1)
	message_label.text = "Bought %s" % item.item_name
	refresh()


func _on_sell_pressed(item: ItemData) -> void:
	if GameManager.remove_item(item, 1):
		var sell_price: int = item.price / 2
		GameManager.gold += sell_price
		message_label.text = "Sold %s for %d gold" % [item.item_name, sell_price]
	refresh()


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


func _bonus_text(item: ItemData) -> String:
	var text_value: String = ""
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
