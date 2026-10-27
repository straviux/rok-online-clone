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
# Phase 6: set once, when the Dungeon Guardian dies (monster.gd). It
# survives the boss respawning, and it is part of every save file.
var dungeon_boss_defeated: bool = false


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
	if scene_path == "res://scenes/world/town.tscn":
		# Phase 6 autosave: arriving in town always writes the
		# autosave slot for the town just entered.
		_write_save("autosave", scene_path, spawn)
	get_tree().change_scene_to_file(scene_path)


func _ready() -> void:
	# Starting gear and potions, once, on a fresh game.
	if inventory.is_empty() and equipment["weapon"] == null:
		_give_starting_gear()
	# Quests init on their own guard, not inside the starting-gear
	# block, so they are set up even if the inventory is not empty.
	_init_quests()


func _give_starting_gear() -> void:
	var hp_potion: ItemData = preload("res://data/items/hp_potion.tres")
	var wooden_sword: ItemData = preload("res://data/items/wooden_sword.tres")
	var leather_armor: ItemData = preload("res://data/items/leather_armor.tres")
	add_item(hp_potion, 3)
	add_item(wooden_sword, 1)
	add_item(leather_armor, 1)
	equip(wooden_sword)
	equip(leather_armor)


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


func _item_catalog() -> Dictionary:
	# Every item id in data/items/, so saves can rebuild inventories
	# and equipment from ids alone. Quest rewards use this too.
	return {
		"herb": preload("res://data/items/herb.tres"),
		"hp_potion": preload("res://data/items/hp_potion.tres"),
		"iron_armor": preload("res://data/items/iron_armor.tres"),
		"iron_helm": preload("res://data/items/iron_helm.tres"),
		"iron_sword": preload("res://data/items/iron_sword.tres"),
		"leather_armor": preload("res://data/items/leather_armor.tres"),
		"novice_cap": preload("res://data/items/novice_cap.tres"),
		"silver_ring": preload("res://data/items/silver_ring.tres"),
		"small_hp_potion": preload("res://data/items/small_hp_potion.tres"),
		"sp_potion": preload("res://data/items/sp_potion.tres"),
		"wooden_ring": preload("res://data/items/wooden_ring.tres"),
		"wooden_sword": preload("res://data/items/wooden_sword.tres"),
	}


func _load_item(item_id: String) -> ItemData:
	return _item_catalog().get(item_id, null)


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

# ------------------------------------------------------------------
# Phase 6: save/load. One ConfigFile per slot in user://, so saves
# live on the player's device and survive closing the game:
# "manual" is the pause menu's Save button, "autosave" is written
# automatically on entering town (see travel_to).
# A load is validated into temporary values FIRST and only applied
# once every check passes, so a missing, partial, or corrupted file
# can never leave the game in a half-loaded state: it just reports
# an error and the caller stays where it was (title or pause menu).

const SAVE_VERSION: int = 1
const KNOWN_MAPS: Array = [
	"res://scenes/world/town.tscn",
	"res://scenes/world/field.tscn",
	"res://scenes/world/dungeon.tscn",
]
const _QUEST_STATES: Array = ["locked", "available", "active", "done"]


func _save_path(slot: String) -> String:
	return "user://save_" + slot + ".cfg"


func has_save(slot: String) -> bool:
	return FileAccess.file_exists(_save_path(slot))


func start_new_game() -> void:
	# Fresh state, then town at its default spawn. Autoloads are never
	# re-created, so _ready()'s one-time gear block cannot do this.
	gold = 0
	inventory = []
	storage = []
	equipment = {"weapon": null, "armor": null, "headgear": null, "accessory": null}
	player_level = 1
	player_xp = 0
	player_stat_points = 0
	player_stat_str = 5
	player_stat_agi = 5
	player_stat_vit = 5
	player_stat_int = 5
	player_stat_dex = 5
	player_stat_luk = 5
	player_hp = -1.0
	player_sp = -1.0
	has_player_state = false
	dungeon_boss_defeated = false
	quests = {}
	_init_quests()
	_give_starting_gear()
	spawn_position = Vector2(0, 300)
	has_spawn_position = true
	get_tree().change_scene_to_file("res://scenes/world/town.tscn")


func save_game(slot: String) -> String:
	# "" means saved; anything else is a plain-word error for the UI.
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		return "Cannot save right now: no adventurer is loaded."
	var scene: Node = get_tree().current_scene
	if scene == null or scene.scene_file_path not in KNOWN_MAPS:
		return "Cannot save from here."
	capture_player_state(player, true)
	return _write_save(slot, scene.scene_file_path, player.position)


