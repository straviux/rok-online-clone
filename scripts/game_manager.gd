extends Node
## Autoloaded game state. Autoloads persist across scene changes, so
## map travel (Phase 1), gold (Phase 2), and now inventory, equipment,
## and storage (Phase 4) all survive changing scenes, while the Player
## node itself is recreated in every world scene.
##
## Inventory/storage slots are Dictionaries: {"item": ItemData, "count": int}.
## Equipment is a Dictionary of slot name -> ItemData or null.

var spawn_position: Vector2 = Vector2.ZERO
var has_spawn_position: bool = false
var gold: int = 0
var inventory: Array = []
var storage: Array = []
var equipment: Dictionary = {
	"weapon": null,
	"armor": null,
	"headgear": null,
	"accessory": null,
}


func travel_to(scene_path: String, spawn: Vector2) -> void:
	if scene_path.is_empty():
		return
	spawn_position = spawn
	has_spawn_position = true
	get_tree().change_scene_to_file(scene_path)


func _ready() -> void:
	# Starting gear and potions, once, on a fresh game.
	if inventory.is_empty() and equipment["weapon"] == null:
		var hp_potion: ItemData = preload("res://data/items/hp_potion.tres")
		var wooden_sword: ItemData = preload("res://data/items/wooden_sword.tres")
		var leather_armor: ItemData = preload("res://data/items/leather_armor.tres")
		add_item(hp_potion, 3)
		add_item(wooden_sword, 1)
		add_item(leather_armor, 1)
		equip(wooden_sword)
		equip(leather_armor)


func _add_to_list(list: Array, item: ItemData, count: int) -> void:
	for slot: Dictionary in list:
		if slot["item"].item_id == item.item_id and item.stackable:
			slot["count"] += count
			return
	list.append({"item": item, "count": count})


func _remove_from_list(list: Array, item: ItemData, count: int) -> bool:
	for slot: Dictionary in list:
		if slot["item"].item_id == item.item_id:
			if slot["count"] <= count:
				list.erase(slot)
			else:
				slot["count"] -= count
			return true
	return false


func _count_in_list(list: Array, item_id: String) -> int:
	var total: int = 0
	for slot: Dictionary in list:
		if slot["item"].item_id == item_id:
			total += slot["count"]
	return total


func add_item(item: ItemData, count: int = 1) -> void:
	_add_to_list(inventory, item, count)


func remove_item(item: ItemData, count: int = 1) -> bool:
	return _remove_from_list(inventory, item, count)


func count_item(item_id: String) -> int:
	return _count_in_list(inventory, item_id)


func equip(item: ItemData) -> bool:
	var slot_name: String = item.slot_name()
	if slot_name.is_empty():
		return false
	if not remove_item(item, 1):
		return false
	var current: ItemData = equipment[slot_name]
	if current != null:
		add_item(current, 1)
	equipment[slot_name] = item
	return true


func unequip(slot_name: String) -> bool:
	var current: ItemData = equipment.get(slot_name, null)
	if current == null:
		return false
	add_item(current, 1)
	equipment[slot_name] = null
	return true


func deposit_item(item: ItemData) -> bool:
	if not remove_item(item, 1):
		return false
	_add_to_list(storage, item, 1)
	return true


func withdraw_item(item: ItemData) -> bool:
	if not _remove_from_list(storage, item, 1):
		return false
	_add_to_list(inventory, item, 1)
	return true
