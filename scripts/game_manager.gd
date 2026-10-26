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
# Player progression, kept here for the same reason as gold and
# inventory: the Player node is recreated in every world scene, so
# anything stored only on it (level, XP, stats) reset on every map
# change. These are the single source of truth; the Player loads
# them in _ready() and they are captured again before every travel.
# player_hp/player_sp of -1 means "full on next spawn" (used after
# death, where the respawn is at full HP/SP).
var has_player_state: bool = false
var player_level: int = 1
var player_xp: int = 0
var player_stat_points: int = 0
var player_stat_str: int = 5
var player_stat_agi: int = 5
var player_stat_vit: int = 5
var player_stat_int: int = 5
var player_stat_dex: int = 5
var player_stat_luk: int = 5
var player_hp: float = -1.0
var player_sp: float = -1.0
# Phase 5 quests, in chain order. quests[quest_id] is a Dictionary:
# {"data": QuestData, "state": String, "progress": int}.
# States: "locked" (earlier quest not done), "available" (talk to the
# Elder), "active", "done".
var quest_order: Array = ["meet_elder", "slime_hunt", "herb_gathering", "wolf_hunt", "dungeon_boss"]
var quests: Dictionary = {}


func capture_player_state(player: Node, keep_hp: bool = true) -> void:
	if player == null:
		return
	player_level = player.level
	player_xp = player.xp
	player_stat_points = player.stat_points
	player_stat_str = player.stat_str
	player_stat_agi = player.stat_agi
	player_stat_vit = player.stat_vit
	player_stat_int = player.stat_int
	player_stat_dex = player.stat_dex
	player_stat_luk = player.stat_luk
	if keep_hp:
		player_hp = player.hp
		player_sp = player.sp
	else:
		player_hp = -1.0
		player_sp = -1.0
	has_player_state = true


func travel_to(scene_path: String, spawn: Vector2, keep_hp: bool = true) -> void:
	if scene_path.is_empty():
		return
	# Capture before the scene changes, or the old Player (and its
	# level, XP, and stats) is gone with the old scene.
	capture_player_state(get_tree().get_first_node_in_group("player"), keep_hp)
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
	# Quests init on their own guard, not inside the starting-gear
	# block, so they are set up even if the inventory is not empty.
	_init_quests()


func _init_quests() -> void:
	if not quests.is_empty():
		return
	var quest_files: Dictionary = {
		"meet_elder": preload("res://data/quests/meet_elder.tres"),
		"slime_hunt": preload("res://data/quests/slime_hunt.tres"),
		"herb_gathering": preload("res://data/quests/herb_gathering.tres"),
		"wolf_hunt": preload("res://data/quests/wolf_hunt.tres"),
		"dungeon_boss": preload("res://data/quests/dungeon_boss.tres"),
	}
	for index: int in range(quest_order.size()):
		var quest_id: String = quest_order[index]
		quests[quest_id] = {
			"data": quest_files[quest_id],
			"state": "available" if index == 0 else "locked",
			"progress": 0,
		}


func accept_quest(quest_id: String) -> void:
	var quest: Dictionary = quests.get(quest_id, {})
	if quest.is_empty() or quest["state"] != "available":
		return
	quest["state"] = "active"
	# Talking to the Elder IS the talk quest's objective, so it
	# completes as soon as it is accepted.
	var data: QuestData = quest["data"]
	if data.objective_type == "talk":
		_complete_quest(quest_id)


func notify_kill(monster_id: String) -> void:
	if monster_id.is_empty():
		return
	for quest_id: String in quest_order:
		var quest: Dictionary = quests[quest_id]
		if quest["state"] != "active":
			continue
		var data: QuestData = quest["data"]
		if data.objective_type in ["kill", "boss"] and data.target_id == monster_id:
			quest["progress"] += 1
			if quest["progress"] >= data.amount:
				_complete_quest(quest_id)


func notify_item_collected(item_id: String) -> void:
	for quest_id: String in quest_order:
		var quest: Dictionary = quests[quest_id]
		if quest["state"] != "active":
			continue
		var data: QuestData = quest["data"]
		if data.objective_type == "collect" and data.target_id == item_id:
			quest["progress"] += 1
			if quest["progress"] >= data.amount:
				_complete_quest(quest_id)


func _complete_quest(quest_id: String) -> void:
	var quest: Dictionary = quests[quest_id]
	var data: QuestData = quest["data"]
	quest["state"] = "done"
	quest["progress"] = data.amount
	gold += data.reward_gold
	if data.reward_item_id != "":
		var reward_item: ItemData = _load_item(data.reward_item_id)
		if reward_item != null:
			add_item(reward_item, 1)
	var player: Node = get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("gain_xp"):
		player.gain_xp(data.reward_xp)
	_show_quest_message("Quest complete: " + data.quest_name)
	# Unlock the next quest in the chain.
	var index: int = quest_order.find(quest_id)
	if index >= 0 and index + 1 < quest_order.size():
		var next_quest: Dictionary = quests[quest_order[index + 1]]
		if next_quest["state"] == "locked":
			next_quest["state"] = "available"


func _load_item(item_id: String) -> ItemData:
	match item_id:
		"iron_sword":
			return preload("res://data/items/iron_sword.tres")
	return null


func _show_quest_message(text_value: String) -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var damage_number_scene: PackedScene = preload("res://scenes/ui/damage_number.tscn")
	var number: Node = damage_number_scene.instantiate()
	number.position = player.global_position + Vector2(0.0, -70.0)
	get_tree().current_scene.add_child(number)
	number.setup_damage(text_value, Color(0.4, 1.0, 0.4, 1.0))


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