func _write_save(slot: String, map_path: String, position: Vector2) -> String:
	var cfg := ConfigFile.new()
	cfg.set_value("save", "version", SAVE_VERSION)
	cfg.set_value("save", "map", map_path)
	cfg.set_value("save", "position", position)
	cfg.set_value("save", "gold", gold)
	cfg.set_value("save", "boss_defeated", dungeon_boss_defeated)
	cfg.set_value("save", "level", player_level)
	cfg.set_value("save", "xp", player_xp)
	cfg.set_value("save", "stat_points", player_stat_points)
	cfg.set_value("save", "stats", {
		"str": player_stat_str, "agi": player_stat_agi, "vit": player_stat_vit,
		"int": player_stat_int, "dex": player_stat_dex, "luk": player_stat_luk,
	})
	cfg.set_value("save", "hp", player_hp)
	cfg.set_value("save", "sp", player_sp)
	cfg.set_value("save", "inventory", _slots_to_data(inventory))
	cfg.set_value("save", "storage", _slots_to_data(storage))
	var equipment_ids: Dictionary = {}
	for slot_name: String in equipment:
		var equipped: ItemData = equipment[slot_name]
		equipment_ids[slot_name] = equipped.item_id if equipped != null else ""
	cfg.set_value("save", "equipment", equipment_ids)
	var quest_data: Array = []
	for quest_id: String in quest_order:
		var quest: Dictionary = quests.get(quest_id, {})
		if not quest.is_empty():
			quest_data.append({"id": quest_id, "state": quest["state"], "progress": quest["progress"]})
	cfg.set_value("save", "quests", quest_data)
	var err: Error = cfg.save(_save_path(slot))
	if err != OK:
		return "The save could not be written."
	return ""


func load_game(slot: String) -> String:
	# "" means loaded (the scene has changed); anything else is a
	# plain-word error and nothing was applied.
	if not has_save(slot):
		return "No save found."
	var cfg := ConfigFile.new()
	if cfg.load(_save_path(slot)) != OK:
		return "That save file could not be read."
	# --- validate everything into locals before touching live state ---
	# Every get_value below carries a default that FAILS its check, so
	# a partial file reports a plain error instead of printing engine
	# errors about missing keys (a null default would do the latter).
	var version: Variant = cfg.get_value("save", "version", -1)
	if typeof(version) != TYPE_INT or version != SAVE_VERSION:
		return "That save is from an unknown version."
	var map_path: Variant = cfg.get_value("save", "map", "")
	if typeof(map_path) != TYPE_STRING or map_path not in KNOWN_MAPS:
		return "That save points to a place that no longer exists."
	var position: Variant = cfg.get_value("save", "position", Vector2(1e10, 1e10))
	if typeof(position) != TYPE_VECTOR2 or not _is_finite_vector(position):
		return "That save has a broken position."
	var gold_value: Variant = cfg.get_value("save", "gold", -1)
	if typeof(gold_value) != TYPE_INT or gold_value < 0:
		return "That save has broken gold."
	var boss_value: Variant = cfg.get_value("save", "boss_defeated", -1)
	if typeof(boss_value) != TYPE_BOOL:
		return "That save has a broken dungeon record."
	var level_value: Variant = cfg.get_value("save", "level", -1)
	var xp_value: Variant = cfg.get_value("save", "xp", -1)
	var points_value: Variant = cfg.get_value("save", "stat_points", -1)
	if typeof(level_value) != TYPE_INT or level_value < 1 or level_value > 99:
		return "That save has a broken level."
	if typeof(xp_value) != TYPE_INT or xp_value < 0:
		return "That save has broken XP."
	if typeof(points_value) != TYPE_INT or points_value < 0:
		return "That save has broken stat points."
	var stats_value: Variant = cfg.get_value("save", "stats", {})
	if typeof(stats_value) != TYPE_DICTIONARY:
		return "That save has broken stats."
	var stats: Dictionary = {}
	for key: String in ["str", "agi", "vit", "int", "dex", "luk"]:
		var stat: Variant = stats_value.get(key, null)
		if typeof(stat) != TYPE_INT or stat < 1 or stat > 99:
			return "That save has a broken stat."
		stats[key] = stat
	var hp_value: Variant = cfg.get_value("save", "hp", -999.0)
	var sp_value: Variant = cfg.get_value("save", "sp", -999.0)
	if (typeof(hp_value) != TYPE_INT and typeof(hp_value) != TYPE_FLOAT) or hp_value < -1.0:
		return "That save has broken health."
	if (typeof(sp_value) != TYPE_INT and typeof(sp_value) != TYPE_FLOAT) or sp_value < -1.0:
		return "That save has broken mana."
	var inventory_value: Variant = cfg.get_value("save", "inventory", -1)
	var storage_value: Variant = cfg.get_value("save", "storage", -1)
	var equipment_value: Variant = cfg.get_value("save", "equipment", -1)
	var quests_value: Variant = cfg.get_value("save", "quests", -1)
	if typeof(inventory_value) != TYPE_ARRAY or typeof(storage_value) != TYPE_ARRAY:
		return "That save has broken items."
	if typeof(equipment_value) != TYPE_DICTIONARY or typeof(quests_value) != TYPE_ARRAY:
		return "That save has broken equipment or quests."
	# Malformed entries and unknown item ids are skipped by
	# _data_to_slots (an item removed from the game must not brick an
	# old save); only a wrong top-level type fails the load, above.
	var new_inventory: Array = _data_to_slots(inventory_value)
	var new_storage: Array = _data_to_slots(storage_value)
	var new_equipment: Dictionary = {"weapon": null, "armor": null, "headgear": null, "accessory": null}
	var catalog: Dictionary = _item_catalog()
	for slot_name: String in new_equipment:
		var item_id: Variant = equipment_value.get(slot_name, "")
		if typeof(item_id) == TYPE_STRING and item_id != "":
			# Unknown ids become an empty slot, never a crash: an item
			# removed from the game must not brick an old save.
			new_equipment[slot_name] = catalog.get(item_id, null)
	var new_quests: Dictionary = {}
	for entry: Variant in quests_value:
		if typeof(entry) != TYPE_DICTIONARY:
			return "That save has broken quests."
		var quest_id: Variant = entry.get("id", "")
		var quest_state: Variant = entry.get("state", "")
		var quest_progress: Variant = entry.get("progress", 0)
		if typeof(quest_id) != TYPE_STRING or quest_id not in quest_order:
			continue
		if typeof(quest_state) != TYPE_STRING or quest_state not in _QUEST_STATES:
			return "That save has broken quests."
		if typeof(quest_progress) != TYPE_INT or quest_progress < 0:
			return "That save has broken quests."
		new_quests[quest_id] = {"state": quest_state, "progress": quest_progress}
	# --- every check passed: apply, then change to the saved map ---
	gold = gold_value
	dungeon_boss_defeated = boss_value
	player_level = level_value
	player_xp = xp_value
	player_stat_points = points_value
	player_stat_str = stats["str"]
	player_stat_agi = stats["agi"]
	player_stat_vit = stats["vit"]
	player_stat_int = stats["int"]
	player_stat_dex = stats["dex"]
	player_stat_luk = stats["luk"]
	# 0 or less health on load means "came back full", the same
	# sentinel death respawn uses (-1). The new Player clamps to max.
	player_hp = -1.0 if float(hp_value) <= 0.0 else float(hp_value)
	player_sp = -1.0 if float(sp_value) <= 0.0 else float(sp_value)
	has_player_state = true
	inventory = new_inventory
	storage = new_storage
	equipment = new_equipment
	quests = {}
	_init_quests()
	for quest_id: String in new_quests:
		var saved: Dictionary = new_quests[quest_id]
		var quest: Dictionary = quests[quest_id]
		var data: QuestData = quest["data"]
		quest["state"] = saved["state"]
		quest["progress"] = mini(saved["progress"], data.amount)
		if quest["state"] == "done":
			quest["progress"] = data.amount
	spawn_position = Vector2(clampf(position.x, -1600.0, 1600.0), clampf(position.y, -1200.0, 1200.0))
	has_spawn_position = true
	get_tree().paused = false
	get_tree().change_scene_to_file(map_path)
	return ""


func _is_finite_vector(value: Vector2) -> bool:
	return absf(value.x) < 1e9 and absf(value.y) < 1e9 and value.x == value.x and value.y == value.y


func _slots_to_data(list: Array) -> Array:
	var data: Array = []
	for slot: Dictionary in list:
		var item: ItemData = slot["item"]
		data.append({"id": item.item_id, "count": slot["count"]})
	return data


func _data_to_slots(data: Array) -> Array:
	var list: Array = []
	var catalog: Dictionary = _item_catalog()
	for entry: Variant in data:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var item_id: Variant = entry.get("id", "")
		var count: Variant = entry.get("count", 0)
		if typeof(item_id) != TYPE_STRING or typeof(count) != TYPE_INT:
			continue
		var item: ItemData = catalog.get(item_id, null)
		if item == null:
			continue
		if not item.stackable:
			count = 1
		_add_to_list(list, item, clampi(count, 1, 999))
	return list

